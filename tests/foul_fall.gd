extends SceneTree
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)

func setup(team: int) -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.elapsed = 30; game.kick_lock = 0; game.pending_restart.clear()
	game.ball.freeze = true; game.ball.position = Vector3(5,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	for actor in game.players:
		actor.set_physics_process(false); actor.reset_at(game.formation(actor.team,actor.slot)); actor.contact_done = false
	var p = game.players[team*5+4]; var victim = game.players[(1-team)*5+4]
	p.reset_at(Vector3(0,.05,0)); p.facing = Vector3.RIGHT; p.cooldown = 0
	victim.reset_at(Vector3(.6,.05,0)); victim.facing = Vector3.LEFT
	game.controlled = game.players[4]; game.ball.freeze = false
	p.request_tackle(true); game.challenge(p,true)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.juice.set_process(false); game.muted = true
	for team in 2:
		setup(team)
		var offender = game.players[team*5+4]; var victim = game.players[(1-team)*5+4]
		var at: Vector3 = victim.position; var ball_at: Vector3 = game.ball.position
		check(game.phase == "foul" and not game.live(),"contact stops live play before restart: "+str(team))
		check(victim.current_clip == "football/Hit_Knockback" and victim.fall_time == 0,"victim immediately uses original knockdown: "+str(team))
		check(offender.action == "slide" and offender.contact_done,"offender finishes one slide rather than becoming idle")
		check(victim.position == Vector3(.6,.05,0) and game.ball.position == Vector3(5,.25,0),"no participant or ball teleports to free-kick formation at contact")
		check(game.carrier == null and game.ball.freeze and game.pending_restart.team == 1-team,"foul cannot steal ball and award is reserved for victim")
		check(game.juice.slide.active and game.juice.slide.direction == (1 if team == 0 else -1),"same cinematic runs in either team's direction")
		check(game.juice.slide.origin.distance_to(Vector3(.3,.70,0)) < .01,"cinematic centers on foul contact rather than distant ball")
		check(game.hud.reactions.size() == 1 and game.hud.reactions[0].kind == "foul","foul reaction replaces clean NA BOLA reaction")
		var serial: int = game.juice.slide.serial
		game.challenge(offender,true)
		check(game.juice.slide.serial == serial,"contact cannot repeat cinematic or foul")
		check(not victim.request_kick("shot",Vector3(24,0,0),1) and not victim.request_tackle(true),"fallen player cannot kick or slide")
		game.juice._process(.14); game._update_camera(0)
		check(is_equal_approx(Engine.time_scale,.3) and game.camera.fov < 32 and absf(game.camera.rotation.y) > .1,"same slow motion, zoom and Y orbit apply to foul")
		var remaining: float = game.phase_timer; var fall_age: float = victim.fall_time
		game.toggle_pause(); victim._physics_process(.3); game._physics_process(.3); game.juice._process(.3)
		check(game.phase == "paused" and game.phase_timer == remaining and victim.fall_time == fall_age and victim.animation_tree.get("parameters/Rate/scale") == 0,"pause freezes foul clock, fall and animation")
		game.toggle_pause(); victim._physics_process(.1)
		check(game.phase == "foul" and victim.fall_time > fall_age and is_equal_approx(victim.animation_tree.get("parameters/Rate/scale"),victim.FALL_RATE),"resume continues knockdown without restarting it")
		game.juice._process(.62*Engine.time_scale); game._update_camera(0)
		check(Engine.time_scale == 1 and game.juice.slide.active,"normal speed resumes while foul camera returns")
		game.juice._process(.4); game._update_camera(0)
		check(not game.juice.slide.active and is_zero_approx(game.camera.rotation.y),"foul camera orbit is fully undone")
		victim._physics_process(.6)
		check(victim.current_clip == "football/LayToIdle" and victim.position.distance_to(at) < .15,"original get-up follows knockdown at contact location")
		check(game.ball.position == ball_at and game.elapsed == 30,"ball and match clock stay stopped during foul presentation")
		victim._physics_process(1.2)
		check(victim.fall_time < 0 and victim.stun == 0,"get-up ends before arranging free kick")
		game._physics_process(remaining+.01)
		check(game.phase == "restart" and game.restart_team == 1-team and game.pending_restart.is_empty(),"presentation commits a single free kick to fouled team")
		check(game.carrier == victim and game.restart_taker == victim and victim.fall_time < 0,"recovered victim is ready with ball at feet")
		game._physics_process(1.16)
		check(game.phase == "set_piece" and game.ball.freeze and game.can_play_ball(victim),"free kick awaits ordinary shot or pass with ready possession")
	# Validate both source clips on every current model/build/height, without editing rig or mesh.
	for actor in game.players:
		actor.reset_at(game.formation(actor.team,actor.slot))
		var rig: Skeleton3D = actor.avatar.find_children("*","Skeleton3D",true,false)[0]
		var pelvis := rig.find_bone("pelvis")
		actor.animator.play("football/Hit_Knockback"); actor.animator.seek(.7,true); actor.animator.pause()
		rig.force_update_all_bone_transforms(); var low := rig.get_bone_global_pose(pelvis).origin
		actor.animator.play("football/LayToIdle"); actor.animator.seek(1.53,true); actor.animator.pause()
		rig.force_update_all_bone_transforms(); var high := rig.get_bone_global_pose(pelvis).origin
		check(low.is_finite() and high.is_finite() and high.y-low.y > actor.profile.altura*.3,"original bone tracks fall and stand at metric height: "+str(actor.name))
	setup(0); game.selection_menu()
	check(Engine.time_scale == 1 and game.players[9].fall_time < 0,"menu cancels fall and cinematic")
	setup(1); game.new_match()
	check(Engine.time_scale == 1 and game.players[4].fall_time < 0 and game.phase == "restart","new match clears foul presentation")
	game.queue_free(); await process_frame; await process_frame
	check(Engine.time_scale == 1,"scene teardown restores normal time")
	print("FOUL_FALL ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
