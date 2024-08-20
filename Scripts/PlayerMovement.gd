extends CharacterBody3D

@onready var third_person_camera: Camera3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/ThirdPersonCamera
@onready var first_person_camera: Camera3D = $CamRoot/CamYaw/CamPitch/FirstPersonCamera

@onready var pivot: Node3D = $CamOrigin
@onready var raycast: RayCast3D = $CamRoot/CamYaw/CamPitch/FirstPersonCamera/RayCast3D
@onready var magnifying_glass: Node3D = $CamRoot/CamYaw/CamPitch/FirstPersonCamera/magnifying_glass
@onready var arm: MeshInstance3D = $CamRoot/CamYaw/CamPitch/FirstPersonCamera/Arm
@onready var actionable_finder: Area3D = $Model/ActionableFinder
@onready var interactable_finder: Area3D = $Model/InteractableFinder


# Speed Variables
var direction
var curspeed = WALK_SPEED
var target_speed = WALK_SPEED
var acceleration = 120
const WALK_SPEED := 5.0
const RUN_SPEED := 7.0
const SPRINT_ACCELERATION := 15.0

const JUMP_VELOCITY = 5
const GRAVITY = 9.8 

# Zoom Variables
var normal_fov = 70.0
var zoomed_fov = 30.0
var zoom_speed = 5.0
var target_fov = normal_fov

# Resizing Variables
@export var resize_max: float = 5.0
@export var resize_min: float = 0.1
var resize_factor = 2.5
var resize_speed = 15

var target_scale: Vector3 = Vector3.ONE
var current_target: Node3D = null

var currentCamera
var cam_rotation : float = 0
var direct : Vector3

var rotation_speed := 5.0 # Rotation speed in degrees per second
var dialogueAvaliable = true

func _ready():
	# Set the camera's initial position and rotation
	currentCamera = third_person_camera
	currentCamera.current = true
	currentCamera.fov = normal_fov
	
	# Check Dialogue Ended
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _input(event):	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			resize_factor = 0.1
			checkForObjects()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			resize_factor = -0.1
			checkForObjects()
					
	if Input.is_action_just_pressed("Interact") and dialogueAvaliable == true:
		var actionables = actionable_finder.get_overlapping_areas()
		var interactables = interactable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			actionables[0].action()
			dialogueAvaliable = false
			return
		elif interactables.size() > 0:
			interactables[0].action()
			return
		
func _physics_process(delta: float):
	if dialogueAvaliable == true:
		
		if Input.is_action_pressed("Reset Character"):
			self.global_position = Vector3(0,0,0)
			
		

		if Input.is_action_just_pressed("Jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Handle sprinting with smooth acceleration
		if Input.is_action_pressed("Run") and is_on_floor():
			target_speed = RUN_SPEED
		else:
			target_speed = WALK_SPEED
		
		curspeed = lerp(curspeed, target_speed, SPRINT_ACCELERATION * delta)
		
		var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
		direction = ($CamRoot/CamYaw.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		# Disable movement if 'Interact' or 'Zoom' is pressed and the player is not in third-person mode
		if (Input.is_action_pressed("Interact") and currentCamera != third_person_camera) or Input.is_action_pressed("Zoom"):
			curspeed = 0.0
		else:
			# Allow movement in third-person mode
			if input_dir != Vector2(0, 0):
				$Model.rotation.y = lerp_angle($Model.rotation.y, atan2(-direction.x, -direction.z), delta * 7)
		
		if Input.is_action_pressed("Zoom"):
			currentCamera = first_person_camera
		else:
			currentCamera = third_person_camera
	else:
		curspeed = 0.0
		currentCamera = third_person_camera
		
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		
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
	
	if currentCamera == third_person_camera:
		third_person_camera.current = true
		first_person_camera.current = false
		
		magnifying_glass.visible = false
		arm.visible = false
		$Model.visible = true
		
	elif currentCamera == first_person_camera:
		third_person_camera.current = false
		first_person_camera.current = true
		
		magnifying_glass.visible = true
		arm.visible = true
		$Model.visible = false

func set_target_scale(target: Node3D):
	# Calculate new target scale
	target_scale = target.scale + Vector3(resize_factor, resize_factor, resize_factor)
	
	# Clamp the new target scale within the min and max bounds manually
	target_scale.x = clamp(target_scale.x, resize_min, resize_max)
	target_scale.y = clamp(target_scale.y, resize_min, resize_max)
	target_scale.z = clamp(target_scale.z, resize_min, resize_max)
	
	current_target = target
	print("Resizing object: ", target.name, " Target scale: ", target_scale)
	
func _on_dialogue_ended(_resource: DialogueResource):
	dialogueAvaliable = true

func checkForObjects():
	if currentCamera == first_person_camera:
				if raycast.is_colliding():
					var target: Node = raycast.get_collider()
					var target_parent: Node = target.get_parent()
					if target is Node3D and target_parent != get_node("/root/World/Map/UnsizeableObjects"):
						set_target_scale(target)
