extends Node3D

const Dungeon = preload("res://scripts/dungeon.gd")
const Paladin = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const HUD = preload("res://ui/hud.gd")
var data: Dictionary
var dungeon: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var kills := 0
var started := false
var exit_notice := 0.0
var audio: Node
var total_enemies := 0

func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/dungeon.json"))
	configure_inputs()
	if not has_node("WorldEnvironment"):
		add_lighting(self)
	if has_node("Dungeon"):
		dungeon = get_node("Dungeon")
	else:
		dungeon = Dungeon.new()
		dungeon.name = "Dungeon"
		dungeon.data = data
		add_child(dungeon)
	audio = preload("res://scripts/audio.gd").new()
	audio.name = "Audio"
	add_child(audio)
	player = Paladin.new()
	player.name = "Paladin"
	player.game = self
	add_child(player)
	if has_node("PlayerSpawn"):
		player.transform = get_node("PlayerSpawn").transform
		get_node("PlayerSpawn").visible = false
	else:
		player.position = dungeon.world(Vector2i(data.spawn[0],data.spawn[1]))
		player.rotation.y = PI / 2.0
	if has_node("EnemySpawns"):
		var markers := get_node("EnemySpawns")
		markers.visible = false
		for marker in markers.get_children():
			spawn_enemy(marker.get_meta("kind"),marker.position)
	else:
		for spawn in data.enemy_spawns+data.extra_enemy_spawns:
			spawn_enemy(spawn.kind,dungeon.world(Vector2i(spawn.x,spawn.y)))
	hud = HUD.new()
	hud.game = self
	add_child(hud)
	print("READY map=", data.id, " enemies=", total_enemies, " walkable=", dungeon.nav.get_point_count())

func configure_inputs() -> void:
	var bindings := {"forward":KEY_W, "back":KEY_S, "left":KEY_A, "right":KEY_D, "action_1":KEY_1, "action_2":KEY_2, "action_3":KEY_3, "action_4":KEY_4}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)

func begin() -> void:
	started = true
	audio.start()
	hud.intro.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func clear_ray(from: Vector3, to: Vector3, mask: int = 1) -> bool:
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, mask)).is_empty()

func notify(message: String) -> void:
	hud.message.text = message
	hud.message_time = 2.5
	hud.add_log(message)

func _process(delta: float) -> void:
	exit_notice -= delta
	if not started or exit_notice>0 or not player.alive:
		return
	var current: Vector2i = dungeon.cell(player.position)
	for exit_record in data.exits:
		if current == Vector2i(exit_record[0],exit_record[1]):
			notify("Salida al mapa %d: fuera de este prototipo" % exit_record[2])
			exit_notice = 4.0
			break

func spawn_enemy(kind: String, at: Vector3) -> void:
	var enemy := Enemy.new()
	enemy.game = self
	enemy.stats = data.enemies[kind]
	enemy.kind = kind
	enemy.position = at
	add_child(enemy)
	total_enemies += 1

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_O:
			audio.toggle("Music")
		elif event.physical_keycode==KEY_P:
			audio.toggle("SFX")

static func add_lighting(parent: Node3D) -> void:
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("111723")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("bcc6df")
	settings.ambient_light_energy = 0.52
	environment.environment = settings
	parent.add_child(environment)
	var light := DirectionalLight3D.new()
	light.name = "DungeonLight"
	light.rotation_degrees = Vector3(-65,-25,0)
	light.light_energy = 0.25
	parent.add_child(light)
