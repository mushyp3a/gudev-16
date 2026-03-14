extends Control

@onready var background = $background

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background.texture = global.load_background()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu2.tscn")
