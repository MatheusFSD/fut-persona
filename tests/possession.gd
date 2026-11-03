extends SceneTree
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("PASS ",label)
	else: failures.append(label); push_error("FAIL "+label)

func ticks(count: int) -> void:
	for i in count: await physics_frame

func reset_world(receiver_at := Vector3(9,.05,1.7)) -> void:
	for action in ["left","right","up","down","sprint"]: Input.action_release(action)
	game.set_physics_process(false); game._drop_carrier(); game.clear_reception()
	game.collision_epoch += 1
	game.released_by = null; game.release_guard = 0; game.kick_lock = 0
	game.phase = "playing"; game.elapsed = 0; game.spectator = false; game.auto_switch_lock = 0
	for p in game.players:
		p.set_physics_process(false); p.reset_at(Vector3(-20+p.slot*2,.05,12 if p.team else -12))
		game.ball.remove_collision_exception_with(p)
	game.controlled = game.players[4]
	game.players[4].reset_at(Vector3(0,.05,0)); game.players[4].cooldown = 0
	game.players[2].reset_at(receiver_at); game.players[2].cooldown = 0
	game.ball.freeze = true; game.ball.position = Vector3(.75,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	await ticks(2); game.ball.freeze = false; await ticks(2)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.juice.slide_cinematic_enabled = false # Measure possession at normal speed.
	game.juice.shot_cinematic_enabled = false
	game.hud.hide(); game.muted = true
	await reset_world()
	var passer = game.players[4]; var receiver = game.players[2]
	Input.action_press("down")
	receiver.velocity = Vector3(0,0,4.5)
	receiver.set_physics_process(true); game.take_possession(passer)
	game.strike(passer,Vector3(15,0,0),"pass",.5); game.set_physics_process(true)
	check(game.receiving_player == receiver and game.controlled == receiver,"pass commits its receiver and hands over control")
	await ticks(12)
	check(receiver.position.z < 1.55,"held passer movement cannot make receiver run off the pass line")
	var waited := 0
	while game.carrier != receiver and waited < 100: await ticks(1); waited += 1
	print("HUMAN_RECEIVE ticks=",waited+12," receiver=",receiver.position," ball=",game.ball.position," carrier=",game.carrier)
	check(game.carrier == receiver,"receiver intercepts and cushions a fast pass")
	check(game.receiving_player == null,"first touch ends reception assistance")
	await ticks(60)
	check(game.carrier == receiver and game.flat_distance(receiver.position,game.ball.position) < 1.35,"ball stays controlled when receiver starts moving")
	Input.action_release("down")
	await reset_world(Vector3(9,.05,.8))
	passer = game.players[4]; receiver = game.players[2]
	game.take_possession(passer); receiver.velocity = Vector3(0,0,4.5)
	receiver.set_physics_process(true); game.set_physics_process(true)
	passer.request_kick("pass",Vector3(15,0,0),.5)
	await ticks(10)
	check(receiver.position.z < .8 and not game.receiving_flight,"AI receiver holds the incoming lane during the kick wind-up")
	game.strike(passer,Vector3(15,0,0),"pass",.5)
	await ticks(65)
	check(game.carrier == receiver,"reserved receiver completes the pass after wind-up")
	await reset_world(Vector3(3,.05,0))
	passer = game.players[4]; receiver = game.players[2]
	game.take_possession(passer); receiver.set_physics_process(true)
	game.strike(passer,Vector3(8,0,0),"pass",.5); game.set_physics_process(true)
	await ticks(12)
	check(game.carrier == receiver,"short fast pass can be trapped before 0.32 seconds")
	check(game.carrier != passer,"kicker cannot instantly recapture his own released pass")
	await reset_world(Vector3(9,.05,0))
	passer = game.players[4]; receiver = game.players[2]
	var defender = game.players[9]; defender.reset_at(Vector3(4,.05,.15))
	game.take_possession(passer); game.strike(passer,Vector3(15,0,0),"pass",.5)
	game.set_physics_process(true); await ticks(25)
	check(game.carrier == defender,"a nearer opponent can intercept the physical pass")
	check(game.receiving_player == null,"interception cancels the receiver commitment")
	await reset_world()
	var tackler = game.players[4]; var victim = game.players[9]
	victim.reset_at(Vector3(1.25,.05,0)); victim.facing = Vector3.LEFT
	game.take_possession(victim); game.controlled = tackler
	tackler.set_physics_process(true); game.set_physics_process(true)
	tackler.request_tackle(false); await ticks(20)
	check(game.carrier == tackler and tackler.contact_done,"clean standing tackle immediately wins possession")
	check(game.ball.linear_velocity.length() < 4,"standing tackle cushions instead of kicking the ball away")
	victim.cooldown = 0
	check(not victim.request_kick("shot",Vector3(-20,0,0),1),"dispossessed opponent cannot kick the winner's controlled ball")
	var shots_before: int = game.stats.shots[1]
	game.strike(victim,Vector3(-20,0,0),"shot",1); await ticks(2)
	check(game.carrier == tackler and game.stats.shots[1] == shots_before,"pending kick cannot release a ball already won by a tackle")
	await ticks(50)
	check(game.carrier == tackler and game.flat_distance(tackler.position,game.ball.position) < 1.25,"standing-tackle winner retains the ball through recovery")
	await reset_world()
	tackler = game.players[4]; victim = game.players[9]
	victim.reset_at(Vector3(1.4,.05,0)); victim.facing = Vector3.LEFT
	game.take_possession(victim); game.controlled = tackler
	tackler.set_physics_process(true); game.set_physics_process(true)
	tackler.request_tackle(true); await ticks(20)
	check(game.carrier == tackler and tackler.contact_done,"clean slide tackle wins possession rather than creating a loose ball")
	await ticks(60)
	print("SLIDE_RECOVERY carrier=",game.carrier," distance=",game.flat_distance(tackler.position,game.ball.position)," height=",game.ball.position.y)
	check(game.carrier == tackler and game.flat_distance(tackler.position,game.ball.position) < 1.5,"slide winner keeps the ball after getting up")
	await reset_world()
	tackler = game.players[4]
	game.ball.position = Vector3(.9,.3,0); game.ball.linear_velocity = Vector3(-22,0,0)
	game._possession(1.0/60); await ticks(2)
	print("FAST_TRAP carrier=",game.carrier," speed=",game.ball.linear_velocity.length()," ball=",game.ball.position)
	check(game.carrier == tackler and game.ball.linear_velocity.length() < 6,"first touch absorbs fast ground balls without a speed rejection")
	check(game.ball is RigidBody3D and not game.ball.freeze and game.ball.get_parent() == game,"grab keeps native physics and does not parent or freeze the ball")
	await reset_world()
	game.ball.position = Vector3(.9,1.5,0); game.ball.linear_velocity = Vector3(-12,0,0)
	game._possession(1.0/60)
	check(game.carrier == null,"ground-ball grab does not pull high airborne balls down")
	await reset_world()
	passer = game.players[4]; receiver = game.players[2]
	Input.action_press("down"); game.prepare_reception(passer,Vector3(15,0,0))
	check(not game.reception_command(receiver,Vector3.BACK,true).is_empty(),"existing held direction preserves reception assistance")
	game.reception_command(receiver,Vector3.ZERO,true)
	check(game.reception_command(receiver,Vector3.LEFT,true).is_empty() and game.receiving_player == null,"fresh direction after release intentionally overrides assistance")
	game.prepare_reception(passer,Vector3(15,0,0)); game.controlled = receiver; game.switch_player()
	check(game.receiving_player == null,"manual player switch cancels the reception commitment")
	Input.action_release("down")
	await reset_world()
	tackler = game.players[4]; game.take_possession(tackler)
	tackler.set_physics_process(true); game.set_physics_process(true)
	Input.action_press("right"); Input.action_press("sprint"); await ticks(45)
	Input.action_release("right"); Input.action_press("up")
	var maximum_gap := 0.0
	for i in 60:
		await ticks(1)
		maximum_gap = maxf(maximum_gap,game.flat_distance(tackler.position,game.ball.position))
	check(game.carrier == tackler and maximum_gap < 1.7,"grab remains stable through a sprint and a ninety-degree turn")
	Input.action_release("up"); Input.action_release("sprint")
	game.begin_restart(0,Vector3.ZERO,"TEST",true)
	check(game.carrier == game.restart_taker and game.receiving_player == null and game.released_by == null,"restart assigns only its taker and clears old reception state")
	check(game.ball.get_collision_exceptions().size() == 1 and game.ball.get_collision_exceptions()[0] == game.restart_taker,"restart reserves ball collision exception for its taker")
	print("POSSESSION ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.set_physics_process(false); game.phase = "finished"; await ticks(60)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
