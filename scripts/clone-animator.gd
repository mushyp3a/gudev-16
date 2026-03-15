extends CharacterBody2D

var recording_system: RecordingSystem
var clone_id: int = -1

@onready var animator: AnimationPlayer = $Skeleton2D/hips/AnimationPlayer
@onready var skeleton: Node2D = $Skeleton2D
@onready var collision_detector: Area2D = $CollisionDetector
@onready var selection_indicator: Label = $SelectionIndicator

const DEATH_PARTICLES_SCENE = preload("res://scenes/effects/clone-death-particles.tscn")

var clone_manager: CloneManager = null
var prev_x: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	clone_manager = get_node_or_null("/root/CloneManager")
	if clone_manager == null:
		clone_manager = get_tree().root.find_child("CloneManager", true, false)

	if collision_detector:
		collision_detector.body_entered.connect(_on_collision_detected)

	if clone_manager:
		clone_manager.recording_started.connect(_on_run_started)
		clone_manager.playback_started.connect(_on_run_started)
		clone_manager.clone_selected.connect(_on_clone_selected)
		clone_manager.clone_deselected.connect(_on_clone_deselected)

	if selection_indicator:
		selection_indicator.visible = false

func play_anim(anim_name: String) -> void:
	if animator.current_animation != anim_name:
		animator.play(anim_name, 0.15)

func _process(_delta: float) -> void:
	if is_dead:
		visible = false
		return

	if clone_manager == null or recording_system == null:
		return

	var replay = recording_system.get_replay(clone_id)
	if replay == null or replay.is_empty():
		return

	match clone_manager.current_state:
		CloneState.State.IDLE:
			_handle_idle_state(replay)
		CloneState.State.WAITING_INPUT:
			_handle_waiting_state(replay)
		CloneState.State.RECORDING, CloneState.State.PLAYING:
			_handle_playback_state(replay)

func _handle_idle_state(replay: Replay) -> void:
	visible = true

	if replay.positionHistory.size() > 0:
		global_position = replay.positionHistory[-1]

	var final_anim = _get_animation_from_final_state(replay)
	play_anim(final_anim)

	if animator.is_playing():
		animator.seek(animator.current_animation_length, true)
		animator.pause()

	if replay.facingHistory.size() > 0:
		skeleton.scale.x = replay.facingHistory[-1]

func _handle_waiting_state(replay: Replay) -> void:
	if recording_system and recording_system.current_recording_id == clone_id:
		visible = false
		return

	visible = true
	if replay.positionHistory.size() > 0:
		global_position = replay.positionHistory[0]
	play_anim("idle")

func _handle_playback_state(replay: Replay) -> void:
	if clone_manager.current_state == CloneState.State.RECORDING:
		if recording_system.current_recording_id == clone_id:
			visible = false
			return
		else:
			visible = true
			# Disable collision detection during RECORDING for non-recording clones
			if collision_detector:
				collision_detector.monitoring = false
	else:
		# Enable collision detection during PLAYBACK
		if collision_detector:
			collision_detector.monitoring = true

	if replay.positionHistory.size() < 2:
		if replay.positionHistory.size() > 0:
			global_position = replay.positionHistory[0]
		play_anim("idle")
		return

	prev_x = global_position.x
	var state_data = recording_system.sample(clone_id, clone_manager.time_elapsed)

	if state_data.is_empty():
		return

	global_position = state_data["position"]
	skeleton.scale.x = state_data["facing"]

	var moving_x = abs(global_position.x - prev_x) > 0.5
	_update_animation(state_data, moving_x)

func _update_animation(state: Dictionary, moving_x: bool) -> void:
	var vel_y = state.get("velocity_y", 0.0)

	if state.get("is_sliding", false):
		play_anim("slide")
	elif state.get("is_wall_sliding", false):
		play_anim("wall_slide")
	elif vel_y < -10:
		if state.get("has_double_jump", true):
			play_anim("jump")
		else:
			play_anim("double_jump")
	elif vel_y > 10:
		play_anim("fall")
	elif moving_x:
		play_anim("run")
	else:
		play_anim("idle")

func _on_collision_detected(body: Node) -> void:
	if is_dead:
		return

	if body is StaticBody2D:
		print("Clone %d hit StaticBody2D: %s (monitoring: %s)" % [clone_id, body.name, collision_detector.monitoring if collision_detector else "null"])
		_kill_clone()

func _kill_clone() -> void:
	is_dead = true

	# Only notify CloneManager about death during PLAYBACK, not during RECORDING
	if clone_manager and clone_manager.current_state == CloneState.State.PLAYING:
		clone_manager.clone_died.emit(clone_id, clone_manager.time_elapsed)

	var particles = DEATH_PARTICLES_SCENE.instantiate()
	particles.global_position = global_position
	get_tree().root.add_child(particles)

	var original_scale = skeleton.scale
	var tween = create_tween()
	tween.tween_property(skeleton, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	skeleton.scale = original_scale

	visible = false
	play_anim("idle")

func _on_run_started(_param = null) -> void:
	is_dead = false
	visible = true

	if skeleton.scale == Vector2.ZERO:
		skeleton.scale = Vector2(1.0, 1.0)

func _on_clone_selected(selected_id: int) -> void:
	if selection_indicator:
		selection_indicator.visible = (selected_id == clone_id)

func _on_clone_deselected() -> void:
	if selection_indicator:
		selection_indicator.visible = false

func _get_animation_from_final_state(replay: Replay) -> String:
	if replay.positionHistory.size() < 2:
		return "idle"

	var last_idx = replay.positionHistory.size() - 1
	var vel_y = replay.velocityYHistory[last_idx]
	var is_sliding = replay.isSlidingHistory[last_idx]
	var is_wall_sliding = replay.isWallSlidingHistory[last_idx]
	var has_double_jump = replay.hasDoubleJumpHistory[last_idx]

	var moving_x = false
	if last_idx > 0:
		var delta_x = abs(replay.positionHistory[last_idx].x - replay.positionHistory[last_idx - 1].x)
		moving_x = delta_x > 0.5

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
