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
	clones[id] = clone
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
	
func replayClone(id : int) -> void:
	showClone(id)
	unpause()
	replayable.time = 0
	
func showClone(id : int) -> void:
	for i in len(clones):
		if clones[i] == null:
			continue
		if i == id:
			clones[i].set_visible(true)
		else:
			clones[i].set_visible(false)
	
func showAllClones() -> void:
	for i in len(clones):
		if clones[i] == null:
			continue
		clones[i].set_visible(true)

func selectClone(id : int) -> void:
	if selectedClone == id:
		showAllClones()
	selectedClone = id

func _process(delta: float) -> void:
	if paused:
		if Input.is_key_pressed(KEY_1):
			selectClone(0)
		elif Input.is_key_pressed(KEY_2):
			selectClone(1)
		elif Input.is_key_pressed(KEY_3):
			selectClone(2)
		elif Input.is_key_pressed(KEY_4):
			selectClone(3)
		
		if Input.is_key_pressed(KEY_P) && selectedClone != -1:
			if cloneIxs.has(selectedClone):
				showAllClones()
				createClone(selectedClone)
				selectedClone = -1
				unpause()
			else:
				replayClone(selectedClone)
	else:
		timeElapsed += delta
		replayable.time = timeElapsed
		if timeElapsed >= timeLimit:
			timeLoop()
			paused = true
