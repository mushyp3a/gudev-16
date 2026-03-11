class_name ActionGroup extends Node

@export var actionNodes : Array[Action]

# Override this
func act():
	pass

func isValid() -> bool:
	for actionNode in actionNodes:
		if not actionNode.act():
			return false
	return true

func _process(delta : float) -> void:
	if isValid():
		act()
