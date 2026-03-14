extends CanvasLayer

## Displays the remaining time during recording/playback
## Automatically finds CloneManager in the scene tree

## Reference to CloneManager (found dynamically)
var clone_manager: CloneManager = null

func _ready() -> void:
	# Find CloneManager in scene tree
	_find_clone_manager()

	if clone_manager == null:
		push_error("TimerUpdater: CloneManager not found in scene tree!")
		return

	# Position label at top center
	$Label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	$Label.position.y = 10

## Find the CloneManager node in the scene tree
func _find_clone_manager() -> void:
	# First try to find it as a direct child of root
	var root = get_tree().root
	clone_manager = root.get_node_or_null("CloneManager")

	# If not found, search recursively
	if clone_manager == null:
		clone_manager = root.find_child("CloneManager", true, false)

	if clone_manager == null:
		push_warning("TimerUpdater: Could not find CloneManager node")

func _process(_delta: float) -> void:
	if clone_manager == null or clone_manager.config == null:
		return

	# Calculate remaining time
	var remaining = clone_manager.config.time_limit - clone_manager.time_elapsed

	# Update label text
	$Label.text = "%.2f" % remaining
