extends Node

var replayable
@export var posNode : Node2D
@export var timeLimit : float
@export var startPosition : Vector2

var timeElapsed : float = 0
var paused = true
var previewing = false  # O-key playback: clock runs but no player/world reset on finish
var selectedClone : int = -1

@onready var cloneSpace : Node = get_tree().root
@onready var cloneSprite = load("res://scenes/replay-clone.tscn")

var cloneNodes : Dictionary = {}

func _ready() -> void:
	replayable = get_parent().get_node("Replayable")
	startPosition = posNode.global_position

# ── Spawn a new ghost and start recording into slot [id] ──────────────────────
func createClone(id : int) -> void:
	if cloneNodes.has(id) and is_instance_valid(cloneNodes[id]):
		cloneNodes[id].queue_free()
		cloneNodes.erase(id)

	replayable.newRecording(id)

	var clone = cloneSprite.instantiate()
	var script = clone.get_node("ReplayCloneScript")
	script.cloneId = id
	script.replayable = replayable
	clone.visible = false   # hide while recording; shown when playback starts
	cloneSpace.add_child(clone)
	cloneNodes[id] = clone

	replayable.recording = true

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

# ── O key: preview a clone without touching the player ───────────────────────
func playSelectedClone(id : int) -> void:
	if replayable.replays[id] == null:
		print("No recording for clone ", id)
		return

	if not (cloneNodes.has(id) and is_instance_valid(cloneNodes[id])):
		var clone = cloneSprite.instantiate()
		var script = clone.get_node("ReplayCloneScript")
		script.cloneId = id
		script.replayable = replayable
		cloneSpace.add_child(clone)
		cloneNodes[id] = clone

	replayable.replays[id].reset()
	replayable.time = 0
	replayable.recording = false
	timeElapsed = 0
	previewing = true
	paused = false

# ── Full reset: only called at end of a real recording run ───────────────────
func timeLoop() -> void:
	posNode.global_position = startPosition
	replayable.reset()
	timeElapsed = 0
	paused = true
	previewing = false
	replayable.recording = false
	# Reveal the clone we just finished recording
	var justRecorded = replayable.currIx
	if cloneNodes.has(justRecorded) and is_instance_valid(cloneNodes[justRecorded]):
		cloneNodes[justRecorded].visible = true

# ── Preview finished: just stop the clock, leave everything in place ─────────
func previewEnd() -> void:
	replayable.reset()
	timeElapsed = 0
	previewing = false
	paused = true

# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_check_clone_select()

	if paused:
		# P  →  start recording the selected clone
		if Input.is_action_just_pressed("record_clone") and selectedClone != -1:
			createClone(selectedClone)
			spawnExistingClones()
			replayable.time = 0
			timeElapsed = 0
			previewing = false
			paused = false

		# O  →  preview selected clone (no player reset)
		if Input.is_action_just_pressed("play_clone") and selectedClone != -1:
			playSelectedClone(selectedClone)
	else:
		timeElapsed += delta
		replayable.time = timeElapsed

		if timeElapsed >= timeLimit:
			if previewing:
				previewEnd()   # clock done — just stop, don't touch the player
			else:
				timeLoop()     # recording run done — full reset

func _check_clone_select() -> void:
	if Input.is_action_just_pressed("select_clone_1"):
		selectedClone = 0
	elif Input.is_action_just_pressed("select_clone_2"):
		selectedClone = 1
	elif Input.is_action_just_pressed("select_clone_3"):
		selectedClone = 2
	elif Input.is_action_just_pressed("select_clone_4"):
		selectedClone = 3
