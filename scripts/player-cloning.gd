extends Node

@export var replayable: Replayable
@export var posNode : Node2D
@export var timeLimit : float
@export var startPosition : Vector2
var timeElapsed : float = 0
var paused = false
@onready var cloneSpace : Node = get_tree().root
@onready var cloneSprite = load("res://scenes/replay-clone.tscn")

var cloneCount : int = 0

func createClone() -> void:
	var clone = cloneSprite.instantiate()
	var script = clone.get_node("ReplayCloneScript")
	script.cloneId = cloneCount
	script.replayable = replayable
	cloneCount += 1
	replayable.newRecording()
	cloneSpace.add_child(clone)
	replayable.recording = true
	
func timeLoop() -> void:
	replayable.reset()
	createClone()
	posNode.global_position = startPosition
	timeElapsed = 0

func _process(delta: float) -> void:
	if not paused:
		if timeElapsed >= timeLimit:
			timeLoop()
			return
		# TODO - remove this
		if Input.is_action_just_pressed("test_clone"):
			print("Creating a test clone")
			createClone()
		timeElapsed += delta
