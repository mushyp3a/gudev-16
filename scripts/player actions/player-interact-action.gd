class_name PlayerInteractAction extends Action

# Add logic here to make clone interact with levels or what have you

var action : Action

func _init(action : Action):
	self.action = action


func act() -> bool:
	# Return it - I don't even care that this is pointless
	return self.action.act()
