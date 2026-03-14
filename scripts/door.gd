extends StaticBody2D

## Simple door that opens/closes in response to lever/switch signals
## Connect a lever's "switched" signal to the on_switch_toggled() method

@export var open_sprite: Texture2D  ## Sprite to show when door is open
@export var closed_sprite: Texture2D  ## Sprite to show when door is closed
@export var animation_duration: float = 0.3  ## Duration of fade animation
@export var start_open: bool = false  ## Whether the door starts in the open state

@onready var sprite: Sprite2D = $Sprite2D
var is_open: bool = false

func _ready() -> void:
	# Set initial sprite based on start_open
	if start_open:
		sprite.texture = open_sprite
		is_open = true
		_set_collision(false)
	else:
		sprite.texture = closed_sprite
		is_open = false
		_set_collision(true)

## Called when a lever/switch is toggled
## Connect this to the lever's "switched" signal
func on_switch_toggled(switch_is_on: bool) -> void:
	if switch_is_on:
		open()
	else:
		close()

## Open the door
func open() -> void:
	if is_open:
		return

	is_open = true
	_set_collision(false)
	sprite.texture = open_sprite

## Close the door
func close() -> void:
	if not is_open:
		return

	is_open = false
	sprite.texture = closed_sprite
	_set_collision(true)

## Enable/disable collision
func _set_collision(enabled: bool) -> void:
	# Disable all collision shapes
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not enabled


func _on_lever_switched(is_on: bool) -> void:
	on_switch_toggled(is_on)
