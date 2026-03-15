class_name CloneConfig extends Resource

@export var max_clones: int = 4
@export var time_limit: float = 10.0
@export var clone_scene_path: String = "res://scenes/replay-clone.tscn"

func is_valid() -> bool:
	if max_clones <= 0:
		push_error("CloneConfig: max_clones must be greater than 0")
		return false
	if time_limit <= 0.0:
		push_error("CloneConfig: time_limit must be greater than 0.0")
		return false
	if clone_scene_path.is_empty():
		push_error("CloneConfig: clone_scene_path cannot be empty")
		return false
	return true
