extends SceneTree
var game
var hud
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL "+label)

func reset() -> void:
	game._drop_carrier(); game.clear_reception(); game.collision_epoch += 1
	game.phase = "playing"; game.message_timer = 0; game.kick_lock = 0
	game.recent_shot_time = 0; game.ball_speed_before_step = 0
	game.released_by = null; game.release_guard = 0; hud.clear_reactions()
	game.ball.freeze = true; game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	for p in game.players:
		p.reset_at(game.formation(p.team,p.slot)); p.contact_done = false
		game.ball.remove_collision_exception_with(p)
	game.controlled = game.players[4]
	game.controlled.reset_at(Vector3(0,.05,0)); game.controlled.facing = Vector3.RIGHT
	game.ball.position = Vector3(.7,.25,0)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	hud = game.hud; hud.set_process(false)
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	reset()
	var p = game.controlled; var victim = game.players[9]
	victim.reset_at(Vector3(1.1,.05,0)); game.take_possession(victim)
	game.challenge(p,true)
	check(game.carrier == p and hud.reactions.size() == 1 and hud.reactions[0].kind == "slide","clean slide creates local reaction and preserves possession")
	check(hud.reactions[0].text == "NA BOLA!" and game.message_timer == 0,"slide uses short slang instead of the upper toast")
	var origin: Vector3 = hud.reactions[0].origin
	game.challenge(p,true)
	check(hud.reactions.size() == 1,"same tackle cannot repeat its reaction")
	p.position += Vector3(5,0,0)
	check(hud.reactions[0].origin == origin,"reaction stays at event point after player leaves")
	var first: Vector2 = hud.reaction_screen_position(hud.reactions[0])
	var camera_transform: Transform3D = game.camera.transform
	game.camera.position.x += 4
	var shifted: Vector2 = hud.reaction_screen_position(hud.reactions[0])
	check(first.distance_to(shifted) > 20,"screen position follows projection of event when camera moves")
	game.camera.transform = camera_transform
	check(not hud.push_reaction("slide",origin+Vector3(.1,0,.1),0),"repeated contacts nearby are coalesced")
	check(hud.push_reaction("slide",origin+Vector3(6,0,0),1),"simultaneous distant event remains visible")
	for i in 8: hud.push_reaction("power",Vector3(i*4,0,4),0)
	check(hud.reactions.size() <= 4,"active reaction count is bounded")
	var age: float = hud.reactions[0].age
	game.phase = "paused"; hud._process(.5)
	check(hud.reactions[0].age == age,"pause freezes reaction animation")
	game.phase = "playing"; hud._process(3)
	check(hud.reactions.is_empty(),"expired visual elements are removed")
	reset(); p = game.controlled; victim = game.players[9]
	victim.reset_at(Vector3(1,.05,0)); game.take_possession(victim); game.challenge(p,false)
	check(hud.reactions.size() == 1 and hud.reactions[0].kind == "steal" and game.carrier == p,"standing steal creates its local reaction")
	reset(); p = game.controlled; victim = game.players[9]
	victim.reset_at(Vector3(.6,.05,0)); game.ball.position = Vector3(6,.25,0)
	game.challenge(p,true)
	check(game.phase == "foul" and hud.reactions.size() == 1 and hud.reactions[0].kind == "foul","foul creates reaction at contact and reserves free kick during knockdown")
	check(hud.reactions[0].origin.distance_to(Vector3(.6,.05,0)) < .01 and hud.reactions[0].detail == "FALTA / ARG","foul reaction preserves location and awarded team")
	check(game.message_timer == 0,"foul is no longer duplicated at the top")
	game.begin_restart(0,Vector3(4,.24,13.6),"LATERAL",false)
	check(hud.reactions.size() == 1 and hud.reactions[0].kind == "throw_in" and hud.reactions[0].detail == "LATERAL / BRA","throw-in is displayed at its world spot with team")
	game.begin_restart(1,Vector3(-23,.24,-13),"ESCANTEIO",false)
	check(hud.reactions[0].kind == "corner","corner uses local cut-paper event")
	game.begin_restart(0,Vector3(-21,.24,0),"TIRO DE META",false)
	check(hud.reactions[0].kind == "goal_kick","goal kick uses local cut-paper event")
	game.new_match()
	check(hud.reactions.is_empty() and game.message_timer > 0,"kickoff clears old reactions and retains its general announcement")
	reset(); p = game.controlled
	game.strike(p,Vector3(24,0,0),"shot",1)
	check(hud.reactions.size() == 1 and hud.reactions[0].kind == "power","strong shot creates WOOOOW at its origin")
	game.ball.linear_velocity = Vector3(15,0,0)
	# A save notification now requires animated glove contact, not body proximity.
	var goalie = game.players[5]; var keeper = goalie.goalkeeper
	goalie.avatar.rotation.y = -PI/2
	keeper.intercept = goalie.position+Vector3(-.5,1,0); keeper.change(keeper.State.REACH)
	goalie._animate(); goalie.animation_tree.tick(.15,false); keeper.finish(.15)
	game.ball.position = keeper.hands[0]; keeper.sample_epoch = -1; keeper.finish(.016)
	check(hud.reactions.any(func(event): return event.kind == "save"),"keeper stopping incoming shot creates MILAGRE")
	var count: int = hud.reactions.size()
	game.take_possession(game.players[5])
	check(hud.reactions.size() == count,"same save is not announced twice")
	reset()
	var posts := get_nodes_in_group("goal_frame")
	check(posts.size() == 6 and posts.all(func(node): return node is StaticBody3D),"only six existing goal-frame colliders are tagged")
	var contacts: Array = []
	game.ball.body_entered.connect(func(body):
		if body.is_in_group("goal_frame"): contacts.append(body))
	game.ball.position = Vector3(22,.7,3.4); game.ball.freeze = false
	game.ball.linear_velocity = Vector3(16,0,0)
	for i in 20: await physics_frame
	check(not contacts.is_empty() and hud.reactions.any(func(event): return event.kind == "woodwork"),"real native ball/post collision creates NA TRAVEEE")
	check(hud.reactions.filter(func(event): return event.kind == "woodwork").size() == 1,"woodwork contact does not spam duplicates")
	reset()
	var ground: Node
	for node in game.get_child(0).get_children():
		if node is StaticBody3D and not node.is_in_group("goal_frame"): ground = node; break
	game.ball.linear_velocity = Vector3(15,0,0); game._ball_contact(ground)
	check(hud.reactions.is_empty(),"ground and net contacts never pretend to be woodwork")
	game.ball.linear_velocity = Vector3.ZERO; game._ball_contact(posts[0])
	check(hud.reactions.is_empty(),"resting contact with a post produces no impact reaction")
	hud.push_reaction("slide",Vector3.ZERO,0); game.goal(0)
	check(hud.reactions.is_empty() and hud.goal_team == -1 and game.goal_reveal_pending,"goal clears local reactions while net close precedes full-screen celebration")
	game.phase = "playing"; hud.push_reaction("steal",Vector3.ZERO,0); game.selection_menu()
	check(hud.reactions.is_empty(),"leaving match clears local reactions")
	check(hud.mouse_filter == Control.MOUSE_FILTER_IGNORE,"new world effects never intercept gameplay clicks")
	print("LOCAL_REACTIONS ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
