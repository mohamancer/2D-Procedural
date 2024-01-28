extends Node2D

var squareGrid: SquareGrid
var vertices: PackedVector3Array
var triangles : PackedInt32Array
# dict<int, Array(Triangle)>
var triangleDictionary: Dictionary = {}
var outlines: Array[Array] 
var checkedVertices: Dictionary = {}

func generate_mesh(map: Array, squareSize: float) -> void:
	outlines.clear()
	checkedVertices.clear()
	triangleDictionary.clear()
	if $"../Walls".get_children().size() > 0:
		for child in $"../Walls".get_children():
			child.queue_free()
	squareGrid = SquareGrid.new(map, squareSize)
	vertices = []
	triangles = []
	
	for x in range(squareGrid.squares.size()):
		for y in range(squareGrid.squares[0].size()):
			triangulate_square(squareGrid.squares[x][y])
	create_map_mesh(map, squareSize)
	
	create_wall_mesh()
	
func create_map_mesh(map: Array, squareSize: float) -> void:
		# Create a new Mesh instance
	var arr_mesh = ArrayMesh.new()
	var uvs = PackedVector2Array()
	uvs.resize(vertices.size())
	
	for i in range(vertices.size()):
		var percentX: float = inverse_lerp(-map.size()/2.0 * squareSize, map.size()/2.0 * squareSize, vertices[i].x)
		var percentY: float = inverse_lerp(-map.size()/2.0 * squareSize, map.size()/2.0 * squareSize, vertices[i].z)
		uvs[i] = Vector2(percentX, percentY) 
		
	# Set the vertices, uvs, and triangles of the mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array(Array(vertices).map(func(pos3: Vector3): return Vector2(pos3.x, pos3.z)))
	arrays[Mesh.ARRAY_INDEX] = triangles
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Update the mesh in the MeshInstance
	$"../OuterMesh".mesh = arr_mesh


func create_wall_mesh() -> void:
	calculate_mesh_outlines()
	var wallVertices: Array[PackedVector3Array] = []

	for i in range(outlines.size()):
		wallVertices.append(PackedVector3Array())
		for j in range(outlines[i].size()):
			wallVertices[i].append(vertices[outlines[i][j]])

	for outline in wallVertices:
		var packed := PackedVector2Array(Array(outline).\
									map(func(pos3: Vector3): return Vector2(pos3.x, pos3.z)))

		
		for k in range(outline.size() - 1):
			var collisionShape = CollisionShape2D.new()
			var shape = RectangleShape2D.new()

			#shape.a = packed[k + 1] 
			#shape.b = packed[k]
			#collisionShape.shape = shape
			var direction = packed[k+1] - packed[k]
			shape.size = Vector2(packed[k+1].distance_to(packed[k]), 0)
			collisionShape.position = packed[k+1] - direction/2
			collisionShape.shape = shape
			collisionShape.rotation = (packed[k+1]-packed[k]).angle()
			$"../Walls".add_child(collisionShape)


	
	
	
	
	
	
	


	
	
func triangulate_square(square: Square) -> void:
	match square.configuration:
	# 1 point:
		1:
			mesh_from_points([square.centerLeft, square.centerBottom, square.bottomLeft])
		2:
			mesh_from_points([square.bottomRight, square.centerBottom, square.centerRight])
		4:
			mesh_from_points([square.topRight, square.centerRight, square.centerTop])
		8:
			mesh_from_points([square.topLeft, square.centerTop, square.centerLeft])
	# 2 points
		3:
			mesh_from_points([square.centerRight, square.bottomRight, square.bottomLeft, square.centerLeft])
		6:
			mesh_from_points([square.centerTop, square.topRight, square.bottomRight, square.centerBottom])
		9:
			mesh_from_points([square.topLeft, square.centerTop, square.centerBottom, square.bottomLeft])
		12:
			mesh_from_points([square.topLeft, square.topRight, square.centerRight, square.centerLeft])
		5:
			mesh_from_points([square.centerTop, square.topRight, square.centerRight, square.centerBottom, square.bottomLeft, square.centerLeft])
		10:
			mesh_from_points([square.topLeft, square.centerTop, square.centerRight, square.bottomRight, square.centerBottom, square.centerLeft])
	# 3 points:
		7:
			mesh_from_points([square.centerTop, square.topRight, square.bottomRight, square.bottomLeft, square.centerLeft])
		11:
			mesh_from_points([square.topLeft, square.centerTop, square.centerRight, square.bottomRight, square.bottomLeft])
		13:
			mesh_from_points([square.topLeft, square.topRight, square.centerRight, square.centerBottom, square.bottomLeft])
		14:
			mesh_from_points([square.topLeft, square.topRight, square.bottomRight, square.centerBottom, square.centerLeft])
	# 4 points
		15:
			mesh_from_points([square.topLeft, square.topRight, square.bottomRight, square.bottomLeft])
			checkedVertices[square.topLeft.vertexIndex] = null
			checkedVertices[square.topRight.vertexIndex] = null
			checkedVertices[square.bottomRight.vertexIndex]  = null
			checkedVertices[square.bottomLeft.vertexIndex]  = null

# points is an array of CustomNode 
func mesh_from_points(points: Array[CustomNode]) -> void:
	assign_vertices(points)
	if points.size() >= 3:
		create_triangle(points[0], points[1], points[2])
	if points.size() >= 4:
		create_triangle(points[0], points[2], points[3])
	if points.size() >= 5:
		create_triangle(points[0], points[3], points[4])
	if points.size() >= 6:
		create_triangle(points[0], points[4], points[5])
func assign_vertices(points: Array[CustomNode] ) -> void:
	for i in range(points.size()):
		if points[i].vertexIndex == -1:
			points[i].vertexIndex = vertices.size()
			vertices.append(points[i].position)
func create_triangle(a: CustomNode, b: CustomNode, c: CustomNode) -> void:
	triangles.append(a.vertexIndex)
	triangles.append(b.vertexIndex)
	triangles.append(c.vertexIndex)
	
	var triangle: Triangle = Triangle.new(a.vertexIndex, b.vertexIndex, c.vertexIndex)
	add_triangle_to_dict(triangle.vertexIndexA, triangle)
	add_triangle_to_dict(triangle.vertexIndexB, triangle)
	add_triangle_to_dict(triangle.vertexIndexC, triangle)


func add_triangle_to_dict(vertexIndexKey: int, triangle: Triangle) -> void:
	if triangleDictionary.get(vertexIndexKey):
		triangleDictionary[vertexIndexKey].append(triangle)
	else:
		triangleDictionary[vertexIndexKey] = [triangle]

func calculate_mesh_outlines() -> void:
	for vertexIndex in range(vertices.size()):
		if not checkedVertices.has(vertexIndex):
			var newOutlineVertex: int = get_connected_outline_vertex(vertexIndex)
			if newOutlineVertex != -1:
				checkedVertices[vertexIndex] = null

				var newOutline: Array[int] = []
				newOutline.append(vertexIndex)
				outlines.append(newOutline)

				var stack: Array[int] = []
				stack.append(newOutlineVertex)

				while stack.size() > 0:
					var currentIndex: int = stack.pop_back()
					if not checkedVertices.has(currentIndex):
						outlines[outlines.size() - 1].append(currentIndex)
						checkedVertices[currentIndex] = null
						var nextVertexIndex: int = get_connected_outline_vertex(currentIndex)
						if nextVertexIndex != -1:
							stack.append(nextVertexIndex)
				
				outlines[outlines.size() - 1].append(vertexIndex)
	
func get_connected_outline_vertex(vertexIndex: int) -> int:
	var trianglesContainingVertex: Array = triangleDictionary[vertexIndex]
	for i in range(trianglesContainingVertex.size()):
		var triangle: Triangle = trianglesContainingVertex[i]
		for j in range(3):
			var vertexB: int = triangle.get_vertex(j)
			if vertexB != vertexIndex and not vertexB in checkedVertices:
				if is_outline_edge(vertexIndex, vertexB):
					return vertexB
	return -1

func is_outline_edge(vertexA: int, vertexB: int) -> bool:
	var trianglesContainingVertexA: Array = triangleDictionary[vertexA]
	var sharedTriangles: int = 0
	
	for i in range(trianglesContainingVertexA.size()):
		if trianglesContainingVertexA[i].contains(vertexB):
			sharedTriangles+=1
			if sharedTriangles > 1:
				break
	return sharedTriangles == 1


class CustomNode:
	var position: Vector3
	var vertexIndex: int = -1
	
	func _init(_pos: Vector3):
		position = _pos

class ControlNode: 
	extends CustomNode
	var active: bool
	var above: CustomNode
	var right: CustomNode
	
	func _init(_pos: Vector3 , _active:  bool, squareSize: float ):
		super._init(_pos)
		active = _active
		
		above = CustomNode.new(position + Vector3.FORWARD * squareSize/2)
		right = CustomNode.new(position + Vector3.RIGHT * squareSize/2)

class Square:
	var topLeft: ControlNode
	var topRight: ControlNode
	var bottomRight: ControlNode
	var bottomLeft: ControlNode
	var centerTop: CustomNode
	var centerRight: CustomNode
	var centerBottom: CustomNode
	var centerLeft: CustomNode
	var configuration: int 
	
	func _init(_topLeft: ControlNode,_topRight: ControlNode,_bottomRight: ControlNode,_bottomLeft: ControlNode):
		topLeft = _topLeft
		topRight = _topRight
		bottomLeft = _bottomLeft
		bottomRight = _bottomRight
		
		centerTop = topLeft.right
		centerRight = bottomRight.above
		centerBottom = bottomLeft.right
		centerLeft = bottomLeft.above

		
		if topLeft.active:
			configuration+=8
		if topRight.active:
			configuration+=4
		if bottomRight.active:
			configuration+=2
		if bottomLeft.active:
			configuration+=1

class SquareGrid:
	var squares: Array = []
	var nodeCountX: int
	var nodeCountY: int
	var mapWidth: float
	var mapHeight: float
	var controlNodes : Array
	
	func _init(map: Array, squareSize: float):
		nodeCountX = map.size()
		nodeCountY = map[0].size()
		mapWidth = nodeCountX * squareSize
		mapHeight = nodeCountY * squareSize
		controlNodes = []
		for x in range(nodeCountX):
			controlNodes.append([])
			for y in range(nodeCountY):
				var pos : Vector3 = Vector3(-mapWidth/2 + x * squareSize + squareSize/2 , 0, mapHeight/2 - y * squareSize - squareSize/2)
				controlNodes[x].append(ControlNode.new(pos, map[x][y] == 1, squareSize))
		
		for x in range(nodeCountX - 1):
			squares.append([])
			for y in range(nodeCountY - 1):
				squares[x].append(Square.new(controlNodes[x][y+1], controlNodes[x+1][y+1],controlNodes[x+1][y],controlNodes[x][y]))

class Triangle:
	var vertexIndexA: int
	var vertexIndexB: int
	var vertexIndexC: int
	
	func _init(a: int, b: int ,c: int):
		vertexIndexA = a
		vertexIndexB = b
		vertexIndexC = c

	func contains(vertexIndex: int) -> bool:
		return vertexIndex == vertexIndexA or vertexIndex == vertexIndexB or vertexIndex == vertexIndexC
	
	func get_vertex(index: int) -> int:
		match index:
			0: return vertexIndexA
			1: return vertexIndexB
			2: return vertexIndexC
			_:
				printerr("Invalid index")
				return 0
