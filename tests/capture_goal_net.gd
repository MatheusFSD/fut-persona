extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func steady_frame() -> Image:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.runtime/goal-net-frames")
	var seen := 0
	for stage in 2:
		game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
		game.muted = true; game.hud.hide(); game.phase = "set_piece"; game.ball.freeze = true
		for actor in game.players:
			actor.hide(); actor.set_physics_process(false); actor.position.z = 12; actor.collision_layer = 0; actor.collision_mask = 0
		game.ball.position = Vector3(22,.65,0) if stage == 0 else Vector3(24.7,.65,1)
		game.ball.linear_velocity = Vector3.ZERO
		for i in 8: await process_frame
		game.phase = "playing"; game.ball.freeze = false
		game.ball.linear_velocity = Vector3(18,1,0) if stage == 0 else Vector3(.4,0,12)
		var net = get_nodes_in_group("goal_net_visual").filter(func(n): return n.position.x > 0)[0]
		var did_hit := false
		for i in 72:
			await process_frame
			game.camera.position = Vector3(20.0,2.8,7.8); game.camera.look_at(Vector3(25.0,1.0,0)); game.camera.fov = 36
			if not net.hits.is_empty(): did_hit = true
			await RenderingServer.frame_post_draw
			var screenshot := root.get_texture().get_image()
			if i in [5,10,15]: screenshot.save_png("res://qa/rede-shader-%d-%02d.png" % [stage,i])
			screenshot.resize(800,500,Image.INTERPOLATE_LANCZOS)
			screenshot.save_png("res://.runtime/goal-net-frames/%03d.png" % (stage*72+i))
		if did_hit: seen += 1
		game.queue_free(); await process_frame; await process_frame
	# GPU integration: isolate net movement, then prove pause holds and rest is exact.
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.hud.hide(); game.ball.freeze = true; game.ball.hide(); game.phase = "playing"
	for district in get_nodes_in_group("rio_district"): district.set_process(false) # Isolate net pixels from ambient water motion.
	for p in game.players: p.hide(); p.set_physics_process(false)
	game.camera.position = Vector3(20.0,2.8,7.8); game.camera.look_at(Vector3(25.0,1.0,0)); game.camera.fov = 36
	var net = get_nodes_in_group("goal_net_visual").filter(func(n): return n.position.x > 0)[0]
	var rest := await steady_frame(); rest.save_png("res://qa/rede-shader-repouso.png")
	net.impact(net.to_global(Vector3(.9,1.28,0)),20,0); net.set_physics_process(false); net._physics_process(.12)
	var wave := await steady_frame(); wave.save_png("res://qa/rede-shader-onda.png")
	game.phase = "paused"; net._physics_process(.5)
	var paused := await steady_frame()
	game.phase = "playing"; net._physics_process(1.8)
	var settled := await steady_frame()
	var gpu_ok: bool = rest.get_data() != wave.get_data() and wave.get_data() == paused.get_data() and settled.get_data() == rest.get_data()
	print("NET_GPU ","PASS" if gpu_ok else "FAIL"," deforms=",rest.get_data() != wave.get_data()," pause=",wave.get_data() == paused.get_data()," returns=",settled.get_data() == rest.get_data())
	game.queue_free(); await process_frame; await process_frame
	print("GOAL_NET_CAPTURE ","PASS" if seen == 2 and gpu_ok else "FAIL"," stages=",seen," frames=144")
	quit(0 if seen == 2 and gpu_ok else 1)
