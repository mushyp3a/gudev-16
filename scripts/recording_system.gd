class_name RecordingSystem extends Node

signal recording_frame_captured(clone_id: int, frame_data: Dictionary)

@export var player: CharacterBody2D
@export var max_recordings: int = 4

var replays: Array[Replay] = []
var current_recording_id: int = -1
var current_time: float = 0.0
var is_recording: bool = false

func _ready() -> void:
	replays.resize(max_recordings)
	for i in range(max_recordings):
		replays[i] = null

func start_recording(slot_id: int) -> void:
	if slot_id < 0 or slot_id >= max_recordings:
		push_error("RecordingSystem: Invalid recording slot %d" % slot_id)
		return

	if player == null:
		push_error("RecordingSystem: Player node not set")
		return

	if replays[slot_id] != null:
		replays[slot_id].clear()

	replays[slot_id] = Replay.new(player.global_position, 0.0, PlayerActions.new([]))
	current_recording_id = slot_id
	current_time = 0.0
	is_recording = true

func stop_recording() -> void:
	is_recording = false
	current_recording_id = -1

func reset_playback() -> void:
	for replay in replays:
		if replay != null:
			replay.reset()
	current_time = 0.0

func get_replay(slot_id: int) -> Replay:
	if slot_id < 0 or slot_id >= replays.size():
		return null
	return replays[slot_id]

func sample(slot_id: int, time: float) -> Dictionary:
	var replay = get_replay(slot_id)
	if replay == null:
		return {}
	return replay.sample(time)

func has_recording(slot_id: int) -> bool:
	var replay = get_replay(slot_id)
	return replay != null and not replay.is_empty()

func get_recording_duration(slot_id: int) -> float:
	var replay = get_replay(slot_id)
	if replay == null:
		return 0.0
	return replay.get_duration()

func _process(_delta: float) -> void:
	if not is_recording or current_recording_id == -1:
		return

	if player == null:
		return

	var skeleton: Node2D = player.get_node_or_null("Skeleton2D")
	var facing: float = skeleton.scale.x if skeleton else 1.0

	replays[current_recording_id].record(
		player.global_position,
		current_time,
		PlayerActions.new([]),
		facing,
		player.velocity.y,
		player.is_sliding,
		player.is_wall_sliding,
		player.has_double_jump
	)

	var frame_data = {
		"position": player.global_position,
		"time": current_time,
		"facing": facing,
		"velocity_y": player.velocity.y,
		"is_sliding": player.is_sliding,
		"is_wall_sliding": player.is_wall_sliding,
		"has_double_jump": player.has_double_jump
	}
	recording_frame_captured.emit(current_recording_id, frame_data)

func set_time(time: float) -> void:
	current_time = time
