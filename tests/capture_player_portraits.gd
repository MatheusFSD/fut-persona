extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	for player in game.players:
		player.set_physics_process(false)
		player._animate(); player.animation_tree.tick(.2,false)
		if player.goalkeeper != null: player.goalkeeper.finish(.2)
	game.hud._process(0)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/retratos-"+label+".png")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.ball.freeze = true
	await capture("menu-brasil")
	game.hud.team_choices[0].item_selected.emit(1)
	await capture("menu-brasil-adversario")
	game.hud.team_choices[0].item_selected.emit(0)
	game.phase = "playing"; game.show_attributes = true
	await capture("ficha-brasil")
	game.controlled = game.players[0]
	await capture("ficha-goleiro")
	root.size = Vector2i(960,600)
	game.phase = "menu"; game.show_attributes = false
	await capture("menu-960")
	game.queue_free(); await process_frame; await process_frame
	print("PLAYER_PORTRAIT_CAPTURES_OK"); quit()
