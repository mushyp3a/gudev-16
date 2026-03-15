extends Control

@export var tex : TextureRect
@export var sceneName : String
@export var diamond : CanvasLayer
@export var bump : AudioStreamPlayer2D

var start_pos : Vector2

func _on_mouse_entered():
	expand()

func _on_mouse_exited():
	shrink()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			bump.play()
			diamond.change_scene("res://scenes/" + sceneName + ".tscn")

func expand():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(tex, "scale", Vector2(1.03, 1.03), 0.3)
	tween.parallel().tween_property(tex, "position:y", start_pos.y - 5, 0.3)

func shrink():
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(tex, "scale", Vector2(1, 1), 0.25)
	tween.parallel().tween_property(tex, "position:y", start_pos.y, 0.25)

var bounce_tween
var is_bouncing = false

func _ready():
	start_pos = tex.position
	_start_idle_bounce()

func _start_idle_bounce():
	if bounce_tween:
		bounce_tween.kill()

	bounce_tween = create_tween()
	bounce_tween.set_loops()
	bounce_tween.set_ease(Tween.EASE_IN_OUT)
	bounce_tween.set_trans(Tween.TRANS_SINE)

	# Very gentle floating motion
	bounce_tween.tween_property(tex, "position:y", start_pos.y - 3, 1)
	bounce_tween.tween_property(tex, "position:y", start_pos.y + 3, 1)
