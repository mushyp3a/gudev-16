extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const DOUBLE_JUMP_VELOCITY = -270.0
const WALL_JUMP_VELOCITY_X = 150.0
const WALL_JUMP_VELOCITY_Y = -300.0
const WALL_SLIDE_GRAVITY = 40.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var floor = $FloorParticles
@onready var wall = $WallParticles

var has_double_jump := true
var is_wall_sliding := false
var wall_jump_cooldown := 0.0
var last_wall_normal := Vector2.ZERO

func _ready():
	ShaderManager.go_to_plan()

func _physics_process(delta):

	if _get_input_direction() != 0:
		ShaderManager.go_to_run()

	if wall_jump_cooldown > 0:
		wall_jump_cooldown -= delta

	is_wall_sliding = false
	if not is_on_floor():
		if is_on_wall() and _get_input_direction() != 0 and velocity.y > 0:
			is_wall_sliding = true
			wall.emitting = true
			last_wall_normal = get_wall_normal()
			velocity.y = move_toward(velocity.y, WALL_SLIDE_GRAVITY, gravity * delta)
		else:
			velocity.y += gravity * delta
			wall.emitting = false

	if is_on_floor():
		has_double_jump = true
		wall_jump_cooldown = 0.0
		wall.emitting = false

	var direction = _get_input_direction()

	if Input.is_action_just_pressed("restart"):
			#get_tree().reload_current_scene()
		ShaderManager.go_to_plan()

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			floor.restart()
			floor.emitting = true

		elif is_wall_sliding:
			if direction > 0 and wall.position.x < 0:
				wall.position.x *= -1
			elif direction < 0 and wall.position.x > 0:
				wall.position.x *= -1

			velocity.x = last_wall_normal.x * WALL_JUMP_VELOCITY_X
			velocity.y = WALL_JUMP_VELOCITY_Y
			has_double_jump = true # Reward the wall jump with a fresh double jump
			wall_jump_cooldown = 0.18

		elif has_double_jump:
			ShaderManager.trigger_hit()
			velocity.y = DOUBLE_JUMP_VELOCITY
			has_double_jump = false
			floor.restart()
			floor.emitting = true


	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if wall_jump_cooldown > 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 3 * delta)
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# --- ANIMATIONS ---
	# if is_wall_sliding:
	# 	animated_sprite.play("wall_slide")
	# elif is_on_floor():
	# 	if direction == 0:
	# 		animated_sprite.play("idle")
	# 	else:
	# 		animated_sprite.play("run")
	# elif velocity.y < 0:
	# 	animated_sprite.play("jump")
	# elif not has_double_jump and velocity.y > 0:
	# 	animated_sprite.play("fall")

	move_and_slide()

func _get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")
