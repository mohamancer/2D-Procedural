extends Camera2D

var follow_speed: float = 400.0
var damping: float = 0.1


func _process(delta):
	handle_input(delta)
	# Ensure the camera stays within the bounds of the scene
	clamp_to_screen()

func handle_input(delta):
	# Handle input to move the camera with the keyboard
	var input_vector = Vector2()

	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1

	# Normalize the input vector to ensure consistent movement speed in all directions
	input_vector = input_vector.normalized()

	# Move the camera based on input and delta time
	position += input_vector * follow_speed * delta

# Optional: Function to clamp the camera within the bounds of the scene
func clamp_to_screen() -> void:
	var viewport_size = get_viewport_rect().size
	var half_width = viewport_size.x / 2
	var half_height = viewport_size.y / 2

	position.x = clamp(position.x, -half_width, half_width)
	position.y = clamp(position.y, -half_height, half_height)
