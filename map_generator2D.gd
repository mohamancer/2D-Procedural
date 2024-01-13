extends Node2D

@export var width: int 
@export var height: int

@export var my_seed : String
@export var useRandomSeed : bool
@export_range(0, 100) var randomFillPercent: int 

var map : Array

var created: bool = false

var n: int = 0
var m: int = 0

func _ready():
	generate_map()
	
	


func generate_map() -> void:
	map = []
	random_fill_map()

	for i in range(5):
		smooth_map()
	
	process_map()
	var borderSize: int = 20
	var borderMap: Array = add_border_map(borderSize)
	$"Mesh Generator".generate_mesh(borderMap,5)
	created = false

func process_map() -> void:
	var wallRegions: Array[Array] = get_regions(1)
	var wallThresholdSize: int = 50
	for wallRegion in wallRegions:
		if wallRegion.size() < wallThresholdSize:
			for tile in wallRegion:
				map[tile.tileX][tile.tileY] = 0
	
	var roomRegions: Array[Array] = get_regions(0)
	var roomThresholdSize: int = 50
	var survivingRooms: Array[Room] = []
	
	for roomRegion in roomRegions:
		if roomRegion.size() < roomThresholdSize:
			for tile in roomRegion:
				map[tile.tileX][tile.tileY] = 1
		else:
			survivingRooms.append(Room.new(roomRegion, map))
	
	survivingRooms.sort_custom(by_roomSize)
	survivingRooms[0].isMainRoom = true
	survivingRooms[0].isAccessableFromMainRoom = true
	connect_closest_rooms(survivingRooms)
	
func connect_closest_rooms(allRooms: Array[Room], forceAccessibilityFromMainRoom: bool = false) -> void:
	var roomListA: Array[Room] = []
	var roomListB: Array[Room] = []
	if forceAccessibilityFromMainRoom:
		for room in allRooms:
			if room.isAccessableFromMainRoom:
				roomListB.append(room)
			else:
				roomListA.append(room)
	else:
		roomListA = allRooms
		roomListB = allRooms
		
	var bestDistance: int = 0
	var bestTileA: Coord
	var bestTileB: Coord
	var bestRoomA: Room
	var bestRoomB: Room
	var possibleConnectionFound: bool = false
	
	for roomA in roomListA:
		if not forceAccessibilityFromMainRoom:
			possibleConnectionFound = false
			if roomA.connectedRooms.size() > 0:
				continue
		possibleConnectionFound = false
		for roomB in roomListB:
			if roomA == roomB or roomA._is_connected(roomB): continue
			for tileIndexA in range(roomA.edgeTiles.size()):
				for tileIndexB in range(roomB.edgeTiles.size()):
					var tileA: Coord = roomA.edgeTiles[tileIndexA]
					var tileB: Coord = roomB.edgeTiles[tileIndexB]
					var distanceBetweenRooms: int = int((tileA.tileX - tileB.tileX)**2 + \
					 								(tileA.tileY - tileB.tileY)**2) 
					if distanceBetweenRooms < bestDistance or not possibleConnectionFound:
						bestDistance = distanceBetweenRooms
						possibleConnectionFound = true 
						bestTileA = tileA
						bestTileB = tileB
						bestRoomA = roomA
						bestRoomB = roomB
	
		if possibleConnectionFound and not forceAccessibilityFromMainRoom:
			create_passage(bestRoomA, bestRoomB, bestTileA, bestTileB)
	
	if possibleConnectionFound and forceAccessibilityFromMainRoom:
		create_passage(bestRoomA, bestRoomB, bestTileA, bestTileB)
		connect_closest_rooms(allRooms, true)
	
	if not forceAccessibilityFromMainRoom:
		connect_closest_rooms(allRooms, true)
	
func create_passage(roomA: Room, roomB: Room, tileA: Coord, tileB: Coord) -> void:
	Room.connect_rooms(roomA, roomB)
#	_draw_line(coord_to_world_point(tileA), coord_to_world_point(tileB), Color.GREEN)
	var line: Array[Coord] = get_line(tileA, tileB)
	for coord in line:
		_draw_circle(coord, 4)

func _draw_circle(c: Coord, r: int) -> void:
	for x in range(-r, r+1):
		for y in range(-r, r+1):
			if x**2 + y**2 <= r**2:
				var drawX: int = c.tileX + x
				var drawY: int = c.tileY + y
				
				if is_in_map_range(drawX, drawY):
					map[drawX][drawY] = 0
				
	

func get_line(from: Coord, to: Coord) -> Array[Coord]:
	var line: Array[Coord] = []
	
	var x: int = from.tileX
	var y: int = from.tileY
	
	var dx: int = to.tileX - from.tileX
	var dy: int = to.tileY - from.tileY
	
	var inverted: bool = false
	var step: int = sign(dx)
	var gradientStep: int = sign(dy)
	
	var longest: int = abs(dx)
	var shortest: int = abs(dy)
	
	if longest < shortest:
		inverted = true
		longest = abs(dy)
		shortest = abs(dx)
		
		step = sign(dy)
		gradientStep = sign(dx)
	
	@warning_ignore("integer_division")
	var gradientAccumulation: int = longest / 2
	for i in range(longest):
		line.append(Coord.new(x,y))
		
		if inverted:
			y+= step
		else: 
			x+= step
		gradientAccumulation += shortest
		if gradientAccumulation >= longest:
			if inverted:
				x+=gradientStep
			else:
				y+=gradientStep
			gradientAccumulation -= longest
	
	return line
func _draw_line(pos1: Vector3, pos2: Vector3, color: Color):
	var meshInstance  = MeshInstance3D.new()
	var immediateMesh = ImmediateMesh.new()
	var nMaterial  = ORMMaterial3D.new()
	meshInstance.mesh = immediateMesh
	meshInstance.cast_shadow = false
	immediateMesh.surface_begin(Mesh.PRIMITIVE_LINES, nMaterial)
	immediateMesh.surface_add_vertex(pos1)
	immediateMesh.surface_add_vertex(pos2)
	immediateMesh.surface_end()
	nMaterial.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	nMaterial.albedo_color = color
	add_child(meshInstance)

func coord_to_world_point(tile: Coord) -> Vector3:
	return Vector3(-width/2.0 + 0.5 + tile.tileX, 0, - height/2.0+0.5+tile.tileY)
	
func get_regions(tileType: int) -> Array[Array]:
	var regions: Array[Array] = []
	var mapFlags: Array[Array] = []
	for x in range(width):
		mapFlags.append([])
		for y in range(height):
			mapFlags[x].append(0)
			
	for x in range(width):
		for y in range(height):
			if mapFlags[x][y] == 0 and map[x][y] == tileType:
				var newRegion: Array[Coord] = get_region_tiles(x,y)
				regions.append(newRegion)
				for tile in newRegion:
					mapFlags[tile.tileX][tile.tileY] = 1
	return regions
func get_region_tiles(startX: int, startY: int) -> Array[Coord]:
	var tiles: Array[Coord] = []
	var mapFlags: Array[Array] = []
	for x in range(width):
		mapFlags.append([])
		for y in range(height):
			mapFlags[x].append(0)
	var tileType = map[startX][startY]
	
	var queue: Array[Coord] = []
	queue.append(Coord.new(startX, startY))
	mapFlags[startX][startY] = 1
	
	while queue.size() > 0:
		var tile: Coord = queue.pop_front()
		tiles.append(tile)
		for x in range(tile.tileX - 1, tile.tileX + 2):
			for y in range(tile.tileY - 1, tile.tileY + 2):
				if is_in_map_range(x,y) and (x == tile.tileX or y == tile.tileY):
					if mapFlags[x][y] == 0 and map[x][y] == tileType:
						mapFlags[x][y] = 1
						queue.append(Coord.new(x,y))
	return tiles
func is_in_map_range(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height
func random_fill_map() -> void:
	if useRandomSeed:
		my_seed = str(Time.get_ticks_msec() / 1000.0)

	var pseudoRandom = RandomNumberGenerator.new()
	pseudoRandom.seed = my_seed.hash()
	
	for x in range(width):
		map.append([])
		for y in range(height):
			if x == 0 || x == width - 1 || y == 0 || y == height - 1:
				map[x].append(1)
			else:
				map[x].append(1 if pseudoRandom.randi_range(0, 99) < randomFillPercent else 0)
func smooth_map() -> void:
	for x in range(width):
		for y in range(height):
			var neighbour_wall_tiles : int = get_surrounding_wall_count(x, y)

			if neighbour_wall_tiles > 4:
				map[x][y] = 1
			elif neighbour_wall_tiles < 4:
				map[x][y] = 0
func add_border_map(borderSize: int) -> Array:
	var  borderMap: Array = []
	for x in range(width + borderSize * 2):
		borderMap.append([])
		for y in range(height + borderSize * 2):
			if x >= borderSize and x < width + borderSize and y>= borderSize and y < height + borderSize:
				borderMap[x].append(map[x - borderSize][y-borderSize])
			else:
				borderMap[x].append(1)
	return borderMap
func get_surrounding_wall_count(gridX, gridY) -> int:
	var wallCount : int = 0

	for neighbourX in range(gridX - 1, gridX + 2):
		for neighbourY in range(gridY - 1, gridY + 2):
			if is_in_map_range(neighbourX, neighbourY):
				if neighbourX != gridX || neighbourY != gridY:
					wallCount += map[neighbourX][neighbourY]
					
			else:
				wallCount += 1

	return wallCount

func _process(_delta: float):
	if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
		generate_map()
#		queue_redraw()
#	manual()
#	immediate()



func immediate():
	if not created:
		for x in range($"Mesh Generator".squareGrid.squares.size()):
			for y in range($"Mesh Generator".squareGrid.squares[0].size()):
				create_top_left_cube(x,y)
				create_top_right_cube(x,y)
				create_bottom_right_cube(x,y)
				create_bottom_left_cube(x,y)
				create_center_top_cube(x,y)
				create_center_right_cube(x,y)
				create_center_bottom_cube(x,y)
				create_center_left_cube(x,y)
		created = true
func manual():
	if not created:
		create_top_left_cube(n,m)
		create_top_right_cube(n,m)
		create_bottom_right_cube(n,m)
		create_bottom_left_cube(n,m)
		create_center_top_cube(n,m)
		create_center_right_cube(n,m)
		create_center_bottom_cube(n,m)
		create_center_left_cube(n,m)
	m += 1
	if m == $"Mesh Generator".squareGrid.squares[0].size(): 
		m = 0
		n += 1
		if n == $"Mesh Generator".squareGrid.squares.size():
			created = true

func create_top_left_cube(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var newMaterial = StandardMaterial3D.new()
	if $"Mesh Generator".squareGrid.squares[x][y].topLeft.active:
		newMaterial.albedo_color = Color.BLACK
	else:
		newMaterial.albedo_color = Color.GHOST_WHITE
	
	add_child(mesh_instance)

	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.4
	cube_mesh.material = newMaterial
	mesh_instance.mesh = cube_mesh
	mesh_instance.set_position($"Mesh Generator".squareGrid.squares[x][y].topLeft.position)
func create_top_right_cube(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var newMaterial = StandardMaterial3D.new()
	if $"Mesh Generator".squareGrid.squares[x][y].topRight.active:
		newMaterial.albedo_color = Color.BLACK
	else:
		newMaterial.albedo_color = Color.GHOST_WHITE
	
	add_child(mesh_instance)

	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.4
	cube_mesh.material = newMaterial
	mesh_instance.mesh = cube_mesh
	mesh_instance.set_position($"Mesh Generator".squareGrid.squares[x][y].topRight.position)
func create_bottom_right_cube(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var newMaterial = StandardMaterial3D.new()
	if $"Mesh Generator".squareGrid.squares[x][y].bottomRight.active:
		newMaterial.albedo_color = Color.BLACK
	else:
		newMaterial.albedo_color = Color.GHOST_WHITE
	
	add_child(mesh_instance)

	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.4
	cube_mesh.material = newMaterial
	mesh_instance.mesh = cube_mesh
	mesh_instance.set_position($"Mesh Generator".squareGrid.squares[x][y].bottomRight.position)
func create_bottom_left_cube(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var newMaterial = StandardMaterial3D.new()
	if $"Mesh Generator".squareGrid.squares[x][y].bottomLeft.active:
		newMaterial.albedo_color = Color.BLACK
	else:
		newMaterial.albedo_color = Color.GHOST_WHITE
	
	add_child(mesh_instance)

	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.4
	cube_mesh.material = newMaterial
	mesh_instance.mesh = cube_mesh
	mesh_instance.set_position($"Mesh Generator".squareGrid.squares[x][y].bottomLeft.position)
func create_center_top_cube(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_color = Color.GRAY
	
	add_child(mesh_instance)

	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.15
	cube_mesh.material = newMaterial
	mesh_instance.mesh = cube_mesh
	mesh_instance.set_position($"Mesh Generator".squareGrid.squares[x][y].centerTop.position)
func create_center_right_cube(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_color = Color.GRAY
	
	add_child(mesh_instance)

	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.15
	cube_mesh.material = newMaterial
	mesh_instance.mesh = cube_mesh
	mesh_instance.set_position($"Mesh Generator".squareGrid.squares[x][y].centerRight.position)
func create_center_bottom_cube(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_color = Color.GRAY
	
	add_child(mesh_instance)

	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.15
	cube_mesh.material = newMaterial
	mesh_instance.mesh = cube_mesh
	mesh_instance.set_position($"Mesh Generator".squareGrid.squares[x][y].centerBottom.position)
func create_center_left_cube(x: int, y: int):
	var mesh_instance = MeshInstance3D.new()
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_color = Color.GRAY
	
	add_child(mesh_instance)

	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.15
	cube_mesh.material = newMaterial
	mesh_instance.mesh = cube_mesh
	mesh_instance.set_position($"Mesh Generator".squareGrid.squares[x][y].centerLeft.position)

class Coord:
	var tileX: int
	var tileY: int
	
	func _init(x: int, y: int):
		tileX = x
		tileY = y
		
#func _draw():
#	if map != null:
#		for x in range(width):
#			for y in range(height):
#				var color: Color
#				color = Color(0, 0, 0) if map[x][y] == 1 else Color(1, 1, 1)
#				var rect_size = Vector2(5, 5) 
#
#				var pos : Vector2 = Vector2(x , y) * rect_size + \
#				get_viewport_rect().size / 2 - rect_size/2 * Vector2(width, height)
#
#				draw_rect(Rect2(pos, rect_size), color)
func by_roomSize(roomA: Room, roomB: Room) -> bool:
	return roomA.roomSize > roomB.roomSize
class Room:
	var tiles: Array[Coord] = []
	var edgeTiles: Array[Coord]
	var connectedRooms: Array[Room]
	var roomSize: int 
	var isAccessableFromMainRoom: bool
	var isMainRoom: bool
	func _init(roomTiles: Array[Coord], map: Array):
		tiles = roomTiles 
		roomSize = tiles.size()
		connectedRooms = []
		edgeTiles = []
		for tile in tiles:
			for x in range(tile.tileX - 1, tile.tileX + 2):
				for y in range(tile.tileY - 1, tile.tileY + 2):
					if x == tile.tileX or y == tile.tileY:
						if map[x][y] == 1:
							edgeTiles.append(tile)
		
	func set_accessible_from_main_room() -> void:
		if not isAccessableFromMainRoom:
			isAccessableFromMainRoom = true
			for room in connectedRooms:
				room.set_accessible_from_main_room()
	
	static func connect_rooms(roomA: Room, roomB: Room) -> void:
		if roomA.isAccessableFromMainRoom:
			roomB.set_accessible_from_main_room()
		elif roomB.isAccessableFromMainRoom:
			roomA.set_accessible_from_main_room()
		
		roomA.connectedRooms.append(roomB)
		roomB.connectedRooms.append(roomA)
	
	func _is_connected(otherRoom: Room) -> bool:
		return otherRoom in connectedRooms

		
		
