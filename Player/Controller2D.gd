
extends CollisionShape2D

class_name Controller2D

@export var collisionMask: int = 2

const skinWidth: float = 0.15
@export var horizontalRayCount: int = 4
@export var verticalRayCount: int = 4


var horizontalRaySpacing: float
var verticalRaySpacing: float

var raycastOrigins := RaycastOrigins.new()
var collisions := CollisionInfo.new()

var mat = ShaderMaterial.new()

func _ready():
	var shader = load("res://Player/Ray.gdshader")
	
	mat.shader = shader
	calculate_ray_spacing()




func move(velocity: Vector2) -> void:
	update_raycast_origins()
	collisions.reset()
	if velocity.x != 0:
		velocity = horizontal_collisions(velocity)
	if velocity.y != 0:
		velocity = vertical_collisions(velocity)
	
	get_parent().translate(velocity)

func delete_all_children(node: Node) -> void:
	# Iterate through each child of the node
	for child in node.get_children():
		# Queue the child node for deletion
		child.queue_free()
func horizontal_collisions(velocity: Vector2) -> Vector2:
	delete_all_children(self)
	var directionX: float = sign(velocity.x)
	var rayLength: float = abs(velocity.x) + skinWidth

	for i in range(horizontalRayCount):
		var rayOrigin: Vector2 = raycastOrigins.bottomLeft if directionX == -1  else raycastOrigins.bottomRight
		rayOrigin += Vector2.UP * horizontalRaySpacing * i
		
		# Create a RayCast2D node dynamically for raycasting
		var raycast_node = RayCast2D.new()
		add_child(raycast_node)
		# Configure the raycast

		raycast_node.material = mat
		raycast_node.target_position = Vector2.RIGHT * directionX * rayLength
		raycast_node.position = rayOrigin
		raycast_node.collision_mask = collisionMask

		# Perform the raycast
		raycast_node.force_raycast_update()


		if raycast_node.is_colliding():
			var origin = raycast_node.global_transform.origin
			var collision_point = raycast_node.get_collision_point()
			var distance = origin.distance_to(collision_point)
			velocity.x = (distance - skinWidth) * directionX 
			rayLength = distance
			
			collisions.left = directionX == -1 
			collisions.right = directionX == 1


	return velocity

func vertical_collisions(velocity: Vector2) -> Vector2:
	delete_all_children(self)
	var directionY: float = sign(velocity.y)
	var rayLength: float = abs(velocity.y) + skinWidth

	for i in range(verticalRayCount):
		var rayOrigin: Vector2 = raycastOrigins.bottomLeft if directionY == 1  else raycastOrigins.topLeft
		rayOrigin += Vector2.RIGHT * (verticalRaySpacing * i + velocity.x)
		
		# Create a RayCast2D node dynamically for raycasting
		var raycast_node = RayCast2D.new()
		add_child(raycast_node)
		# Configure the raycast

		raycast_node.material = mat
		raycast_node.target_position = Vector2.DOWN * directionY * rayLength
		raycast_node.position = rayOrigin
		raycast_node.collision_mask = collisionMask

		# Perform the raycast
		raycast_node.force_raycast_update()


		if raycast_node.is_colliding():
			var origin = raycast_node.global_transform.origin
			var collision_point = raycast_node.get_collision_point()
			var distance = origin.distance_to(collision_point)
			velocity.y = (distance - skinWidth) * directionY 
			rayLength = distance
			
			collisions.below = directionY == 1
			collisions.above = directionY == -1


	return velocity

func update_raycast_origins() -> void:
	var bounds: Rect2 = shape.get_rect().grow(skinWidth * -2)

	raycastOrigins.bottomLeft = Vector2(bounds.position.x, bounds.end.y)
	raycastOrigins.bottomRight = Vector2(bounds.end)
	raycastOrigins.topLeft = Vector2(bounds.position)
	raycastOrigins.topRight = Vector2(bounds.end.x, bounds.position.y)
	
func calculate_ray_spacing() -> void:
	var bounds: Rect2 = shape.get_rect().grow(skinWidth * -2)
	
	horizontalRayCount = clamp(horizontalRayCount, 2, INF)
	verticalRayCount = clamp(verticalRayCount, 2, INF)
	
	horizontalRaySpacing = bounds.size.y/ (horizontalRayCount - 1)
	verticalRaySpacing = bounds.size.x / (verticalRayCount - 1)
	
	
class RaycastOrigins:
	var topLeft: Vector2; var topRight: Vector2;
	var bottomLeft: Vector2; var bottomRight: Vector2;

class CollisionInfo:
	var above: bool; var below: bool;
	var left: bool; var right: bool;
	
	func reset() -> void:
		above = false; below = false;
		left = false; right = false;
		
	
