extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	game.phase = "playing"; game.message_timer = 0; game.kick_lock = 0; game.ball.freeze = true
	for actor in game.players:
		actor.set_physics_process(false); actor.position.z = -8 if actor.team == 0 else 8
	var p = game.players[4]; var victim = game.players[9]
	game.controlled = p
	p.reset_at(Vector3(-.4,.05,0)); p.facing = Vector3.RIGHT; p.avatar.rotation.y = PI/2; p.cooldown = 0
	victim.reset_at(Vector3(.3,.05,0)); victim.facing = Vector3.LEFT; victim.avatar.rotation.y = -PI/2
	game.ball.position = Vector3(4,.25,0)
	game.camera_focus = Vector3(0,.35,0); game.camera_base_fov = 43; game._update_camera(0)
	for i in 12: await process_frame
	game.ball.freeze = false; p.set_physics_process(true); game.set_physics_process(true); p.request_tackle(true)
	DirAccess.make_dir_recursive_absolute("res://.runtime/foul-fall-frames")
	var fell := false; var rose := false; var prepared := false
	for i in 105:
		await process_frame
		if game.phase == "foul": victim.set_physics_process(true); fell = true
		if victim.current_clip == "football/LayToIdle": rose = true
		if game.phase == "restart": prepared = true
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		if i in [15,28,48,70]: screenshot.save_png("res://qa/falta-carrinho-%02d.png" % i)
		screenshot.resize(800,500,Image.INTERPOLATE_LANCZOS)
		screenshot.save_png("res://.runtime/foul-fall-frames/%03d.png" % i)
	print("FOUL_CAPTURE ","PASS" if fell and rose and prepared else "FAIL"," fall=",fell," get_up=",rose," free_kick=",prepared)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if fell and rose and prepared else 1)
