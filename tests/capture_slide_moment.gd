extends SceneTree
var game
var frames := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.muted = true; game.phase = "playing"; game.message_timer = 0; game.kick_lock = 0
	game.set_physics_process(false)
	game.ball.freeze = true
	for actor in game.players:
		actor.set_physics_process(false)
		actor.position.z = -8 if actor.team == 0 else 8
	var p = game.players[4]; var victim = game.players[9]
	game.controlled = p
	p.reset_at(Vector3(-.4,.05,0)); p.facing = Vector3.RIGHT; p.avatar.rotation.y = PI/2; p.cooldown = 0
	victim.reset_at(Vector3(1.5,.05,0)); victim.facing = Vector3.LEFT; victim.avatar.rotation.y = -PI/2
	game.ball.position = Vector3(.5,.25,0); game.take_possession(victim)
	game.camera_focus = Vector3(.5,.35,0); game.camera_base_fov = 43; game._update_camera(0)
	for i in 12: await process_frame
	game.ball.freeze = false; p.set_physics_process(true); game.set_physics_process(true)
	p.request_tackle(true)
	var started := 0; var normal_at := -1.0; var ended_at := -1.0; var saw_slow := false
	var record: bool = "--record" in OS.get_cmdline_user_args()
	if record: DirAccess.make_dir_recursive_absolute("res://.runtime/slide-moment-frames")
	var deadline := Time.get_ticks_usec()+(30000000 if record else 5000000)
	while Time.get_ticks_usec() < deadline:
		await process_frame
		var slide = game.juice.slide
		if slide.active and started == 0: started = Time.get_ticks_usec()
		if started != 0:
			var age := (Time.get_ticks_usec()-started)/1000000.0
			if Engine.time_scale < 1: saw_slow = true
			if saw_slow and Engine.time_scale == 1 and normal_at < 0: normal_at = age
			if not slide.active and ended_at < 0: ended_at = age
			if record:
				await RenderingServer.frame_post_draw
				var screenshot := root.get_texture().get_image()
				if frames == 7: screenshot.save_png("res://qa/carrinho-cinematico.png")
				screenshot.resize(800,500,Image.INTERPOLATE_LANCZOS)
				screenshot.save_png("res://.runtime/slide-moment-frames/%03d.png" % frames); frames += 1
			if (record and frames >= 55) or (not record and age > 1.65): break
	var valid: bool = normal_at > .65 and normal_at < .85 and ended_at > 1.0 and ended_at < 1.25
	if record: valid = frames == 55 and not game.juice.slide.active
	valid = valid and game.juice.slide.serial == 1 and Engine.time_scale == 1
	if record: print("SLIDE_CAPTURE ","PASS" if valid else "FAIL"," frames=",frames)
	else: print("SLIDE_REALTIME ","PASS" if valid else "FAIL"," slow_seconds=",normal_at," return_end=",ended_at)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if valid else 1)
