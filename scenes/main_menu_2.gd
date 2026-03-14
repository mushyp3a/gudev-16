extends Control 

@onready var background = $background
@onready var scene = $"/root/Diamond"
@onready var transition = $Diamond

var levels_completed:int = 0 
var textures = [ 
	preload("res://ui designs/Cyberpunk_background_intro.png"), 
	preload("res://ui designs/Cyberpunk_background_1.png"), 
	preload("res://ui designs/Cyberpunk_background_2.png"), 
	preload("res://ui designs/Cyberpunk_background_3.png"), 
	preload("res://ui designs/Cyberpunk_background_4.png") 
	] 

# Called when the node enters the scene tree for the first time. 
func _ready() -> void: 
	print(global.levels_completed)
	var index = clamp(global.levels_completed, 0, textures.size() - 1) 
	background.texture = textures[index] 
	
# Called every frame. 'delta' is the elapsed time since the previous frame. 
func _process(delta: float) -> void: 
	pass 

func _on_start_button_pressed() -> void: 
	transition.change_scene("res://scenes/intro.tscn")
	#idk whats going on
	#the below line is a function in diamond.gd (for some reason it half works)
	#Diamond.change_scene("res://scenes/level selection.tscn") 
	
func _on_quit_pressed() -> void: 
	get_tree().quit() 

func _on_lore_pressed() -> void: 
	transition.change_scene("res://scenes/lore.tscn")

func _on_credits_pressed() -> void: 
	transition.change_scene("res://scenes/credits.tscn")
