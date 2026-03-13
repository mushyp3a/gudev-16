extends Node

# clone-animator.gd (on the parent Node2D) handles all positioning and animation.
# This script only exists to receive cloneId/replayable from PlayerCloning
# and forward them up to the animator.

var replayable: Replayable
var cloneId: int

func _ready() -> void:
	# Forward the references to clone-animator on the parent as soon as they're set
	_sync_to_animator()

func _sync_to_animator() -> void:
	var animator = get_parent()
	if animator and animator.has_method("play_anim"):
		animator.replayable = replayable
		animator.cloneId    = cloneId
