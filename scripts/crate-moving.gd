extends StaticBody2D

@export var point_a: Vector2 = Vector2.ZERO
@export var point_b: Vector2 = Vector2(500, 0)
@export var move_duration: float = 2.0

var move_progress: float = 0.0
var is_powered: bool = false

func _ready() -> void:
	position = point_a
	move_progress = 0.0

func on_switch_toggled(switch_is_on: bool) -> void:
	is_powered = switch_is_on

func _process(delta: float) -> void:
	var target_progress = 1.0 if is_powered else 0.0

	if move_progress < target_progress:
		move_progress += delta / move_duration
		if move_progress > target_progress:
			move_progress = target_progress
	elif move_progress > target_progress:
		move_progress -= delta / move_duration
		if move_progress < target_progress:
			move_progress = target_progress

	var t = ease_in_out(move_progress)
	position = point_a.lerp(point_b, t)

func ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
