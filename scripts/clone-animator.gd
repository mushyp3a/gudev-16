extends Node2D

# Assign these from the clone spawner (replay-clone.gd sets cloneId and replayable)
var replayable
var cloneId: int

@onready var animator: AnimationPlayer = $Skeleton2D/hips/AnimationPlayer
@onready var skeleton: Node2D = $Skeleton2D

func play_anim(anim_name: String) -> void:
	if animator.current_animation != anim_name:
		animator.play(anim_name, 0.15)

func _process(_delta: float) -> void:
	if replayable == null or replayable.replays[cloneId] == null:
		return
	if replayable.replays[cloneId].positionHistory.size() < 2:
		return

	var prev_x: float = global_position.x
	var s: Dictionary = replayable.sample(cloneId)

	global_position = s["position"]
	skeleton.scale.x = s["facing"]

	var vel_y: float = s["velocity_y"]
	var moving_x: bool = abs(global_position.x - prev_x) > 0.5

	if s["is_sliding"]:
		play_anim("slide")
	elif s["is_wall_sliding"]:
		play_anim("wall_slide")
	elif vel_y < -10:
		if s["has_double_jump"]:
			play_anim("jump")
		else:
			play_anim("double_jump")
	elif vel_y > 10:
		play_anim("fall")
	elif moving_x:
		play_anim("run")
	else:
		play_anim("idle")
