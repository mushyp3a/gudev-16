class_name PressureButtonAction extends Action

@export var buttonPressHandler : ButtonPressHandler

func act() -> bool:
	return buttonPressHandler.isPressed
