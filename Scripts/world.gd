extends Node3D

@onready var map = $Map
@onready var MainMenu = $MenuCanvas/MainMenu
var Player = preload("res://scenes/player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	MainMenu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_button_pressed():
	pass


func _on_button_pressed():
	MainMenu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var instance = Player.instantiate()
	add_child(instance)
