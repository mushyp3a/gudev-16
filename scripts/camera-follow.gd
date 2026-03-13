extends Camera2D

@export var target: Node2D
@export var smooth_speed: float = 8.0
@export var bounds_min: Vector2 = Vector2(-500, -500)
@export var bounds_max: Vector2 = Vector2(500, 500)

func _physics_process(delta: float) -> void:
	if not target:
		return

	var target_pos = target.global_position

	# clamp to bounds
	target_pos.x = clamp(target_pos.x, bounds_min.x, bounds_max.x)
	target_pos.y = clamp(target_pos.y, bounds_min.y, bounds_max.y)

	# smooth follow
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
