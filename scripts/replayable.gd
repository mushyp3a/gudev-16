class_name Replayable extends Node

var replays: Array = [null, null, null, null]

var time: float = 0.0
var recording: bool = false

@export var node :Node2D  # the player CharacterBody2D

var currIx : int = -1
	
func newRecording(id : int) -> void:
	replays[id] = Replay.new(node.global_position, 0, PlayerActions.new([]))
	currIx = id
	reset()

func sample(cloneId: int) -> Dictionary:
	return replays[cloneId].sample(time)

func getPosition(cloneId : int) -> Vector2:
	return replays[cloneId].replayPos(time)
	
func reset() -> void:
	for replay in replays:
		if replay != null:
			replay.reset()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if recording:
		if currIx != -1:
			# TODO - actually code this part fully
			replays[currIx].record(node.global_position, time, PlayerActions.new([]))
