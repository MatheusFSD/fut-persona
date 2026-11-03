extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.runtime/shot-moment-frames")
	var seen := 0
	for team in 2:
		game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
		game.muted = true; game.set_physics_process(false)
		game.juice.reset_presentation(); game.hud.clear_reactions(); game._drop_carrier()
		game.phase = "playing"; game.message_timer = 0; game.kick_lock = 0; game.ball.freeze = true
		game.released_by = null; game.release_guard = 0; game.clear_reception(); game.collision_epoch += 1
		game.pending_restart.clear(); game.restart_taker = null; game.goal_candidates = [false,false]
		for actor in game.players:
			actor.set_physics_process(false); actor.reset_at(game.formation(actor.team,actor.slot))
			actor.position.z = -9 if actor.team == 0 else 9
		var p = game.players[team*5+4]
		var at := Vector3(9 if team == 0 else -9,.05,-3 if team == 0 else 3)
		var target := Vector3(24 if team == 0 else -24,0,0)
		var axis := (target-at); axis.y = 0; axis = axis.normalized()
		p.reset_at(at); p.facing = axis; p.avatar.rotation.y = atan2(-axis.x,-axis.z)+p.visual_offset; p.cooldown = 0
		game.controlled = p
		game.ball.position = at+axis*.75+Vector3.UP*.20
		game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
		game.take_possession(p)
		game.camera_focus = at+Vector3.UP*.35; game.camera_base_fov = 43; game._update_camera(0)
		for i in 10: await process_frame
		await physics_frame; await physics_frame
		game.ball.freeze = false; p.set_physics_process(true); game.set_physics_process(true)
		var accepted: bool = p.request_kick("shot",target,1)
		print("SHOT_STAGE team=",team," accepted=",accepted," player=",p.position," ball=",game.ball.position," carrier=",game.carrier)
		var did_shoot := false
		for i in 66:
			await process_frame
			if game.juice.shot.active: did_shoot = true
			await RenderingServer.frame_post_draw
			var screenshot := root.get_texture().get_image()
			if i in [12,22,35]: screenshot.save_png("res://qa/chute-costas-%d-%02d.png" % [team,i])
			screenshot.resize(800,500,Image.INTERPOLATE_LANCZOS)
			screenshot.save_png("res://.runtime/shot-moment-frames/%03d.png" % (team*66+i))
		if did_shoot: seen += 1
		game.set_physics_process(false); p.set_physics_process(false)
		game.queue_free(); await process_frame; await process_frame
	print("SHOT_CAPTURE ","PASS" if seen == 2 else "FAIL"," teams=",seen," frames=132")
	quit(0 if seen == 2 else 1)
