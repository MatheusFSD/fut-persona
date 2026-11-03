extends SceneTree
var game
var hud

func _initialize() -> void:
	call_deferred("run")

func frame(label: String) -> void:
	hud.queue_redraw()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/campo-"+label+".png")

func refresh_markers() -> void:
	for p in game.players:
		p.marker.visible = p == game.controlled; p.number_label.visible = p == game.controlled

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.ball.freeze = true
	hud = game.hud; hud.set_process(false); hud.hide(); game.ball.hide()
	for p in game.players: p.set_physics_process(false); p.marker.hide(); p.number_label.hide()
	game.camera.position = Vector3(43,32,44); game.camera.fov = 53
	game.camera.look_at(Vector3(0,0,0)); await frame("alambrado-completo")
	game.camera.position = Vector3(34,8,25); game.camera.fov = 53
	game.camera.look_at(Vector3(14,1.0,4)); await frame("alambrado-detalhe")
	game.camera.fov = 43; hud.show(); game.ball.show()
	for entry in [[Vector3(23.5,.24,13.5),"ESCANTEIO","escanteio-pronto"],[Vector3(-21,.24,0),"TIRO DE META","tiro-de-meta-pronto"],[Vector3(6,.05,-4),"FALTA • BOLA PARADA","falta-pronta"]]:
		game.begin_restart(0,entry[0],entry[1],false); game._physics_process(1.2)
		hud._process(.2); refresh_markers()
		await frame(entry[2])
	if "--record-out" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://.runtime/out-frames")
		game._drop_carrier(); game.clear_reception(); game.restart_taker = null
		game.phase = "playing"; game.last_touch = 1; game.message_timer = 0
		game.ball.freeze = false; game.ball.position = Vector3(23.8,.5,8)
		game.ball.linear_velocity = Vector3(16,0,0); game.set_physics_process(true)
		for i in 58:
			hud._process(.05); refresh_markers(); hud.queue_redraw()
			await process_frame; await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image(); image.resize(800,500,Image.INTERPOLATE_LANCZOS)
			image.save_png("res://.runtime/out-frames/%03d.png" % i)
		game.set_physics_process(false)
	print("FENCE_RESTART_CAPTURES_OK")
	game.queue_free(); await process_frame; await process_frame
	quit()
