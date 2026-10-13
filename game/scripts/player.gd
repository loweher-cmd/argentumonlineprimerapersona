extends CharacterBody3D

const Bolt = preload("res://scripts/projectile.gd")
var game: Node3D
var camera: Camera3D
var hp := 120
var mana := 80
var health_charges := 8
var mana_charges := 8
var cooldowns := [0.0,0.0,0.0,0.0]
var alive := true
var sword_flash := 0.0
var hurt_flash := 0.0
var sword_audio: AudioStreamPlayer
var magic_audio: AudioStreamPlayer
const SPEED := 4.4

func _ready() -> void:
	collision_layer = 2
	collision_mask = 5
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.5
	collider.shape = shape
	collider.position.y = 0.75
	add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.3
	camera.fov = 74
	camera.far = 65
	add_child(camera)
	camera.make_current()
	var lantern := OmniLight3D.new()
	lantern.position.y = 1.4
	lantern.light_color = Color("ffdda9")
	lantern.light_energy = 0.8
	lantern.omni_range = 12.0
	lantern.shadow_enabled = false
	add_child(lantern)
	sword_audio = AudioStreamPlayer.new()
	sword_audio.stream = preload("res://assets/sword.wav")
	sword_audio.volume_db = -14
	sword_audio.bus = "SFX"
	add_child(sword_audio)
	magic_audio = AudioStreamPlayer.new()
	magic_audio.stream = preload("res://assets/magic.wav")
	magic_audio.volume_db = -12
	magic_audio.bus = "SFX"
	add_child(magic_audio)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if not alive or not game.started or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if not alive or not game.started:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x*0.0025)
		camera.rotation.x = clampf(camera.rotation.x-event.relative.y*0.0025,-0.85,0.85)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			action(0)
	for i in range(4):
		if event.is_action_pressed("action_%d" % (i+1)):
			action(i)

func _physics_process(delta: float) -> void:
	for i in range(4):
		cooldowns[i] = maxf(0,cooldowns[i]-delta)
	sword_flash = maxf(0,sword_flash-delta)
	hurt_flash = maxf(0,hurt_flash-delta)
	if not alive or not game.started:
		return
	var direction := Input.get_vector("left","right","forward","back")
	var motion := transform.basis * Vector3(direction.x,0,direction.y)
	velocity.x = motion.x*SPEED
	velocity.z = motion.z*SPEED
	velocity.y = -2
	move_and_slide()

func aimed(range_limit: float) -> Dictionary:
	var start := camera.global_position
	var end := start-camera.global_basis.z*range_limit
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,5))

func action(index: int) -> void:
	if not alive or not game.started or cooldowns[index]>0:
		return
	match index:
		0:
			cooldowns[0] = 0.55
			sword_flash = 0.24
			sword_audio.play()
			var hit := aimed(3.0)
			if not hit.is_empty() and hit.collider.has_method("take_damage"):
				hit.collider.take_damage(22)
		1:
			if mana<10:
				game.notify("No tienes suficiente mana")
				return
			mana -= 10
			cooldowns[1] = 0.8
			magic_audio.play()
			game.hud.add_log("Lanzas Dardo magico (-10 mana).")
			var bolt := Bolt.new()
			bolt.game = game
			bolt.direction = -camera.global_basis.z
			game.add_child(bolt)
			bolt.global_position = camera.global_position-camera.global_basis.z*0.35
		2:
			if health_charges<=0 or hp>=120:
				return
			health_charges -= 1
			hp = mini(120,hp+45)
			cooldowns[2] = 1.0
			game.notify("+45 vida")
		3:
			if mana_charges<=0 or mana>=80:
				return
			mana_charges -= 1
			mana = mini(80,mana+35)
			cooldowns[3] = 1.0
			game.notify("+35 mana")

func take_damage(amount: int) -> void:
	if not alive:
		return
	hp = maxi(0,hp-amount)
	game.hud.add_log("Recibes %d puntos de dano." % amount)
	hurt_flash = 0.3
	if hp==0:
		alive = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		game.hud.death.show()
		game.hud.add_log("Has caido en el Dungeon Newbie.")
