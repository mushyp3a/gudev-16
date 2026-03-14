extends Area2D

@export var default_state: bool = false

@onready var animator = $AnimationPlayer

var is_active: bool = false

## Reference to systems (found dynamically)
var recording_system: RecordingSystem = null
var clone_manager: CloneManager = null

# per-slot history: Array of 4 Arrays, each {time, entering: bool}
var slotHistory: Array = [[], [], [], []]

# merged timeline of all slots, sorted by time
var mergedHistory: Array = []

signal activated(is_active: bool)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_find_systems()
	_connect_signals()
	_apply_state(default_state, false)

## Find the required systems in the scene tree
func _find_systems() -> void:
	var root = get_tree().root

	recording_system = root.get_node_or_null("RecordingSystem")
	if recording_system == null:
		recording_system = root.find_child("RecordingSystem", true, false)

	clone_manager = root.get_node_or_null("CloneManager")
	if clone_manager == null:
		clone_manager = root.find_child("CloneManager", true, false)

## Connect to CloneManager signals for lifecycle events
func _connect_signals() -> void:
	if clone_manager == null:
		return

	clone_manager.recording_started.connect(_on_recording_started)
	clone_manager.playback_started.connect(_on_playback_started)
	clone_manager.state_changed.connect(_on_state_changed)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Player entered - record it
		if recording_system and recording_system.is_recording and recording_system.current_recording_id >= 0:
			slotHistory[recording_system.current_recording_id].push_back({
				"time": clone_manager.time_elapsed,
				"entering": true
			})
		_check_state()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		# Player exited - record it
		if recording_system and recording_system.is_recording and recording_system.current_recording_id >= 0:
			slotHistory[recording_system.current_recording_id].push_back({
				"time": clone_manager.time_elapsed,
				"entering": false
			})
		_check_state()

func _process(_delta: float) -> void:
	if not clone_manager or not recording_system:
		return

	# Don't process during IDLE or WAITING_INPUT states
	if clone_manager.current_state == CloneState.State.IDLE or clone_manager.current_state == CloneState.State.WAITING_INPUT:
		return

	# Replay merged timeline during recording and playback
	if mergedHistory.size() > 0:
		var should_be_active = _sampleMerged(clone_manager.time_elapsed)
		_apply_state(should_be_active, true)

func _check_state() -> void:
	# Check if player is currently on plate (for immediate feedback during recording)
	var player_on_plate = false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			player_on_plate = true
			break
	_apply_state(player_on_plate, true)

## Sample the merged timeline to check if plate should be active at time t
func _sampleMerged(t: float) -> bool:
	# Build complete timeline including current recording
	var complete_timeline = mergedHistory.duplicate()

	# Add current recording's events if we're recording
	if recording_system and recording_system.is_recording and recording_system.current_recording_id >= 0:
		var current_slot = recording_system.current_recording_id
		for entry in slotHistory[current_slot]:
			complete_timeline.push_back(entry)
		complete_timeline.sort_custom(func(a, b): return a["time"] < b["time"])

	# Count how many bodies are on the plate at time t
	var bodies_on_plate = 0
	for entry in complete_timeline:
		if entry["time"] <= t:
			if entry["entering"]:
				bodies_on_plate += 1
			else:
				bodies_on_plate -= 1
		else:
			break

	# Active if at least one body is on the plate
	return bodies_on_plate > 0

func _apply_state(state: bool, animate: bool) -> void:
	if state == is_active:
		return

	is_active = state

	if animate:
		if is_active:
			animator.play("press_down")
		else:
			animator.play("press_up")

	activated.emit(is_active)

func startRecording(slot: int) -> void:
	_apply_state(default_state, false)
	slotHistory[slot] = []
	_rebuildMerged(slot)

func resetToDefault() -> void:
	_apply_state(default_state, false)
	mergedHistory = []

## Rebuild merged timeline from all slots except the one being recorded
func _rebuildMerged(recordingSlot: int) -> void:
	mergedHistory = []
	for slot in range(4):
		if slot == recordingSlot:
			continue
		for entry in slotHistory[slot]:
			mergedHistory.push_back({"time": entry["time"], "entering": entry["entering"]})
	mergedHistory.sort_custom(func(a, b): return a["time"] < b["time"])

func preparePlayback() -> void:
	_apply_state(default_state, false)
	# Merge all slots for playback
	mergedHistory = []
	for slot in range(4):
		for entry in slotHistory[slot]:
			mergedHistory.push_back({"time": entry["time"], "entering": entry["entering"]})
	mergedHistory.sort_custom(func(a, b): return a["time"] < b["time"])

## Called when CloneManager starts recording for a slot
func _on_recording_started(slot_id: int) -> void:
	startRecording(slot_id)

## Called when CloneManager starts playback
func _on_playback_started(_clone_ids: Array[int]) -> void:
	preparePlayback()

## Called when CloneManager state changes
func _on_state_changed(new_state: int) -> void:
	if new_state == CloneState.State.IDLE:
		resetToDefault()
