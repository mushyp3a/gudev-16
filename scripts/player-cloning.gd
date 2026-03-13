extends Node

@export var replayable: Replayable
@export var posNode : Node2D
@export var timeLimit : float
@export var startPosition : Vector2
var timeElapsed : float = 0
var paused = true
@onready var cloneSpace : Node = get_tree().root
@onready var cloneSprite = load("res://scenes/replay-clone.tscn")

var cloneIxs : Array[int] = [0,1,2,3]
var clones : Array[Node] = [null, null, null, null]

func _ready() -> void:
	startPosition = posNode.global_position  # grab it automatically on start
	replayable.reset()

func createClone(id : int) -> void:
	replayable.newRecording(id)  # push new replay FIRST
	var clone = cloneSprite.instantiate()
	var script = clone.get_node("ReplayCloneScript")
	script.cloneId = id
	script.replayable = replayable
	removeId(id)
	cloneSpace.add_child(clone)
	replayable.recording = true
	
func removeId(id : int):
	for i in len(cloneIxs):
		if cloneIxs[i] == id:
			cloneIxs.remove_at(i)
			break
	
func timeLoop() -> void:
	posNode.global_position = startPosition
	replayable.reset()
	timeElapsed = 0

var selectedClone : int = -1

func unpause() -> void:
	paused = false
	replayable.reset()

func _process(delta: float) -> void:
	if paused:
		if Input.is_key_pressed(KEY_1):
			selectedClone = 0
		elif Input.is_key_pressed(KEY_2):
			selectedClone = 1
		elif Input.is_key_pressed(KEY_3):
			selectedClone = 2
		elif Input.is_key_pressed(KEY_4):
			selectedClone = 3
		
		if Input.is_key_pressed(KEY_P) && selectedClone != -1:
			createClone(selectedClone)
			selectedClone = -1
			unpause()
	else:
		timeElapsed += delta
		replayable.time = timeElapsed
		if timeElapsed >= timeLimit:
			timeLoop()
			paused = true
