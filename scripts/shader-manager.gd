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
var is_transitioning := false
var transition_tween : Tween
var music_tween : Tween
var material : ShaderMaterial
var music : AudioStreamPlayer2D

const PLAN_PITCH = 0.5
const RUN_PITCH = 1.0

func _ready():
	await get_tree().process_frame
	_fetch_nodes()
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	if node.name == "Game":
		await get_tree().process_frame
		_fetch_nodes()

func _fetch_nodes():
	material = get_tree().root.get_node("Game/cyberpunk-shader/ColorRect").material
	music = get_tree().root.get_node("Game/AudioStreamPlayer2D")
	music.pitch_scale = PLAN_PITCH
	current_phase = "plan"
	is_transitioning = false
	apply_phase_instant(PHASE_PLAN)

func go_to_run():
	if current_phase == "run" or is_transitioning:
		return
	current_phase = "run"
	_tween_pitch(RUN_PITCH, 0.6)
	_glitch_transition(PHASE_RUN, 0.5)

func go_to_plan():
	if current_phase == "plan" or is_transitioning:
		return
	current_phase = "plan"
	_tween_pitch(PLAN_PITCH, 2.0)
	_glitch_transition(PHASE_PLAN, 1.2)

func _glitch_transition(target_phase: Dictionary, settle_duration: float):
	is_transitioning = true
	if transition_tween:
		transition_tween.kill()
	transition_tween = create_tween()
	transition_tween.set_parallel(false)

	transition_tween.tween_callback(func():
		material.set_shader_parameter("glitch_intensity", 1.0)
		material.set_shader_parameter("chroma_strength", 9.0)
		material.set_shader_parameter("saturation", 1.5)
		material.set_shader_parameter("flicker_intensity", 0.2)
	)
	transition_tween.tween_interval(0.06)

	transition_tween.tween_callback(func():
		material.set_shader_parameter("glitch_intensity", 0.0)
		material.set_shader_parameter("chroma_strength", 0.0)
		material.set_shader_parameter("saturation", 0.1)
		material.set_shader_parameter("flicker_intensity", 0.0)
	)
	transition_tween.tween_interval(0.05)

	transition_tween.tween_callback(func():
		material.set_shader_parameter("glitch_intensity", 0.85)
		material.set_shader_parameter("chroma_strength", 7.0)
		material.set_shader_parameter("saturation", 1.5)
		material.set_shader_parameter("vignette_strength", 0.5)
	)
	transition_tween.tween_interval(0.07)

	transition_tween.tween_callback(func():
		var settle = create_tween()
		settle.set_parallel(true)
		for key in target_phase:
			var from = material.get_shader_parameter(key)
			var to = target_phase[key]
			settle.tween_method(
				func(v): material.set_shader_parameter(key, v),
				from, to, settle_duration
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		settle.finished.connect(func(): is_transitioning = false, CONNECT_ONE_SHOT)
	)

func apply_phase_instant(phase: Dictionary):
	for key in phase:
		material.set_shader_parameter(key, phase[key])

func _tween_pitch(target: float, duration: float):
	if !music or !is_instance_valid(music):
		return
	if music_tween:
		music_tween.kill()
	music_tween = create_tween()
	music_tween.tween_property(music, "pitch_scale", target, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func trigger_hit(intensity: float = 1.0):
	is_transitioning = false
	if transition_tween:
		transition_tween.kill()

	var base = PHASE_PLAN if current_phase == "plan" else PHASE_RUN

	material.set_shader_parameter("chroma_strength", 8.0 * intensity)
	material.set_shader_parameter("glitch_intensity", 0.95 * intensity)
	material.set_shader_parameter("vignette_strength", 1.4 * intensity)
	material.set_shader_parameter("saturation", 2.2)
	material.set_shader_parameter("contrast", 1.6)

	var recover_time = 0.35 + (0.2 * intensity)
	var hit_tween = create_tween()
	hit_tween.set_parallel(true)

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
