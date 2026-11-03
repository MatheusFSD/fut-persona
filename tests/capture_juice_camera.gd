extends SceneTree
var game

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.ball.freeze = true; game.phase = "playing"
	game.hud.set_process(false); game.juice.set_process(false)
	for p in game.players:
		p.set_physics_process(false); p.marker.visible = p == game.controlled; p.number_label.visible = p == game.controlled
	game.controlled.position = Vector3(0,.05,0); game.controlled.avatar.rotation.y = PI/2
	DirAccess.make_dir_recursive_absolute("res://.runtime/juice-frames")
	var displacement := 0.0
	for stage in 2:
		game.juice.reset_presentation(); game.hud.clear_reactions()
		game.ball.position = Vector3(.75,.25,0) if stage == 0 else Vector3(23.7,.6,3.4)
		game.camera_focus = Vector3(.75,.35,0) if stage == 0 else Vector3(19,.35,3.4)
		game.camera_base_fov = 43; game._update_camera(0)
		game.flash("CÂMERA / CHUTE FORTE" if stage == 0 else "CÂMERA / NA TRAVE",1.2)
		for i in 36:
			if i == 4:
				game.juice.impact("power" if stage == 0 else "post",game.ball.global_position)
				game.hud.push_reaction("power" if stage == 0 else "woodwork",game.ball.global_position,0)
				if stage == 0:
					game.controlled.animator.play("custom/shot"); game.controlled.animator.seek(.19,true); game.controlled.animator.pause()
			game.juice._process(1.0/30); game.hud._process(1.0/30); game._update_camera(1.0/30)
			var point: Vector3 = game.ball.global_position+Vector3(-5,1,-5)
			displacement = maxf(displacement,game.camera.unproject_position(point).distance_to(game.aim_camera.unproject_position(point)))
			game.hud.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if i == 7: image.save_png("res://qa/juicy-"+("chute" if stage == 0 else "trave")+".png")
			image.resize(800,500,Image.INTERPOLATE_LANCZOS)
			image.save_png("res://.runtime/juice-frames/%03d.png" % (stage*36+i))
	print("JUICE_CAMERA_CAPTURE frames=72 max_pixel_shift=",displacement)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if displacement > .5 and displacement < 15 else 1)
