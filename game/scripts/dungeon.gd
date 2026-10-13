extends Node3D

var data: Dictionary
var nav := AStar2D.new()
var blocked := {}
var floors := {}
var wall_count := 0
const TILE := 2.0
const CEILING_HEIGHT := 4.5
const DIRS := [Vector2i(0,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0)]

func world(c: Vector2i) -> Vector3:
	return Vector3(c.x*TILE,0,c.y*TILE)

func cell(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x/TILE),roundi(p.z/TILE))

func id(c: Vector2i) -> int:
	return c.y*101+c.x

func walkable(c: Vector2i) -> bool:
	return c.x>=1 and c.y>=1 and c.x<=100 and c.y<=100 and int(blocked.get(c,0)) & 15 != 15 and floors.has(c)

func connected(a: Vector2i, b: Vector2i, direction: int) -> bool:
	return walkable(a) and walkable(b) and int(blocked.get(a,0)) & (1<<direction)==0 and int(blocked.get(b,0)) & (1<<((direction+2)%4))==0

func material(path: String, tint := Color.WHITE) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_texture = load(path)
	result.albedo_color = tint
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	result.roughness = 1.0
	return result

func grid(library: MeshLibrary, node_name: String) -> GridMap:
	var result := GridMap.new()
	result.name = node_name
	result.cell_size = Vector3(TILE,CEILING_HEIGHT,TILE)
	result.cell_center_x = false
	result.cell_center_y = false
	result.cell_center_z = false
	result.mesh_library = library
	add_child(result)
	return result

func _ready() -> void:
	if data.is_empty():
		data = JSON.parse_string(FileAccess.get_file_as_string("res://data/dungeon.json"))
	for r in data.blocked:
		blocked[Vector2i(r[0],r[1])] = int(r[2])
	for r in data.layer1:
		floors[Vector2i(r[0],r[1])] = int(r[2])
	for c in floors:
		if walkable(c):
			nav.add_point(id(c),Vector2(c))
	for c in floors:
		if not walkable(c):
			continue
		for direction in [1,2]:
			var next: Vector2i = c+DIRS[direction]
			if connected(c,next,direction):
				nav.connect_points(id(c),id(next))
	# Baked children are saved in main.tscn and visible without executing scripts.
	if not has_node("Floor"):
		build_geometry()
	wall_count = get_node("Walls").get_used_cells().size()

func build_geometry() -> void:
	var floor_library := MeshLibrary.new()
	var ceiling_library := MeshLibrary.new()
	var tiles := {}
	for r in data.layer1:
		var index := int(r[2])
		if tiles.has(index):
			continue
		var item := tiles.size()
		tiles[index] = item
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(TILE,TILE)
		mesh.material = material(data.textures[str(index)])
		floor_library.create_item(item)
		floor_library.set_item_mesh(item,mesh)
		floor_library.set_item_name(item,"Piso %d" % index)
		floor_library.set_item_preview(item,mesh.material.albedo_texture)
		ceiling_library.create_item(item)
		ceiling_library.set_item_mesh(item,mesh)
		ceiling_library.set_item_name(item,"Techo %d" % index)
		ceiling_library.set_item_preview(item,mesh.material.albedo_texture)
		ceiling_library.set_item_mesh_transform(item,Transform3D(Basis(Vector3.RIGHT,PI),Vector3(0,CEILING_HEIGHT,0)))
	var floor_grid := grid(floor_library,"Floor")
	var ceiling_grid := grid(ceiling_library,"Ceiling")
	var wall_library := MeshLibrary.new()
	wall_library.create_item(0)
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(TILE,CEILING_HEIGHT,TILE)
	var wall_material := material(data.wall_texture)
	wall_material.uv1_triplanar = true
	wall_material.uv1_world_triplanar = true
	wall_material.uv1_triplanar_sharpness = 16.0
	wall_material.uv1_scale = Vector3(0.25,0.25,0.25)
	wall_mesh.material = wall_material
	wall_library.set_item_mesh(0,wall_mesh)
	wall_library.set_item_name(0,"Pared de piedra")
	wall_library.set_item_preview(0,wall_material.albedo_texture)
	var offset := Transform3D(Basis.IDENTITY,Vector3(0,CEILING_HEIGHT/2.0,0))
	wall_library.set_item_mesh_transform(0,offset)
	var shape := BoxShape3D.new()
	shape.size = wall_mesh.size
	wall_library.set_item_shapes(0,[shape,offset])
	var walls := grid(wall_library,"Walls")
	var boundaries := {}
	var edges := Node3D.new()
	edges.name = "DirectionalBlockers"
	add_child(edges)
	for c in floors:
		if not walkable(c):
			continue
		floor_grid.set_cell_item(Vector3i(c.x,0,c.y),tiles[floors[c]])
		ceiling_grid.set_cell_item(Vector3i(c.x,0,c.y),tiles[floors[c]])
		for direction in range(4):
			var neighbor: Vector2i = c+DIRS[direction]
			if not walkable(neighbor):
				boundaries[neighbor] = true
			elif not connected(c,neighbor,direction):
				var barrier := StaticBody3D.new()
				barrier.name = "Edge_%d_%d_%d" % [c.x,c.y,direction]
				var collider := CollisionShape3D.new()
				var edge := BoxShape3D.new()
				edge.size = Vector3(2,CEILING_HEIGHT,0.06) if direction%2==0 else Vector3(0.06,CEILING_HEIGHT,2)
				collider.shape = edge
				barrier.add_child(collider)
				barrier.position = (world(c)+world(neighbor))*0.5+Vector3.UP*CEILING_HEIGHT/2.0
				edges.add_child(barrier)
	for c in boundaries:
		walls.set_cell_item(Vector3i(c.x,0,c.y),0)
	var ground := StaticBody3D.new()
	ground.name = "GroundCollision"
	var collider := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(204,0.2,204)
	collider.shape = ground_shape
	ground.position = Vector3(101,-0.1,101)
	ground.add_child(collider)
	add_child(ground)
	var decorations := Node3D.new()
	decorations.name = "Decorations"
	add_child(decorations)
	for decoration in data.decorations:
		var sprite := Sprite3D.new()
		sprite.texture = load(decoration.texture)
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		var is_sign: bool = decoration.texture.ends_with("grh_50925.png")
		sprite.name = "WelcomeSign" if is_sign else "Decoration_%d_%d" % [decoration.x,decoration.y]
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED if is_sign else BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.pixel_size = 1.6/float(sprite.texture.get_width()) if is_sign else TILE/32.0
		sprite.position = world(Vector2i(decoration.x,decoration.y))
		sprite.position.y = 1.45 if is_sign else sprite.texture.get_height()*sprite.pixel_size*0.5
		decorations.add_child(sprite)

func path(from: Vector3, to: Vector3) -> PackedVector2Array:
	var a := cell(from)
	var b := cell(to)
	if not nav.has_point(id(a)) or not nav.has_point(id(b)):
		return PackedVector2Array()
	return nav.get_point_path(id(a),id(b))
