extends CanvasLayer

@onready var cloning = get_tree().root.find_child("PlayerCloning", true, false)

func _ready() -> void:
	$Label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	$Label.position.y = 10

func _process(_delta: float) -> void:
	var remaining = cloning.timeLimit - cloning.timeElapsed
	$Label.text = "%.2f" % remaining
