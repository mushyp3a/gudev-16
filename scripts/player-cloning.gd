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
	startPosition = posNode.global_position  # grab it automatically on start
	replayable.reset()

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
	clones[id] = clone
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
	if cloneIxs.has(id):
		showAllClones()
	else:
		showClone(id)
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
