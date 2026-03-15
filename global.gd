extends Node

var levels_completed:int = 0
var next_tower_level: String = ""
var textures = [
	preload("res://ui designs/Cyberpunk_background_intro.png"),
	preload("res://ui designs/Cyberpunk_background_1.png"),
	preload("res://ui designs/Cyberpunk_background_2.png"),
	preload("res://ui designs/Cyberpunk_background_3.png"),
	preload("res://ui designs/Cyberpunk_background_4.png")
]

func load_background() -> Object:
	var index = clamp(levels_completed, 0, textures.size() - 1)
	return textures[index]
