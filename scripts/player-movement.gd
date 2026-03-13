extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -800.0
const DOUBLE_JUMP_VELOCITY = -800.0
const WALL_JUMP_VELOCITY_X = 500.0
const WALL_JUMP_VELOCITY_Y = -800.0
const WALL_SLIDE_GRAVITY = 200.0
const GRAVITY_MULT = 2
const SLIDE_SPEED = 900.0
const SLIDE_DURATION = 0.5
const SLIDE_COOLDOWN = 0
const SLIDE_JUMP_VELOCITY_Y = -800.0
const SLIDE_JUMP_VELOCITY_X = 480.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var floor_particles = $FloorParticles
@onready var wall = $WallParticles
@onready var jumpFx = $JumpFx
@onready var slideFx = $SlideFx
@onready var animator = $Skeleton2D/hips/AnimationPlayer
@onready var skeleton = $Skeleton2D

var has_double_jump := true
var wall_jump_cooldown := 0.0
var last_wall_normal := Vector2.ZERO
var slide_timer := 0.0
var slide_cooldown_timer := 0.0
var slide_direction := 1.0

# These are now plain state vars — set by physics, not by input checks
var is_sliding := false
var is_wall_sliding := false
var facing := 1.0  # 1 = right, -1 = left

func play_anim(anim_name: String):
	if animator.current_animation != anim_name:
		animator.play(anim_name, 0.15)

# Called by both the player and clone nodes to pick the right animation
func update_animation() -> void:
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
	elif velocity.y < 0 and not has_double_jump:
		play_anim("double_jump")
	else:
		play_anim("fall")

func _ready():
	ShaderManager.go_to_plan()

func _physics_process(delta):
	if slide_timer > 0:
		slide_timer -= delta
	if slide_cooldown_timer > 0:
		slide_cooldown_timer -= delta
	if wall_jump_cooldown > 0:
		wall_jump_cooldown -= delta

	# ── Sliding ───────────────────────────────────────────────────────────────
	if is_sliding:
		if slide_timer <= 0:
			is_sliding = false
		else:
			var slide_progress = 1.0 - (slide_timer / SLIDE_DURATION)
			velocity.x = slide_direction * lerp(SLIDE_SPEED, SPEED, slide_progress)

	# ── Wall sliding — set purely from physics ────────────────────────────────
	is_wall_sliding = false
	if not is_on_floor():
		if is_on_wall() and velocity.y > 0 and _get_input_direction() != 0:
			is_wall_sliding = true
			wall.emitting = true
			slideFx.play()
			last_wall_normal = get_wall_normal()
			velocity.y = move_toward(velocity.y, WALL_SLIDE_GRAVITY, gravity * delta)
		else:
			velocity.y += gravity * delta * GRAVITY_MULT
			wall.emitting = false
			slideFx.stop()

	# ── Floor ─────────────────────────────────────────────────────────────────
	if is_on_floor():
		if is_sliding:
			slideFx.play()
		else:
			slideFx.stop()
		has_double_jump = true
		wall_jump_cooldown = 0.0
		wall.emitting = false

		# Slide input — only place input touches is_sliding
		if not is_sliding and slide_cooldown_timer <= 0:
			if Input.is_action_just_pressed("crouch"):
				var dir = _get_input_direction()
				slide_direction = dir if dir != 0 else facing
				is_sliding = true
				slide_timer = SLIDE_DURATION
				slide_cooldown_timer = SLIDE_COOLDOWN
				ShaderManager.trigger_hit()

	# ── Jump ──────────────────────────────────────────────────────────────────
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
		elif is_on_floor():
			velocity.y = JUMP_VELOCITY
			jumpFx.play()
			floor_particles.restart()
			floor_particles.emitting = true
		elif is_wall_sliding:
			if direction > 0 and wall.position.x < 0:
				wall.position.x *= -1
			elif direction < 0 and wall.position.x > 0:
				wall.position.x *= -1
			velocity.x = last_wall_normal.x * WALL_JUMP_VELOCITY_X
			velocity.y = WALL_JUMP_VELOCITY_Y
			has_double_jump = true
			wall_jump_cooldown = 0
			jumpFx.play()
		elif has_double_jump:
			ShaderManager.trigger_hit()
			velocity.y = DOUBLE_JUMP_VELOCITY
			has_double_jump = false
			jumpFx.play()
			floor_particles.restart()
			floor_particles.emitting = true

	# ── Facing & horizontal movement ─────────────────────────────────────────
	if not is_sliding:
		if direction > 0:
			facing = 1.0
		elif direction < 0:
			facing = -1.0
		skeleton.scale.x = facing

	if is_sliding:
		pass
	elif wall_jump_cooldown > 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 3 * delta)
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if direction != 0:
		ShaderManager.go_to_run()

	update_animation()
	move_and_slide()

func _get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")
