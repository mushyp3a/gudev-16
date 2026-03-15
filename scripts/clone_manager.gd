class_name CloneManager extends Node

signal clone_created(clone_id: int)
signal clone_deleted(clone_id: int)
signal clone_selected(clone_id: int)
signal clone_deselected()
signal state_changed(new_state: CloneState.State)
signal recording_started(clone_id: int)
signal recording_stopped(clone_id: int)
signal playback_started(clone_ids: Array[int])
signal playback_stopped()
signal time_updated(elapsed: float)

@export var config: CloneConfig
@export var recording_system: RecordingSystem
@export var player_node: Node2D
@export var start_position: Vector2

var current_state: CloneState.State = CloneState.State.IDLE
var selected_clone_id: int = -1
var time_elapsed: float = 0.0
var clones: Array[Node] = []
var available_slots: Array[int] = []

func _ready() -> void:
	if config == null:
		push_error("CloneManager: No CloneConfig assigned!")
		return

	if not config.is_valid():
		push_error("CloneManager: Invalid CloneConfig!")
		return

	if start_position == Vector2.ZERO and player_node != null:
		start_position = player_node.global_position

	_initialize_slots()

func _initialize_slots() -> void:
	clones.resize(config.max_clones)
	available_slots.clear()
	for i in range(config.max_clones):
		clones[i] = null
		available_slots.append(i)

func create_clone(slot_id: int) -> void:
	if slot_id < 0 or slot_id >= config.max_clones:
		push_error("CloneManager: Invalid slot_id %d" % slot_id)
		return

	if clones[slot_id] != null:
		delete_clone(slot_id)

	var clone_scene = load(config.clone_scene_path)
	if clone_scene == null:
		push_error("CloneManager: Failed to load clone scene at %s" % config.clone_scene_path)
		return

	var clone = clone_scene.instantiate()
	clone.clone_id = slot_id
	clone.recording_system = recording_system
	clone.visible = false

	var script_node = clone.get_node_or_null("ReplayCloneScript")
	if script_node:
		script_node.clone_id = slot_id
		script_node.recording_system = recording_system

	get_tree().root.add_child(clone)
	clones[slot_id] = clone
	available_slots.erase(slot_id)
	clone_created.emit(slot_id)

func delete_clone(slot_id: int) -> void:
	if slot_id < 0 or slot_id >= clones.size():
		return

	if clones[slot_id] != null:
		clones[slot_id].queue_free()
		clones[slot_id] = null

		if not available_slots.has(slot_id):
			available_slots.append(slot_id)

		clone_deleted.emit(slot_id)

func select_clone(slot_id: int) -> void:
	if slot_id < 0 or slot_id >= config.max_clones:
		return

	selected_clone_id = slot_id
	clone_selected.emit(slot_id)

func deselect_clone() -> void:
	selected_clone_id = -1
	clone_deselected.emit()

func start_recording(slot_id: int) -> void:
	if not CloneState.can_transition(current_state, CloneState.State.WAITING_INPUT):
		push_warning("CloneManager: Cannot start recording from state %s" % CloneState.get_state_name(current_state))
		return

	if player_node == null:
		push_error("CloneManager: player_node is not set!")
		return

	create_clone(slot_id)
	recording_system.reset_playback()
	recording_system.replays[slot_id] = Replay.new(player_node.global_position, 0.0, PlayerActions.new([]))
	recording_system.current_recording_id = slot_id
	time_elapsed = 0.0
	recording_system.set_time(time_elapsed)
	_change_state(CloneState.State.WAITING_INPUT)
	recording_started.emit(slot_id)

func stop_recording() -> void:
	var recording_id = recording_system.current_recording_id
	recording_system.stop_recording()
	_reset_to_start()
	recording_stopped.emit(recording_id)

func start_playback(clone_ids: Array[int]) -> void:
	if not CloneState.can_transition(current_state, CloneState.State.PLAYING):
		push_warning("CloneManager: Cannot start playback from state %s" % CloneState.get_state_name(current_state))
		return

	recording_system.reset_playback()
	time_elapsed = 0.0
	recording_system.set_time(time_elapsed)
	_change_state(CloneState.State.PLAYING)
	playback_started.emit(clone_ids)

func stop_playback() -> void:
	if player_node != null:
		player_node.global_position = start_position
		if player_node.has_method("reset_movement_state"):
			player_node.reset_movement_state()
		elif player_node is CharacterBody2D:
			player_node.velocity = Vector2.ZERO

	time_elapsed = config.time_limit
	recording_system.set_time(time_elapsed)
	_snap_clones_to_final_positions()
	_change_state(CloneState.State.IDLE)
	playback_stopped.emit()

func _change_state(new_state: CloneState.State) -> void:
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		state_changed.emit(new_state)

func is_paused() -> bool:
	return current_state == CloneState.State.IDLE

func _update_clone_visibility() -> void:
	if selected_clone_id == -1:
		show_all_clones()
	else:
		show_clone(selected_clone_id)

func show_clone(slot_id: int) -> void:
	for i in range(clones.size()):
		if clones[i] != null:
			clones[i].visible = (i == slot_id)

func show_all_clones() -> void:
	for clone in clones:
		if clone != null:
			clone.visible = true

func _reset_to_start() -> void:
	if player_node != null:
		player_node.global_position = start_position
		if player_node.has_method("reset_movement_state"):
			player_node.reset_movement_state()
		elif player_node is CharacterBody2D:
			player_node.velocity = Vector2.ZERO

	time_elapsed = config.time_limit
	recording_system.set_time(time_elapsed)
	_snap_clones_to_final_positions()
	_change_state(CloneState.State.IDLE)

func _snap_clones_to_final_positions() -> void:
	for i in range(clones.size()):
		if clones[i] == null:
			continue

		var replay = recording_system.get_replay(i)
		if replay == null:
			continue

		if replay.positionHistory.size() > 0:
			clones[i].global_position = replay.positionHistory[-1]

		if replay.facingHistory.size() > 0 and clones[i].has_node("Skeleton2D"):
			var skeleton = clones[i].get_node("Skeleton2D")
			skeleton.scale.x = abs(skeleton.scale.x) * replay.facingHistory[-1]

func snap_clones_first() -> void:
	for i in range(clones.size()):
		if clones[i] == null:
			continue

		var replay = recording_system.get_replay(i)
		if replay == null or replay.positionHistory.size() == 0:
			continue

		clones[i].global_position = replay.positionHistory[0]

func _input(event: InputEvent) -> void:
	if current_state != CloneState.State.WAITING_INPUT:
		return

	var should_start = false

	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		should_start = true
	elif event.is_action_pressed("jump"):
		should_start = true
	elif event.is_action_pressed("crouch"):
		should_start = true

	if should_start:
		recording_system.is_recording = true
		_change_state(CloneState.State.RECORDING)

func _physics_process(delta: float) -> void:
	if current_state == CloneState.State.IDLE:
		return

	if current_state == CloneState.State.WAITING_INPUT:
		return

	time_elapsed += delta
	recording_system.set_time(time_elapsed)
	time_updated.emit(time_elapsed)

	if time_elapsed >= config.time_limit:
		if current_state == CloneState.State.RECORDING:
			stop_recording()
		elif current_state == CloneState.State.PLAYING:
			stop_playback()
