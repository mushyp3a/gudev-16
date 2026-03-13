class_name PlayerActions

var actions : Array[Action] = []

func _init(actions : Array[Action]) -> void:
	self.actions = actions
	
func actAll() -> void:
	for a in actions:
		a.act()
