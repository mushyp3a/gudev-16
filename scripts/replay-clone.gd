extends Node

var recording_system: RecordingSystem
var clone_id: int

func _ready() -> void:
	var animator = get_parent()
	if animator and animator.has_method("play_anim"):
		animator.recording_system = recording_system
		animator.clone_id = clone_id
	else:
		push_warning("ReplayClone: Parent is not a CloneAnimator")
