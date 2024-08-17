extends Node3D

@export var detection_radius : float = 10.0
@export var sound : AudioStream = preload("res://Models/OhToALostSoul.mp3")

var audio_player : AudioStreamPlayer3D
var player : Node3D = null

func _ready():
	audio_player = $AudioStreamPlayer3D
	audio_player.stream = sound
	$CollisionShape3D.shape = SphereShape3D.new()  # Make sure to set the collision shape if needed

func _on_VisibilityNotifier3D_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		play_sound()

func _on_VisibilityNotifier3D_body_exited(body: Node3D) -> void:
	if body == player:
		player = null

func play_sound() -> void:
	if audio_player:
		audio_player.play()
