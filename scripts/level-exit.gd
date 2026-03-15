extends Area2D

@export_file("*.tscn") var next_level_scene: String = ""
@export var transition_delay: float = 0.5

@onready var victory_sfx: AudioStreamPlayer = $VictorySFX
@onready var diamond: CanvasLayer = null

var triggered: bool = false
var clone_manager: CloneManager = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	var root = get_tree().root
	clone_manager = root.find_child("CloneManager", true, false)
	# Use direct path like main menu does
	diamond = get_node_or_null("/root/Game/Diamond")

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if body.name == "Player":
		triggered = true
		_trigger_level_transition(body)

func _trigger_level_transition(player: Node2D) -> void:
	if next_level_scene.is_empty():
		push_error("No next level scene specified for level exit!")
		return

	print("Transitioning to: %s" % next_level_scene)

	if victory_sfx and victory_sfx.stream:
		victory_sfx.play()

	# Wait for transition delay while scene is still fully visible
	await get_tree().create_timer(transition_delay).timeout

	# NOW hide player and cleanup (Diamond will sample color before this affects visuals)
	player.visible = false

	if player.has_method("set_physics_process"):
		player.set_physics_process(false)

	_freeze_timer()
	_cleanup_clones()

	# Store next level for intermediate scene
	global.next_tower_level = next_level_scene

	# Find Diamond NOW (not in _ready) to avoid timing issues
	if not diamond:
		var root = get_tree().root
		diamond = root.find_child("Diamond", true, true)

	# Transition to tower ascend intermediate scene
	if diamond:
		diamond.change_scene("res://scenes/props/tower-ascend.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/props/tower-ascend.tscn")

func _freeze_timer() -> void:
	if clone_manager:
		clone_manager.set_physics_process(false)

func _cleanup_clones() -> void:
	if not clone_manager:
		return

	for i in range(clone_manager.clones.size() - 1, -1, -1):
		if clone_manager.clones[i] != null:
			clone_manager.delete_clone(i)
