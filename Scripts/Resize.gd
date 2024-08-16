extends CharacterBody3D

# Export a variable to control the resize factor
@export var resize_factor: float = 1.2

# Reference to the RayCast3D node
@onready var raycast: RayCast3D = $Camera3D/RayCast3D

func _process(delta: float):
	if Input.is_action_just_pressed("Zoom"):  # Assuming "ui_resize" is mapped to 'C'
		if raycast.is_colliding():
			var target: Node = raycast.get_collider()
			
			if target and target is Node3D:
				resize_object(target)
				
func resize_object(target: Node3D):
	# Apply the resize factor to the object's scale
	target.scale *= resize_factor

	# Optional: Print the new scale for debugging
	print("Resized object: ", target.name, " New scale: ", target.scale)
