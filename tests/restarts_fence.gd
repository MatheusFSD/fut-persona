extends SceneTree
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL "+label)

func ticks(count: int) -> void:
	for i in count: await physics_frame

func mouse(button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new(); event.button_index = button; event.pressed = pressed
	event.position = Vector2(950,420); Input.parse_input_event(event)

func setup(team: int, spot: Vector3, kind: String) -> void:
	for action in ["left","right","up","down","sprint"]: Input.action_release(action)
	for p in game.players: p.set_physics_process(false); p.reset_at(game.formation(p.team,p.slot))
	game.spectator = false; game.begin_restart(team,spot,kind,false)
	game._physics_process(1.2)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.muted = true; game.set_physics_process(false)
	for p in game.players: p.set_physics_process(false)
	var mesh_sides := get_nodes_in_group("pitch_fence_mesh")
	var walls := get_nodes_in_group("pitch_fence_body")
	check(mesh_sides.size() == 4 and walls.size() == 4,"diamond fence and native containment on all four sides")
	var triangles := 0
	for side in mesh_sides: triangles += side.mesh.surface_get_array_len(0)/3
	check(triangles < 2500 and triangles > 300,"four wire panels are a small low-poly mesh")
	check(get_nodes_in_group("pitch_fence_frame").size() == 1 and get_nodes_in_group("pitch_fence_frame")[0].multimesh.instance_count < 80,"posts and rails share one MultiMesh")
	check(walls.all(func(wall): return wall is StaticBody3D and wall.collision_mask == 4),"fence uses native ball collisions")
	game.phase = "playing"; game.elapsed = 12; game.last_touch = 0
	game.ball.freeze = false; game.ball.position = Vector3(24.5,.5,8); game.ball.linear_velocity = Vector3(12,0,0)
	game._check_lines()
	check(game.phase == "out" and game.pending_restart.kind == "TIRO DE META" and not game.ball.freeze,"out begins without freezing or teleporting ball")
	var at: Vector3 = game.ball.position
	await ticks(6)
	check(game.ball.position.distance_to(at) > .3,"native ball keeps moving after leaving the pitch")
	game._physics_process(game.OUT_DURATION-.05)
	check(game.phase == "out" and game.elapsed == 12,"out remains visible until configured delay with clock stopped")
	var remaining: float = game.phase_timer
	game.toggle_pause(); game._physics_process(.5)
	check(game.phase == "paused" and game.ball.freeze and is_equal_approx(game.phase_timer,remaining),"pause freezes outgoing ball and delay")
	game.toggle_pause(); game.last_touch = 1
	check(game.phase == "out" and not game.ball.freeze,"resume continues outgoing ball")
	game._physics_process(.06)
	check(game.phase == "restart" and game.restart_team == 1 and game.pending_restart.is_empty(),"after configured delay prepare committed restart without changing awarded team")
	check(game.carrier == game.restart_taker and game.restart_taker.is_goalkeeper() and game.ball.freeze,"goal kick already belongs to goalkeeper during preparation")
	for entry in [
		[Vector3(8,.05,-3),"FALTA • BOLA PARADA"],
		[Vector3(23.5,.24,13.5),"ESCANTEIO"],
		[Vector3(-21,.24,0),"TIRO DE META"],
		[Vector3(2,.24,13.6),"LATERAL"]]:
		setup(0,entry[0],entry[1])
		var p = game.restart_taker
		check(game.phase == "set_piece" and game.carrier == p and game.controlled == p and game.can_play_ball(p),"ready player owns ball: "+entry[1])
		check(game.ball.freeze and game.flat_distance(p.position,game.ball.position) < .9,"stationary ball is already at taker's feet: "+entry[1])
		check(not game.players[9].request_kick("shot",Vector3.ZERO,1) and not p.request_tackle(true),"only taker may kick and cannot slide while ready: "+entry[1])
		p.set_physics_process(true)
		var player_at: Vector3 = p.position; var ball_at: Vector3 = game.ball.position
		Input.action_press("right"); Input.action_press("sprint"); await ticks(12)
		Input.action_release("right"); Input.action_release("sprint")
		check(game.flat_distance(p.position,player_at) < .03 and game.ball.position.distance_to(ball_at) < .001,"movement cannot carry or lose ball before kick: "+entry[1])
		p.set_physics_process(false)
	setup(0,Vector3(4,.05,0),"FALTA • BOLA PARADA")
	var taker = game.restart_taker; taker.set_physics_process(true)
	game.toggle_pause(); game.toggle_pause()
	check(game.phase == "set_piece" and game.ball.freeze and game.carrier == taker,"pause/resume preserves prepared ownership")
	var passes: int = game.stats.passes[0]
	mouse(MOUSE_BUTTON_RIGHT,true); await ticks(2); mouse(MOUSE_BUTTON_RIGHT,false); await ticks(18)
	check(game.phase == "playing" and game.stats.passes[0] == passes+1 and not game.ball.freeze,"right click directly takes ready free-kick pass")
	check(game.ball.linear_velocity.length() > 10 and game.restart_taker == null,"ready pass releases real impulse without prior collection")
	setup(0,Vector3(9,.05,-2),"FALTA • BOLA PARADA")
	taker = game.restart_taker; taker.set_physics_process(true)
	var shots: int = game.stats.shots[0]
	mouse(MOUSE_BUTTON_LEFT,true); await ticks(22)
	check(taker.charging > .2 and game.phase == "set_piece" and game.ball.freeze,"left button charges while prepared ball stays still")
	mouse(MOUSE_BUTTON_LEFT,false); await ticks(18)
	check(game.phase == "playing" and game.stats.shots[0] == shots+1 and game.ball.linear_velocity.length() > 12,"left release directly shoots prepared ball")
	setup(1,Vector3(-23.5,.24,-13.5),"ESCANTEIO")
	taker = game.restart_taker; taker.set_physics_process(true)
	await ticks(55)
	check(game.phase == "playing" and not game.ball.freeze and game.stats.passes[1] > 0,"opponent AI takes corner without chasing stationary ball")
	setup(0,Vector3(-21,.24,0),"TIRO DE META")
	game.spectator = true; taker = game.restart_taker; taker.set_physics_process(true)
	await ticks(55)
	check(game.phase == "playing" and not game.ball.freeze,"spectator AI also takes user's goal kick")
	for p in game.players: p.set_physics_process(false)
	game.phase = "playing"; game._drop_carrier(); game.ball.freeze = false
	game.ball.position = Vector3(0,.5,15.3); game.ball.linear_velocity = Vector3(0,0,14)
	game.wait_for_out(0,Vector3(0,.24,13.6),"LATERAL")
	await ticks(20)
	check(game.ball.position.z < 16.6 and game.ball.linear_velocity.z < 0,"fence physically returns an outgoing ball")
	game.selection_menu()
	check(game.restart_taker == null and game.pending_restart.is_empty() and game.carrier == null,"selection clears pending out and taker state")
	print("RESTARTS_FENCE ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
