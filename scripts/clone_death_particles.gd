extends GPUParticles2D

## Self-destructing particle effect
## Automatically cleans up after emission finishes

func _ready() -> void:
	print("Death particles instantiated at position: %s" % global_position)

	# Force emission to start
	emitting = true
	restart()

	print("Death particles emitting: %s, amount: %d, lifetime: %f" % [emitting, amount, lifetime])

	# Wait for particles to finish, then remove
	await get_tree().create_timer(lifetime).timeout
	print("Death particles cleaning up")
	queue_free()
