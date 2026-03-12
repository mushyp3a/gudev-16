class_name ButtonPressHandler extends Area2D

var isPressed : bool = false


func queryCollision() -> void:
	var bodies = get_overlapping_bodies()
	isPressed = len(bodies) > 0

func _process(delta : float) -> void:
	queryCollision()
