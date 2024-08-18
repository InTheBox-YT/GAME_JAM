extends CharacterBody3D

@onready var third_person_camera: Camera3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/ThirdPersonCamera
@onready var first_person_camera: Camera3D = $CamOrigin/FirstPersonCamera

@onready var pivot: Node3D = $CamOrigin
@onready var raycast: RayCast3D = $CamOrigin/FirstPersonCamera/RayCast3D
@onready var magnifying_glass: Node3D = $CamOrigin/FirstPersonCamera/Magnifying_Glass
@onready var arm: MeshInstance3D = $CamOrigin/FirstPersonCamera/Arm

# Speed Variables
var curspeed = WALK_SPEED
var target_speed = WALK_SPEED
var acceleration = 10.0
const WALK_SPEED := 5.0
const RUN_SPEED := 10.0
const SPRINT_ACCELERATION := 15.0

const JUMP_VELOCITY = 6 
const GRAVITY = 9.8  

# Zoom Variables
var normal_fov = 70.0
var zoomed_fov = 30.0
var zoom_speed = 5.0
var target_fov = normal_fov

# Resizing Variables
@export var resize_max: float = 5.0
@export var resize_min: float = 1
var resize_factor = 2
var resize_speed = 15

var target_scale: Vector3 = Vector3.ONE
var current_target: Node3D = null

var currentCamera

var rotation_speed := 5.0 # Rotation speed in degrees per second
var smooth_rotation_speed := 20.0 # Faster rotation speed for aligning with camera
var current_yaw_rotation: float = 0.0
var target_yaw_rotation: float = 0.0

# Camera friction variables
var camera_friction := 5.0 # Higher value means more friction

func _ready():
	# Set the camera's initial position and rotation
	currentCamera = third_person_camera
	currentCamera.current = true
	currentCamera.fov = normal_fov
	update_camera_position(0)
	
	# Lock the mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Rotate the pivot (character) based on mouse movement
		rotate_y(deg_to_rad(-event.relative.x * 0.1))  # Adjust sensitivity as needed
		pivot.rotate_x(deg_to_rad(-event.relative.y * 0.1))
		if currentCamera == first_person_camera:
			pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		if currentCamera == third_person_camera:
			pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-40), deg_to_rad(40))
			
			# Update the target yaw rotation based on mouse movement
			target_yaw_rotation += -event.relative.x * 0.1

	if Input.is_action_pressed("Interact"):
		DialogueManager.show_example_dialogue_balloon(load("res://dialogue/main.dialogue"), "Test")
		return

func _input(event):	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			resize_factor = 0.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			resize_factor = -0.1

		if currentCamera == first_person_camera:
			if raycast.is_colliding():
				var target: Node = raycast.get_collider()
				var target_parent: Node = target.get_parent()
				if target is Node3D and target_parent != get_node("/root/World/Map/UnsizeableObjects"):
					set_target_scale(target)

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle sprinting with smooth acceleration
	if Input.is_action_pressed("Run") and is_on_floor():
		target_speed = RUN_SPEED
	else:
		target_speed = WALK_SPEED
	
	curspeed = lerp(curspeed, target_speed, SPRINT_ACCELERATION * delta)

	var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if currentCamera == third_person_camera:
		third_person_camera.current = true
		first_person_camera.current = false
		
		magnifying_glass.visible = false
		arm.visible = false
		# Align the player's facing direction with the camera's facing direction
		align_player_with_camera()

	elif currentCamera == first_person_camera:
		third_person_camera.current = false
		first_person_camera.current = true
		
		magnifying_glass.visible = true
		arm.visible = true

	# Apply some control in the air
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * curspeed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * curspeed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	move_and_slide()

	# Smoothly scale the target object
	if current_target:
		current_target.scale = current_target.scale.lerp(target_scale, resize_speed * delta)

	# Update camera position and rotation
	update_camera_position(delta)

func update_camera_position(delta: float):
	if Input.is_action_pressed("Zoom"):
		currentCamera = first_person_camera
	else:
		currentCamera = third_person_camera

	# Smoothly interpolate the camera's yaw rotation towards the target
	current_yaw_rotation = lerp(current_yaw_rotation, target_yaw_rotation, smooth_rotation_speed * delta)
	$CamRoot/CamYaw.rotation.y = deg_to_rad(current_yaw_rotation)

	# Apply friction to slow down the rotation over time
	target_yaw_rotation = lerp_angle(target_yaw_rotation, $CamRoot/CamYaw.rotation.y, camera_friction * delta)

func align_player_with_camera():
	# Get the camera's forward direction in world space
	var camera_forward = third_person_camera.global_transform.basis.z.normalized()
	camera_forward.y = 0 # Remove any vertical component to keep player on the ground

	# Calculate the new rotation for the player based on the camera's forward direction
	var player_rotation = Vector3(0, atan2(camera_forward.x, camera_forward.z), 0)
	rotation.y = lerp_angle(rotation.y, player_rotation.y, smooth_rotation_speed * get_process_delta_time())

func set_target_scale(target: Node3D):
	# Calculate new target scale
	target_scale = target.scale + Vector3(resize_factor, resize_factor, resize_factor)
	
	# Clamp the new target scale within the min and max bounds manually
	target_scale.x = clamp(target_scale.x, resize_min, resize_max)
	target_scale.y = clamp(target_scale.y, resize_min, resize_max)
	target_scale.z = clamp(target_scale.z, resize_min, resize_max)
	
	current_target = target
	print("Resizing object: ", target.name, " Target scale: ", target_scale)
