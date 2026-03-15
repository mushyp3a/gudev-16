extends Label

func _ready() -> void:
	var level_core = get_node_or_null("/root/Game/LevelCore")
	var level_exit = get_node_or_null("/root/Game/LevelExit")

	if level_core:
		text = "Destroy the core"
	elif level_exit:
		text = "Ascend the tower"
