extends SceneTree
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)

func reset(direction := Vector3.RIGHT) -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.kick_lock = 0; game.released_by = null; game.release_guard = 0
	game.collision_epoch += 1
	var p = game.players[4]
	p.reset_at(Vector3(-10,.05,0)); p.facing = direction
	game.controlled = p; game.carrier = p
	game.ball.freeze = true; game.ball.position = p.position+direction*.75+Vector3.UP*.2
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	await physics_frame; await physics_frame
	game.ball.freeze = false

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	game.juice.shot_cinematic_enabled = false; game.juice.slide_cinematic_enabled = false
	for p in game.players:
		p.set_physics_process(false); p.reset_at(Vector3(-15+p.slot*4,.05,12 if p.team == 0 else -12))
	var shooter = game.players[4]
	var previous_peak := 0.0; var previous_range := 0.0
	for row in [[.3,.32,.5],[.7,1.2,1.6],[1.0,1.8,2.25]]:
		await reset()
		var start: Vector3 = game.ball.position
		var shots: int = game.stats.shots[0]
		game.strike(shooter,Vector3(20,0,0),"shot",row[0])
		check(game.carrier == null and not game.ball.freeze and game.ball.get_parent() == game,"shot releases native rigid body")
		var peak: float = start.y; var descending := false; var landing := -1.0
		for frame in 90:
			await physics_frame
			# Run the ordinary possession code too: it must not flatten a released shot.
			game.release_guard = maxf(0,game.release_guard-1.0/60.0)
			game._possession(1.0/60.0)
			peak = maxf(peak,game.ball.position.y)
			descending = descending or game.ball.linear_velocity.y < -.1
			if descending and game.ball.position.y < .29:
				landing = game.ball.position.x-start.x; break
		check(peak >= row[1] and peak <= row[2],"measured apex for power "+str(row[0])+": "+str(peak))
		check(peak > previous_peak and landing > previous_range,"charge raises apex and first-bounce range")
		check(landing > 2 and landing < 30 and game.stats.shots[0] == shots+1,"one shot lands naturally inside measured range")
		print("TRAJECTORY power=",row[0]," peak_center_m=",peak," first_bounce_m=",landing)
		previous_peak = peak; previous_range = landing
	# Free aiming in every horizontal direction keeps the same vertical arc.
	for direction in [Vector3.LEFT,Vector3.BACK,Vector3(1,0,1).normalized()]:
		await reset(direction)
		var start: Vector3 = game.ball.position
		game.strike(shooter,start+direction*10,"shot",.7)
		await physics_frame; await physics_frame; await physics_frame
		var velocity: Vector3 = game.ball.linear_velocity
		var horizontal := Vector3(velocity.x,0,velocity.z)
		check(horizontal.normalized().dot(direction) > .995 and velocity.y > 4,"elevated shot preserves free aim: "+str(direction))
	await reset()
	game.strike(shooter,Vector3(10,0,0),"pass",.5)
	var pass_peak := 0.0
	for frame in 35:
		await physics_frame
		pass_peak = maxf(pass_peak,game.ball.position.y)
	check(pass_peak < .35 and game.ball.position.x > -2,"passes stay low and travel firmly")
	# Changing ball gravity must still produce an arc rather than a hardcoded lift.
	game.ball.gravity_scale = .5
	await reset()
	game.strike(shooter,Vector3(20,0,0),"shot",1)
	var scaled_peak := 0.0
	for frame in 50:
		await physics_frame
		scaled_peak = maxf(scaled_peak,game.ball.position.y)
	check(scaled_peak > 1.7 and scaled_peak < 2.3,"launch calculation respects the ball gravity scale")
	game.ball.gravity_scale = 1
	game.queue_free(); await process_frame; await process_frame
	print("SHOT_TRAJECTORY ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
