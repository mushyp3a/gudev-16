extends Node2D

var replayable
var cloneId: int

@onready var animator: AnimationPlayer = $Skeleton2D/hips/AnimationPlayer
@onready var skeleton: Node2D = $Skeleton2D

var cloning = null

func _ready() -> void:
	cloning = get_tree().root.find_child("PlayerCloning", true, false)

func play_anim(anim_name: String) -> void:
	if animator.current_animation != anim_name:
		animator.play(anim_name, 0.15)

func _process(_delta: float) -> void:
	if replayable == null or replayable.replays[cloneId] == null:
		return
	var replay = replayable.replays[cloneId]
	if replay.positionHistory.size() < 2:
		return

	if cloning == null:
		return

	# Hide this clone while it's the one being recorded — the player is the visual stand-in
	visible = not (cloning.recording and replayable.currIx == cloneId)

	if cloning.paused:
		global_position = replay.positionHistory[-1]
		play_anim("idle")
		return

	if cloning.waitingForInput:
		global_position = replay.positionHistory[0]
		play_anim("idle")
		return

	if cloning.recording:
		var prev_x: float = global_position.x
		var s: Dictionary = replayable.sample(cloneId)
		global_position = s["position"]
		skeleton.scale.x = s["facing"]
		var vel_y: float = s["velocity_y"]
		var moving_x: bool = abs(global_position.x - prev_x) > 0.5
		_update_anim(s, vel_y, moving_x)
		return

	if cloning.previewing:
		var prev_x: float = global_position.x
		var s: Dictionary = replayable.sample(cloneId)
		global_position = s["position"]
		skeleton.scale.x = s["facing"]
		var vel_y: float = s["velocity_y"]
		var moving_x: bool = abs(global_position.x - prev_x) > 0.5
		_update_anim(s, vel_y, moving_x)
		return

func _update_anim(s: Dictionary, vel_y: float, moving_x: bool) -> void:
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
