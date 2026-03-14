extends Control

@onready var background = $background

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background.texture = global.load_background() 

func _on_level_1_pressed() -> void:
	#change below to level 1
	get_tree().change_scene_to_file("res://scenes/platformer-scene.tscn")

func _on_level_2_pressed() -> void:
	#change below to level 2
	#get_tree().change_scene_to_file("res://scenes/platformer-scene.tscn")
	pass

func _on_level_3_pressed() -> void:
	#change below to level 3
	#get_tree().change_scene_to_file("res://scenes/platformer-scene.tscn")
	pass

func _on_level_4_pressed() -> void:
	#change below to level 4
	#get_tree().change_scene_to_file("res://scenes/platformer-scene.tscn")
	pass

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu2.tscn")
