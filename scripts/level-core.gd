extends Area2D

@export var level_number: int = 1
@export var transition_delay: float = 0.5

@onready var victory_sfx: AudioStreamPlayer = $VictorySFX
@onready var diamond: CanvasLayer = null

var triggered: bool = false
var clone_manager: CloneManager = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	var root = get_tree().root
	clone_manager = root.find_child("CloneManager", true, false)
	diamond = root.find_child("Diamond", true, false)

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if body.name == "Player":
		triggered = true
		_trigger_level_complete(body)

func _trigger_level_complete(player: Node2D) -> void:
	print("Level %d completed!" % level_number)

	player.visible = false

	if player.has_method("set_physics_process"):
		player.set_physics_process(false)

	if victory_sfx and victory_sfx.stream:
		victory_sfx.play()

	if levels_completed:
		levels_completed.complete_level(level_number)

	_freeze_timer()
	_cleanup_clones()

	await get_tree().create_timer(transition_delay).timeout

	if diamond:
		diamond.change_scene("res://scenes/levels/level-beat.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/levels/level-beat.tscn")

func _freeze_timer() -> void:
	if clone_manager:
		clone_manager.set_physics_process(false)
		print("Timer frozen at: %.2f" % clone_manager.time_elapsed)

func _cleanup_clones() -> void:
	if not clone_manager:
		return

	for i in range(clone_manager.clones.size() - 1, -1, -1):
		if clone_manager.clones[i] != null:
			clone_manager.delete_clone(i)

	print("All clones cleaned up before level transition")

