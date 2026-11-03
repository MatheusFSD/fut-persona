extends SceneTree
var game
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func reset(axis := Vector3.RIGHT, team := 0, at := Vector3.ZERO) -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.kick_lock = 0; game.released_by = null; game.release_guard = 0
	game.pending_restart.clear(); game.hud.clear_reactions()
	for p in game.players: p.reset_at(game.formation(p.team,p.slot)); p.contact_done = false
	game.controlled = game.players[team*5+4]; game.controlled.position = at+Vector3.UP*.05; game.controlled.facing = axis
	game.controlled.cooldown = 0
	game.ball.freeze = true; game.ball.position = at+axis*.75+Vector3.UP*.25
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.camera_focus = at+Vector3.UP*.35; game.camera_base_fov = 43; game._update_camera(0)
	game.ball.freeze = false
func step(seconds: float) -> void:
	game.juice._process(seconds*Engine.time_scale); game._update_camera(0)
func shoot(axis: Vector3, power := 1.0) -> void:
	game.strike(game.controlled,game.ball.position+axis*20,"shot",power)
	game.ball.linear_velocity = axis*20 # Explicit live flight for presentation-only clock steps.
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.juice.set_process(false); game.muted = true; game.hud.hide()
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	var shot = game.juice.shot
	for axis in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK,Vector3(1,0,-1).normalized()]:
		reset(axis)
		var at: Vector3 = game.controlled.global_position
		var cursor := Vector2(940,470); var expected: Vector3 = game.mouse_aim(game.controlled,cursor)
		shoot(axis,1)
		check(shot.active and shot.shot_direction.dot(axis) > .999,"real strong shot uses actual impulse direction "+str(axis))
		check(shot.origin.distance_to(at) < .001,"camera anchors to kicker at contact")
		var ball_at: Vector3 = game.ball.position; var velocity: Vector3 = game.ball.linear_velocity
		step(.22)
		check((game.camera.global_position-at).dot(axis) < -8.9,"camera reaches behind kicker on any shot direction")
		check((-game.camera.global_basis.z).dot(axis) > .9 and game.camera.position.y > 4,"lens looks forward along shot from elevated rear view")
		check(is_equal_approx(Engine.time_scale,.3) and is_equal_approx(shot.age,.22),"same short slow-motion timing")
		check(game.mouse_aim(game.controlled,cursor).distance_to(expected) < .002 and not game.aim_camera.current,"input projection remains stable through large camera move")
		check(game.ball.position == ball_at and game.ball.linear_velocity == velocity,"camera does not teleport or redirect ball")
		step(.53); var close_at: Vector3 = game.camera.position
		check(is_equal_approx(Engine.time_scale,1) and shot.active,"world returns to normal speed at 0.75 seconds")
		game.ball.position += axis*3; step(.17)
		check(game.camera.position.distance_to(close_at) > 2.9 and game.camera_fx_applied,"flight follows ball without returning to broadcast camera")
		step(.20)
		check(shot.active and shot.stage == "flight" and not game.camera.transform.is_equal_approx(game.aim_camera.transform),"unresolved shot keeps its cinematic view beyond old automatic return time")
	reset(); game.strike(game.controlled,Vector3(18,0,0),"pass",.5)
	check(not shot.active,"passes do not trigger behind-player camera")
	reset(); game.controlled.cooldown = 0; game.controlled.request_kick("shot",Vector3(24,0,0),1)
	check(not shot.active,"charging and wind-up do not trigger before foot contact")
	game.controlled.position.x = -10; shoot(Vector3.RIGHT)
	check(not shot.active,"failed kick outside ball reach has no cinematic")
	reset(); shoot(Vector3.RIGHT); step(.25); var age: float = shot.age; var view: Transform3D = game.camera.transform
	game.toggle_pause(); step(.5)
	check(shot.age == age and game.camera.transform == view,"pause freezes shot camera and clock")
	game.toggle_pause(); step(.1)
	check(shot.age > age and Engine.time_scale < 1,"resume continues shot cinematic")
	game.phase = "out"; step(.01)
	check(Engine.time_scale == 1 and shot.active and shot.stage == "return","ball out restores speed and eases camera back")
	step(.4); check(not shot.active,"out return finishes without drift")
	reset(); shoot(Vector3.RIGHT); step(.2); game.goal(0); step(.01)
	check(shot.active and shot.scored and shot.stage != "return" and game.phase == "celebrate" and game.goal_reveal_pending,"goal keeps cinematic pending until net close and delayed celebration")
	reset(); shoot(Vector3.RIGHT); step(.2); game.juice.slide_tackle(game.controlled,game.ball.global_position)
	check(not shot.active and game.juice.slide.active and Engine.time_scale == 1,"clean tackle takes priority and restores time before its own slow motion")
	check(not game.juice.shot_kick(game.controlled,Vector3.RIGHT),"shot cannot interrupt tackle cinematic")
	reset(); shoot(Vector3.RIGHT); step(.2); game.players[9].position = Vector3(.5,.05,0)
	game.begin_slide_foul(game.controlled,game.players[9])
	check(not shot.active and game.juice.slide.active and game.phase == "foul","foul cinematic also takes priority without stacking time scales")
	reset(); game.juice.shot_cinematic_enabled = false; shoot(Vector3.RIGHT)
	check(not shot.active,"shot cinematic can be switched off independently")
	game.juice.shot_cinematic_enabled = true
	reset(); shoot(Vector3.RIGHT); step(.2); game.selection_menu()
	check(not shot.active and Engine.time_scale == 1,"selection menu cancels shot camera and global slow motion")
	reset(); shoot(Vector3.RIGHT); step(.2); game.begin_restart(0,Vector3.ZERO,"LATERAL",false)
	check(not shot.active and Engine.time_scale == 1,"restart clears shot cinematic")
	reset(Vector3.FORWARD,1,Vector3(22,0,13)); shoot(Vector3.FORWARD); step(.22)
	check(absf(game.camera.position.x) <= 26.001 and absf(game.camera.position.z) <= 15.601 and (game.camera.position-game.controlled.position).dot(Vector3.FORWARD) < 0,"rear camera stays inside cage near field edge for second team")
	reset(); game.begin_restart(0,Vector3(8,0,0),"FALTA",false); game._physics_process(1.16)
	game.strike(game.restart_taker,Vector3(24,0,0),"shot",1)
	check(shot.active and game.phase == "playing" and not game.ball.freeze,"free-kick shot also starts camera after native ball release")
	game.queue_free(); await process_frame; await process_frame
	check(Engine.time_scale == 1,"teardown never leaves global slow motion")
	print("SHOT_MOMENT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
