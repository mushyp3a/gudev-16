class_name Replayable extends Node

var replays: Array[Replay] = [null, null, null, null]

var time: float
var recording: bool = false

@export var node: Node2D

var currIx : int = -1
	
func newRecording(id : int) -> void:
	replays[id] = Replay.new(node.global_position, 0)
	time = 0

func getPosition(cloneId : int) -> Vector2:
	return replays[cloneId].getPos(time)
	
func reset() -> void:
	for replay in replays:
		if replay != null:
			replay.reset()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if recording:
		if currIx != -1:
			replays[currIx].record(node.global_position, time)
			time += delta
