class_name CassetteUIController extends Control

signal record_requested(clone_id: int)
signal play_requested(clone_ids: Array[int])
signal stop_requested()

var clone_manager: CloneManager = null

@onready var panel = $Panel
@onready var slot_buttons = [
	$Panel/SlotButtons/Slot1,
	$Panel/SlotButtons/Slot2,
	$Panel/SlotButtons/Slot3,
	$Panel/SlotButtons/Slot4
]
@onready var record_button = $Panel/SlotButtons/RecordButton
@onready var play_button = $Panel/SlotButtons/PlayButton
@onready var clickFx = $ClickFX

var is_open: bool = true
var panel_width: float
var tween: Tween

func _ready() -> void:
	var root = get_tree().root
	clone_manager = root.get_node_or_null("CloneManager")
	if clone_manager == null:
		clone_manager = root.find_child("CloneManager", true, false)

	if clone_manager == null:
		push_error("CassetteUIController: CloneManager not found")
		return

	panel_width = panel.size.x

	record_button.pressed.connect(_on_record_pressed)
	play_button.pressed.connect(_on_play_pressed)

	for i in range(slot_buttons.size()):
		var slot_id = i
		slot_buttons[i].pressed.connect(func(): _on_slot_pressed(slot_id))

	clone_manager.state_changed.connect(_on_state_changed)
	clone_manager.clone_selected.connect(_on_clone_selected)
	clone_manager.clone_deselected.connect(_on_clone_deselected)
	clone_manager.recording_stopped.connect(_on_recording_stopped)
	clone_manager.playback_stopped.connect(_on_playback_stopped)

	_update_ui()

func _on_slot_pressed(slot_id: int) -> void:
	clickFx.play()
	if clone_manager.selected_clone_id == slot_id:
		clone_manager.deselect_clone()
	else:
		clone_manager.select_clone(slot_id)

func _on_record_pressed() -> void:
	clickFx.play()
	if clone_manager.selected_clone_id < 0:
		return

	slide_out()
	clone_manager.start_recording(clone_manager.selected_clone_id)
	clone_manager.deselect_clone()

func _on_play_pressed() -> void:
	clickFx.play()
	slide_out()

	var clone_ids: Array[int] = []

	for i in range(clone_manager.config.max_clones):
		if clone_manager.recording_system.has_recording(i):
			clone_ids.append(i)

	if clone_ids.size() > 0:
		clone_manager.start_playback(clone_ids)

func _on_state_changed(new_state: CloneState.State) -> void:
	if new_state == CloneState.State.IDLE and not is_open:
		slide_in()

func _on_clone_selected(_clone_id: int) -> void:
	_update_ui()

func _on_clone_deselected() -> void:
	_update_ui()

func _on_recording_stopped(_clone_id: int) -> void:
	clone_manager.deselect_clone()
	slide_in()

func _on_playback_stopped() -> void:
	clone_manager.deselect_clone()
	slide_in()

func slide_out() -> void:
	is_open = false
	_disable_all_buttons()
	_animate_panel(panel_width)

func slide_in() -> void:
	is_open = true
	clone_manager.time_elapsed = 0.0
	clone_manager.recording_system.set_time(0.0)
	ShaderManager.go_to_plan()
	_animate_panel(0.0)
	_enable_all_buttons()
	_update_ui()

func _animate_panel(offset: float) -> void:
	if tween:
		tween.kill()

	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		panel,
		"position:x",
		get_viewport_rect().size.x - panel_width + offset,
		0.35
	)

func _update_ui() -> void:
	_update_slot_highlights()
	_update_button_states()

func _update_slot_highlights() -> void:
	for i in range(slot_buttons.size()):
		if i < clone_manager.config.max_clones:
			if clone_manager.selected_clone_id == i:
				slot_buttons[i].modulate = Color(1.0, 0.8, 0.0)
			else:
				slot_buttons[i].modulate = Color.WHITE
		else:
			slot_buttons[i].visible = false

func _update_button_states() -> void:
	record_button.disabled = clone_manager.selected_clone_id < 0

	if clone_manager.selected_clone_id < 0:
		play_button.disabled = not _has_any_recording()
	else:
		play_button.disabled = not clone_manager.recording_system.has_recording(clone_manager.selected_clone_id)

func _has_any_recording() -> bool:
	for i in range(clone_manager.config.max_clones):
		if clone_manager.recording_system.has_recording(i):
			return true
	return false

func _disable_all_buttons() -> void:
	record_button.disabled = true
	play_button.disabled = true
	for button in slot_buttons:
		button.disabled = true

	record_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for button in slot_buttons:
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _enable_all_buttons() -> void:
	for i in range(slot_buttons.size()):
		if i < clone_manager.config.max_clones:
			slot_buttons[i].disabled = false
		else:
			slot_buttons[i].disabled = true

	record_button.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.mouse_filter = Control.MOUSE_FILTER_STOP
	for button in slot_buttons:
		button.mouse_filter = Control.MOUSE_FILTER_STOP

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_cassette"):
		if not is_open and clone_manager.current_state == CloneState.State.PLAYING:
			clone_manager.stop_playback()
			slide_in()
		elif not is_open and clone_manager.current_state == CloneState.State.RECORDING:
			clone_manager.early_stop_recording()
			slide_in()

	_update_ui()
