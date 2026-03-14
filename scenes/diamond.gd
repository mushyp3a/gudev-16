extends CanvasLayer

signal diamond_finished

@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready():
	animation_player.play("out")

func change_scene(target_scene : String) -> void:
	animation_player.play("in")
	await get_tree().create_timer(0.75).timeout
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
