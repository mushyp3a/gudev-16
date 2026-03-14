extends Area2D

@export var action_key: String = "interact"
@export var default_state: bool = false

@onready var animator = $AnimationPlayer
@onready var key_prompt = $KeyPrompt

var is_on: bool = false
var player_nearby: bool = false

## Reference to systems (found dynamically)
var recording_system: RecordingSystem = null
var clone_manager: CloneManager = null

# per-slot history: Array of 4 Arrays, each {time, is_on}
var slotHistory: Array = [[], [], [], []]

# merged timeline of all slots, sorted by time — rebuilt on each startRecording
var mergedHistory: Array = []
var lastAppliedState: bool = false
var playerTouchedAt: float = -1.0  # time of last player interaction this run, -1 = never

signal switched(is_on: bool)

func _ready() -> void:
	key_prompt.visible = false
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

	if recording_system == null:
		push_warning("Switch: Could not find RecordingSystem node")
	if clone_manager == null:
		push_warning("Switch: Could not find CloneManager node")

## Connect to CloneManager signals for lifecycle events
func _connect_signals() -> void:
	if clone_manager == null:
		return

	clone_manager.recording_started.connect(_on_recording_started)
	clone_manager.playback_started.connect(_on_playback_started)
	clone_manager.state_changed.connect(_on_state_changed)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		key_prompt.visible = true
		_animate_prompt_in()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		key_prompt.visible = false

func _process(_delta: float) -> void:
	if not recording_system or not clone_manager:
		return

	# Don't process during IDLE or WAITING_INPUT states
	if clone_manager.current_state == CloneState.State.IDLE or clone_manager.current_state == CloneState.State.WAITING_INPUT:
		return

	# player input during recording
	if player_nearby and Input.is_action_just_pressed(action_key):
		if recording_system.is_recording:
			toggle()

	# replay merged timeline
	# Stop replaying once player has touched the lever during recording
	var should_replay = mergedHistory.size() > 0
	if recording_system.is_recording and playerTouchedAt >= 0.0:
		should_replay = false  # Player has taken control, stop replaying

	if should_replay:
		var sampleTime = clone_manager.time_elapsed
		var replayed = _sampleMerged(sampleTime)
		if replayed != lastAppliedState:
			lastAppliedState = replayed
			_apply_state(replayed, true)

func toggle() -> void:
	_apply_state(!is_on, true)
	if recording_system and recording_system.current_recording_id >= 0:
		slotHistory[recording_system.current_recording_id].push_back({"time": clone_manager.time_elapsed, "is_on": is_on})
	lastAppliedState = is_on
	playerTouchedAt = clone_manager.time_elapsed if clone_manager else -1.0

func startRecording(slot: int) -> void:
	_apply_state(default_state, false)
	slotHistory[slot] = [{"time": 0.0, "is_on": default_state}]
	lastAppliedState = default_state
	playerTouchedAt = -1.0
	_rebuildMerged(slot)

func resetToDefault() -> void:
	_apply_state(default_state, true)
	lastAppliedState = default_state
	playerTouchedAt = -1.0
	mergedHistory = []

# rebuild merged timeline from all slots except the one being recorded
func _rebuildMerged(recordingSlot: int) -> void:
	mergedHistory = []
	for slot in range(4):
		if slot == recordingSlot:
			continue
		for entry in slotHistory[slot]:
			mergedHistory.push_back({"time": entry["time"], "is_on": entry["is_on"]})
	# sort by time
	mergedHistory.sort_custom(func(a, b): return a["time"] < b["time"])

# sample the merged timeline at time t
func _sampleMerged(t: float) -> bool:
	if mergedHistory.size() == 0:
		return default_state
	var result = default_state
	for entry in mergedHistory:
		if entry["time"] <= t:
			result = entry["is_on"]
		else:
			break
	return result

func _apply_state(state: bool, animate: bool) -> void:
	is_on = state
	if animate:
		animator.play("switch_on" if is_on else "switch_off")
	switched.emit(is_on)

func _animate_prompt_in() -> void:
	key_prompt.modulate.a = 0.0
	key_prompt.position.y = 10
	var t = create_tween().set_parallel(true)
	t.tween_property(key_prompt, "modulate:a", 1.0, 0.2)
	t.tween_property(key_prompt, "position:y", -20, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func preparePlayback() -> void:
	_apply_state(default_state, false)
	lastAppliedState = default_state
	playerTouchedAt = -1.0
	# merge all slots for playback
	mergedHistory = []
	for slot in range(4):
		for entry in slotHistory[slot]:
			mergedHistory.push_back({"time": entry["time"], "is_on": entry["is_on"]})
	mergedHistory.sort_custom(func(a, b): return a["time"] < b["time"])
	# remove the t=0 default entries to avoid noise — only keep actual toggles
	mergedHistory = mergedHistory.filter(func(e): return e["time"] > 0.0 or e["is_on"] != default_state)

## Called when CloneManager starts recording for a slot
func _on_recording_started(slot_id: int) -> void:
	startRecording(slot_id)

## Called when CloneManager starts playback
func _on_playback_started(_clone_ids: Array[int]) -> void:
	preparePlayback()

## Called when CloneManager state changes
func _on_state_changed(new_state: int) -> void:
	# Reset to default when returning to IDLE
	if new_state == CloneState.State.IDLE:
		resetToDefault()
