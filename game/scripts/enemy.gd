extends CharacterBody3D

const BAT_FLIGHT_HEIGHT := 1.15

var game: Node3D
var stats: Dictionary
var kind: String
var hp: int
var sprite: Sprite3D
var animations := {}
var elapsed := 0.0
var attack_timer := 0.0
var attack_visual := 0.0
var hit_flash := 0.0
var path_timer := 0.0
var route := PackedVector2Array()
var waypoint := 1
var facing := Vector2(0,1)
var dead := false
var aware := false
var wander_timer := 0.0
var home := Vector3.ZERO
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("enemies")
	hp = stats.hp
	home = position
	rng.seed = int(position.x*101+position.z*1009)
	wander_timer = rng.randf_range(0.2,2.5)
	collision_layer = 4
	collision_mask = 7
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.7
	collider.shape = shape
	collider.position.y = 0.85
	add_child(collider)
	sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.no_depth_test = false
	sprite.pixel_size = 0.033 if kind == "wolf" else 0.034
	add_child(sprite)
	for state in ["idle","walk","attack"]:
		animations[state] = []
		for paths in stats[state].directions:
			var frames := []
			for path in paths:
				frames.append(load(path))
			animations[state].append(frames)
	update_sprite("idle")

func _physics_process(delta: float) -> void:
	if dead or not game.started or not game.player.alive:
		return
	elapsed += delta
	attack_timer -= delta
	attack_visual -= delta
	hit_flash -= delta
	path_timer -= delta
	wander_timer -= delta
	var offset: Vector3 = game.player.position-position
	var distance := offset.length()
	if distance < 14 and game.clear_ray(position+Vector3.UP,game.player.position+Vector3.UP):
		if not aware:
			path_timer = 0
		aware = true
	if distance>24:
		aware = false
	velocity = Vector3.ZERO
	if aware:
		if distance<1.65 and game.clear_ray(position+Vector3.UP,game.player.position+Vector3.UP):
			facing = Vector2(offset.x,offset.z).normalized()
			if attack_timer<=0:
				game.player.take_damage(stats.damage)
				attack_timer = 1.4
				attack_visual = 0.4
		else:
			if path_timer<=0:
				route = game.dungeon.path(position,game.player.position)
				waypoint = 1 if route.size()>1 else 0
				path_timer = 0.6+float(get_instance_id()%7)*0.04
			follow_route(float(stats.speed))
	else:
		if wander_timer<=0:
			choose_wander_route()
		follow_route(float(stats.speed)*0.45)
	velocity.y = -2
	move_and_slide()
	update_sprite("attack" if attack_visual>0 else ("walk" if Vector2(velocity.x,velocity.z).length()>0.1 else "idle"))

func update_sprite(state: String) -> void:
	var to_camera: Vector3 = game.player.position-position
	var view := Vector2(to_camera.x,to_camera.z).normalized()
	var angle := facing.angle_to(view)
	var direction := 0
	if absf(angle)>PI*0.75:
		direction = 1
	elif angle>PI*0.25:
		direction = 3
	elif angle < -PI*0.25:
		direction = 2
	var frames: Array = animations[state][direction]
	if frames.is_empty():
		return
	sprite.texture = frames[int(elapsed*float(stats[state].fps))%frames.size()]
	sprite.position.y = BAT_FLIGHT_HEIGHT if kind == "bat" else sprite.texture.get_height()*sprite.pixel_size*0.5
	sprite.modulate = Color(1,0.35,0.25) if hit_flash>0 else Color.WHITE

func take_damage(amount: int) -> void:
	if dead:
		return
	hp = maxi(0,hp-amount)
	game.hud.add_log("%s recibe %d puntos de dano." % [stats.name,amount])
	aware = true
	hit_flash = 0.15
	if hp==0:
		dead = true
		collision_layer = 0
		collision_mask = 0
		game.kills += 1
		game.notify("%s derrotado" % stats.name)
		var tween := create_tween()
		tween.tween_property(sprite,"modulate:a",0.0,0.45)
		tween.tween_callback(queue_free)

func follow_route(speed: float) -> void:
	if waypoint>=route.size():
		return
	var target: Vector3 = game.dungeon.world(Vector2i(route[waypoint]))
	var direction := target-position
	direction.y = 0
	if direction.length()<0.18:
		waypoint += 1
	else:
		velocity = direction.normalized()*speed
		facing = Vector2(direction.x,direction.z).normalized()

func choose_wander_route() -> void:
	wander_timer = rng.randf_range(2.0,5.0)
	var origin: Vector2i = game.dungeon.cell(home)
	for attempt in range(8):
		var destination := origin+Vector2i(rng.randi_range(-4,4),rng.randi_range(-4,4))
		if not game.dungeon.walkable(destination):
			continue
		var candidate: PackedVector2Array = game.dungeon.path(position,game.dungeon.world(destination))
		if candidate.size()>1 and candidate.size()<=14:
			route = candidate
			waypoint = 1
			return

