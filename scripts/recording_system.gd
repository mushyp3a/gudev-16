class_name RecordingSystem extends Node

## Manages recording of player actions and state
## Handles multiple replay recordings and provides sampling interface
## Decoupled from other systems - communicates via signals

## Emitted when a frame of recording data is captured
signal recording_frame_captured(clone_id: int, frame_data: Dictionary)

## Reference to the player CharacterBody2D to record from
@export var player: CharacterBody2D

## Maximum number of concurrent recordings (should match CloneConfig.max_clones)
@export var max_recordings: int = 4

## Array of Replay objects, one per clone slot
var replays: Array[Replay] = []

## Currently recording slot ID (-1 if not recording)
var current_recording_id: int = -1

## Current playback/recording time (set externally by CloneManager)
var current_time: float = 0.0

## Whether we're currently recording
var is_recording: bool = false

func _ready() -> void:
	_initialize_replay_slots()

func _initialize_replay_slots() -> void:
	replays.resize(max_recordings)
	for i in range(max_recordings):
		replays[i] = null

## Start recording to a specific slot
## Cleans up any existing recording in that slot
func start_recording(slot_id: int) -> void:
	if slot_id < 0 or slot_id >= max_recordings:
		push_error("RecordingSystem: Invalid recording slot %d" % slot_id)
		return

	if player == null:
		push_error("RecordingSystem: Player node not set")
		return

	# Clean up old recording
	if replays[slot_id] != null:
		replays[slot_id].clear()

	# Start new recording
	replays[slot_id] = Replay.new(player.global_position, 0.0, PlayerActions.new([]))
	current_recording_id = slot_id
	current_time = 0.0
	is_recording = true

## Stop the current recording
func stop_recording() -> void:
	is_recording = false
	current_recording_id = -1

## Reset all replays to their starting playback position
func reset_playback() -> void:
	for replay in replays:
		if replay != null:
			replay.reset()
	current_time = 0.0

## Get the Replay object for a specific slot
## Returns null if slot is invalid or empty
func get_replay(slot_id: int) -> Replay:
	if slot_id < 0 or slot_id >= replays.size():
		return null
	return replays[slot_id]

## Sample the animation state for a clone at a specific time
## Returns Dictionary with position, facing, velocity_y, animation flags
## Returns empty Dictionary if no recording exists
func sample(slot_id: int, time: float) -> Dictionary:
	var replay = get_replay(slot_id)
	if replay == null:
		return {}
	return replay.sample(time)

## Check if a slot has a recording
func has_recording(slot_id: int) -> bool:
	var replay = get_replay(slot_id)
	return replay != null and not replay.is_empty()

## Get the duration of a recording in seconds
## Returns 0.0 if no recording exists
func get_recording_duration(slot_id: int) -> float:
	var replay = get_replay(slot_id)
	if replay == null:
		return 0.0
	return replay.get_duration()

## Called every frame to record player state
func _process(_delta: float) -> void:
	if not is_recording or current_recording_id == -1:
		return

	if player == null:
		return

	# Get player state
	var skeleton: Node2D = player.get_node_or_null("Skeleton2D")
	var facing: float = skeleton.scale.x if skeleton else 1.0

	# Record this frame
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

	# Emit signal for debugging/monitoring
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

## Set the current time (called by CloneManager)
func set_time(time: float) -> void:
	current_time = time
