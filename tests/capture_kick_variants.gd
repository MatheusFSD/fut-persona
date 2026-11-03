extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.runtime/kick-variants-frames")
	var frame := 0
	for row in [["FRACO","custom/shot",.19,.4],["MÉDIO","kicks/Kick_Medium",.22,.7],["FORTE","kicks/Kick_Strong",.27,1.0]]:
		game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
		game.set_physics_process(false); game.juice.shot_cinematic_enabled = false; game.muted = true; game.hud.hide()
		game.phase = "playing"; game.ball.freeze = true; game.kick_lock = 0
		for actor in game.players: actor.set_physics_process(false); actor.hide()
		var p = game.players[4]; p.show(); p.marker.hide(); p.number_label.hide()
		p.position = Vector3(0,.03,0); p.facing = Vector3.BACK; p.avatar.rotation.y = 0
		game.camera.fov = 34; game.camera.position = Vector3(3.5,2.1,5.3); game.camera.look_at(Vector3(0,.9,0))
		game.ball.position = Vector3(0,.22,.72); game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
		var overlay := CanvasLayer.new(); game.add_child(overlay)
		var title := Label.new(); title.position = Vector2(45,35); title.text = "CHUTE "+row[0]
		title.add_theme_font_override("font",game.hud.font); title.add_theme_font_size_override("font_size",48)
		title.add_theme_color_override("font_color",[Color("2ce3ed"),Color("ffdf70"),Color("fa489e")][frame/44])
		title.add_theme_color_override("font_outline_color",Color("10101c")); title.add_theme_constant_override("outline_size",10); overlay.add_child(title)
		for i in 4: await process_frame
		var kicked := false
		for i in 44:
			var age := maxf(0,i/30.0-.16)
			p.animator.play(row[1],0); p.animator.seek(minf(age,p.animator.current_animation_length),true); p.animator.pause()
			if age >= row[2] and not kicked:
				game.ball.freeze = false; game.strike(p,Vector3(0,0,20),"shot",row[3]); kicked = true
			await process_frame; await RenderingServer.frame_post_draw
			var screenshot := root.get_texture().get_image(); screenshot.resize(800,500,Image.INTERPOLATE_LANCZOS)
			screenshot.save_png("res://.runtime/kick-variants-frames/%03d.png" % frame); frame += 1
		game.queue_free(); await process_frame; await process_frame
	print("KICK_VARIANT_CAPTURE PASS frames=",frame)
	quit()
