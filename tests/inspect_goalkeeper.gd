extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var gallery := Image.create(1920,800,false,Image.FORMAT_RGBA8)
	var column := 0
	for row in [[.3,0.0,"BAIXA"],[.7,3.0,"MERGULHO"],[1.0,0.0,"SALTO"]]:
		var game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
		game.set_physics_process(false); game.muted = true; game.hud.hide(); game.spectator = true
		game.juice.shot_cinematic_enabled = false; game.juice.slide_cinematic_enabled = false
		for p in game.players:
			p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0; p.position.z = 12; p.hide()
		var actor = game.players[5]; var keeper = actor.goalkeeper
		actor.show(); actor.reset_at(Vector3(21.5,.05,0)); actor.collision_layer = 2; actor.collision_mask = 3
		actor.avatar.rotation.y = -PI/2
		game.camera.position = Vector3(15.5,3.1,7); game.camera.fov = 38; game.camera.look_at(Vector3(21.5,1,1))
		var layer := CanvasLayer.new(); game.add_child(layer)
		var title := Label.new(); title.text = row[2]; title.position = Vector2(30,25)
		title.add_theme_font_size_override("font_size",40); title.add_theme_color_override("font_outline_color",Color.BLACK)
		title.add_theme_constant_override("outline_size",8); layer.add_child(title)
		var shooter = game.players[4]; shooter.position = Vector3(12,.05,0)
		game.phase = "playing"; game.ball.freeze = true; game.ball.position = Vector3(12.75,.25,0)
		game.ball.linear_velocity = Vector3.ZERO; await physics_frame; await physics_frame
		game.ball.freeze = false; game.strike(shooter,Vector3(25,0,row[1]),"shot",row[0]); actor.set_physics_process(true)
		var before := false; var contact := false
		for frame in 100:
			await physics_frame
			game.release_guard = maxf(0,game.release_guard-1.0/60); game._possession(1.0/60)
			if not before and keeper.defending() and keeper.age > .1:
				await process_frame; await RenderingServer.frame_post_draw
				var shot := root.get_texture().get_image(); shot.resize(640,400,Image.INTERPOLATE_LANCZOS)
				gallery.blit_rect(shot,Rect2i(0,0,640,400),Vector2i(column*640,0)); before = true
			if keeper.saves > 0:
				game.toggle_pause(); title.text = row[2]+" — CONTATO"
				await process_frame; await RenderingServer.frame_post_draw
				var shot := root.get_texture().get_image()
				shot.save_png("res://.runtime/goalkeeper-"+str(column)+".png")
				shot.resize(640,400,Image.INTERPOLATE_LANCZOS)
				gallery.blit_rect(shot,Rect2i(0,0,640,400),Vector2i(column*640,400)); contact = true; break
		if not before or not contact: push_error("Missing rendered save: "+row[2]); quit(1); return
		game.queue_free(); await process_frame; await process_frame; column += 1
	gallery.save_png("res://.runtime/goalkeeper-defenses.png")
	print("INSPECT_GOALKEEPER PASS 6 frames")
	quit()
