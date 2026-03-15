extends Area2D

@onready var animator : AnimationPlayer = $AnimationPlayer

func _ready():
	animator.play("idle")

func play_idle():
	if animator.current_animation != "idle":
		animator.play("idle", 0.4)

func play_run():
	if animator.current_animation != "run":
		animator.play("run", 0.4)
