extends CharacterBody2D



@export var jumpHeight: float = 55
@export var timeToJumpApex: float = 0.4
var accelerationTimeAirborne : float = 0.2
var accelerationTimeGrounded : float = 0.1
var moveSpeed: float = 100

var gravity: float
var jumpVelocity: float
var localVelocity: Vector2 = Vector2.ZERO
var velocityXSmoothing: float

@onready var controller: Controller2D  

func _ready():
	controller = $CollisionShape2D as Controller2D
	if not controller:
		return
	gravity = -(2 * jumpHeight)/pow(timeToJumpApex,2)
	jumpVelocity = abs(gravity) * timeToJumpApex
	print("Gravity: " + str(gravity) + " Jump Velocity:" + str(jumpVelocity))
	
func _process(delta: float):
	if controller.collisions.above or controller.collisions.below:
		localVelocity.y = 0

	var input = Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
					Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"))
		
	if Input.is_key_pressed(KEY_SPACE) and controller.collisions.below:
		print("jump")
		localVelocity.y = -jumpVelocity
		
	var targetVelocity: float = input.x * moveSpeed 
	var result: Array = smooth_damp(localVelocity.x, targetVelocity, velocityXSmoothing, accelerationTimeGrounded if controller.collisions.below else accelerationTimeAirborne)
	velocityXSmoothing = result[1]
	localVelocity.x = result[0]
	localVelocity.y -= gravity * delta
	
	controller.move(localVelocity * delta)
	
func smooth_damp(current: float, target: float, current_velocity: float, smooth_time: float, max_speed: float = INF, delta: float = get_process_delta_time()) -> Array:
	smooth_time = max(0.0001, smooth_time)
	var num = 2.0 / smooth_time
	var num2 = num * delta
	var num3 = 1.0 / (1.0 + num2 + 0.48 * num2 * num2 + 0.235 * num2 * num2 * num2)
	var num4 = current - target
	var num5 = target
	var num6 = max_speed * smooth_time
	num4 = clamp(num4, -num6, num6)
	target = current - num4
	var num7 = (current_velocity + num * num4) * delta
	var new_current_velocity = (current_velocity - num * num7) * num3
	var num8 = target + (num4 + num7) * num3

	if (num5 - current > 0.0) == (num8 > num5):
		num8 = num5
		new_current_velocity = (num8 - num5) / delta

	return [num8, new_current_velocity]
	
	
