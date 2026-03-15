extends TextureRect

@export var up : Texture2D
@export var down : Texture2D

func click_down():
	texture = down

func click_up():
	texture = up
