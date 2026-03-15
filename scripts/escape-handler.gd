extends Node

const MAIN_MENU_SCENE := "res://scenes/main_menu2.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/level_selection.tscn"
const CORE_DESTRUCTION_SCENE := "res://scenes/levels/level-beat.tscn"

const IN_GAME_SCENES := [
	"res://scenes/platformer-scene.tscn",
	"res://scenes/levels/level-1.tscn",
	"res://scenes/levels/level-2.tscn",
	"res://scenes/levels/level-3.tscn",
	"res://scenes/levels/level-4.tscn"
]

const ESCAPE_DISABLED_SCENES := [
	CORE_DESTRUCTION_SCENE
]

var diamond: CanvasLayer = null

func _ready() -> void:
	diamond = get_tree().root.find_child("Diamond", true, false)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_handle_escape()

func _handle_escape() -> void:
	var current_scene := get_tree().current_scene
	if not current_scene:
		return

	var scene_path := current_scene.scene_file_path

	if scene_path in ESCAPE_DISABLED_SCENES:
		return

	if scene_path in IN_GAME_SCENES:
		_change_scene(LEVEL_SELECT_SCENE)
		return

	if scene_path == MAIN_MENU_SCENE:
		return

	_change_scene(MAIN_MENU_SCENE)

func _change_scene(target_scene: String) -> void:
	if not diamond:
		diamond = get_tree().root.find_child("Diamond", true, false)

	if diamond:
		diamond.change_scene(target_scene)
	else:
		get_tree().change_scene_to_file(target_scene)
