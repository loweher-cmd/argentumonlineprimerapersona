extends Control
var game: Node3D
var map_texture: ImageTexture
var elapsed := 0.0
const CELLS := 36.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var map_image := Image.create(100,100,false,Image.FORMAT_RGBA8)
	map_image.fill(Color("100f0c"))
	for c in game.dungeon.floors:
		if game.dungeon.walkable(c):
			map_image.set_pixel(c.x-1,c.y-1,Color("797361"))
	map_texture = ImageTexture.create_from_image(map_image)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed>=0.1:
		elapsed = 0
		queue_redraw()

func _draw() -> void:
	if map_texture==null:
		return
	var player_cell := Vector2(game.player.position.x/2.0-1,game.player.position.z/2.0-1)
	var origin := (player_cell-Vector2.ONE*CELLS/2).clamp(Vector2.ZERO,Vector2.ONE*(100-CELLS))
	draw_texture_rect_region(map_texture,Rect2(Vector2.ZERO,size),Rect2(origin,Vector2.ONE*CELLS))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dead:
			continue
		var point := (Vector2(enemy.position.x/2.0-1,enemy.position.z/2.0-1)-origin)*size/CELLS
		if Rect2(Vector2(3,3),size-Vector2(6,6)).has_point(point):
			draw_circle(point,2.0,Color("ca6550"))
	var center := (player_cell-origin)*size/CELLS
	var triangle := PackedVector2Array()
	for point in [Vector2(0,-7),Vector2(4,5),Vector2(0,2),Vector2(-4,5)]:
		triangle.append(center+point.rotated(-game.player.rotation.y))
	draw_colored_polygon(triangle,Color("ffe4a1"))
