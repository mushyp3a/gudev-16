extends CanvasLayer

signal diamond_finished

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var diamond_rect : ColorRect = $diamond

# Persistent color storage across scene changes
static var last_transition_color: Color = Color(0.15, 0.25, 0.35)  # Initial dark teal

func _ready():
	# Use the color from the previous scene's transition
	if diamond_rect:
		diamond_rect.color = last_transition_color
	RenderingServer.set_default_clear_color(last_transition_color)

	# Play out animation (transition from previous scene)
	animation_player.play("out")

	# Wait for "out" animation to finish before sampling
	await animation_player.animation_finished

	# NOW sample new color for future transitions (won't affect current visuals)
	_update_diamond_color()

func change_scene(target_scene: String) -> void:
	# Wait for any existing animation to finish
	if animation_player.is_playing():
		await animation_player.animation_finished

	# Sample screen color before transition (current scene color)
	await _update_diamond_color()

	# Play transition in animation
	animation_player.play("in")
	await animation_player.animation_finished

	# Change scene (accept full path as-is)
	# Note: The new scene's Diamond instance will sample its own color in _ready()
	get_tree().change_scene_to_file(target_scene)

# 	if get_tree().paused:
# 		get_tree().paused = false

# func change_scene(target_scene: String) -> void:
# 	print("Transition started")
# 	animation_player.play("diamond")
# 	Let the animation actually appear on screen
# 	await get_tree().process_frame
# 	Wait for animation duration
# 	await get_tree().create_timer(animation_player.current_animation_length).timeout
# 	await get_tree().create_timer(1.2).timeout
# 	print("Changing scene")
# 	get_tree().change_scene_to_file(target_scene)

# func start_transition() -> void:
# 	animation_player.play_backwards("diamond")
# 	await get_tree().process_frame
# 	await get_tree().create_timer(animation_player.current_animation_length).timeout
# 	diamond_finished.emit()

# func start_transition() -> void:
# 	animation_player.play_backwards("diamond")
# 	await animation_player.animation_finished
# 	diamond_finished.emit()

## Update diamond color based on current screen median color
func _update_diamond_color() -> void:
	if not ScreenColorSampler:
		return

	var median_color := await ScreenColorSampler.get_median_color()

	# Slightly darken the color for better aesthetics (0.85 multiplier)
	# Prevents washed-out whites from dominating the transition
	median_color = Color(
		median_color.r * 0.85,
		median_color.g * 0.85,
		median_color.b * 0.85,
		1.0
	)

	# Store for next scene transition
	last_transition_color = median_color

	# Update diamond ColorRect
	if diamond_rect:
		diamond_rect.color = median_color

	# Update Godot's clear color (background)
	RenderingServer.set_default_clear_color(median_color)
