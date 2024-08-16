extends CharacterBody3D

@onready var camera = $Camera3D


# Speed Variables
const WALK_SPEED = 5.0
const RUN_SPEED = 8.0
const CROUCH_SPEED = 2.0
var curspeed = WALK_SPEED

const STAMINA_MAX = 10.0
var STAMINA = STAMINA_MAX

const JUMP_VELOCITY = 6 
const GRAVITY = 9.8  

# Zoom Variables
var normal_fov = 70.0
var zoomed_fov = 30.0
var zoom_speed = 5.0
var target_fov = normal_fov

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	camera.fov = normal_fov

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .002)
		camera.rotate_x(-event.relative.y * .002)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2) 

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("Space") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_pressed("Shift") and is_on_floor():
		STAMINA -= delta
		if STAMINA >= 0:
			curspeed = RUN_SPEED
		else:
			curspeed = WALK_SPEED
	else:
		if STAMINA <= STAMINA_MAX:
			STAMINA += delta
		curspeed = WALK_SPEED

	var input_dir = Input.get_vector("A", "D", "W", "S")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * curspeed
		velocity.z = direction.z * curspeed
	else:
		velocity.x = move_toward(velocity.x, 0, curspeed)
		velocity.z = move_toward(velocity.z, 0, curspeed)

	move_and_slide()

	if Input.is_action_pressed("C"):
		target_fov = zoomed_fov
	else:
		target_fov = normal_fov

	camera.fov = lerp(camera.fov, target_fov, zoom_speed * delta)
