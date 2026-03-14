class_name CloneManager extends Node

## Main orchestrator for the clone/replay system
## Manages clone lifecycle, state transitions, and coordinates between components
## Communicates via signals for loose coupling

# ========== SIGNALS ==========

## Emitted when a new clone is created
signal clone_created(clone_id: int)

## Emitted when a clone is deleted/freed
signal clone_deleted(clone_id: int)

## Emitted when a clone slot is selected in the UI
signal clone_selected(clone_id: int)

## Emitted when clone selection is cleared
signal clone_deselected()

## Emitted when the system state changes
signal state_changed(new_state: CloneState.State)

## Emitted when recording starts for a clone
signal recording_started(clone_id: int)

## Emitted when recording stops
signal recording_stopped(clone_id: int)

## Emitted when playback begins (with list of clone IDs to play)
signal playback_started(clone_ids: Array[int])

## Emitted when playback ends
signal playback_stopped()

## Emitted each frame during recording/playback with elapsed time
signal time_updated(elapsed: float)

# ========== EXPORTS ==========

## Configuration resource for clone system settings
@export var config: CloneConfig

## Reference to the recording system
@export var recording_system: RecordingSystem

## Reference to the player node (for position reset)
@export var player_node: Node2D

## Starting position for player reset
@export var start_position: Vector2

# ========== STATE ==========

## Current state of the clone system
var current_state: CloneState.State = CloneState.State.IDLE

## Currently selected clone slot (-1 = none)
var selected_clone_id: int = -1

## Elapsed time in current session
var time_elapsed: float = 0.0

# ========== CLONE MANAGEMENT ==========

## Array of instantiated clone nodes
var clones: Array[Node] = []

## Array of available (unused) slot IDs
var available_slots: Array[int] = []

# ========== INITIALIZATION ==========

func _ready() -> void:
	if config == null:
		push_error("CloneManager: No CloneConfig assigned!")
		return

	if not config.is_valid():
		push_error("CloneManager: Invalid CloneConfig!")
		return

	# Set start position from player if not explicitly set
	if start_position == Vector2.ZERO and player_node != null:
		start_position = player_node.global_position

	_initialize_slots()

func _initialize_slots() -> void:
	clones.resize(config.max_clones)
	available_slots.clear()
	for i in range(config.max_clones):
		clones[i] = null
		available_slots.append(i)

# ========== CLONE LIFECYCLE ==========

## Create a new clone in the specified slot
## Automatically cleans up any existing clone in that slot
func create_clone(slot_id: int) -> void:
	if slot_id < 0 or slot_id >= config.max_clones:
		push_error("CloneManager: Invalid slot_id %d" % slot_id)
		return

	# Clean up old clone if exists
	if clones[slot_id] != null:
		delete_clone(slot_id)

	# Load and instantiate clone scene
	var clone_scene = load(config.clone_scene_path)
	if clone_scene == null:
		push_error("CloneManager: Failed to load clone scene at %s" % config.clone_scene_path)
		return

	var clone = clone_scene.instantiate()
	clone.clone_id = slot_id
	clone.recording_system = recording_system

	# Start invisible - will be shown by animator if needed
	clone.visible = false

	# Also set properties on the child script node (for forwarding)
	var script_node = clone.get_node_or_null("ReplayCloneScript")
	if script_node:
		script_node.clone_id = slot_id
		script_node.recording_system = recording_system

	# Add to scene tree
	get_tree().root.add_child(clone)
	clones[slot_id] = clone

	# Remove from available slots
	available_slots.erase(slot_id)

	clone_created.emit(slot_id)

## Delete and free a clone from a specific slot
func delete_clone(slot_id: int) -> void:
	if slot_id < 0 or slot_id >= clones.size():
		return

	if clones[slot_id] != null:
		clones[slot_id].queue_free()
		clones[slot_id] = null

		# Add back to available slots
		if not available_slots.has(slot_id):
			available_slots.append(slot_id)

		clone_deleted.emit(slot_id)

# ========== SELECTION ==========

## Select a clone slot (for UI highlighting and operations)
func select_clone(slot_id: int) -> void:
	if slot_id < 0 or slot_id >= config.max_clones:
		return

	selected_clone_id = slot_id
	clone_selected.emit(slot_id)
	_update_clone_visibility()

## Deselect the currently selected clone
func deselect_clone() -> void:
	selected_clone_id = -1
	clone_deselected.emit()
	_update_clone_visibility()

# ========== RECORDING ==========

## Start recording a new clone in the specified slot
func start_recording(slot_id: int) -> void:
	if not CloneState.can_transition(current_state, CloneState.State.WAITING_INPUT):
		push_warning("CloneManager: Cannot start recording from state %s" % CloneState.get_state_name(current_state))
		return

	if player_node == null:
		push_error("CloneManager: player_node is not set!")
		return

	create_clone(slot_id)

	# Reset all existing clones' playback positions so they can replay during recording
	recording_system.reset_playback()

	# Initialize the replay slot but don't start recording yet (wait for input)
	recording_system.replays[slot_id] = Replay.new(player_node.global_position, 0.0, PlayerActions.new([]))
	recording_system.current_recording_id = slot_id
	time_elapsed = 0.0
	recording_system.set_time(time_elapsed)
	_change_state(CloneState.State.WAITING_INPUT)
	recording_started.emit(slot_id)

## Stop the current recording session
func stop_recording() -> void:
	var recording_id = recording_system.current_recording_id
	recording_system.stop_recording()
	_reset_to_start()
	recording_stopped.emit(recording_id)

# ========== PLAYBACK ==========

## Start playing back clones
## clone_ids: Array of slot IDs to play (empty array = play all)
func start_playback(clone_ids: Array[int]) -> void:
	if not CloneState.can_transition(current_state, CloneState.State.PLAYING):
		push_warning("CloneManager: Cannot start playback from state %s" % CloneState.get_state_name(current_state))
		return

	recording_system.reset_playback()
	time_elapsed = 0.0
	recording_system.set_time(time_elapsed)
	_change_state(CloneState.State.PLAYING)
	playback_started.emit(clone_ids)

## Stop the current playback session
func stop_playback() -> void:
	# Reset player to spawn
	if player_node != null:
		player_node.global_position = start_position
		# Cancel all momentum and movement state
		if player_node.has_method("reset_movement_state"):
			player_node.reset_movement_state()
		elif player_node is CharacterBody2D:
			player_node.velocity = Vector2.ZERO

	# Set time to max to show full duration on timer
	time_elapsed = config.time_limit
	recording_system.set_time(time_elapsed)

	# Snap all clones to their final positions
	_snap_clones_to_final_positions()

	_change_state(CloneState.State.IDLE)
	playback_stopped.emit()

# ========== STATE MANAGEMENT ==========

## Change the current state and emit signal
func _change_state(new_state: CloneState.State) -> void:
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		state_changed.emit(new_state)

## Check if currently in a paused/idle state
func is_paused() -> bool:
	return current_state == CloneState.State.IDLE

# ========== VISIBILITY CONTROL ==========

## Update clone visibility based on selection
func _update_clone_visibility() -> void:
	if selected_clone_id == -1:
		show_all_clones()
	else:
		show_clone(selected_clone_id)

## Show only a specific clone, hide all others
func show_clone(slot_id: int) -> void:
	for i in range(clones.size()):
		if clones[i] != null:
			clones[i].visible = (i == slot_id)

## Show all existing clones
func show_all_clones() -> void:
	for clone in clones:
		if clone != null:
			clone.visible = true

# ========== POSITION MANAGEMENT ==========

## Reset player and system to starting state
func _reset_to_start() -> void:
	if player_node != null:
		player_node.global_position = start_position
		# Cancel all momentum and movement state
		if player_node.has_method("reset_movement_state"):
			player_node.reset_movement_state()
		elif player_node is CharacterBody2D:
			player_node.velocity = Vector2.ZERO

	# Set time to max to show full duration on timer
	time_elapsed = config.time_limit
	recording_system.set_time(time_elapsed)

	# Snap all clones to their final positions
	_snap_clones_to_final_positions()

	_change_state(CloneState.State.IDLE)

## Snap all clones to their final recorded positions
func _snap_clones_to_final_positions() -> void:
	for i in range(clones.size()):
		if clones[i] == null:
			continue

		var replay = recording_system.get_replay(i)
		if replay == null:
			continue

		# Snap position
		if replay.positionHistory.size() > 0:
			clones[i].global_position = replay.positionHistory[-1]

		# Snap facing / skeleton scale
		if replay.facingHistory.size() > 0 and clones[i].has_node("Skeleton2D"):
			var skeleton = clones[i].get_node("Skeleton2D")
			skeleton.scale.x = abs(skeleton.scale.x) * replay.facingHistory[-1]

## Snap all clones to their first recorded positions
func snap_clones_first() -> void:
	for i in range(clones.size()):
		if clones[i] == null:
			continue

		var replay = recording_system.get_replay(i)
		if replay == null or replay.positionHistory.size() == 0:
			continue

		clones[i].global_position = replay.positionHistory[0]

# ========== INPUT ==========

func _input(event: InputEvent) -> void:
	# Only process input during WAITING_INPUT state
	if current_state != CloneState.State.WAITING_INPUT:
		return

	# Check for any movement input to start recording
	var should_start = false

	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		should_start = true
	elif event.is_action_pressed("jump"):
		should_start = true
	elif event.is_action_pressed("crouch"):
		should_start = true

	if should_start:
		# Start actual recording now that player has given input
		recording_system.is_recording = true
		_change_state(CloneState.State.RECORDING)
		# Input will still be processed by player on this frame

# ========== PROCESS ==========

func _physics_process(delta: float) -> void:
	# Don't process in idle state
	if current_state == CloneState.State.IDLE:
		return

	# Don't update time during waiting for input
	if current_state == CloneState.State.WAITING_INPUT:
		return

	# Update time for recording/playback
	time_elapsed += delta
	recording_system.set_time(time_elapsed)
	time_updated.emit(time_elapsed)

	# Check time limit
	if time_elapsed >= config.time_limit:
		if current_state == CloneState.State.RECORDING:
			stop_recording()
		elif current_state == CloneState.State.PLAYING:
			stop_playback()
