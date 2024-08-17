extends Camera3D

@export var follow_target: CharacterBody3D  # The player or target the camera follows
@export var follow_distance: float = 10.0
@export var follow_height: float = 5.0
@export var follow_speed: float = 5.0
@export var min_distance: float = 5.0
@export var max_distance: float = 15.0

# Camera Collision Variables
@export var collision_radius: float = 0.5
@export var collision_margin: float = 0.1
var camera_offset: Vector3 = Vector3(0, 1, -5)  # Adjust as needed

# Mouse Control Variables
@export var rotation_sensitivity: float = 0.5
var current_rotation: Vector2 = Vector2.ZERO

@onready var raycast: RayCast3D = $ColideCast

func _ready():
	# Initialize the raycast
	if raycast == null:
		print("RayCast3D node is not found or initialized.")
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float):
	if not follow_target:
		return

	handle_camera_movement(delta)
	handle_mouse_input(delta)

func handle_camera_movement(delta: float):
	if follow_target == null:
		return
	
	# Calculate desired camera position
	var target_position = follow_target.global_transform.origin
	var desired_position = target_position - follow_target.global_transform.basis.z * follow_distance + Vector3(0, follow_height, 0)
	
	# Use a raycast to prevent clipping
	raycast.origin = target_position
	raycast.cast_to = desired_position - target_position
	raycast.enabled = true
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		desired_position = raycast.get_collision_point()
	
	# Smoothly update the camera position
	global_transform.origin = global_transform.origin.lerp(desired_position, follow_speed * delta)

func handle_mouse_input(delta: float):
	var mouse_delta = Input.get_last_mouse_velocity() * rotation_sensitivity * delta
	current_rotation += Vector2(mouse_delta.x, mouse_delta.y)
	
	# Clamp vertical rotation to prevent flipping
	current_rotation.y = clamp(current_rotation.y, -89, 89)
	
	# Apply rotation to the camera
	var rotation_amount = Vector3(current_rotation.y, current_rotation.x, 0)
	global_transform.basis = Basis().rotated(Vector3.UP, deg_to_rad(rotation_amount.x)).rotated(Vector3.RIGHT, deg_to_rad(rotation_amount.y))
	
	# Recalculate camera position after rotation
	handle_camera_movement(delta)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			follow_distance = max(follow_distance - 1.0, min_distance)  # Adjust distance with zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			follow_distance = min(follow_distance + 1.0, max_distance)  # Adjust distance with zoom
