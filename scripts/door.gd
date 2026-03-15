extends StaticBody2D

@export var open_sprite: Texture2D
@export var closed_sprite: Texture2D
@export var animation_duration: float = 0.3
@export var start_open: bool = false

@onready var sprite: Sprite2D = $Sprite2D
var is_open: bool = false

func _ready() -> void:
	if start_open:
		sprite.texture = open_sprite
		is_open = true
		_set_collision(false)
	else:
		sprite.texture = closed_sprite
		is_open = false
		_set_collision(true)

func on_switch_toggled(switch_is_on: bool) -> void:
	if switch_is_on:
		open()
	else:
		close()

func open() -> void:
	if is_open:
		return

	print("Door %s OPENING (collision disabled)" % name)
	is_open = true
	_set_collision(false)
	sprite.texture = open_sprite

func close() -> void:
	if not is_open:
		return

	print("Door %s CLOSING (collision enabled)" % name)
	is_open = false
	_set_collision(true)
	sprite.texture = closed_sprite

func _set_collision(enabled: bool) -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not enabled
