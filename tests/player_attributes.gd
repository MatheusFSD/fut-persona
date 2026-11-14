extends SceneTree
const PROFILE = preload("res://scripts/player_data.gd")
const ROSTER = preload("res://scripts/roster_loader.gd")
var game
var actor
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func neutral() -> void:
	for key in PROFILE.ATTRIBUTE_KEYS: actor.set(key,70)
	actor.reset_at(Vector3(0,.05,0)); actor.cooldown = 0; actor.stamina = 1
	game.phase = "playing"; game._drop_carrier(); game.kick_lock = 0; game.release_guard = 0
	game.released_by = null; game.clear_reception(); game.recent_shot_time = 0
	game.ball.freeze = true; game.ball.position = Vector3(.72,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.controlled = actor; game.spectator = false
func measure_kick(kind: String, rating: int) -> Vector3:
	neutral(); actor.set("chute" if kind == "shot" else "passe",rating)
	await physics_frame; await physics_frame
	game.ball.freeze = false
	await physics_frame; await physics_frame
	game.strike(actor,Vector3(20,0,0),kind,1.0)
	await physics_frame
	return game.ball.linear_velocity
func run() -> void:
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROSTER.DEFAULT_PATH))
	var legacy: Dictionary = document.jogadores[0].duplicate(true)
	for key in PROFILE.ATTRIBUTE_KEYS: legacy.erase(key)
	var old = PROFILE.from_dictionary(legacy)
	for key in PROFILE.ATTRIBUTE_KEYS: check(old.get(key) == 70,"legacy record defaults to neutral "+key)
	for bad in [0,100,-5,2.5,"80",true,null,INF,NAN]: check(not PROFILE.valid_attribute(bad),"invalid ratings rejected: "+str(bad))
	for good in [1,70,99,85.0]: check(PROFILE.valid_attribute(good),"valid integer rating accepted")
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	game.juice.shot_cinematic_enabled = false; game.juice.hit_stop_enabled = false
	for p in game.players: p.set_physics_process(false); p.position.z = 12
	actor = game.players[4]
	for key in PROFILE.ATTRIBUTE_KEYS:
		actor.set(key,83); check(actor.profile.get(key) == 83,"object attribute persists to profile: "+key)
		actor.profile.set(key,62); check(actor.get(key) == 62,"profile edits immediately reach player object: "+key)
		actor.set(key,120); check(actor.get(key) == 99,"object setter clamps high rating")
		actor.set(key,-1); check(actor.get(key) == 1,"object setter clamps low rating")
	neutral(); check(is_equal_approx(actor.movement_speed(true),7.4) and is_equal_approx(actor.shot_speed(1),26),"neutral attributes preserve original speed and power")
	var low_shot: Vector3 = await measure_kick("shot",30)
	var high_shot: Vector3 = await measure_kick("shot",95)
	check(high_shot.x > low_shot.x+2 and is_equal_approx(high_shot.y,low_shot.y) and absf(high_shot.z) < .001,"shot rating changes physical launch speed and preserves mouse heading and arc")
	var low_pass: Vector3 = await measure_kick("pass",30)
	var high_pass: Vector3 = await measure_kick("pass",95)
	check(high_pass.x > low_pass.x+1 and is_equal_approx(high_pass.y,low_pass.y),"pass rating changes physical pass impulse")
	var distances: Array[float] = []; var energy: Array[float] = []
	for rating in [30,95]:
		neutral(); actor.velocidade = rating; actor.folego = rating
		Input.action_press("right"); Input.action_press("sprint")
		for frame in 60: await physics_frame; actor._physics_process(1.0/60)
		distances.append(actor.position.x); energy.append(actor.stamina)
		Input.action_release("right"); Input.action_release("sprint")
	check(distances[1] > distances[0]+.7,"higher speed moves farther through actual player physics")
	check(energy[1] > energy[0],"higher stamina rating spends less energy during a sprint")
	neutral(); actor.folego = 30; var low_recovery: float = actor.stamina_recovery()
	actor.folego = 95; check(actor.stamina_recovery() > low_recovery,"stamina rating improves regeneration")
	neutral(); actor.defesa = 30; actor.request_tackle(false); var slow: float = actor.cooldown
	neutral(); actor.defesa = 95; actor.request_tackle(false)
	check(actor.cooldown < slow,"defence rating shortens actual tackle recovery")
	neutral(); actor.tecnica = 30; game.take_possession(actor); actor.request_dribble(Vector3.BACK)
	var cost_low: float = 1-actor.stamina; var cooldown_low: float = actor.dribble.cooldown
	neutral(); actor.tecnica = 95; game.take_possession(actor); actor.request_dribble(Vector3.BACK)
	check(1-actor.stamina < cost_low and actor.dribble.cooldown < cooldown_low,"technique makes actual cuts cheaper and more agile")
	var goalie = game.players[5]; goalie.reflexos = 30
	var delay: float = goalie.goalkeeper.reaction_seconds()
	goalie.reflexos = 95
	check(goalie.goalkeeper.reaction_seconds() < delay,"goalkeeper reflexes reduce baseline reaction time")
	goalie.goalkeeper.threat_speed = 26
	check(goalie.goalkeeper.reaction_seconds() > delay,"strong shot penalty remains effective against high reflexes")
	var event := InputEventKey.new(); event.physical_keycode = KEY_I; event.pressed = true
	check(event.is_action_pressed("attributes"),"physical I key maps to the attributes action")
	game._unhandled_input(event); await process_frame
	check(game.show_attributes,"I opens the selected player's attribute sheet")
	game.queue_free(); await process_frame; await process_frame
	print("PLAYER_ATTRIBUTES ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
