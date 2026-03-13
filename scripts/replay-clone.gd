extends Node

var replayable : Replayable
@onready var posNode : Node2D = get_parent()

var cloneId : int

func setPos() -> void:
	if replayable == null:
		return
	if replayable.replays[cloneId] == null:
		return
	var replay = replayable.replays[cloneId]
	# Need at least 2 recorded frames before we can interpolate
	if replay.positionHistory.size() < 2:
		return
	posNode.global_position = replayable.getPosition(cloneId)

func _ready() -> void:
	setPos()

func _process(_delta: float) -> void:
	setPos()
