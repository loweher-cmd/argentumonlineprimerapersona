extends SceneTree
var failures := 0
var checks := 0
var game: Node3D

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: "+description)
	else:
		print("PASS: "+description)

func tick(count: int = 3) -> void:
	for i in range(count):
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	check(game.get_node("Dungeon/Floor").get_used_cells().size()==2605,"floor geometry is serialized before any ready callback")
	check(game.get_node("Dungeon/Ceiling").get_used_cells().size()==2605,"ceiling copies all floor cells and is editor-visible")
	check(game.get_node("EnemySpawns").get_child_count()==84,"84 editor-visible spawn markers saved")
	var visible_cells := {"Floor":0,"Ceiling":0,"Walls":0}
	var editor_resources_ok := true
	for visual in game.get_node("Dungeon/TexturedGeometry").get_children():
		var category: String = String(visual.name).get_slice("_",0)
		visible_cells[category] += visual.multimesh.instance_count
		editor_resources_ok = editor_resources_ok and visual.visible and visual.custom_aabb.size.length()>0 and visual.multimesh.mesh.material.albedo_texture!=null
	check(editor_resources_ok,"serialized editor render nodes have textures and focus bounds before ready")
	for category in visible_cells:
		var grid: GridMap = game.get_node("Dungeon/"+category)
		check(visible_cells[category]==grid.get_used_cells().size() and grid.visible and not game.get_node("Dungeon/TexturedGeometry").visible,"GridMap visible and cached render copy hidden: "+category)
		var previews_ok := true
		for item in grid.mesh_library.get_item_list():
			previews_ok = previews_ok and grid.mesh_library.get_item_preview(item)!=null and not grid.mesh_library.get_item_name(item).is_empty()
		check(previews_ok,"GridMap palette has named texture previews: "+category)
	root.add_child(game)
	await tick()
	check(game.data.id==37,"verified map 37 loads")
	check(game.dungeon.nav.get_point_count()==2605,"2605 source walkable cells")
	var ceiling_grid: GridMap = game.dungeon.get_node("Ceiling")
	check(is_equal_approx(ceiling_grid.mesh_library.get_item_mesh_transform(0).origin.y,4.5),"saved ceiling raised to 4.5 meters")
	var walls_grid: GridMap = game.dungeon.get_node("Walls")
	check(is_equal_approx(walls_grid.mesh_library.get_item_mesh(0).size.y,4.5),"walls extend to raised ceiling")
	var bats_level := true
	for enemy in get_nodes_in_group("enemies"):
		if enemy.kind=="bat":
			bats_level = bats_level and is_equal_approx(enemy.sprite.position.y,1.15)
	check(bats_level,"bat sprite center flies at 1.15 meters near eye level")
	check(game.hud.root.find_child("EquipmentInventory",true,false)!=null and game.hud.slots.size()==4,"equipment and inventory coexist with four bottom actions")
	check(game.hud.sword.get_index()==0 and game.hud.sword.size==Vector2(340,340),"large retro dagger renders behind all HUD panels")
	var wolves_larger := true
	for creature in get_nodes_in_group("enemies"):
		if creature.kind=="wolf":
			wolves_larger = wolves_larger and is_equal_approx(creature.sprite.pixel_size,0.033)
	check(wolves_larger,"wolf visuals enlarged while keeping combat collision unchanged")
	game.notify("Registro de prueba")
	game.hud.message_time = 0
	await tick()
	await process_frame
	await process_frame
	check(game.hud.event_log.text.contains("Registro de prueba") and game.hud.message.text.is_empty(),"event log persists after transient message expires")
	check(get_nodes_in_group("enemies").size()==84,"84 enemies including 36 original and 48 extra spawns")
	var kinds := {}
	for enemy in get_nodes_in_group("enemies"):
		kinds[enemy.kind] = true
		enemy.set_physics_process(false)
		check(game.dungeon.walkable(game.dungeon.cell(enemy.position)),"spawn on walkable cell: "+enemy.kind)
	check(kinds.size()==4,"exactly four enemy species")
	var wall_material = game.dungeon.get_node("Walls").mesh_library.get_item_mesh(0).material
	check(wall_material.uv1_triplanar and wall_material.uv1_world_triplanar,"wall texture tiles in world space")
	var sign_node = game.dungeon.get_node("Decorations/WelcomeSign")
	check(sign_node.billboard==BaseMaterial3D.BILLBOARD_DISABLED and sign_node.texture.get_width()*sign_node.pixel_size<=1.61,"sign fixed facing and fits its 2m cell")
	check(game.data.weapon.object_id==15 and game.data.icons[0].ends_with("grh_5603.png"),"original common dagger equipped")
	check(game.hud.root.find_child("Minimap",true,false)!=null,"minimap present")
	check(game.audio.music.stream.loop,"original dungeon music loops")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),false)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),false)
	var audio_key := InputEventKey.new()
	audio_key.pressed = true
	audio_key.physical_keycode = KEY_O
	game._input(audio_key)
	check(game.audio.muted("Music") and not game.audio.muted("SFX"),"O mutes only music")
	audio_key.physical_keycode = KEY_P
	game._input(audio_key)
	check(game.audio.muted("SFX"),"P mutes SFX")
	game.hud.music_button.pressed.emit()
	game.hud.sfx_button.pressed.emit()
	check(not game.audio.muted("Music") and not game.audio.muted("SFX"),"audio buttons unmute independent buses")
	game.begin()
	check(game.audio.music.playing,"music starts after Enter interaction")
	var p: CharacterBody3D = game.player
	p.position = Vector3(146,0,164)
	p.rotation.y = 0
	await tick()
	var start: Vector3 = p.position
	Input.action_press("forward")
	await tick(20)
	Input.action_release("forward")
	check(p.position.distance_to(start)>0.8,"WASD movement advances player")
	# North of (73,80) is a full wall at (73,79).
	p.position = Vector3(146,0,160)
	await tick()
	Input.action_press("forward")
	await tick(60)
	Input.action_release("forward")
	check(p.position.z>159.2,"player cannot cross source wall")
	check(game.dungeon.path(Vector3(146,0,164),Vector3(138,0,164)).size()>0,"AStar route in room")
	check(not game.dungeon.connected(Vector2i(76,85),Vector2i(76,84),0),"north partial block restricts navigation")
	# Isolated target in actual room, three metres south of camera.
	p.position = Vector3(146,0,164)
	p.rotation.y = PI
	p.camera.rotation.x = 0
	var enemy = get_nodes_in_group("enemies")[0]
	enemy.position = Vector3(146,0,166.5)
	enemy.hp = 100
	await tick()
	p.action(0)
	check(enemy.hp==78,"sword hits target in front within range")
	p.action(0)
	check(enemy.hp==78,"sword cooldown prevents repeated hit")
	p.cooldowns[0] = 0
	enemy.position.z = 170
	await tick()
	p.action(0)
	check(enemy.hp==78,"sword rejects out-of-range target")
	# Place enemy across known source wall.
	p.position = Vector3(146,0,160)
	p.rotation.y = 0
	enemy.position = Vector3(146,0,157.5)
	p.cooldowns[0] = 0
	await tick()
	p.action(0)
	check(enemy.hp==78,"sword line of sight blocked by wall")
	p.cooldowns[1] = 0
	p.action(1)
	await tick(25)
	check(enemy.hp==78,"magic projectile stops at wall")
	p.position = Vector3(146,0,164)
	p.rotation.y = PI
	enemy.position = Vector3(146,0,168)
	p.cooldowns[1] = 0
	await tick()
	var old_mana: int = p.mana
	p.action(1)
	await tick(25)
	check(p.mana==old_mana-10,"magic consumes 10 mana")
	check(enemy.hp==50,"moving projectile deals 28 damage on impact")
	p.mana = 0
	p.cooldowns[1] = 0
	p.action(1)
	check(p.cooldowns[1]==0,"insufficient mana prevents cast")
	p.hp = 100
	p.action(2)
	check(p.hp==120 and p.health_charges==7,"health potion caps health and spends charge")
	p.cooldowns[2] = 0
	p.action(2)
	check(p.health_charges==7,"full health does not waste potion")
	p.mana = 70
	p.action(3)
	check(p.mana==80 and p.mana_charges==7,"mana potion caps mana and spends charge")
	p.health_charges = 0
	p.hp = 20
	p.cooldowns[2] = 0
	p.action(2)
	check(p.hp==20,"empty consumables cannot heal")
	# Enemy is put in melee range and enabled for real physics ticks.
	p.hp = 120
	enemy.position = p.position+Vector3(0,0,1.3)
	enemy.attack_timer = 0
	enemy.set_physics_process(true)
	await tick(4)
	var damaged_hp: int = p.hp
	check(damaged_hp<120,"enemy melee damages player")
	await tick(10)
	check(p.hp==damaged_hp,"enemy attack cooldown enforced")
	enemy.set_physics_process(false)
	p.position = Vector3(146,0,160)
	enemy.position = Vector3(146,0,156)
	enemy.aware = true
	enemy.path_timer = 0
	enemy.set_physics_process(true)
	var remained_walkable := true
	var moved := false
	var enemy_start: Vector3 = enemy.position
	for step in range(180):
		await tick(1)
		remained_walkable = remained_walkable and game.dungeon.walkable(game.dungeon.cell(enemy.position))
		moved = moved or enemy.position.distance_to(enemy_start)>1.0
	check(remained_walkable and moved, "enemy follows route around walls without entering blocked cells")
	enemy.set_physics_process(false)
	enemy.position = Vector3(152,0,138)
	enemy.home = enemy.position
	enemy.aware = false
	enemy.route = PackedVector2Array()
	enemy.wander_timer = 0
	p.position = Vector3(146,0,164)
	var wander_start: Vector3 = enemy.position
	enemy.set_physics_process(true)
	await tick(180)
	check(not enemy.aware and enemy.position.distance_to(wander_start)>0.4,"idle enemy roams without detecting player")
	check(game.dungeon.walkable(game.dungeon.cell(enemy.position)),"roaming stays in walkable map cells")
	enemy.set_physics_process(false)
	enemy.take_damage(1000)
	check(enemy.dead and enemy.collision_layer==0 and game.kills==1,"enemy death removes collision and counts kill")
	p.take_damage(1000)
	check(not p.alive and game.hud.death.visible,"player death opens restart screen")
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"death releases mouse")
	# A fresh instance models the scene reload used by Restart.
	game.free()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await tick()
	check(game.player.hp==120 and game.player.mana==80 and game.player.health_charges==8 and game.kills==0,"new run restores initial state")
	game.started = true
	game.player.hp = 70
	game.hud.inventory_health.pressed.emit()
	await tick()
	await process_frame
	await process_frame
	check(game.player.hp==115 and game.player.health_charges==7 and game.hud.inventory_health.text=="7","inventory potion consumes the same charge and updates health")
	check(game.hud.slots[2].text.contains("Vida x7"),"bottom bar and inventory stay synchronized")
	for i in range(120):
		game.hud.add_log("Evento %d" % i)
	check(game.hud.log_entries.size()==100 and game.hud.event_log.text.ends_with("Evento 119"),"persistent log bounds history and retains latest event")
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
