class_name CloneConfig extends Resource

## Configuration resource for the clone/replay system
## This allows easy modification of clone system parameters without code changes

## Maximum number of clones that can be created
@export var max_clones: int = 4

## Time limit in seconds for recording/playback before auto-reset
@export var time_limit: float = 10.0

## Path to the clone scene template
@export var clone_scene_path: String = "res://scenes/replay-clone.tscn"

## Validate configuration values
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
