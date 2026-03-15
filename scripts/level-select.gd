extends Control

@export var tex : TextureRect
@export var sceneName : String
@export var diamond : CanvasLayer
@export var bump : AudioStreamPlayer2D
@export var tower_number : int = 1  # Which tower this is (1-4)
@export var unlocked_sprite : Sprite2D

var start_pos : Vector2
var is_unlocked : bool = false
var is_completed : bool = false

func _on_mouse_entered():
	if is_unlocked:
		expand()

func _on_mouse_exited():
	if is_unlocked:
		shrink()

func _gui_input(event):
	if not is_unlocked:
		return

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

	# Determine if this tower should be unlocked and completed
	# Tower 1 is always unlocked (leftmost)
	# Tower N is unlocked if Tower N-1 is completed
	if tower_number == 1:
		is_unlocked = true
		is_completed = levels_completed.is_level_completed(1)
	elif tower_number == 2:
		is_unlocked = levels_completed.is_level_completed(1)
		is_completed = levels_completed.is_level_completed(2)
	elif tower_number == 3:
		is_unlocked = levels_completed.is_level_completed(2)
		is_completed = levels_completed.is_level_completed(3)
	elif tower_number == 4:
		is_unlocked = levels_completed.is_level_completed(3)
		is_completed = levels_completed.is_level_completed(4)

	# Enable the fire sprite if this building is completed
	if unlocked_sprite:
		unlocked_sprite.visible = is_completed

	# Only start idle bounce if unlocked
	if is_unlocked:
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
