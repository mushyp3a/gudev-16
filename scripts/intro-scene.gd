extends Control

@export var text_lines: Array[String] = [
	"People have been enhancing their bodies with technology for years ",
	"But now massive tech company Obsidian Corp plan to release a virus ",
	"Which would control the minds of anyone using these mechanical enhancements",
	"The police wont listen, now it's up to you to stop them",
	"Using your grandfather’s old time machine, you must travel back and break into their headquarters before the upload begins",
	"you must destroy their plans before they can take control of millions",
]

@export var time_per_line: float = 3.0
@export var fade_duration: float = 0.8

@onready var background_shader: ColorRect = $BackgroundShader
@onready var text_label: Label = $TextLabel
@onready var diamond: CanvasLayer = $Diamond
@onready var intro_music: AudioStreamPlayer = $IntroMusic

var current_line: int = 0
var shader_material: ShaderMaterial

const INTRO_DURATION: float = 28.1

var presets = {
	"police": {
		"color1": Color(0.0, 0.3, 1.0),  # Bright blue
		"color2": Color(1.0, 0.0, 0.0),  # Bright red
		"color3": Color(0.05, 0.05, 0.15)   # Near-black background
	},
	"city": {
		"color1": Color(0.0, 0.8, 1.0),  # Cyan
		"color2": Color(1.0, 0.0, 0.5),  # Magenta
		"color3": Color(1.0, 0.5, 0.0)   # Orange
	},
	"violence": {
		"color1": Color(0.8, 0.0, 0.0),  # Blood red
		"color2": Color(0.5, 0.0, 0.1),  # Wine red
		"color3": Color(1.0, 0.4, 0.0)   # Orange
	},
	"corporate": {
		"color1": Color(0.0, 1.0, 0.5),  # Green
		"color2": Color(0.0, 0.5, 1.0),  # Blue
		"color3": Color(0.1, 0.1, 0.1)   # Dark
	},
	"underground": {
		"color1": Color(0.5, 0.0, 1.0),  # Purple
		"color2": Color(1.0, 0.0, 0.5),  # Magenta
		"color3": Color(0.1, 0.0, 0.2)   # Dark purple
	},
	"noir": {
		"color1": Color(0.8, 0.8, 0.8),  # White
		"color2": Color(0.3, 0.3, 0.3),  # Gray
		"color3": Color(0.0, 0.0, 0.0)   # Black
	}
}

var preset_sequence: Array[String] = ["city", "city", "police", "police", "violence", "violence"]

func _process(delta):
	if Input.is_key_pressed(KEY_SPACE):
		_finish_intro()


func _ready() -> void:
	if Music:
		Music.fade_out(2.0)

	_fade_in_intro_music(2.0)

	shader_material = background_shader.material as ShaderMaterial

	if preset_sequence.size() > 0:
		_apply_preset(preset_sequence[0])

	text_label.modulate.a = 0.0

	_start_intro()

func _start_intro() -> void:
	await get_tree().create_timer(0.5).timeout
	_show_next_line()

func _show_next_line() -> void:
	if current_line >= text_lines.size():
		_finish_intro()
		return

	text_label.text = text_lines[current_line]

	if current_line < preset_sequence.size():
		_tween_to_preset(preset_sequence[current_line], fade_duration)

	var tween = create_tween()
	tween.tween_property(text_label, "modulate:a", 1.0, fade_duration)

	await get_tree().create_timer(time_per_line).timeout

	tween = create_tween()
	tween.tween_property(text_label, "modulate:a", 0.0, fade_duration)

	await tween.finished

	current_line += 1
	_show_next_line()

func _apply_preset(preset_name: String) -> void:
	if not presets.has(preset_name):
		return

	var preset = presets[preset_name]
	shader_material.set_shader_parameter("color1", preset["color1"])
	shader_material.set_shader_parameter("color2", preset["color2"])
	shader_material.set_shader_parameter("color3", preset["color3"])

func _tween_to_preset(preset_name: String, duration: float) -> void:
	if not presets.has(preset_name):
		return

	var preset = presets[preset_name]
	var tween = create_tween().set_parallel(true)
	tween.tween_method(_set_color1, shader_material.get_shader_parameter("color1"), preset["color1"], duration)
	tween.tween_method(_set_color2, shader_material.get_shader_parameter("color2"), preset["color2"], duration)
	tween.tween_method(_set_color3, shader_material.get_shader_parameter("color3"), preset["color3"], duration)

func _set_color1(color: Color) -> void:
	shader_material.set_shader_parameter("color1", color)

func _set_color2(color: Color) -> void:
	shader_material.set_shader_parameter("color2", color)

func _set_color3(color: Color) -> void:
	shader_material.set_shader_parameter("color3", color)

func _finish_intro() -> void:
	_fade_out_intro_music(2.0)

	if Music:
		Music.fade_in(2.0)

	await get_tree().create_timer(0.5).timeout

	diamond.change_scene("res://scenes/level_selection.tscn")

func _fade_in_intro_music(duration: float) -> void:
	if not intro_music:
		return

	intro_music.volume_db = -80.0
	intro_music.play()

	var tween = create_tween()
	tween.tween_property(intro_music, "volume_db", -10.0, duration)

func _fade_out_intro_music(duration: float) -> void:
	if not intro_music or not intro_music.playing:
		return

	var tween = create_tween()
	tween.tween_property(intro_music, "volume_db", -80.0, duration)
	await tween.finished
	intro_music.stop()
