extends Area2D

@export var action_key: String = "interact"
@export var default_state: bool = false

@onready var animator = $AnimationPlayer
@onready var key_prompt = $KeyPrompt

var is_on: bool = false
var player_nearby: bool = false
var recording_system: RecordingSystem = null
var clone_manager: CloneManager = null
var slotHistory: Array = [[], [], [], []]
var mergedHistory: Array = []
var lastAppliedState: bool = false

signal switched(is_on: bool)

func _ready() -> void:
	key_prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var root = get_tree().root
	recording_system = root.get_node_or_null("RecordingSystem")
	if recording_system == null:
		recording_system = root.find_child("RecordingSystem", true, false)

	clone_manager = root.get_node_or_null("CloneManager")
	if clone_manager == null:
		clone_manager = root.find_child("CloneManager", true, false)

	if clone_manager:
		clone_manager.recording_started.connect(_on_recording_started)
		clone_manager.playback_started.connect(_on_playback_started)
		clone_manager.state_changed.connect(_on_state_changed)

	_apply_state(default_state, false)

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

	if clone_manager.current_state == CloneState.State.IDLE or clone_manager.current_state == CloneState.State.WAITING_INPUT:
		return

	if player_nearby and Input.is_action_just_pressed(action_key):
		if recording_system.is_recording:
			toggle()

	if mergedHistory.size() > 0:
		var sampleTime = clone_manager.time_elapsed
		var replayed = _sampleMerged(sampleTime)
		if replayed != lastAppliedState:
			lastAppliedState = replayed
			_apply_state(replayed, true)

func toggle() -> void:
	_apply_state(!is_on, true)
	if recording_system and recording_system.current_recording_id >= 0:
		slotHistory[recording_system.current_recording_id].push_back({"time": clone_manager.time_elapsed})
	lastAppliedState = is_on

func startRecording(slot: int) -> void:
	_apply_state(default_state, false)
	slotHistory[slot] = []
	lastAppliedState = default_state
	_rebuildMerged(slot)

func resetToDefault() -> void:
	_apply_state(default_state, true)
	lastAppliedState = default_state
	mergedHistory = []

func _rebuildMerged(recordingSlot: int) -> void:
	mergedHistory = []
	for slot in range(4):
		if slot == recordingSlot:
			continue
		for entry in slotHistory[slot]:
			mergedHistory.push_back({"time": entry["time"]})
	mergedHistory.sort_custom(func(a, b): return a["time"] < b["time"])

func _sampleMerged(t: float) -> bool:
	var complete_timeline = mergedHistory.duplicate()

	if recording_system and recording_system.is_recording and recording_system.current_recording_id >= 0:
		var current_slot = recording_system.current_recording_id
		for entry in slotHistory[current_slot]:
			complete_timeline.push_back(entry)
		complete_timeline.sort_custom(func(a, b): return a["time"] < b["time"])

	if complete_timeline.size() == 0:
		return default_state

	var toggle_count = 0
	for entry in complete_timeline:
		if entry["time"] <= t:
			toggle_count += 1
		else:
			break

	var result = default_state
	if toggle_count % 2 == 1:
		result = !default_state

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
	mergedHistory = []
	for slot in range(4):
		for entry in slotHistory[slot]:
			mergedHistory.push_back({"time": entry["time"]})
	mergedHistory.sort_custom(func(a, b): return a["time"] < b["time"])

func _on_recording_started(slot_id: int) -> void:
	startRecording(slot_id)

func _on_playback_started(_clone_ids: Array[int]) -> void:
	preparePlayback()

func _on_state_changed(new_state: int) -> void:
	if new_state == CloneState.State.IDLE:
		resetToDefault()
