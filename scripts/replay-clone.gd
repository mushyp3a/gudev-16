extends Node

var replayable : Replayable
@onready var posNode : Node2D = get_parent()

var cloneId : int

func setPos():
	posNode.global_position = replayable.getPosition(cloneId)

func _ready() -> void:
	setPos()
	
func _process(delta: float) -> void:
	setPos()
