extends SceneTree
var game
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func reset(power := 1.0) -> void:
	game.begin_restart(0,Vector3.ZERO,"LATERAL",false)
	game.phase = "playing"; game.restart_taker = null; game.carrier = null; game.kick_lock = 0
	game.ball.freeze = true; game.ball.position = Vector3(.75,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.score = [0,0]; game.elapsed = 20; game.controlled = game.players[4]
	game.controlled.position = Vector3(0,.05,0); game.controlled.stun = 0
	game.camera_focus = Vector3(0,.35,0); game.camera_base_fov = 43; game._update_camera(0)
	game.ball.freeze = false
	game.strike(game.controlled,Vector3(25,0,0),"shot",power)
	game.ball.linear_velocity = Vector3(24,0,0)
func step(seconds: float) -> void:
	game.juice._process(seconds*Engine.time_scale); game._update_camera(0)
func post() -> void:
	game.ball.position = Vector3(23.7,.7,3.14); game.ball_speed_before_step = 24
	var body = get_nodes_in_group("goal_frame").filter(func(n): return n.position.x > 0 and n.position.z > 3)[0]
	game._ball_contact(body); game.ball.linear_velocity = Vector3(-12,0,-6)
func net() -> void:
	game.ball.position = Vector3(25.5,.5,0); game.ball_speed_before_step = 18
	var body = get_nodes_in_group("goal_net_body").filter(func(n): return n.position.x > 0 and n.get_meta("net_panel") == 0)[0]
	game._ball_contact(body)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.juice.set_process(false); game.hud.set_process(false); game.muted = true; game.hud.hide()
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	var shot = game.juice.shot
	reset(); step(.22); var behind: Transform3D = game.camera.transform
	step(.53)
	check(shot.stage == "flight" and Engine.time_scale == 1 and shot.active,"kick ends in full-speed tracking instead of automatic zoom-out")
	check(game.camera.position.distance_to(behind.origin) < .001 and is_equal_approx(game.camera.fov,48),"kick-to-flight transition preserves camera position and lens")
	game.ball.position.x += 5; step(.25)
	check(game.camera.position.distance_to(behind.origin+Vector3(5,0,0)) < .001,"flight camera travels with actual ball")
	step(1)
	check(shot.active and shot.stage == "flight" and not game.camera.transform.is_equal_approx(game.aim_camera.transform),"long unresolved flight never snaps back at previous 1.1-second limit")
	var before: Transform3D = game.camera.transform; post(); game._update_camera(0)
	check(shot.stage == "post" and game.camera.transform.is_equal_approx(before),"woodwork starts from exact existing camera pose")
	step(.10)
	# Zoom values are artist-tunable; require a close lens rather than the old preset.
	check(is_equal_approx(Engine.time_scale,.3) and game.camera.fov >= 20 and game.camera.fov < 40 and absf(game.camera.rotation.z) > .03,"post gets close lens, slight tilt and slow motion")
	game.ball.position.x = 22.7; step(.64)
	check(shot.stage == "post" and Engine.time_scale < 1,"rebound does not cut off woodwork beat immediately")
	step(.011)
	check(shot.stage == "return" and Engine.time_scale == 1,"post rebound into pitch finishes beat then returns")
	step(.36)
	check(not shot.active and game.camera.transform.is_equal_approx(game.aim_camera.transform) and is_equal_approx(game.camera.fov,43),"return completely restores broadcast framing")
	reset(); step(.3); game.wait_for_out(1,Vector3(24,.25,8),"TIRO DE META"); step(.01)
	check(shot.stage == "return" and Engine.time_scale == 1 and game.phase_timer == game.OUT_DURATION,"direct wide shot keeps original out delay and smooth return")
	reset(); step(.75); post(); step(.1); game.wait_for_out(1,Vector3(24,.25,8),"TIRO DE META"); step(.2)
	check(shot.stage == "post" and Engine.time_scale < 1,"post-to-out keeps collision close before return")
	step(.46); check(shot.stage == "return" and Engine.time_scale == 1,"post-to-out eventually releases camera and slow motion")
	reset(); step(.75); post(); step(.15)
	var serial: int = game.hud.goal_serial
	game.goal(0)
	check(shot.stage == "post" and shot.scored and game.hud.goal_serial == serial,"post-to-goal preserves collision shot and defers overlay")
	var timer: float = game.phase_timer; game._physics_process(.5)
	check(game.phase_timer == timer and game.phase == "celebrate" and game.goal_reveal_pending,"kickoff countdown cannot consume cinematic goal hold")
	net(); var post_view: Transform3D = game.camera.transform
	check(shot.net_queued and shot.stage == "post" and game.goal_hold_elapsed == 0,"immediate net contact queues after minimum readable post beat")
	step(.04)
	check(shot.stage == "post" and game.goal_hold_elapsed == 0,"queued net does not start overlay clock while still watching post")
	post_view = game.camera.transform
	step(.02)
	check(shot.stage == "net" and shot.net_started and game.camera.transform.is_equal_approx(post_view),"post-to-net changes stages from same live camera pose")
	step(.10)
	check(game.camera.fov >= 20 and game.camera.fov < 40 and absf(game.camera.rotation.z) > .03 and Engine.time_scale < 1 and game.goal_reveal_pending,"net gets its own tilted slow-motion close")
	var goal_age: float = game.goal_hold_elapsed; var camera: Transform3D = game.camera.transform
	game.toggle_pause(); step(2)
	check(game.goal_hold_elapsed == goal_age and game.camera.transform == camera and shot.stage_age < .11,"pause freezes net close and real-time goal-reveal clock")
	game.toggle_pause(); step(.64)
	check(game.goal_reveal_pending and game.hud.goal_serial == serial and game.hud.goal_team == -1,"goal graphic stays hidden for first 0.74 seconds of net close")
	var same_serial: int = shot.serial; net()
	check(shot.serial == same_serial and shot.stage_age > .7,"second net bounce cannot restart close or countdown")
	step(.011)
	check(not game.goal_reveal_pending and game.hud.goal_serial == serial+1 and game.hud.goal_team == 0,"goal wave starts only after 0.75 real seconds watching net")
	check(Engine.time_scale == 1 and shot.stage == "return" and game.phase_timer == game.GOAL_DURATION,"overlay gets full celebration duration and smooth camera return")
	game.goal(0)
	check(game.score == [1,0] and game.hud.goal_serial == serial+1,"same goal cannot score or present twice")
	game._physics_process(2.81)
	check(game.phase == "restart" and not shot.active and Engine.time_scale == 1,"kickoff begins only after net hold and entire overlay")
	reset(.7)
	check(not shot.active,"medium shot still has no behind-kicker sequence")
	game.goal(1); net(); step(.1)
	check(shot.stage == "net" and shot.scored and game.goal_reveal_pending,"direct goal can highlight real net contact even without strong kick camera")
	step(.66)
	check(game.hud.goal_team == 1 and not game.goal_reveal_pending,"direct goal follows same delayed reveal")
	reset(); step(.08); game.goal(0); net()
	check(shot.stage == "shot" and shot.net_queued,"very short-range goal does not discard unfinished kick entry")
	step(.15)
	check(shot.stage == "net" and game.goal_hold_elapsed < .01,"short-range net clock begins with net close rather than early collision")
	reset(.7); game.goal(0); var waves: int = get_nodes_in_group("goal_net_visual")[0].impact_serial
	step(1.26); step(.75)
	check(not game.goal_reveal_pending and game.hud.goal_team == 0 and not shot.net_seen,"missing physical net contact has bounded fallback without fake net impact")
	check(get_nodes_in_group("goal_net_visual")[0].impact_serial == waves,"fallback never fabricates shader collision")
	reset(); step(.75); game.carrier = game.players[9]; step(.01)
	check(shot.stage == "return" and Engine.time_scale == 1,"interception or save resolves flight naturally")
	reset(); step(.2); game.goal(0); net(); step(.2); game.selection_menu()
	check(not game.goal_reveal_pending and not shot.active and Engine.time_scale == 1,"menu cancels all pending beats and goal reveal")
	game.queue_free(); await process_frame; await process_frame
	check(Engine.time_scale == 1,"teardown restores world speed")
	print("SHOT_SEQUENCE ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
