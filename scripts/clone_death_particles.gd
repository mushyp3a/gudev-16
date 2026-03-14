extends GPUParticles2D

## Self-destructing particle effect
## Automatically cleans up after emission finishes

func _ready() -> void:
	# Force emission to start
	emitting = true
	restart()

	# Wait for particles to finish, then remove
	await get_tree().create_timer(lifetime).timeout
	queue_free()
