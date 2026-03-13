extends Area2D

@export var action_key: String = "interact"
@export var default_state: bool = false

@onready var animator = $AnimationPlayer
@onready var key_prompt = $KeyPrompt

var is_on: bool = false
var player_nearby: bool = false
var replayable = null
var cloning = null

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
	replayable = get_tree().root.find_child("Replayable", true, false)
	cloning = get_tree().root.find_child("PlayerCloning", true, false)
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
	if not replayable or not cloning or cloning.paused or cloning.waitingForInput:
		return

	# player input during recording
	if player_nearby and Input.is_action_just_pressed(action_key):
		if replayable.recording:
			toggle()

	# replay merged timeline
	if mergedHistory.size() > 0:
		# during recording, stop replaying once player has touched the lever
		var sampleTime = replayable.time
		if replayable.recording and playerTouchedAt >= 0.0:
			sampleTime = playerTouchedAt  # freeze replay at moment player took over
		var replayed = _sampleMerged(sampleTime)
		if replayed != lastAppliedState:
			lastAppliedState = replayed
			_apply_state(replayed, true)

func toggle() -> void:
	_apply_state(!is_on, true)
	if replayable and replayable.currIx >= 0:
		slotHistory[replayable.currIx].push_back({"time": replayable.time, "is_on": is_on})
	lastAppliedState = is_on
	playerTouchedAt = replayable.time if replayable else -1.0

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
