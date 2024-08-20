extends Node3D

@onready var map = $Map
@onready var MainMenu = $"MenuCanvas/Main Menu"
@onready var SettingsMenu = $MenuCanvas/SettingsMenu
@onready var music_player = $AudioStreamPlayer  # Reference to AudioStreamPlayer node for music
var Player = preload("res://scenes/player.tscn")
@onready var ambience_player = $AudioStreamPlayer2
@onready var Music2 = $AudioStreamPlayer3

# Called when the node enters the scene tree for the first time.
func _ready():
	MainMenu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Play the background music
	if music_player:
		music_player.play()
	
	if ambience_player:
		ambience_player.stop()
	
	if Music2:
		Music2.stop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_play_button_pressed():
	MainMenu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Stop the background music when the game starts
	if music_player:
		music_player.stop()

	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	var instance = Player.instantiate()
	add_child(instance)
	
	if ambience_player:
		ambience_player.play()
	
	if Music2:
		Music2.play()

func _on_button_pressed():
	pass


func _on_settings_button_pressed():
	SettingsMenu.show()


func _on_back_pressed():
	SettingsMenu.hide()
