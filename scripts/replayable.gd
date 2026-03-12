class_name Replayable extends Node

var replays: Array[Replay]

var time: float
var recording: bool

@export var node: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start with no replays
	replays = []
	# Start "recording"
	newRecording()
	recording = true
	
func newRecording() -> void:
	replays.push_back(Replay.new(node.global_position, 0))
	time = 0

func getPosition(cloneId : int) -> Vector2:
	return replays[cloneId].getPos(time)
	
func reset() -> void:
	for replay in replays:
		replay.reset()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if recording:
		replays[-1].record(node.global_position, time)
		time += delta
