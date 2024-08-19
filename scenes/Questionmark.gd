extends Node3D

@export var player: NodePath
@export var sprite: NodePath

var player_node: CharacterBody3D
var sprite_node: Sprite3D

func _ready():
	# Attempt to get the nodes from the scene
	player_node = get_node_or_null(player)
	sprite_node = get_node_or_null(sprite)

	if sprite_node:
		sprite_node.visible = false  # Initially hide the sprite

func _process(delta):
	if not sprite_node or not player_node:
		return  # Exit if nodes are not valid

	if Input.is_action_pressed("Zoom"):  # 'C' key is bound to 'ui_focus_next' by default
		sprite_node.look_at(player_node.global_transform.origin, Vector3.UP)
		sprite_node.visible = true
	else:
		sprite_node.visible = false
