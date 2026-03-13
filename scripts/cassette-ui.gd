extends Control

@onready var cloning = get_tree().root.find_child("PlayerCloning", true, false)
@onready var panel = $Panel
@onready var slot_buttons = [$Panel/SlotButtons/Slot1, $Panel/SlotButtons/Slot2, $Panel/SlotButtons/Slot3, $Panel/SlotButtons/Slot4]

var is_open: bool = true
var is_recording: bool = false
var tween: Tween
var panel_width: float

var _was_paused: bool = false

func _ready() -> void:
	panel_width = panel.size.x
	$Panel/SlotButtons/RecordButton.pressed.connect(_on_record_pressed)
	$Panel/SlotButtons/PlayButton.pressed.connect(_on_play_pressed)
	for i in range(4):
		var id = i
		slot_buttons[i].pressed.connect(func(): _on_slot_pressed(id))

func _on_slot_pressed(id: int) -> void:
	if cloning.selectedClone == id:
		cloning.selectedClone = -1
	else:
		cloning.selectClone(id)
	_update_slot_highlights()

func _on_record_pressed() -> void:
	if cloning.selectedClone < 0:
		return
	is_recording = true
	slide_out()
	cloning.showAllClones()
	cloning.createClone(cloning.selectedClone)
	cloning.selectedClone = -1
	cloning.unpause()

func _on_play_pressed() -> void:
	if cloning.selectedClone == -1:
		return
	is_recording = false
	slide_out()
	cloning.replayClone(cloning.selectedClone)

func slide_out() -> void:
	is_open = false
	_animate(panel_width)

func slide_in() -> void:
	is_open = true
	is_recording = false
	if not cloning.paused:
		cloning.paused = true
	ShaderManager.go_to_plan()
	_animate(0.0)
	_update_slot_highlights()

func _update_slot_highlights() -> void:
	for i in range(4):
		if cloning.selectedClone == i:
			slot_buttons[i].modulate = Color(1.0, 0.8, 0.0)
		else:
			slot_buttons[i].modulate = Color.WHITE

func _update_play_button() -> void:
	var play_btn = $Panel/SlotButtons/PlayButton
	if cloning.selectedClone < 0:
		play_btn.disabled = true
		return
	play_btn.disabled = cloning.replayable.replays[cloning.selectedClone] == null

func _update_record_button() -> void:
	var record_btn = $Panel/SlotButtons/RecordButton
	record_btn.disabled = cloning.selectedClone < 0

func _animate(offset: float) -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "position:x", get_viewport_rect().size.x - panel_width + offset, 0.35)

func _process(_delta: float) -> void:
	# Auto slide in when timeLoop fires or recording ends
	if not _was_paused and cloning.paused and not is_open:
		slide_in()
	_was_paused = cloning.paused

	if Input.is_action_just_pressed("toggle_cassette"):
		if not is_open:
			# Tab to open: only allowed while previewing (not recording)
			if cloning.previewing:
				slide_in()
		# Tab while UI is open has no extra effect here

	# Snap clones on tab press depending on current run state
	if Input.is_action_just_pressed("toggle_cassette") and not is_open:
		if cloning.recording or cloning.waitingForInput:
			# Player is recording — jump all clones to their final position
			cloning.snapClonesLast()
		# (previewing case already handled above — slide_in)

	_update_slot_highlights()
	_update_play_button()
	_update_record_button()
