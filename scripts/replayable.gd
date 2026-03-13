class_name Replayable extends Node

var replays: Array = [null, null, null, null]

var time: float = 0.0
var recording: bool = false

@export var node :Node2D  # the player CharacterBody2D

var currIx: int = -1

func newRecording(id: int) -> void:
	replays[id] = load("res://scripts/replay.gd").new(node.global_position, 0)
	currIx = id
	reset()

func sample(cloneId: int) -> Dictionary:
	return replays[cloneId].sample(time)

func reset() -> void:
	for replay in replays:
		if replay != null:
			replay.reset()

func _process(_delta: float) -> void:
	if not recording or currIx == -1:
		return
	replays[currIx].record(
		node.global_position,
		time,
		node.facing,
		node.is_sliding,
		node.is_wall_sliding,
		node.velocity.y,
		node.has_double_jump
	)
