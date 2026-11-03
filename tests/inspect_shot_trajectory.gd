extends SceneTree
## Draw only paths sampled from the actual rigid body; no predicted/replaced flight.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.hud.hide()
	game.juice.shot_cinematic_enabled = false
	for p in game.players:
		p.set_physics_process(false); p.position = Vector3(-15+p.slot*4,.05,12 if p.team == 0 else -12); p.hide()
	var p = game.players[4]; p.position = Vector3(-10,.05,0)
	game.camera.position = Vector3(0,6,14); game.camera.fov = 65
	game.camera.look_at(Vector3(0,1,0))
	for row in [[.3,"FRACO",Color("ffe177")],[.7,"MÉDIO",Color("26e5ef")],[1.0,"FORTE",Color("ff55a0")]]:
		game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
		game.phase = "playing"; game.ball.freeze = true; game.ball.position = Vector3(-9.25,.25,0)
		game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
		await physics_frame; await physics_frame
		game.ball.freeze = false; game.strike(p,Vector3(20,0,0),"shot",row[0])
		var points := PackedVector3Array([game.ball.position]); var peak: Vector3 = game.ball.position
		for frame in 90:
			await physics_frame
			points.append(game.ball.position)
			if game.ball.position.y > peak.y: peak = game.ball.position
			if game.ball.linear_velocity.y < -.1 and game.ball.position.y < .29: break
		var line := MeshInstance3D.new(); var mesh := ImmediateMesh.new()
		var material := StandardMaterial3D.new(); material.albedo_color = row[2]
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP,material)
		for at in points: mesh.surface_add_vertex(at)
		mesh.surface_end(); line.mesh = mesh; game.add_child(line)
		var marker := MeshInstance3D.new(); var sphere := SphereMesh.new()
		sphere.radius = .14; sphere.height = .28; marker.mesh = sphere
		marker.material_override = material; marker.position = peak; game.add_child(marker)
		var label := Label3D.new(); label.text = "%s: %.2f m" % [row[1],peak.y]
		label.position = peak+Vector3.UP*.55; label.modulate = row[2]
		label.font_size = 48; label.pixel_size = .007
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; game.add_child(label)
	game.ball.freeze = true; game.ball.hide()
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://.runtime/shot-trajectories.png")
	game.queue_free(); await process_frame; await process_frame
	print("INSPECT_SHOT_TRAJECTORY ",error_string(result))
	quit(result)
