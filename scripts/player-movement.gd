extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -800.0
const DOUBLE_JUMP_VELOCITY = -800.0
const WALL_JUMP_VELOCITY_X = 300.0
const WALL_JUMP_VELOCITY_Y = -600.0
const WALL_SLIDE_GRAVITY = 200.0
const GRAVITY_MULT = 2
const SLIDE_SPEED = 900.0
const SLIDE_DURATION = 0.5
const SLIDE_COOLDOWN = 0
const SLIDE_JUMP_VELOCITY_Y = -800.0
const SLIDE_JUMP_VELOCITY_X = 480.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var floor = $FloorParticles
@onready var wall = $WallParticles

@onready var jumpFx = $JumpFx
@onready var slideFx = $SlideFx

@onready var animator = $Skeleton2D/hips/AnimationPlayer
@onready var skeleton = $Skeleton2D

var has_double_jump := true
var is_wall_sliding := false
var wall_jump_cooldown := 0.0
var last_wall_normal := Vector2.ZERO

var is_sliding := false
var slide_timer := 0.0
var slide_cooldown_timer := 0.0
var slide_direction := 1.0

func play_anim(anim_name: String):
	if animator.current_animation != anim_name:
		animator.play(anim_name, 0.15)

func _ready():
	ShaderManager.go_to_plan()

func _physics_process(delta):
	if _get_input_direction() != 0:
		ShaderManager.go_to_run()

	if slide_timer > 0:
		slide_timer -= delta
	if slide_cooldown_timer > 0:
		slide_cooldown_timer -= delta
	if wall_jump_cooldown > 0:
		wall_jump_cooldown -= delta

	if is_sliding:
		if slide_timer <= 0:
			is_sliding = false
		else:
			var slide_progress = 1.0 - (slide_timer / SLIDE_DURATION)
			velocity.x = slide_direction * lerp(SLIDE_SPEED, SPEED, slide_progress)

	is_wall_sliding = false
	if not is_on_floor():
		if is_on_wall() and _get_input_direction() != 0 and velocity.y > 0:
			is_wall_sliding = true
			wall.emitting = true
			slideFx.play()
			last_wall_normal = get_wall_normal()
			velocity.y = move_toward(velocity.y, WALL_SLIDE_GRAVITY, gravity * delta)
		else:
			velocity.y += gravity * delta * GRAVITY_MULT
			wall.emitting = false
			slideFx.stop()

	if is_on_floor():
		if is_sliding:
			slideFx.play()
		else:
			slideFx.stop()
		has_double_jump = true
		wall_jump_cooldown = 0.0
		wall.emitting = false
		if not is_sliding and slide_cooldown_timer <= 0:
			if Input.is_action_just_pressed("crouch"):
				var dir = _get_input_direction()
				slide_direction = dir if dir != 0 else (1.0 if skeleton.scale.x > 0 else -1.0)
				is_sliding = true
				slide_timer = SLIDE_DURATION
				slide_cooldown_timer = SLIDE_COOLDOWN
				ShaderManager.trigger_hit()

	var direction = _get_input_direction()

	if Input.is_action_just_pressed("restart"):
		ShaderManager.go_to_plan()

	if Input.is_action_just_pressed("jump"):
		ShaderManager.go_to_run()
		if is_sliding:
			is_sliding = false
			slide_timer = 0.0
			velocity.y = SLIDE_JUMP_VELOCITY_Y
			velocity.x = slide_direction * SLIDE_JUMP_VELOCITY_X
			# jumpFx.play()
			# floor.restart()
			# floor.emitting = true
			# ShaderManager.trigger_hit()
		elif is_on_floor():
			velocity.y = JUMP_VELOCITY
			jumpFx.play()
			floor.restart()
			floor.emitting = true
		elif is_wall_sliding:
			if direction > 0 and wall.position.x < 0:
				wall.position.x *= -1
			elif direction < 0 and wall.position.x > 0:
				wall.position.x *= -1
			velocity.x = last_wall_normal.x * WALL_JUMP_VELOCITY_X
			velocity.y = WALL_JUMP_VELOCITY_Y
			has_double_jump = true
			wall_jump_cooldown = 0.18
			jumpFx.play()
		elif has_double_jump:
			ShaderManager.trigger_hit()
			velocity.y = DOUBLE_JUMP_VELOCITY
			has_double_jump = false
			jumpFx.play()
			floor.restart()
			floor.emitting = true

	if not is_sliding:
		if direction > 0:
			skeleton.scale.x = 1
		elif direction < 0:
			skeleton.scale.x = -1

	if is_sliding:
		pass
	elif wall_jump_cooldown > 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 3 * delta)
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_sliding:
		play_anim("slide")
	elif is_wall_sliding:
		play_anim("wall_slide")
	elif is_on_floor():
		if abs(velocity.x) < 1:
			play_anim("idle")
		else:
			play_anim("run")
	elif velocity.y < 0 and has_double_jump:
		play_anim("jump")
	elif velocity.y < 0 and !has_double_jump:
		play_anim("double_jump")
	else:
		play_anim("fall")

	move_and_slide()

func _get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")
