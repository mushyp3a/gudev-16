extends Control

@onready var cloning = get_tree().root.find_child("PlayerCloning", true, false)
@onready var panel = $Panel
@onready var slot_buttons = [$Panel/SlotButtons/Slot1, $Panel/SlotButtons/Slot2, $Panel/SlotButtons/Slot3, $Panel/SlotButtons/Slot4]

var is_open: bool = true
var tween: Tween
var panel_width: float

func _ready() -> void:
	panel_width = panel.size.x
	for i in range(4):
		var id = i
		slot_buttons[i].pressed.connect(func(): _on_slot_pressed(id))
	$Panel/SlotButtons/RecordButton.pressed.connect(_on_record_pressed)
	$Panel/SlotButtons/PlayButton.pressed.connect(_on_play_pressed)

func _on_slot_pressed(id: int) -> void:
	# toggle off if already selected, otherwise select
	if cloning.selectedClone == id:
		cloning.selectedClone = -2  # none selected = show all
	else:
		cloning.selectedClone = id
	_update_slot_highlights()
	cloning._updateVisibility()

func _update_slot_highlights() -> void:
	for i in range(4):
		if cloning.selectedClone == i:
			slot_buttons[i].modulate = Color(1.0, 0.8, 0.0)  # yellow = selected
		else:
			slot_buttons[i].modulate = Color.WHITE

func _on_record_pressed() -> void:
	if cloning.selectedClone < 0:
		return
	slide_out()
	cloning.createClone(cloning.selectedClone)
	cloning.spawnExistingClones()
	cloning.replayable.time = 0
	cloning.timeElapsed = 0
	cloning.previewing = false
	cloning.paused = false
	cloning.selectedClone = -2
	cloning._updateVisibility()

func _on_play_pressed() -> void:
	if cloning.selectedClone == -1:
		return
	slide_out()
	if cloning.selectedClone == -2:
		cloning._play_all_clones()
	else:
		cloning.playSelectedClone(cloning.selectedClone)

func slide_out() -> void:
	is_open = false
	_animate(panel_width)

func slide_in() -> void:
	is_open = true
	cloning.paused = true
	cloning.previewing = false
	ShaderManager.go_to_plan()
	_animate(0.0)
	_update_slot_highlights()

func _animate(offset: float) -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "position:x", get_viewport_rect().size.x - panel_width + offset, 0.35)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next"):
		if not is_open:
			slide_in()
	_update_slot_highlights()
	if not cloning.paused == false and not is_open:
		slide_in()
