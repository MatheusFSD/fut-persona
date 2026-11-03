extends SceneTree
var game
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL " + label)
	else: print("PASS ", label)

func ticks(count: int) -> void:
	for i in count: await physics_frame

func place_ball(at: Vector3) -> void:
	game.ball.freeze = true; game.ball.position = at
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	await ticks(2)
	game.ball.freeze = false
	game.carrier = null; game.kick_lock = 0

func isolate() -> void:
	game.set_physics_process(false)
	for p in game.players:
		p.set_physics_process(false); p.reset_at(Vector3(-15+p.slot*4,.05,10 if p.team == 0 else -10))
	game.phase = "playing"

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.juice.slide_cinematic_enabled = false # Normal-speed physics; cinematic timing has its own suite.
	game.juice.shot_cinematic_enabled = false
	await ticks(10)
	check(game.players.size() == 10,"ten rigged players")
	check(game.players[0].avatar.scene_file_path != game.players[5].avatar.scene_file_path,"two distinct original models")
	check(game.ball is RigidBody3D,"native rigid body ball")
	check(game.players[4] is CharacterBody3D,"native character controllers")
	var animator: AnimationPlayer = game.players[4].animator
	for clip in ["football/Idle_Loop","football/Jog_Fwd_Loop","football/Sprint_Loop","football/Slide_Start","football/Slide_Loop","football/Slide_Exit","custom/shot","custom/pass","custom/tackle"]:
		check(animator.has_animation(clip),"animation "+clip)
	game.new_match(); await ticks(105)
	check(game.live(),"kickoff countdown starts match")
	isolate()
	var p = game.players[4]
	p.reset_at(Vector3(0,.05,0)); game.controlled = p
	await place_ball(Vector3(.85,.25,0))
	game._possession(.016)
	check(game.carrier == p,"ball acquired by proximity")
	p.set_physics_process(true); game.set_physics_process(true)
	Input.action_press("right"); await ticks(45); Input.action_release("right")
	var trot_distance: float = p.position.x
	print("TROT ",trot_distance," pos=",p.position," ball=",game.ball.position)
	check(trot_distance > 2.4,"human trot input moves character")
	p.reset_at(Vector3(0,.05,0)); p.stamina = 1; await place_ball(Vector3(.85,.25,0)); await ticks(2)
	Input.action_press("right"); Input.action_press("sprint"); await ticks(45)
	Input.action_release("right"); Input.action_release("sprint")
	print("SPRINT ",p.position.x," ball=",game.ball.position," carrier=",game.carrier," velocity=",p.velocity," phase=",game.phase)
	check(p.position.x > trot_distance*1.35,"sprint faster than trot")
	check(p.stamina < .95,"sprint spends stamina")
	await ticks(30); check(p.stamina > .85,"stamina recovers")
	p.set_physics_process(false); game.set_physics_process(false); p.reset_at(Vector3(0,.05,0))
	game.players[2].position = Vector3(10,.05,0)
	await place_ball(Vector3(.85,.25,0))
	game.strike(p,Vector3(10,0,0),"pass",.5); await ticks(2)
	check(game.ball.linear_velocity.x > 6,"pass applies real impulse")
	check(game.stats.passes[0] == 1,"pass statistics")
	check(game.controlled != p,"pass switches to receiver")
	await place_ball(Vector3(.85,.25,0))
	game.strike(p,Vector3(24,0,0),"shot",1); await ticks(2)
	check(game.ball.linear_velocity.x > 20,"charged shot stronger than pass")
	check(game.ball.linear_velocity.y > 2,"shot has physical loft")
	await place_ball(Vector3(.9,.25,0)); p.facing = Vector3.RIGHT; p.contact_done = false
	game.challenge(p,false); await ticks(2)
	check(game.stats.tackles[0] == 1,"standing tackle contacts ball")
	await place_ball(Vector3(1.5,.25,0)); p.contact_done = false
	game.challenge(p,true); await ticks(2)
	check(game.stats.tackles[0] == 2,"slide has longer reach")
	game.controlled = p; game.switch_player()
	check(game.controlled != p and game.controlled.team == 0,"switch selects teammate")
	# Let the native solver and goal Area3D detect a real crossing.
	game.score = [0,0]; game.phase = "playing"; game.set_physics_process(true)
	await place_ball(Vector3(22,.3,0)); game.ball.linear_velocity = Vector3(20,0,0)
	await ticks(18)
	check(game.score[0] == 1 and game.phase == "celebrate","physical ball crossing scores once")
	await ticks(20); check(game.score[0] == 1,"goal never counted twice")
	isolate(); await place_ball(Vector3(25,.3,7)); game._check_lines()
	check(game.phase == "out" and game.restart_kind != "SAÍDA DE BOLA","outside posts is no goal and waits before reset")
	game.phase = "playing"; game.last_touch = 0
	await place_ball(Vector3(3,.3,14.5)); game._check_lines()
	check(game.phase == "out" and game.restart_kind == "LATERAL" and game.restart_team == 1,"touchline awards opponent throw-in after out delay")
	game.phase = "playing"; game.last_touch = 1
	await place_ball(Vector3(24.5,.3,8)); game._check_lines()
	check(game.restart_kind == "ESCANTEIO" and game.restart_team == 0,"defender last touch awards corner")
	game.phase = "playing"; game.last_touch = 0
	await place_ball(Vector3(24.5,.3,8)); game._check_lines()
	check(game.restart_kind == "TIRO DE META" and game.restart_team == 1,"attacker last touch awards goal kick")
	game.phase = "playing"; game.toggle_pause()
	check(game.phase == "paused" and game.ball.freeze,"pause freezes ball")
	game.toggle_pause(); check(game.live() and not game.ball.freeze,"resume releases ball")
	game.elapsed = game.DURATION-.01; game.set_physics_process(true); await ticks(2)
	check(game.phase == "finished","match ends after three minutes")
	game.new_match(); check(game.score == [0,0] and game.elapsed == 0,"restart clears score and timer")
	print("REGRESSION ", checks-failures.size(),"/",checks," passed; failures=",failures)
	await ticks(60)
	game.queue_free()
	await process_frame
	OS.delay_msec(120) # Allow the real-time audio disposal queue to drain in fixed-FPS tests.
	await process_frame
	quit(0 if failures.is_empty() else 1)
