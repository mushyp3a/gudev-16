extends GPUParticles2D

func _ready() -> void:
	emitting = true
	restart()
	await get_tree().create_timer(lifetime).timeout
	queue_free()
