extends AudioStreamPlayer

## Global music controller with fade support

var fade_tween: Tween

func fade_out(duration: float = 1.0) -> void:
	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(self, "volume_db", -80.0, duration)
	await fade_tween.finished
	stop()
	volume_db = -10.0  # Reset to default

func fade_in(duration: float = 1.0) -> void:
	if not playing:
		volume_db = -80.0
		play()

	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(self, "volume_db", -10.0, duration)
