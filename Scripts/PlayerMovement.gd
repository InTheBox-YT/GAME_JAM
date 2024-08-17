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
@export var resize_max: float = 10.0
var resize_factor = 1.0

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
				if resize_factor <= resize_max:
					resize_factor += 0.1
						
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if resize_factor >= 1:
					resize_factor -= 0.1
					
		if raycast.is_colliding():
			var target: Node = raycast.get_collider()
			if target is Node3D:
				resize_object(target)

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

func resize_object(target: Node3D):
	target.scale.x = resize_factor
	target.scale.y = resize_factor
	target.scale.z = resize_factor
	print("Resized object: ", target.name, " New scale: ", target.scale)
