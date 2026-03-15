extends Control

@onready var prompt_label: Label = $Label
@onready var diamond: CanvasLayer = $Diamond
@onready var boom_sfx: AudioStreamPlayer = $BoomSFX

var can_continue: bool = false

func _ready() -> void:
	# Fade out music
	if Music:
		Music.fade_out(1.5)

	# Trigger shader effects
	if ShaderManager:
		ShaderManager.trigger_hit(2.0)

	# Fade in prompt text
	prompt_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.8)
	tween.set_ease(Tween.EASE_OUT)
	await tween.finished

	can_continue = true

func _process(_delta: float) -> void:
	if can_continue and Input.is_action_just_pressed("ui_accept"):
		_transition_to_next_level()

func _transition_to_next_level() -> void:
	can_continue = false

	# Play boom intro sound
	if boom_sfx and boom_sfx.stream:
		boom_sfx.play()

	# Fade in music
	if Music:
		Music.fade_in(1.5)

	# Fade out prompt
	var tween = create_tween()
	tween.tween_property(prompt_label, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Transition to next level
	var next_scene = global.next_tower_level
	if next_scene.is_empty():
		push_error("No next level scene stored!")
		return

	if diamond:
		diamond.change_scene(next_scene)
	else:
		get_tree().change_scene_to_file(next_scene)
