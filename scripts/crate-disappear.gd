extends StaticBody2D

@export var start_visible: bool = true

@onready var sprite: Sprite2D = $Sprite2D
var is_visible: bool = start_visible

func _ready() -> void:
	if start_visible:
		show_crate()
	else:
		hide_crate()

func on_switch_toggled(switch_is_on: bool) -> void:
	if switch_is_on:
		show_crate()
	else:
		hide_crate()

func show_crate() -> void:
	if is_visible:
		return

	is_visible = true
	sprite.visible = true
	_set_collision(true)

func hide_crate() -> void:
	if not is_visible:
		return

	is_visible = false
	sprite.visible = false
	_set_collision(false)

func _set_collision(enabled: bool) -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not enabled
