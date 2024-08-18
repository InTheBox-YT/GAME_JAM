extends Node3D

@onready var third_person_camera: Camera3D = $ThirdPersonCamera
@onready var first_person_camera: Camera3D = $CamOrigin/FirstPersonCamera

@onready var pivot: Node3D = $CamOrigin
@onready var raycast: RayCast3D = $CamOrigin/FirstPersonCamera/RayCast3D
@onready var magnifying_glass: Node3D = $CamOrigin/FirstPersonCamera/Magnifying_Glass
@onready var arm: MeshInstance3D = $CamOrigin/FirstPersonCamera/Arm

# Zoom Variables
var normal_fov = 70.0
var zoomed_fov = 30.0
var zoom_speed = 5.0
var target_fov = normal_fov

var currentCamera

func _ready():
	currentCamera = third_person_camera
	currentCamera.current = true
	currentCamera.fov = normal_fov

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			emit_signal("resize_request", 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			emit_signal("resize_request", -0.1)

		if currentCamera == first_person_camera:
			if raycast.is_colliding():
				var target: Node = raycast.get_collider()
				var target_parent: Node = target.get_parent()
				if target is Node3D and target_parent != get_node("/root/World/Map/UnsizeableObjects"):
					emit_signal("set_target_scale", target)

func _process(delta):
	# Smooth camera follow and update based on the player's orientation
	if currentCamera == first_person_camera:
		first_person_camera.current = true
		third_person_camera.current = false
		
		magnifying_glass.visible = true
		arm.visible = true
	else:
		third_person_camera.current = true
		first_person_camera.current = false
		
		magnifying_glass.visible = false
		arm.visible = false

	if Input.is_action_pressed("Zoom"):
		currentCamera = first_person_camera
	else:
		currentCamera = third_person_camera
