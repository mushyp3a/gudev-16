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

func _ready() -> void:
	startPosition = posNode.global_position  # grab it automatically on start

func createClone() -> void:
	replayable.newRecording()  # push new replay FIRST
	var clone = cloneSprite.instantiate()
	var script = clone.get_node("ReplayCloneScript")
	script.cloneId = cloneCount
	script.replayable = replayable
	cloneCount += 1
	cloneSpace.add_child(clone)
	replayable.recording = true
	
func timeLoop() -> void:
	createClone()
	posNode.global_position = startPosition
	replayable.reset()
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
