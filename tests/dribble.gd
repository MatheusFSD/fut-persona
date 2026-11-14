extends SceneTree
var game
var actor
var defender
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)

func reset(axis := Vector3.RIGHT, side := 0, distance := 1.35) -> void:
	game._drop_carrier(); game.clear_reception(); game.hud.clear_reactions()
	game.phase = "playing"; game.pending_restart.clear(); game.kick_lock = 0
	game.released_by = null; game.release_guard = 0; game.recent_shot_time = 0
	game.spectator = false
	for p in game.players:
		p.reset_at(Vector3(-10+p.slot*3,.05,10+5*p.team))
		p.cooldown = 0; p.contact_done = false
	actor = game.players[side*5+4]; defender = game.players[(1-side)*5+1]
	# Test baseline cut mechanics independently of the selected roster's ratings.
	for key in actor.profile.ATTRIBUTE_KEYS: actor.set(key,70)
	game.controlled = actor
	actor.position = Vector3(0,.05,0); actor.facing = axis; actor.stamina = 1
	defender.position = actor.position+axis*distance; defender.facing = -axis
	game.ball.freeze = true; game.ball.position = actor.position+axis*.72+Vector3.UP*.22
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.take_possession(actor)
	await physics_frame; await physics_frame
	game.ball.freeze = false

func step(count: int) -> void:
	for frame in count:
		await physics_frame
		actor._physics_process(1.0/60)
		if game.live(): game._possession(1.0/60)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	game.juice.shot_cinematic_enabled = false; game.juice.slide_cinematic_enabled = false
	for p in game.players: p.set_physics_process(false)
	check(InputMap.action_get_events("dribble").any(func(event): return event is InputEventKey and event.physical_keycode == KEY_E),"E is bound to the cut")
	for axis in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
		for side_sign in [-1,1]:
			await reset(axis,0 if axis.x >= 0 else 1)
			var lateral: Vector3 = Vector3.UP.cross(axis)*side_sign
			check(actor.request_dribble(lateral),"cut starts in each facing and lateral direction")
			check(is_equal_approx(actor.stamina,.82),"cut spends 18 percent stamina once")
			check(defender.stun == 0 and game.hud.reactions.is_empty(),"pressing cut never awards an immediate win")
			await step(23)
			check(actor.position.dot(lateral) > .8,"native movement creates a lateral cut")
			check(actor.dribble.beaten and defender.stun > 0,"physically passing the marker causes brief imbalance")
			check(game.hud.reactions.any(func(event): return event.kind == "dribble"),"successful cut announces ENTORTOU")
			check(game.carrier == actor and not game.ball.freeze and game.ball.get_parent() == game,"cut keeps native ball physics and possession")
			await step(8)
			check(actor.action.is_empty() and absf(actor.avatar.rotation.z) < .001,"cut ends with an upright locomotion pose")
			check(not actor.request_dribble(lateral),"cooldown prevents repeated cuts")
	await reset(Vector3.RIGHT,0,2.2)
	check(actor.request_dribble(Vector3.BACK),"cut can be attempted before reaching a distant marker")
	await step(24)
	check(defender.stun == 0 and not actor.dribble.beaten and game.hud.reactions.is_empty(),"uncrossed defender is not stunned or celebrated")
	await reset(); actor.stamina = .17
	check(not actor.request_dribble(),"exhausted player cannot cut")
	await reset(); game.phase = "set_piece"; game.restart_taker = actor
	check(not actor.request_dribble(),"set-piece taker cannot dribble before taking the restart")
	await reset(); game.phase = "paused"
	check(not actor.request_dribble(),"pause blocks new cuts")
	await reset(); game._drop_carrier()
	check(not actor.request_dribble(),"loose ball is not enough: cut requires possession")
	await reset(); actor.stun = .2
	check(not actor.request_dribble(),"stunned player cannot cut")
	await reset(); actor.action = "shot"
	check(not actor.request_dribble(),"cut cannot interrupt a kick")
	await reset(); game.ball.position.y = 1
	check(not actor.request_dribble(),"high ball cannot be cut along the ground")
	await reset(); actor.cooldown = .2
	check(not actor.request_dribble(),"recent action recovery blocks a cut")
	await reset(); game.take_possession(game.players[0])
	check(not game.players[0].request_dribble(),"goalkeeper cannot use field-player cuts")
	await reset(); actor.request_dribble(Vector3.BACK)
	await step(4)
	var at: Vector3 = actor.position; var age: float = actor.action_time; var remaining: float = actor.dribble.cooldown
	game.toggle_pause(); await step(4)
	check(actor.position == at and actor.action_time == age and actor.dribble.cooldown == remaining,"pause freezes cut movement and cooldown")
	game.toggle_pause(); await step(2)
	check(actor.action_time > age,"cut resumes after pause")
	game._drop_carrier(); await step(1)
	check(actor.action.is_empty() and actor.avatar.rotation.z == 0,"losing possession cancels cut and lean")
	await reset(); actor.request_dribble()
	defender.position = game.ball.position+Vector3(.7,0,0)
	game.challenge(defender,false); await step(1)
	check(game.carrier == defender and actor.action.is_empty(),"cut offers no immunity against a well-timed tackle")
	await reset(); defender.position.z = .4
	check(actor.request_dribble() and actor.dribble.direction.z < 0,"automatic cut chooses the side away from the marker")
	actor.reset_at(Vector3.ZERO)
	check(actor.dribble.cooldown == 0 and actor.action.is_empty(),"restart reset clears all cut state")
	await reset()
	var key := InputEventKey.new(); key.physical_keycode = KEY_E; key.pressed = true
	Input.parse_input_event(key); await step(1)
	check(actor.action == "dribble","actual E key starts the cut through the human input path")
	key = InputEventKey.new(); key.physical_keycode = KEY_E; key.pressed = false
	Input.parse_input_event(key); await step(80)
	check(actor.dribble.cooldown == 0 and actor.request_dribble(Vector3.BACK),"cut becomes available again after its cooldown")
	await reset(); game.ball.position.x = 4
	check(not actor.request_dribble(),"stale possession cannot cut a ball beyond the player's reach")
	game.queue_free(); await process_frame; await process_frame
	print("DRIBBLE ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
