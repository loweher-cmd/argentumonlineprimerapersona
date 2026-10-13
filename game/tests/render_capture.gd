extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.hud.intro.hide()
	game.started = true
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	game.player.position = Vector3(152,0,140)
	game.player.rotation.y = 0
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/gameplay.png"))
	print("Rendered original wolf at original spawn for visual QA")
	quit()
