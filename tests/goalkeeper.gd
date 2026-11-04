extends SceneTree
var game
var keeper
var actor
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func ticks(count: int) -> void:
	for i in count: await physics_frame
func setup(side: int) -> void:
	if game != null:
		game.queue_free(); await process_frame; await process_frame
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.spectator = true
	game.juice.shot_cinematic_enabled = false; game.juice.slide_cinematic_enabled = false
	for p in game.players:
		p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0; p.position.z = 12
	actor = game.players[side*5]; keeper = actor.goalkeeper
	actor.reset_at(Vector3(-keeper.attack()*21.5,.05,0)); actor.collision_layer = 2; actor.collision_mask = 3
	game.phase = "playing"; game.ball.freeze = true; game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
func shoot(power: float, z := 0.0, start := 12.0) -> void:
	var toward: float = -keeper.attack()
	var shooter = game.players[(1-actor.team)*5+4]
	shooter.position = Vector3(toward*start,.05,0)
	game.ball.position = shooter.position+Vector3(toward*.75,.2,0)
	await ticks(2)
	game.ball.freeze = false
	game.strike(shooter,Vector3(toward*25,0,z),"shot",power)
	# Test physical reach in isolation; power-shot delay has its own suite.
	game.recent_shot_time = 0
	actor.set_physics_process(true); game.set_physics_process(true)
func proof(label: String) -> void:
	check(not keeper.last_contact.is_empty(),"actual glove evidence exists: "+label)
	if keeper.last_contact.is_empty(): return
	check(keeper.last_contact.distance <= game.BALL_RADIUS+keeper.GLOVE_RADIUS+.0001,"save lies within physical ball/glove radii: "+label)
	check(keeper.last_contact.ball.distance_to(keeper.last_contact.hand) <= .3801,"stored positions independently confirm contact: "+label)
	check(not game.ball.freeze and game.ball.get_parent() == game,"ball remains free native rigid body: "+label)
func run() -> void:
	# Real physics, both attack directions, varied model and player heights.
	for side in 2:
		for entry in [[.3,0.0,"low"],[.7,3.0,"dive_right"],[.7,-3.0,"dive_left"],[1.0,0.0,"high"]]:
			await setup(side); await shoot(entry[0],entry[1])
			var states: Array[int] = []; var highest: float = actor.position.y
			for frame in 85:
				await physics_frame
				if keeper.state not in states: states.append(keeper.state)
				highest = maxf(highest,actor.position.y)
				if keeper.saves > 0: break
			var label: String = str(side)+"/"+entry[2]
			check(keeper.saves == 1 and game.score == [0,0],"reachable shot defended once: "+label)
			proof(label)
			if entry[2] == "high": check(keeper.State.JUMP in states and highest > .15,"high defense jumps physically")
			if entry[2].begins_with("dive"):
				check(keeper.State.DIVE in states,"lateral defense commits a dive")
				check(actor.body_collision.shape.height < actor.profile.altura*.7,"diving body collider follows the lowered torso")
			if entry[2] == "low":
				check(keeper.holding and game.carrier == actor,"low shot caught with hands")
				check(keeper.feet.size() == 2 and keeper.feet.all(func(foot): return foot.y > .02),"low crouch keeps both feet above the pitch")
				await ticks(24)
				var midpoint: Vector3 = (keeper.hands[0]+keeper.hands[1])*.5
				check(keeper.holding and game.ball.position.distance_to(midpoint) < .35,"physical spring holds ball near actual gloves")
				var passes: int = game.stats.passes[side]
				await ticks(90)
				check(not keeper.holding and game.carrier != actor and game.stats.passes[side] == passes+1,"AI releases one throw after catch and recovers")
			print("KEEPER_CASE ",label," states=",states," contact=",keeper.last_contact," saves=",keeper.saves)
	# Prediction compared with the native free flight, not a copy of its equation.
	await setup(1); actor.collision_layer = 0; actor.collision_mask = 0
	game.ball.position = Vector3(13,.3,.2); await ticks(2)
	game.ball.freeze = false; game.ball.linear_velocity = Vector3(24,7,2)
	var prediction: Dictionary = keeper.predict_plane(21)
	check(not prediction.is_empty() and prediction.time > 0,"incoming ball predicts positive interception time")
	var before: Vector3 = game.ball.position; var crossing := Vector3.ZERO
	for frame in 60:
		await physics_frame
		var at: Vector3 = game.ball.position
		if at.x >= 21:
			crossing = before.lerp(at,inverse_lerp(before.x,at.x,21)); break
		before = at
	check(not prediction.is_empty() and crossing.distance_to(prediction.get("point",Vector3.ZERO)) < .15,"predicted point agrees with actual gravity and air damping")
	game.ball.linear_velocity = Vector3(-24,0,0)
	check(keeper.predict_plane(21).is_empty(),"outgoing ball is not an incoming threat")
	# The old body-proximity capture must not award a save or possession.
	game.ball.position = actor.position+Vector3(-.9,.7,0); game.ball.linear_velocity = Vector3(24,0,0)
	game.recent_shot_team = 0; game.recent_shot_time = 2
	game._possession(.016); game.take_possession(actor)
	check(game.carrier == null and keeper.saves == 0,"fast shot cannot be captured by body proximity or direct possession call")
	# Sweep a fast native ball across the real gloves in a single physics step.
	# Both endpoint positions miss the glove: only continuous contact can save it.
	await setup(1); actor.collision_layer = 0; actor.collision_mask = 0
	actor.avatar.rotation.y = -PI/2
	keeper.intercept = actor.position+Vector3(-.5,1.2,0); keeper.change(keeper.State.REACH)
	actor._animate(); actor.animation_tree.tick(.15,false); keeper.finish(.15)
	var hand: Vector3 = keeper.hands[0]
	game.ball.position = hand-Vector3(.75,0,0); await ticks(2)
	keeper.sample_epoch = -1; keeper.finish(0)
	var from: Vector3 = game.ball.position
	game.ball.freeze = false; game.ball.linear_velocity = Vector3(90,0,0)
	for frame in 3:
		await physics_frame
		if game.ball.position.x > hand.x+.45: break
	check(from.distance_to(hand) > .38 and game.ball.position.distance_to(hand) > .38,"fast-sweep fixture misses glove at both endpoints")
	keeper.finish(1.0/60)
	check(keeper.saves == 1 and not keeper.last_contact.is_empty() and keeper.last_contact.distance <= .38,"swept glove contact catches tunneling ball")
	await ticks(2)
	check(game.ball.linear_velocity.x < 0 and not game.ball.freeze,"parry redirects fast ball physically away from goal")
	# Human goalkeeper keeps the ball, then releases once on the arm animation.
	await setup(0); game.spectator = false; await shoot(.3)
	for frame in 80:
		await physics_frame
		if keeper.holding: break
	await ticks(22)
	check(game.controlled == actor and keeper.state == keeper.State.HOLD,"hand catch transfers human control to keeper")
	var passes: int = game.stats.passes[0]
	check(actor.request_kick("pass",Vector3(0,0,0),.6),"human pass requests a hand distribution")
	await ticks(10)
	check(keeper.holding and game.stats.passes[0] == passes,"throw anticipation holds ball without early impulse")
	await ticks(12)
	check(not keeper.holding and game.carrier != actor and game.stats.passes[0] == passes+1,"arm contact releases exactly one physical throw")
	await ticks(35)
	check(game.stats.passes[0] == passes+1 and actor.action.is_empty(),"throw recovery cannot release a second ball")
	# Late corner shot: reaction and finite reach must permit a real goal.
	await setup(1); actor.position.z = -2.8
	game.ball.position = Vector3(20,1.1,2.8); await ticks(2)
	game.ball.freeze = false; game.ball.linear_velocity = Vector3(30,0,0)
	game.recent_shot_team = 0; game.recent_shot_time = 2
	actor.set_physics_process(true); game.set_physics_process(true)
	await ticks(25)
	check(game.score[0] == 1 and keeper.saves == 0 and keeper.last_contact.is_empty(),"late unreachable shot scores without an invented save")
	# Ball over the crossbar: don't jump or save a trajectory outside the goal.
	await setup(1); game.ball.position = Vector3(13,6,0); await ticks(2)
	game.ball.freeze = false; game.ball.linear_velocity = Vector3(26,0,0)
	actor.set_physics_process(true); game.set_physics_process(true)
	var attempted := false
	for frame in 25:
		await physics_frame
		attempted = attempted or keeper.state in [keeper.State.REACH,keeper.State.DIVE,keeper.State.JUMP]
	check(not attempted and keeper.saves == 0,"above-goal trajectory does not trigger a defense")
	# Pause and menu must cancel no contact and preserve the active jump clock.
	await setup(1); await shoot(1)
	for frame in 30:
		await physics_frame
		if keeper.state == keeper.State.JUMP: break
	var age: float = keeper.age; var at: Vector3 = actor.position; var hands: Array = keeper.hands.duplicate()
	game.toggle_pause(); await ticks(12)
	check(keeper.age == age and actor.position == at and keeper.hands == hands,"pause freezes decision, jump and IK gloves")
	game.toggle_pause(); await ticks(3)
	check(keeper.age > age and actor.position != at,"resume continues airborne defense")
	game.selection_menu()
	check(keeper.state == keeper.State.POSITION and not keeper.holding and actor.avatar.rotation.z == 0,"menu clears defense and body tilt immediately")
	game.new_match()
	check(keeper.state == keeper.State.POSITION and is_equal_approx(actor.position.y,.05),"new match restores keeper on ground")
	game.queue_free(); await process_frame; await process_frame
	print("GOALKEEPER ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
