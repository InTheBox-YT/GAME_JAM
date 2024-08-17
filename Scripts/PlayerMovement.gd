extends CharacterBody3D

@onready var camera: Camera3D = $CamOrigin/Camera3D
@onready var pivot: Node3D = $CamOrigin
@onready var raycast: RayCast3D = $CamOrigin/RayCast3D

# Speed Variables
const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const CROUCH_SPEED := 2.0
var curspeed = WALK_SPEED

const STAMINA_MAX := 10.0
var STAMINA = STAMINA_MAX

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

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	camera.fov = normal_fov

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * 0.5))
		pivot.rotate_x(deg_to_rad(-event.relative.y * 0.5))
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-40), deg_to_rad(40))

func _input(event):
	if event is InputEventMouseButton:
		if Input.is_action_pressed("Zoom"):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				resize_factor = 0.1
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				resize_factor = -0.1
				
			# Handle resizing if the raycast is colliding
			if raycast.is_colliding():
				var target: Node = raycast.get_collider()
				if target is Node3D:
					# Set the target scale for the object
					set_target_scale(target)


func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_pressed("Run") and is_on_floor():
		STAMINA -= delta
		if STAMINA >= 0:
			curspeed = RUN_SPEED
		else:
			curspeed = WALK_SPEED
	else:
		if STAMINA <= STAMINA_MAX:
			STAMINA += delta
		curspeed = WALK_SPEED
	
	var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * curspeed
		velocity.z = direction.z * curspeed
	else:
		velocity.x = move_toward(velocity.x, 0, curspeed)
		velocity.z = move_toward(velocity.z, 0, curspeed)

	move_and_slide()

	if Input.is_action_pressed("Zoom"):
		target_fov = zoomed_fov	
	else:
		target_fov = normal_fov

	camera.fov = lerp(camera.fov, target_fov, zoom_speed * delta)

	# Smoothly scale the target object
	if current_target:
		current_target.scale = current_target.scale.lerp(target_scale, resize_speed * delta)

func set_target_scale(target: Node3D):
	# Calculate new target scale
	target_scale = target.scale + Vector3(resize_factor, resize_factor, resize_factor)
	
	# Clamp the new target scale within the min and max bounds
	target_scale.x = clamp(target_scale.x, resize_min, resize_max)
	target_scale.y = clamp(target_scale.y, resize_min, resize_max)
	target_scale.z = clamp(target_scale.z, resize_min, resize_max)
	
	current_target = target
	print("Resizing object: ", target.name, " Target scale: ", target_scale)
