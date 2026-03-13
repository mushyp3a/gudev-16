extends Node

@export var replayable: Replayable
@export var posNode : Node2D
@export var timeLimit : float
@export var startPosition : Vector2
var timeElapsed : float = 0
var paused = true
var waitingForInput: bool = false
var recording: bool = false
var previewing: bool = false

@onready var cloneSpace : Node = get_tree().root
@onready var cloneSprite = load("res://scenes/replay-clone.tscn")

var cloneIxs : Array[int] = [0,1,2,3]
var clones : Array[Node] = [null, null, null, null]

func _ready() -> void:
	startPosition = posNode.global_position
	replayable.reset()

func createClone(id : int) -> void:
	replayable.newRecording(id)
	var clone = cloneSprite.instantiate()
	clone.cloneId    = id
	clone.replayable = replayable
	var script = clone.get_node("ReplayCloneScript")
	script.cloneId    = id
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
	waitingForInput = true
	recording = true
	previewing = false
	replayable.reset()
	replayable.time = 0

func replayClone(id : int) -> void:
	showClone(id)
	paused = false
	waitingForInput = false
	recording = false
	previewing = true
	replayable.reset()
	replayable.time = 0
	timeElapsed = 0

func showClone(id : int) -> void:
	for i in len(clones):
		if clones[i] == null:
			continue
		clones[i].set_visible(i == id)

func showAllClones() -> void:
	for i in len(clones):
		if clones[i] == null:
			continue
		clones[i].set_visible(true)

func selectClone(id : int) -> void:
	if cloneIxs.has(id):
		showAllClones()
	else:
		showClone(id)
	selectedClone = id

func snapClonesFirst() -> void:
	for i in range(4):
		if clones[i] == null or replayable.replays[i] == null:
			continue
		var history = replayable.replays[i].positionHistory
		if history.size() > 0:
			clones[i].global_position = history[0]

func snapClonesToFinalPositions() -> void:
	var count = min(clones.size(), replayable.replays.size())
	for i in range(count):
		var clone = clones[i]
		var replay = replayable.replays[i]
		if clone == null or replay == null:
			continue

		# Snap position
		if replay.positionHistory.size() > 0:
			clone.global_position = replay.positionHistory[-1]

		# Snap facing / skeleton scale
		if replay.facingHistory.size() > 0:
			if clone.has_node("Skeleton2D"):
				var skeleton = clone.get_node("Skeleton2D") as Node2D
				skeleton.scale.x = abs(skeleton.scale.x) * replay.facingHistory[-1]

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
		elif Input.is_key_pressed(KEY_0):
			selectClone(3)

		if Input.is_key_pressed(KEY_P) && selectedClone != -1:
			showAllClones()
			createClone(selectedClone)
			selectedClone = -1
			unpause()

		if Input.is_key_pressed(KEY_O):
			replayClone(selectedClone)
	else:
		if waitingForInput:
			var moved = Input.get_axis("move_left", "move_right") != 0 \
				or Input.is_action_just_pressed("jump")
			if moved:
				waitingForInput = false
			return

		timeElapsed += delta
		replayable.time = timeElapsed
		if timeElapsed >= timeLimit:
			if previewing:
				snapClonesToFinalPositions()
				paused = true
				recording = false
				previewing = false
			else:
				timeLoop()
				paused = true
				recording = false
				previewing = false
