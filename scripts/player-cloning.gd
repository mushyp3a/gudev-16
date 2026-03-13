extends Node

signal recording_ended

var replayable
@export var posNode : Node2D
@export var timeLimit : float
@export var startPosition : Vector2

var timeElapsed : float = 0
var paused = true
var previewing = false
var selectedClone : int = -1
var waitingForInput : bool = false

@onready var cloneSpace : Node = get_tree().root
@onready var cloneSprite = load("res://scenes/replay-clone.tscn")

var cloneNodes : Dictionary = {}

func _ready() -> void:
	replayable = get_parent().get_node("Replayable")
	startPosition = posNode.global_position

# ── Spawn a new ghost and start recording into slot [id] ─────────────────────
func createClone(id : int) -> void:
	if cloneNodes.has(id) and is_instance_valid(cloneNodes[id]):
		cloneNodes[id].queue_free()
		cloneNodes.erase(id)

	replayable.newRecording(id)
	replayable.time = 0
	timeElapsed = 0

	var clone = cloneSprite.instantiate()
	var script = clone.get_node("ReplayCloneScript")
	script.cloneId = id
	script.replayable = replayable
	clone.visible = false
	cloneSpace.add_child(clone)
	cloneNodes[id] = clone

	replayable.recording = true
	waitingForInput = true
	for lever in get_tree().get_nodes_in_group("lever"):
		lever.startRecording(id)

# ── Spawn ghosts for every slot that already has recorded data ────────────────
func spawnExistingClones() -> void:
	for id in range(4):
		if replayable.replays[id] == null:
			continue
		if id == replayable.currIx:
			continue
		if cloneNodes.has(id) and is_instance_valid(cloneNodes[id]):
			continue
		var clone = cloneSprite.instantiate()
		var script = clone.get_node("ReplayCloneScript")
		script.cloneId = id
		script.replayable = replayable
		cloneSpace.add_child(clone)
		cloneNodes[id] = clone

# ── Preview a single clone — all others run invisible in sync ─────────────────
func playSelectedClone(id : int) -> void:
	if replayable.replays[id] == null:
		print("No recording for clone ", id)
		return

	replayable.reset()
	replayable.time = 0
	replayable.recording = false
	timeElapsed = 0
	previewing = true
	paused = false
	waitingForInput = false
	for lever in get_tree().get_nodes_in_group("lever"):
		lever.preparePlayback()

	for other_id in range(4):
		if replayable.replays[other_id] == null:
			continue
		if not (cloneNodes.has(other_id) and is_instance_valid(cloneNodes[other_id])):
			var clone = cloneSprite.instantiate()
			var script = clone.get_node("ReplayCloneScript")
			script.cloneId = other_id
			script.replayable = replayable
			cloneSpace.add_child(clone)
			cloneNodes[other_id] = clone
		cloneNodes[other_id].visible = (other_id == id)

func _play_all_clones() -> void:
	replayable.reset()
	replayable.time = 0
	timeElapsed = 0
	replayable.recording = false
	previewing = true
	paused = false
	waitingForInput = false
	for lever in get_tree().get_nodes_in_group("lever"):
		lever.preparePlayback()
	for id in range(4):
		if replayable.replays[id] == null:
			continue
		if not (cloneNodes.has(id) and is_instance_valid(cloneNodes[id])):
			var clone = cloneSprite.instantiate()
			var script = clone.get_node("ReplayCloneScript")
			script.cloneId = id
			script.replayable = replayable
			cloneSpace.add_child(clone)
			cloneNodes[id] = clone
		cloneNodes[id].visible = true

# ── Full reset: only called at end of a real recording run ───────────────────
func timeLoop() -> void:
	posNode.global_position = startPosition
	replayable.reset()
	timeElapsed = 0
	replayable.time = 0
	paused = true
	previewing = false
	replayable.recording = false
	waitingForInput = false
	ShaderManager.go_to_plan()
	for lever in get_tree().get_nodes_in_group("lever"):
		lever.resetToDefault()
	var justRecorded = replayable.currIx
	if cloneNodes.has(justRecorded) and is_instance_valid(cloneNodes[justRecorded]):
		cloneNodes[justRecorded].visible = true
	recording_ended.emit()

# ── Preview finished: stop clock, leave everything in place ──────────────────
func previewEnd() -> void:
	replayable.reset()
	timeElapsed = 0
	replayable.time = 0
	previewing = false
	paused = true
	waitingForInput = false
	ShaderManager.go_to_plan()
	for lever in get_tree().get_nodes_in_group("lever"):
		lever.resetToDefault()
	recording_ended.emit()

# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_check_clone_select()

	if not paused:
		if waitingForInput:
			if Input.is_action_just_pressed("move_left") or \
			   Input.is_action_just_pressed("move_right") or \
			   Input.is_action_just_pressed("jump") or \
			   Input.is_action_just_pressed("crouch"):
				waitingForInput = false
				ShaderManager.go_to_run()
		else:
			timeElapsed += delta
			replayable.time = timeElapsed

		if timeElapsed >= timeLimit:
			if previewing:
				previewEnd()
			else:
				timeLoop()

func _check_clone_select() -> void:
	if Input.is_action_just_pressed("select_clone_1"):
		selectedClone = 0
	elif Input.is_action_just_pressed("select_clone_2"):
		selectedClone = 1
	elif Input.is_action_just_pressed("select_clone_3"):
		selectedClone = 2
	elif Input.is_action_just_pressed("select_clone_4"):
		selectedClone = 3
	elif Input.is_action_just_pressed("select_all_clones"):
		selectedClone = -2
	else:
		return
	_updateVisibility()

func _updateVisibility() -> void:
	for id in cloneNodes:
		var node = cloneNodes[id]
		if not is_instance_valid(node):
			continue
		if id == replayable.currIx and replayable.recording:
			continue
		if selectedClone == -2 or selectedClone == -1:
			node.visible = true
		else:
			node.visible = (id == selectedClone and replayable.replays[id] != null)

func snapClonesToEnd() -> void:
	for id in cloneNodes:
		var node = cloneNodes[id]
		if not is_instance_valid(node):
			continue
		if replayable.replays[id] == null:
			continue
		var replay = replayable.replays[id]
		if replay.positionHistory.size() > 0:
			node.global_position = replay.positionHistory[-1]
			node.visible = true
