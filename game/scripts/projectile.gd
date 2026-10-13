extends Node3D
var game: Node3D
var direction := Vector3.FORWARD
var age := 0.0
var sprite: Sprite3D
var textures := []

func _ready() -> void:
	sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.014
	add_child(sprite)
	for path in game.data.spell_frames:
		textures.append(load(path))
	sprite.texture = textures[0]

func _physics_process(delta: float) -> void:
	age += delta
	var next := global_position+direction*14.0*delta
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position,next,5))
	if not hit.is_empty():
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(28)
		queue_free()
		return
	global_position = next
	sprite.texture = textures[int(age*18)%textures.size()]
	if age>3:
		queue_free()
