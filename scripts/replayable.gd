class_name Replayable extends Node

var replays: Array[Replay] = [null, null, null, null]

var time: float = 0.0
var recording: bool = false

@export var node: Node2D

var currIx : int = -1

func newRecording(id : int) -> void:
	replays[id] = Replay.new(node.global_position, 0)
	currIx = id
	# Reset ALL replays so existing clones replay from t=0 in sync with the new recording
	reset()

func getPosition(cloneId : int) -> Vector2:
	return replays[cloneId].getPos(time)

func reset() -> void:
	for replay in replays:
		if replay != null:
			replay.reset()

func _process(_delta: float) -> void:
	# Time is driven externally by player-cloning.gd — we only record here
	if recording and currIx != -1:
		replays[currIx].record(node.global_position, time)
