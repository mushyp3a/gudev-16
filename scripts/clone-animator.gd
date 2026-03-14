extends Node2D

## Handles animation playback for clone instances
## Samples replay data and applies it to the clone's visual representation
## Listens to CloneManager state to determine behavior

# ========== PROPERTIES ==========

## Reference to the recording system (set by parent)
var recording_system: RecordingSystem

## ID of this clone (set by parent)
var clone_id: int = -1

# ========== NODES ==========

@onready var animator: AnimationPlayer = $Skeleton2D/hips/AnimationPlayer
@onready var skeleton: Node2D = $Skeleton2D
@onready var collision_detector: Area2D = $CollisionDetector

# Particle effect scene to instantiate on death
const DEATH_PARTICLES_SCENE = preload("res://scenes/effects/clone-death-particles.tscn")

# ========== STATE ==========

## Reference to CloneManager for state queries
var clone_manager: CloneManager = null

## Previous X position for movement detection
var prev_x: float = 0.0

## Whether this clone has died during this run (temporary state)
var is_dead: bool = false


# ========== INITIALIZATION ==========

func _ready() -> void:
	# Find CloneManager in the scene tree
	clone_manager = get_node_or_null("/root/CloneManager")
	if clone_manager == null:
		# Try alternative search
		clone_manager = get_tree().root.find_child("CloneManager", true, false)

	if clone_manager == null:
		push_warning("CloneAnimator: CloneManager not found")

	# Connect collision detection
	if collision_detector:
		collision_detector.body_entered.connect(_on_collision_detected)

	# Connect to CloneManager signals to reset death state
	if clone_manager:
		clone_manager.recording_started.connect(_on_run_started)
		clone_manager.playback_started.connect(_on_run_started)

# ========== ANIMATION ==========

## Play an animation with blending
func play_anim(anim_name: String) -> void:
	if animator.current_animation != anim_name:
		animator.play(anim_name, 0.15)

# ========== PROCESS ==========

func _process(_delta: float) -> void:
	# If dead, stay hidden and don't process
	if is_dead:
		visible = false
		return

	# Validate dependencies
	if clone_manager == null or recording_system == null:
		return

	var replay = recording_system.get_replay(clone_id)
	if replay == null or replay.is_empty():
		return

	# Handle different states
	match clone_manager.current_state:
		CloneState.State.IDLE:
			_handle_idle_state(replay)

		CloneState.State.WAITING_INPUT:
			_handle_waiting_state(replay)

		CloneState.State.RECORDING, CloneState.State.PLAYING:
			_handle_playback_state(replay)

# ========== STATE HANDLERS ==========

## Handle idle/paused state - show clone at final position
func _handle_idle_state(replay: Replay) -> void:
	# Determine the animation from the final recorded frame
	var final_anim = _get_animation_from_final_state(replay)
	play_anim(final_anim)

	# Stop the animation at the last frame
	if animator.is_playing():
		animator.seek(animator.current_animation_length, true)
		animator.pause()

	# Set facing direction from final recorded state
	if replay.facingHistory.size() > 0:
		skeleton.scale.x = replay.facingHistory[-1]

## Handle waiting for input state - show clone at starting position
func _handle_waiting_state(replay: Replay) -> void:
	# Hide the clone being created/initialized (it has no real recording yet)
	if recording_system and recording_system.current_recording_id == clone_id:
		visible = false
		return

	# Show existing clones at their starting position
	visible = true
	if replay.positionHistory.size() > 0:
		global_position = replay.positionHistory[0]
	play_anim("idle")

## Handle recording/playback state - sample and apply animation
func _handle_playback_state(replay: Replay) -> void:
	# Hide the clone being recorded — the player is the visual stand-in
	if clone_manager.current_state == CloneState.State.RECORDING:
		if recording_system.current_recording_id == clone_id:
			visible = false
			return
		else:
			# Ensure other clones are visible during recording
			visible = true

	# Ensure we have enough data to sample
	if replay.positionHistory.size() < 2:
		# Not enough data yet, stay at first position
		if replay.positionHistory.size() > 0:
			global_position = replay.positionHistory[0]
		play_anim("idle")
		return

	# Sample replay data at current time
	prev_x = global_position.x
	var state_data = recording_system.sample(clone_id, clone_manager.time_elapsed)

	if state_data.is_empty():
		return

	# Apply position and facing
	global_position = state_data["position"]
	skeleton.scale.x = state_data["facing"]

	# Determine if clone is moving horizontally
	var moving_x = abs(global_position.x - prev_x) > 0.5

	# Update animation based on state
	_update_animation(state_data, moving_x)

# ========== ANIMATION UPDATE ==========

## Determine and play the appropriate animation based on state data
func _update_animation(state: Dictionary, moving_x: bool) -> void:
	var vel_y = state.get("velocity_y", 0.0)

	# Priority order for animation selection
	if state.get("is_sliding", false):
		play_anim("slide")

	elif state.get("is_wall_sliding", false):
		play_anim("wall_slide")

	elif vel_y < -10:  # Moving upward
		if state.get("has_double_jump", true):
			play_anim("jump")        # First jump
		else:
			play_anim("double_jump")  # Second jump

	elif vel_y > 10:  # Falling
		play_anim("fall")

	elif moving_x:  # Moving horizontally
		play_anim("run")

	else:  # Stationary
		play_anim("idle")

# ========== COLLISION ==========

## Called when clone collides with a wall, door, or obstacle
func _on_collision_detected(body: Node) -> void:
	print("Clone %d collision detected with: %s" % [clone_id, body.name])

	# Don't trigger multiple times
	if is_dead:
		print("Clone %d already dead, ignoring" % clone_id)
		return

	# Check if it's actually a wall/door (layer 2)
	if body is StaticBody2D:
		print("Clone %d hit StaticBody2D, killing" % clone_id)
		_kill_clone()
	else:
		print("Clone %d hit non-StaticBody2D: %s" % [clone_id, body.get_class()])

## Kill this clone for this run (temporary, will respawn on next run)
func _kill_clone() -> void:
	print("Clone %d _kill_clone() called" % clone_id)
	is_dead = true

	# Spawn death particles at clone's current position
	var particles = DEATH_PARTICLES_SCENE.instantiate()
	particles.global_position = global_position

	# Add to scene root so they persist independently
	get_tree().root.add_child(particles)
	print("Clone %d: spawned death particles at %s" % [clone_id, global_position])

	# Shrink skeleton rapidly before hiding
	var original_scale = skeleton.scale
	var tween = create_tween()
	tween.tween_property(skeleton, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	skeleton.scale = original_scale  # Restore scale for next run

	# Hide clone after shrink
	visible = false
	play_anim("idle")  # Reset to idle for next run

## Reset death state when starting a new run
func _on_run_started(_param = null) -> void:
	is_dead = false
	visible = true

	# Ensure skeleton scale is restored (in case clone died mid-animation)
	if skeleton.scale == Vector2.ZERO:
		skeleton.scale = Vector2(1.0, 1.0)  # Default skeleton scale

## Determine animation name from the final frame of a replay
func _get_animation_from_final_state(replay: Replay) -> String:
	if replay.positionHistory.size() < 2:
		return "idle"

	# Get final frame state
	var last_idx = replay.positionHistory.size() - 1
	var vel_y = replay.velocityYHistory[last_idx]
	var is_sliding = replay.isSlidingHistory[last_idx]
	var is_wall_sliding = replay.isWallSlidingHistory[last_idx]
	var has_double_jump = replay.hasDoubleJumpHistory[last_idx]

	# Check if moving horizontally by comparing last two positions
	var moving_x = false
	if last_idx > 0:
		var delta_x = abs(replay.positionHistory[last_idx].x - replay.positionHistory[last_idx - 1].x)
		moving_x = delta_x > 0.5

	# Same logic as _update_animation
	if is_sliding:
		return "slide"
	elif is_wall_sliding:
		return "wall_slide"
	elif vel_y < -10:
		return "jump" if has_double_jump else "double_jump"
	elif vel_y > 10:
		return "fall"
	elif moving_x:
		return "run"
	else:
		return "idle"
