extends CharacterBody3D

@onready var camera: Camera3D = $CamOrigin/Camera3D
@onready var raycast: RayCast3D = $CamOrigin/Camera3D/RayCast3D

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

# Camera Bobbing Variables
var bobbing_speed = 6.0
var bobbing_amount = 0.1
var bobbing_timer = 0.0

func _ready():
	# Set the camera's initial field of view
	camera.current = true
	camera.fov = normal_fov

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			resize_factor = 0.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			resize_factor = -0.1
				
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

	# Apply some control in the air
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * curspeed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * curspeed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	move_and_slide()

	# Camera zoom
	if Input.is_action_pressed("Zoom"):
		target_fov = zoomed_fov	
	else:
		target_fov = normal_fov

	camera.fov = lerp(camera.fov, target_fov, zoom_speed * delta)

	# Smoothly scale the target object
	if current_target:
		current_target.scale = current_target.scale.lerp(target_scale, resize_speed * delta)

	# Camera bobbing effect
	if is_on_floor() and direction:
		bobbing_timer += bobbing_speed * delta
		camera.transform.origin.y = sin(bobbing_timer) * bobbing_amount
	else:
		camera.transform.origin.y = move_toward(camera.transform.origin.y, 0, 10 * delta)

func set_target_scale(target: Node3D):
	# Calculate new target scale
	target_scale = target.scale + Vector3(resize_factor, resize_factor, resize_factor)
	
	# Clamp the new target scale within the min and max bounds manually
	target_scale.x = clamp(target_scale.x, resize_min, resize_max)
	target_scale.y = clamp(target_scale.y, resize_min, resize_max)
	target_scale.z = clamp(target_scale.z, resize_min, resize_max)
	
	current_target = target
	print("Resizing object: ", target.name, " Target scale: ", target_scale)
