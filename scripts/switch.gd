extends Area2D

@export var action_key: String = "interact"
@onready var animator = $AnimationPlayer
@onready var key_prompt = $KeyPrompt

var is_on: bool = false
var player_nearby: bool = false
var replayable = null
var cloning = null

# per-slot history: Array of 4 Arrays, each {time, is_on}
var slotHistory: Array = [[], [], [], []]

signal switched(is_on: bool)

func _ready() -> void:
	key_prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	replayable = get_tree().root.find_child("Replayable", true, false)
	cloning = get_tree().root.find_child("PlayerCloning", true, false)

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
	if not replayable or not cloning or cloning.paused:
		return

	# player input only works during recording
	if player_nearby and Input.is_action_just_pressed(action_key):
		if replayable.recording:
			toggle()

	# replay all OTHER slots (not the one currently recording)
	# this runs during both recording and preview
	var best_slot = -1
	for slot in range(4):
		if replayable.recording and slot == replayable.currIx:
			continue  # skip currently recording slot
		if slotHistory[slot].size() > 1:  # >1 means a toggle was recorded
			best_slot = slot

	if best_slot >= 0:
		var replayed_state = _replayStateAt(best_slot, replayable.time)
		if replayed_state != is_on:
			is_on = replayed_state
			if is_on:
				animator.play("switch_on")
			else:
				animator.play("switch_off")
			switched.emit(is_on)

func toggle() -> void:
	is_on = !is_on
	if is_on:
		animator.play("switch_on")
	else:
		animator.play("switch_off")
	switched.emit(is_on)
	if replayable and replayable.currIx >= 0:
		slotHistory[replayable.currIx].push_back({"time": replayable.time, "is_on": is_on})

func startRecording(slot: int) -> void:
	slotHistory[slot] = [{"time": 0.0, "is_on": is_on}]

func _replayStateAt(slot: int, t: float) -> bool:
	var history = slotHistory[slot]
	if history.size() == 0:
		return is_on
	var result = history[0]["is_on"]
	for entry in history:
		if entry["time"] <= t:
			result = entry["is_on"]
		else:
			break
	return result

func _animate_prompt_in() -> void:
	key_prompt.modulate.a = 0.0
	key_prompt.position.y = 10
	var t = create_tween().set_parallel(true)
	t.tween_property(key_prompt, "modulate:a", 1.0, 0.2)
	t.tween_property(key_prompt, "position:y", -20, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
