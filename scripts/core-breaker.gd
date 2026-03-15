extends Control

## Core breaking sequence - intense 4-hit destruction

@onready var core_solid: TextureRect = $"core-solid"
@onready var core_destroyed: Control = $"core-destroyed"
@onready var instructions: Label = $instructions
@onready var win_text: Label = $"win text"
@onready var press_enter_label: Label = $"press enter"
@onready var camera: Camera2D = $Camera2D
@onready var diamond: CanvasLayer = $Diamond

# Audio players for sound effects (to be assigned later)
@onready var breaking_sfx: AudioStreamPlayer = $BreakingSFX
@onready var broken_sfx: AudioStreamPlayer = $BrokenSFX

var hit_count: int = 0
const MAX_HITS: int = 4
var destruction_complete: bool = false

# Screen shake parameters
const SHAKE_INTENSITIES: Array[float] = [10.0, 15.0, 25.0, 40.0]  # Increasing intensity
const SHAKE_DURATION: float = 0.3

# Rotation parameters
const ROTATION_AMOUNTS: Array[float] = [0.1, 0.15, 0.25, 0.4]  # Radians per hit

var shake_tween: Tween
var is_breaking: bool = false

func _ready() -> void:
	# Hide win text and press enter label initially
	win_text.visible = false
	if press_enter_label:
		press_enter_label.visible = false

	# Ensure camera exists for shake
	if not camera:
		camera = Camera2D.new()
		add_child(camera)
		camera.enabled = true

func _process(_delta: float) -> void:
	if destruction_complete:
		# After core is destroyed, wait for Enter to go to level select
		if Input.is_action_just_pressed("ui_accept"):
			_transition_to_level_select()
	elif not is_breaking:
		# During destruction sequence, press space to break
		if Input.is_action_just_pressed("ui_accept"):
			_on_space_pressed()

func _on_space_pressed() -> void:
	if hit_count >= MAX_HITS:
		return

	is_breaking = true
	hit_count += 1

	# Trigger glitch hit effect
	if ShaderManager:
		ShaderManager.trigger_hit()

	# Rotate core
	_rotate_core()

	# Screen shake
	_screen_shake()

	# Play sound effect
	if hit_count < MAX_HITS:
		if breaking_sfx and breaking_sfx.stream:
			breaking_sfx.play()
	else:
		# Final hit
		if broken_sfx and broken_sfx.stream:
			broken_sfx.play()
		_final_destruction()

	# Small delay before allowing next hit
	await get_tree().create_timer(0.2).timeout
	is_breaking = false

func _rotate_core() -> void:
	if not core_solid:
		return

	var rotation_amount = ROTATION_AMOUNTS[hit_count - 1]

	# Alternate rotation direction for more chaotic feel
	if hit_count % 2 == 0:
		rotation_amount = -rotation_amount

	var tween = create_tween()
	tween.tween_property(core_solid, "rotation", core_solid.rotation + rotation_amount, 0.15)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

func _screen_shake() -> void:
	if not camera:
		return

	if shake_tween:
		shake_tween.kill()

	var intensity = SHAKE_INTENSITIES[hit_count - 1]
	var original_offset = camera.offset

	shake_tween = create_tween()

	# Multiple shake iterations for more intense feel
	var iterations = 8 + (hit_count * 2)  # More shakes on later hits
	var time_per_shake = SHAKE_DURATION / iterations

	for i in range(iterations):
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_tween.tween_property(camera, "offset", shake_offset, time_per_shake)

	# Return to original position
	shake_tween.tween_property(camera, "offset", original_offset, time_per_shake)

func _final_destruction() -> void:
	# Hide solid core
	if core_solid:
		core_solid.visible = false

	# Show destroyed core
	if core_destroyed:
		core_destroyed.visible = true

	# Hide instructions
	if instructions:
		instructions.visible = false

	# Show win text with dramatic entrance
	if win_text:
		win_text.visible = true
		win_text.modulate.a = 0.0

		var tween = create_tween()
		tween.tween_property(win_text, "modulate:a", 1.0, 1.0)
		tween.set_ease(Tween.EASE_OUT)

	# Wait for win text to finish, then show press enter prompt
	await get_tree().create_timer(1.5).timeout
	_show_press_enter()

func _show_press_enter() -> void:
	destruction_complete = true

	if press_enter_label:
		press_enter_label.visible = true
		press_enter_label.modulate.a = 0.0

		var tween = create_tween()
		tween.tween_property(press_enter_label, "modulate:a", 1.0, 0.5)

func _transition_to_level_select() -> void:
	# Transition to level selection screen
	if diamond:
		diamond.change_scene("res://scenes/level_selection.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/level_selection.tscn")
