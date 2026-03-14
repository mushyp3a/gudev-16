class_name CassetteUIController extends Control

## UI controller for the cassette/clone interface
## Listens to CloneManager signals and updates UI accordingly
## Sends user commands to CloneManager via method calls

# ========== SIGNALS ==========

## Emitted when user requests recording (not used currently, direct calls instead)
signal record_requested(clone_id: int)

## Emitted when user requests playback (not used currently, direct calls instead)
signal play_requested(clone_ids: Array[int])

## Emitted when user requests stop (not used currently, direct calls instead)
signal stop_requested()

# ========== REFERENCES ==========

## Reference to the CloneManager (found dynamically)
var clone_manager: CloneManager = null

# ========== UI NODES ==========

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

# ========== STATE ==========

## Whether the cassette panel is currently open (visible)
var is_open: bool = true

## Width of the panel for slide animations
var panel_width: float

## Tween for panel animations
var tween: Tween

# ========== INITIALIZATION ==========

func _ready() -> void:
	# Find CloneManager in the scene tree
	_find_clone_manager()

	if clone_manager == null:
		push_error("CassetteUIController: CloneManager not found in scene tree!")
		return

	panel_width = panel.size.x

	# Connect button signals
	record_button.pressed.connect(_on_record_pressed)
	play_button.pressed.connect(_on_play_pressed)

	# Connect slot button signals
	for i in range(slot_buttons.size()):
		var slot_id = i
		slot_buttons[i].pressed.connect(func(): _on_slot_pressed(slot_id))

	# Connect to CloneManager signals
	clone_manager.state_changed.connect(_on_state_changed)
	clone_manager.clone_selected.connect(_on_clone_selected)
	clone_manager.clone_deselected.connect(_on_clone_deselected)
	clone_manager.recording_stopped.connect(_on_recording_stopped)
	clone_manager.playback_stopped.connect(_on_playback_stopped)

	# Initialize UI state
	_update_ui()

## Find the CloneManager node in the scene tree
func _find_clone_manager() -> void:
	# First try to find it as a direct child of root
	var root = get_tree().root
	clone_manager = root.get_node_or_null("CloneManager")

	# If not found, search recursively
	if clone_manager == null:
		clone_manager = root.find_child("CloneManager", true, false)

	if clone_manager == null:
		push_warning("CassetteUIController: Could not find CloneManager node")

# ========== BUTTON HANDLERS ==========

## Called when a slot button is pressed
func _on_slot_pressed(slot_id: int) -> void:
	clickFx.play()
	if clone_manager.selected_clone_id == slot_id:
		# Toggle off if already selected
		clone_manager.deselect_clone()
	else:
		# Select this slot
		clone_manager.select_clone(slot_id)

## Called when record button is pressed
func _on_record_pressed() -> void:
	clickFx.play()
	if clone_manager.selected_clone_id < 0:
		return  # No slot selected, can't record

	slide_out()
	clone_manager.start_recording(clone_manager.selected_clone_id)
	clone_manager.deselect_clone()

## Called when play button is pressed
func _on_play_pressed() -> void:
	clickFx.play()
	slide_out()

	var clone_ids: Array[int] = []

	# Always play all clones that have recordings
	for i in range(clone_manager.config.max_clones):
		if clone_manager.recording_system.has_recording(i):
			clone_ids.append(i)

	# Keep the selection active during playback (indicator will show)
	# Don't deselect - the indicator will stay visible on the selected clone

	if clone_ids.size() > 0:
		clone_manager.start_playback(clone_ids)

# ========== SIGNAL HANDLERS ==========

## Called when CloneManager state changes
func _on_state_changed(new_state: CloneState.State) -> void:
	if new_state == CloneState.State.IDLE and not is_open:
		slide_in()

## Called when a clone is selected
func _on_clone_selected(_clone_id: int) -> void:
	_update_ui()

## Called when clone selection is cleared
func _on_clone_deselected() -> void:
	_update_ui()

## Called when recording stops
func _on_recording_stopped(_clone_id: int) -> void:
	clone_manager.deselect_clone()
	slide_in()

## Called when playback stops
func _on_playback_stopped() -> void:
	clone_manager.deselect_clone()
	slide_in()

# ========== PANEL ANIMATION ==========

## Slide the panel out (hide it off-screen)
func slide_out() -> void:
	is_open = false
	_disable_all_buttons()
	_animate_panel(panel_width)

## Slide the panel in (show it on-screen)
func slide_in() -> void:
	is_open = true

	# Reset time to 0 so timer shows full time limit
	clone_manager.time_elapsed = 0.0
	clone_manager.recording_system.set_time(0.0)

	ShaderManager.go_to_plan()
	_animate_panel(0.0)
	_enable_all_buttons()
	_update_ui()

## Animate the panel to a specific offset
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

# ========== UI UPDATES ==========

## Update all UI elements
func _update_ui() -> void:
	_update_slot_highlights()
	_update_button_states()

## Update slot button highlight colors based on selection
func _update_slot_highlights() -> void:
	for i in range(slot_buttons.size()):
		if i < clone_manager.config.max_clones:
			# Highlight selected slot in gold, others in white
			if clone_manager.selected_clone_id == i:
				slot_buttons[i].modulate = Color(1.0, 0.8, 0.0)  # Gold
			else:
				slot_buttons[i].modulate = Color.WHITE
		else:
			# Disable buttons beyond max_clones
			slot_buttons[i].visible = false

## Update button enabled/disabled states
func _update_button_states() -> void:
	# Record button: enabled only if a clone slot is selected
	record_button.disabled = clone_manager.selected_clone_id < 0

	# Play button logic
	if clone_manager.selected_clone_id < 0:
		# No selection: enable if any clone has a recording
		play_button.disabled = not _has_any_recording()
	else:
		# Selection: enable if that specific clone has a recording
		play_button.disabled = not clone_manager.recording_system.has_recording(clone_manager.selected_clone_id)

## Check if any clone has a recording
func _has_any_recording() -> bool:
	for i in range(clone_manager.config.max_clones):
		if clone_manager.recording_system.has_recording(i):
			return true
	return false

## Disable all buttons (when panel is hidden)
func _disable_all_buttons() -> void:
	record_button.disabled = true
	play_button.disabled = true
	for button in slot_buttons:
		button.disabled = true

	# Also set mouse filter to ignore to prevent any interaction
	record_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for button in slot_buttons:
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Enable all buttons and update their states (when panel is shown)
func _enable_all_buttons() -> void:
	# Enable all slot buttons
	for i in range(slot_buttons.size()):
		if i < clone_manager.config.max_clones:
			slot_buttons[i].disabled = false
		else:
			slot_buttons[i].disabled = true

	# Restore mouse filter to allow interaction
	record_button.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.mouse_filter = Control.MOUSE_FILTER_STOP
	for button in slot_buttons:
		button.mouse_filter = Control.MOUSE_FILTER_STOP

	# Record and play buttons will be updated by _update_button_states()
	# which is called by _update_ui()

# ========== PROCESS ==========

func _process(_delta: float) -> void:
	# Handle toggle cassette input
	if Input.is_action_just_pressed("toggle_cassette"):
		if not is_open and clone_manager.current_state == CloneState.State.PLAYING:
			# Stop playback and show cassette
			clone_manager.stop_playback()
			slide_in()

	# Continuously update UI
	_update_ui()
