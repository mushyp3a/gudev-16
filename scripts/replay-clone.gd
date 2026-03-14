extends Node

## Simple forwarding script for clone instances
## Receives cloneId and recording_system from CloneManager
## and forwards them to the parent CloneAnimator
## This keeps the clone scene structure simple and decoupled

## Reference to the recording system (set by CloneManager)
var recording_system: RecordingSystem

## ID of this clone (set by CloneManager)
var clone_id: int

func _ready() -> void:
	# Forward the references to clone-animator on the parent as soon as ready
	_sync_to_animator()

## Sync properties to the parent CloneAnimator
func _sync_to_animator() -> void:
	var animator = get_parent()
	if animator and animator.has_method("play_anim"):
		# Parent is the CloneAnimator (extends Node2D)
		animator.recording_system = recording_system
		animator.clone_id = clone_id
	else:
		push_warning("ReplayClone: Parent is not a CloneAnimator")
