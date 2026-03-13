extends Node

# This script sits as a child of the clone scene root (which has clone-animator.gd).
# Its only job is to receive cloneId and replayable from the spawner
# and pass them up to the parent animator.

var replayable
var cloneId: int

func _ready() -> void:
	var parent = get_parent()
	parent.replayable = replayable
	parent.cloneId = cloneId
