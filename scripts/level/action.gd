class_name Action extends Node

# Returns whether or not this action has "passed"
# Used in action groups to determine if the group's action should occur
# This is a default implementation and should always be overriden
func act() -> bool:
	return false
