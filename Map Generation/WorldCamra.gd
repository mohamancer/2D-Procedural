extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		zoom += Vector2.ONE
	if Input.is_key_pressed(KEY_W):
		translate(Vector2.UP)
	if Input.is_key_pressed(KEY_S):
		translate(Vector2.DOWN)
	if Input.is_key_pressed(KEY_A):
		translate(Vector2.LEFT)
	if Input.is_key_pressed(KEY_D):
		translate(Vector2.RIGHT)
