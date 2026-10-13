extends SceneTree

func _initialize() -> void:
	call_deferred("bake")

func own_children(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		own_children(child,scene_root)

func bake_visible_meshes(dungeon: Node3D) -> void:
	# Explicit render nodes give the editor selectable bounds and textured geometry.
	# GridMaps render directly in editor and runtime; cached meshes stay hidden.
	var geometry := Node3D.new()
	geometry.name = "TexturedGeometry"
	geometry.visible = false
	dungeon.add_child(geometry)
	for grid_name in ["Floor","Ceiling","Walls"]:
		var grid: GridMap = dungeon.get_node(grid_name)
		for item in grid.mesh_library.get_item_list():
			var cells := grid.get_used_cells_by_item(item)
			if cells.is_empty():
				continue
			var mesh := grid.mesh_library.get_item_mesh(item)
			var instances := MultiMesh.new()
			instances.transform_format = MultiMesh.TRANSFORM_3D
			instances.mesh = mesh
			instances.instance_count = cells.size()
			var bounds := AABB()
			for i in range(cells.size()):
				var placement := Transform3D(Basis.IDENTITY,grid.map_to_local(cells[i])) * grid.mesh_library.get_item_mesh_transform(item)
				instances.set_instance_transform(i,placement)
				var cell_bounds := placement * mesh.get_aabb()
				bounds = cell_bounds if i==0 else bounds.merge(cell_bounds)
			instances.custom_aabb = bounds.grow(0.01)
			var visual := MultiMeshInstance3D.new()
			visual.name = "%s_%02d" % [grid_name,item]
			visual.multimesh = instances
			visual.custom_aabb = instances.custom_aabb
			geometry.add_child(visual)
		grid.visible = true

func bake() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dungeon.json"))
	var scene_root := Node3D.new()
	scene_root.name = "DungeonNewbie"
	root.add_child(scene_root)
	var dungeon := preload("res://scripts/dungeon.gd").new()
	dungeon.name = "Dungeon"
	dungeon.data = data
	scene_root.add_child(dungeon)
	bake_visible_meshes(dungeon)
	preload("res://scripts/main.gd").add_lighting(scene_root)
	var start := Marker3D.new()
	start.name = "PlayerSpawn"
	start.position = dungeon.world(Vector2i(data.spawn[0],data.spawn[1]))
	start.rotation.y = PI/2.0
	scene_root.add_child(start)
	var camera := Camera3D.new()
	camera.name = "EditorPreviewCamera"
	camera.position.y = 1.3
	camera.fov = 74
	start.add_child(camera)
	var lantern := OmniLight3D.new()
	lantern.name = "EditorPreviewLantern"
	lantern.light_color = Color("ffdda9")
	lantern.light_energy = 0.8
	lantern.omni_range = 12
	lantern.position.y = 1.4
	start.add_child(lantern)
	var markers := Node3D.new()
	markers.name = "EnemySpawns"
	scene_root.add_child(markers)
	var index := 0
	for spawn in data.enemy_spawns+data.extra_enemy_spawns:
		var marker := Marker3D.new()
		marker.name = "%s_%02d_%s" % [spawn.kind,index,"Original" if index<36 else "Extra"]
		marker.position = dungeon.world(Vector2i(spawn.x,spawn.y))
		marker.set_meta("kind",spawn.kind)
		marker.set_meta("original",index<36)
		markers.add_child(marker)
		var preview := Sprite3D.new()
		preview.name = "EditorSprite"
		preview.texture = load(data.enemies[spawn.kind].idle.directions[0][0])
		preview.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		preview.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		preview.pixel_size = 0.033 if spawn.kind=="wolf" else 0.034
		preview.position.y = preload("res://scripts/enemy.gd").BAT_FLIGHT_HEIGHT if spawn.kind=="bat" else preview.texture.get_height()*preview.pixel_size*0.5
		marker.add_child(preview)
		index += 1
	own_children(scene_root,scene_root)
	scene_root.set_script(load("res://scripts/main.gd"))
	var packed := PackedScene.new()
	var error := packed.pack(scene_root)
	if error!=OK:
		push_error("Cannot pack dungeon scene")
		quit(1)
		return
	error = ResourceSaver.save(packed,"res://scenes/main.tscn")
	print("BAKED main.tscn: ",dungeon.get_node("Floor").get_used_cells().size()," floor/ceiling cells, ",index," editable spawns; result=",error)
	quit(error)
