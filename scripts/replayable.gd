class_name Replayable extends Node

var replays: Array[Replay] = [null, null, null, null]

var time: float
var recording: bool = false

# Exported node should be the player CharacterBody2D so we can read
# velocity and animation state each frame
@export var node: CharacterBody2D

var currIx: int = -1

@onready var cloning = get_tree().root.find_child("PlayerCloning", true, false)

func newRecording(id: int) -> void:
	replays[id] = Replay.new(node.global_position, 0, PlayerActions.new([]))
	currIx = id
	time = 0

func getPosition(cloneId: int) -> Vector2:
	return replays[cloneId].replayPos(time)

# Returns the full animation-state dict for a clone at current time
func sample(cloneId: int) -> Dictionary:
	return replays[cloneId].sample(time)

func reset() -> void:
	for replay in replays:
		if replay != null:
			replay.reset()

func _process(_delta: float) -> void:
	if not recording:
		return
	if cloning and cloning.waitingForInput:
		return
	if currIx == -1:
		return

	var skeleton: Node2D = node.get_node("Skeleton2D")
	var facing:   float  = skeleton.scale.x if skeleton else 1.0

	replays[currIx].record(
		node.global_position,
		time,
		PlayerActions.new([]),
		facing,
		node.velocity.y,
		node.is_sliding,
		node.is_wall_sliding,
		node.has_double_jump
	)
