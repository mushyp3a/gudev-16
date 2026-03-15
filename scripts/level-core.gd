extends Area2D

## Level completion core - player walks into this to complete the level

@export var level_number: int = 1  # Which level this core represents (1-4)

var triggered: bool = false

func _ready() -> void:
	# Connect to player entering the area
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	# Check if it's the player
	if body.name == "Player" or body is CharacterBody2D:
		triggered = true
		_trigger_level_complete()

func _trigger_level_complete() -> void:
	print("Level %d completed!" % level_number)

	# Mark level as completed in global tracker
	if levels_completed:
		levels_completed.complete_level(level_number)

	# Instant transition to level-beat scene (no diamond animation)
	get_tree().change_scene_to_file("res://scenes/levels/level-beat.tscn")
