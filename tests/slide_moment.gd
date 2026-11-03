extends SceneTree
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL "+label)

func reset() -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.kick_lock = 0; game.released_by = null; game.release_guard = 0
	game.ball.freeze = true; game.ball.position = Vector3(.7,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	for p in game.players: p.reset_at(game.formation(p.team,p.slot)); p.contact_done = false
	game.controlled = game.players[4]; game.controlled.position = Vector3(0,.05,0); game.controlled.facing = Vector3.RIGHT
	game.camera_focus = Vector3(.7,.35,0); game.camera_base_fov = 43; game._update_camera(0)
	game.ball.freeze = false

func real_step(seconds: float) -> void:
	game.juice._process(seconds*Engine.time_scale)
	game._update_camera(0)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.juice.set_process(false); game.muted = true; game.hud.hide()
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	var slide = game.juice.slide
	reset(); var p = game.controlled
	game.ball.position = Vector3(8,.25,0); game.challenge(p,true)
	check(not slide.active and Engine.time_scale == 1,"missed slide does not start cinematic")
	reset(); game.challenge(game.controlled,false)
	check(not slide.active,"standing tackle has no slow-motion cinematic")
	reset(); game.players[9].position = Vector3(.6,.05,0); game.ball.position = Vector3(8,.25,0)
	game.challenge(game.controlled,true)
	check(game.phase == "foul" and slide.active and game.players[9].fall_time == 0,"foul starts same cinematic with victim knockdown before free kick")
	reset(); p = game.controlled
	game.take_possession(p); game.challenge(p,true)
	check(not slide.active,"sliding onto own controlled ball cannot repeatedly trigger cinematic")
	reset(); p = game.controlled
	var victim = game.players[9]; victim.position = Vector3(1.2,.05,0); game.take_possession(victim)
	var serial: int = slide.serial
	game.challenge(p,true)
	check(slide.active and slide.serial == serial+1 and game.carrier == p,"successful slide starts cinematic after ball is won")
	game.challenge(p,true)
	check(slide.serial == serial+1,"same tackle cannot restart effect")
	check(not game.juice.slide_tackle(p,game.ball.global_position),"other contact cannot interrupt current return envelope")
	var ball_at: Vector3 = game.ball.position; var velocity: Vector3 = game.ball.linear_velocity
	var cursor := Vector2(940,460); var expected: Vector3 = game.mouse_aim(p,cursor)
	var original: Transform3D = game.camera.transform
	real_step(.14)
	check(is_equal_approx(Engine.time_scale,.30) and is_equal_approx(slide.age,.14),"world slows to 30 percent using unscaled cinematic age")
	check(game.camera.fov < 32 and game.camera.position.distance_to(original.origin) > 3,"camera noticeably zooms and orbits the tackle")
	check(absf(game.camera.rotation.y) > .1 and absf(game.camera.rotation.z) > .02,"Y rotation and slight Dutch tilt are present")
	check(absf(game.camera.rotation.x-original.basis.get_euler().x) > .04,"camera adds a small pitch inclination")
	check(absf(game.camera.h_offset)+absf(game.camera.v_offset) > .002,"cinematic includes gentle screen shake")
	check(game.mouse_aim(p,cursor).distance_to(expected) < .002 and not game.aim_camera.current,"cinematic keeps stable input projection and single render camera")
	check(game.ball.position == ball_at and game.ball.linear_velocity == velocity,"camera envelope does not teleport or push ball")
	real_step(.60)
	check(slide.active and is_equal_approx(Engine.time_scale,.30) and is_equal_approx(slide.age,.74),"slow motion remains active at 0.74 real seconds")
	game.toggle_pause(); var age: float = slide.age; var view: Transform3D = game.camera.transform
	real_step(.5)
	check(slide.age == age and game.camera.transform == view,"pause freezes cinematic clock and camera")
	game.toggle_pause(); real_step(.011)
	check(is_equal_approx(Engine.time_scale,1) and slide.active and game.camera.fov < 33,"normal world speed returns after 0.75 seconds while camera begins zoom-out")
	var fov: float = game.camera.fov; real_step(.17)
	check(game.camera.fov > fov and game.camera.fov < 43 and absf(game.camera.rotation.y) < .25,"return smoothly opens lens and undoes orbit")
	real_step(.20)
	check(not slide.active and is_equal_approx(Engine.time_scale,1) and is_equal_approx(game.camera.fov,43),"camera return ends and restores normal speed")
	check(game.camera.transform.is_equal_approx(original) and is_zero_approx(game.camera.h_offset) and is_zero_approx(game.camera.v_offset),"return removes all rotations and shake without drift")
	reset(); p = game.controlled; game.challenge(p,true); real_step(.2)
	game.begin_restart(0,Vector3(5,.05,0),"FALTA • BOLA PARADA",false)
	check(not slide.active and Engine.time_scale == 1,"restart always restores global speed")
	reset(); game.challenge(game.controlled,true); real_step(.2); game.selection_menu()
	check(not slide.active and Engine.time_scale == 1,"selection clears slow motion")
	reset(); game.challenge(game.controlled,true); real_step(.2); game.goal(0); game.juice._process(.01)
	check(not slide.active and Engine.time_scale == 1 and game.phase == "celebrate","goal cancels old slow motion before celebration")
	reset(); game.juice.slide_cinematic_enabled = false; game.challenge(game.controlled,true)
	check(not slide.active,"cinematic can be configured off")
	game.juice.slide_cinematic_enabled = true
	reset(); Engine.time_scale = .8; game.challenge(game.controlled,true); real_step(.2)
	check(is_equal_approx(Engine.time_scale,.24),"slow motion respects preexisting world speed")
	game.juice.reset_presentation()
	check(is_equal_approx(Engine.time_scale,.8),"cancel restores previous speed rather than assuming one")
	Engine.time_scale = 1
	reset(); game.challenge(game.controlled,true); real_step(.2)
	game.queue_free(); await process_frame; await process_frame
	check(is_equal_approx(Engine.time_scale,1),"freeing scene cannot leave engine slowed")
	print("SLIDE_MOMENT ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
