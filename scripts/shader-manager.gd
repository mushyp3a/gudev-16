extends Node

const PHASE_PLAN = {
	"chroma_strength": 0.8,
	"chroma_pulse_speed": 0.6,
	"scanline_intensity": 0.25,
	"vignette_strength": 0.35,
	"vignette_pulse_speed": 0.4,
	"warp_strength": 0.008,
	"flicker_speed": 4.0,
	"flicker_intensity": 0.015,
	"glitch_intensity": 0.02,
	"glitch_speed": 1.0,
	"cyan_boost": 0.12,
	"magenta_boost": 0.02,
	"contrast": 1.05,
	"saturation": 0.85,
}

const PHASE_RUN = {
	"chroma_strength": 3.0,
	"chroma_pulse_speed": 4.0,
	"scanline_intensity": 0.18,
	"vignette_strength": 0.55,
	"vignette_pulse_speed": 1.8,
	"warp_strength": 0.012,
	"flicker_speed": 18.0,
	"flicker_intensity": 0.04,
	"glitch_intensity": 0.18,
	"glitch_speed": 7.0,
	"cyan_boost": 0.08,
	"magenta_boost": 0.05,
	"contrast": 1.15,
	"saturation": 1.4,
}

var current_phase := "plan"
var transition_tween : Tween

var material : ShaderMaterial

var is_transitioning := false

var music : AudioStreamPlayer2D

const PLAN_PITCH = 0.5
const RUN_PITCH = 1.0
var music_tween : Tween

func _ready():
	await get_tree().process_frame
	material = get_tree().root.get_node("Game/cyberpunk-shader/ColorRect").material
	music = get_tree().root.get_node("Game/AudioStreamPlayer2D")
	music.pitch_scale = 0.5
	apply_phase_instant(PHASE_PLAN)

func go_to_run():
	if current_phase == "run" or is_transitioning:
		return
	current_phase = "run"
	_transition_to(PHASE_RUN, 0.6)
	_tween_pitch(RUN_PITCH, 0.6)

func go_to_plan():
	if current_phase == "plan" or is_transitioning:
		return
	current_phase = "plan"
	_transition_to(PHASE_PLAN, 1.8)
	_tween_pitch(PLAN_PITCH, 1.8)

func _tween_pitch(target: float, duration: float):
	print("tween pitch called, music: ", music, " target: ", target)
	if !music:
		print("music is null, aborting")
		return
	print("pitch before: ", music.pitch_scale)
	if music_tween:
		music_tween.kill()
	music_tween = create_tween()
	print("tween created")
	music_tween.tween_property(music, "pitch_scale", target, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	print("tween started")

func _transition_to(phase: Dictionary, duration: float):
	is_transitioning = true
	if transition_tween:
		transition_tween.kill()
	transition_tween = create_tween()
	transition_tween.set_parallel(true)
	for key in phase:
		var from = material.get_shader_parameter(key)
		var to = phase[key]
		transition_tween.tween_method(
			func(v): material.set_shader_parameter(key, v),
			from, to, duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await transition_tween.finished
	is_transitioning = false

func apply_phase_instant(phase: Dictionary):
	for key in phase:
		material.set_shader_parameter(key, phase[key])

func trigger_hit(intensity: float = 1.0):
	if transition_tween:
		transition_tween.kill()

	var base = PHASE_PLAN if current_phase == "plan" else PHASE_RUN

	material.set_shader_parameter("chroma_strength", 8.0 * intensity)
	material.set_shader_parameter("glitch_intensity", 0.95 * intensity)
	material.set_shader_parameter("vignette_strength", 1.4 * intensity)
	material.set_shader_parameter("saturation", 2.2)
	material.set_shader_parameter("contrast", 1.6)

	var hit_tween = create_tween()
	hit_tween.set_parallel(true)
	var recover_time = 0.35 + (0.2 * intensity)

	hit_tween.tween_method(func(v): material.set_shader_parameter("chroma_strength", v),
		8.0 * intensity, base["chroma_strength"], recover_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	hit_tween.tween_method(func(v): material.set_shader_parameter("glitch_intensity", v),
		0.95 * intensity, base["glitch_intensity"], recover_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	hit_tween.tween_method(func(v): material.set_shader_parameter("vignette_strength", v),
		1.4 * intensity, base["vignette_strength"], recover_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	hit_tween.tween_method(func(v): material.set_shader_parameter("saturation", v),
		2.2, base["saturation"], recover_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	hit_tween.tween_method(func(v): material.set_shader_parameter("contrast", v),
		1.6, base["contrast"], recover_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
