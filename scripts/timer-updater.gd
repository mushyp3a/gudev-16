extends CanvasLayer

var clone_manager: CloneManager = null

func _ready() -> void:
	var root = get_tree().root
	clone_manager = root.get_node_or_null("CloneManager")
	if clone_manager == null:
		clone_manager = root.find_child("CloneManager", true, false)

	if clone_manager == null:
		push_error("TimerUpdater: CloneManager not found")
		return

	$Label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	$Label.position.y = 10

func _process(_delta: float) -> void:
	if clone_manager == null or clone_manager.config == null:
		return

	var remaining = clone_manager.config.time_limit - clone_manager.time_elapsed
	$Label.text = "%.2f" % remaining
