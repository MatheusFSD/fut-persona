extends SceneTree
var game
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func run() -> void:
	for entry in [["direto",0.0],["trave-campo",3.4],["trave-rede",3.14]]:
		game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
		game.muted = true; game.set_physics_process(false); game.phase = "set_piece"; game.ball.freeze = true
		for p in game.players:
			p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0; p.position.z = 12
		var p = game.players[4]; game.controlled = p
		p.position = Vector3(20,.05,entry[1]); p.stun = 0; p.facing = Vector3.RIGHT
		game.ball.position = p.position+Vector3(.75,.2,0); game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
		game.camera_focus = p.position+Vector3.UP*.35; game.camera_base_fov = 43; game._update_camera(0)
		for i in 10: await process_frame
		await physics_frame; await physics_frame
		game.phase = "playing"; game.kick_lock = 0; game.ball.freeze = false
		game.strike(p,Vector3(30,0,entry[1]),"shot",1); game.set_physics_process(true)
		var stages: Array[String] = []; var last := ""; var net_clock := -1.0; var overlay_clock := -1.0
		var net_wall := -1.0; var overlay_wall := -1.0
		var elapsed := 0.0; var ticks := 0; var revealed := false; var previous_age := 0.0
		while ticks < 420:
			await process_frame
			ticks += 1
			var shot = game.juice.shot
			var current: String = shot.stage
			if current != last: stages.append(current); last = current
			# Fixed-FPS validation uses the director's unscaled live clock.
			if shot.active and shot.age >= previous_age: elapsed += shot.age-previous_age
			previous_age = shot.age
			if current == "net" and net_clock < 0:
				net_clock = elapsed-shot.stage_age; net_wall = Time.get_ticks_usec()/1000000.0-shot.stage_age
			if game.hud.goal_team >= 0 and overlay_clock < 0:
				overlay_clock = elapsed; overlay_wall = Time.get_ticks_usec()/1000000.0; revealed = true
			if "net" in stages and revealed and current == "idle": break
			if entry[0] == "trave-campo" and "post" in stages and current == "idle": break
			if "--inspect-sequence" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless" and shot.active and current in ["shot","post","net"] and shot.stage_age > .13 and shot.stage_age < .17:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.runtime/sequence-%s-%s.png" % [entry[0],current])
		check("shot" in stages,"actual strong kick starts behind-player stage: "+entry[0])
		if entry[0] == "direto":
			check("net" in stages and not "post" in stages,"direct native goal reaches net close without fake woodwork")
		else: check("post" in stages,"native sphere actually hits a goal-frame collider: "+entry[0])
		if entry[0] == "trave-campo":
			check(not "net" in stages and game.score == [0,0] and not revealed,"woodwork rebound returns to pitch with no goal graphic")
		else:
			check(game.score == [1,0] and "net" in stages and revealed,"native goal and net collision produce delayed overlay: "+entry[0])
			check(overlay_clock-net_clock >= .73,"overlay waits 0.75 real seconds of net close: "+entry[0]+" delay="+str(overlay_clock-net_clock))
			if "--realtime-sequence" in OS.get_cmdline_user_args():
				check(overlay_wall-net_wall > .65 and overlay_wall-net_wall < .9,"wall-clock reveal timing: "+entry[0]+" delay="+str(overlay_wall-net_wall))
			if entry[0] == "trave-rede": check(stages.find("post") < stages.find("net"),"woodwork precedes net rather than returning to broadcast")
		check(Engine.time_scale == 1 and not game.juice.shot.active,"sequence settles at normal speed: "+entry[0])
		print("LIVE_SEQUENCE ",entry[0]," stages=",stages," score=",game.score," reveal_delay=",overlay_clock-net_clock," wall_delay=",overlay_wall-net_wall)
		game.queue_free(); await process_frame; await process_frame
	print("SHOT_SEQUENCE_LIVE ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
