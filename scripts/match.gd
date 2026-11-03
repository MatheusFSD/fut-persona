extends Node3D
const PLAYER = preload("res://scripts/footballer.gd")
const STADIUM = preload("res://scripts/stadium.gd")
const HUD = preload("res://scripts/hud.gd")
const ROSTER = preload("res://scripts/roster_loader.gd")
const DURATION := 180.0
const GOAL_DURATION := 2.8
const GOAL_NET_HOLD := .75
const GOAL_NET_WAIT_LIMIT := 1.25
const OUT_DURATION := 1.5
const BALL_RADIUS := .22
const SHOT_MIN_RISE := .15
const SHOT_MAX_RISE := 2.1
const JUICE = preload("res://scripts/juice.gd")
var players: Array = []
var team_definitions: Array = []
var roster_profiles: Array = []
var team_catalog: Dictionary = {}
var match_selection: Array = []
var ball: RigidBody3D
var controlled
var carrier
var pass_target
var camera: Camera3D
var aim_camera: Camera3D
var camera_base_fov := 43.0
var camera_fx_applied := false
var juice
var hud: Control
var phase := "menu"
var phase_timer := 0.0
var elapsed := 0.0
var score := [0, 0]
var last_goal_team := -1
var last_touch := 0
var kick_lock := 0.0
var released_by
var release_guard := 0.0
var receiving_player
var receiving_from
var receiving_spot := Vector3.ZERO
var receiving_time := 0.0
var receiving_flight := false
var receive_input_released := false
var collision_epoch := 0
var message := "DOMINGO DE CLÁSSICO"
var message_timer := 0.0
var restart_team := 0
var restart_spot := Vector3.ZERO
var restart_kind := "SAÍDA DE BOLA"
var restart_taker
var restart_is_kickoff := false
var pending_restart: Dictionary = {}
var paused_from := "playing"
var paused_ball_frozen := false
var zoomed := true
var camera_focus := Vector3(0, .35, 0)
var auto_switch_lock := 0.0
var muted := false:
	set(value):
		muted = value
		if juice != null: juice.set_muted(value)
var show_help := false
var spectator := false
var chasers := [null, null]
var goal_candidates := [false, false]
var stats := {"shots": [0,0], "passes": [0,0], "tackles": [0,0]}
var rng := RandomNumberGenerator.new()
var recent_shot_team := -1
var recent_shot_time := 0.0
var ball_speed_before_step := 0.0
var goal_reveal_pending := false
var goal_hold_elapsed := -1.0
var goal_net_wait := 0.0

func _ready() -> void:
	rng.seed = 103
	_inputs()
	team_catalog = ROSTER.read_catalog()
	if team_catalog.is_empty(): set_physics_process(false); return
	match_selection = team_catalog.selection.duplicate(true)
	var roster := ROSTER.assemble_match(team_catalog,match_selection)
	if roster.is_empty(): set_physics_process(false); return
	if "--verify-roster" in OS.get_cmdline_user_args(): print("ROSTER_LOADED players=",roster.players.size()," teams=",team_catalog.teams.size()," path=",team_catalog.path)
	team_definitions = roster.teams; roster_profiles = roster.players
	var stadium = STADIUM.new(); stadium.game = self; add_child(stadium)
	_create_ball()
	_spawn_players()
	for side in [-1, 1]: _goal_sensor(side)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 43; camera.far = 160
	camera.position = camera_focus + Vector3(0, 16.5, 25)
	add_child(camera); camera.look_at(camera_focus); camera.current = true
	aim_camera = Camera3D.new(); aim_camera.name = "MiraEstavel"; aim_camera.cull_mask = 0
	add_child(aim_camera); aim_camera.current = false; camera.make_current()
	aim_camera.transform = camera.transform; aim_camera.fov = camera.fov; aim_camera.far = camera.far
	juice = JUICE.new(); juice.name = "Juice"; juice.game = self; add_child(juice); juice.set_muted(muted)
	var layer := CanvasLayer.new(); add_child(layer)
	hud = HUD.new(); hud.game = self; layer.add_child(hud)

func _spawn_players() -> void:
	for team in 2:
		for slot in 5:
			var p := PLAYER.new()
			p.setup(self, team, slot, formation(team, slot),roster_profiles[team*5+slot],team_definitions[team])
			players.append(p); add_child(p)
	controlled = players[4]

func select_match(selection: Array) -> bool:
	if phase != "menu": return false
	var roster := ROSTER.assemble_match(team_catalog,selection)
	if roster.is_empty(): return false
	juice.reset_presentation()
	collision_epoch += 1
	_drop_carrier(); clear_reception()
	ball.freeze = true; ball.linear_velocity = Vector3.ZERO; ball.angular_velocity = Vector3.ZERO
	for p in players:
		p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
		p.hide(); p.queue_free()
	players.clear(); controlled = null; released_by = null; pass_target = null
	restart_taker = null; pending_restart.clear()
	chasers = [null,null]; kick_lock = 0; release_guard = 0; auto_switch_lock = 0
	team_definitions = roster.teams; roster_profiles = roster.players
	match_selection = selection.duplicate(true)
	_spawn_players()
	if hud != null: hud.sync_selection()
	return true

func selection_menu() -> void:
	juice.reset_presentation()
	goal_reveal_pending = false; goal_hold_elapsed = -1
	get_tree().paused = false
	phase = "menu"; collision_epoch += 1
	restart_taker = null; pending_restart.clear()
	_drop_carrier(); clear_reception(); ball.freeze = true
	controlled.cancel_charge()
	for p in players:
		p.cancel_fall()
		if p.goalkeeper != null: p.goalkeeper.reset()
	score = [0,0]; elapsed = 0; message_timer = 0
	hud.sync_selection()

func _inputs() -> void:
	var mapping := {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "sprint": [KEY_SHIFT], "shoot": [KEY_SPACE], "pass": [KEY_E], "tackle": [KEY_F], "slide": [KEY_Q], "switch": [KEY_TAB], "pause": [KEY_ESCAPE, KEY_P], "start": [KEY_ENTER], "restart": [KEY_R], "mute": [KEY_M], "camera": [KEY_V], "help": [KEY_F1], "spectate": [KEY_F2]}
	for action in mapping:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for code in mapping[action]:
			var event := InputEventKey.new(); event.physical_keycode = code
			InputMap.action_add_event(action, event)
	for action in {"mouse_primary": MOUSE_BUTTON_LEFT, "mouse_secondary": MOUSE_BUTTON_RIGHT, "switch": MOUSE_BUTTON_MIDDLE}:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = {"mouse_primary": MOUSE_BUTTON_LEFT, "mouse_secondary": MOUSE_BUTTON_RIGHT, "switch": MOUSE_BUTTON_MIDDLE}[action]
		InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		if phase in ["menu", "finished"]: new_match()
		elif phase == "paused": toggle_pause()
	if event.is_action_pressed("pause") and phase in ["playing","foul","out","restart","set_piece","celebrate","paused"]: toggle_pause()
	if event.is_action_pressed("restart") and phase != "menu": new_match()
	if event.is_action_pressed("switch") and live(): switch_player()
	if event.is_action_pressed("mute"): muted = not muted
	if event.is_action_pressed("camera"): zoomed = not zoomed
	if event.is_action_pressed("help"): show_help = not show_help
	if event.is_action_pressed("spectate"):
		spectator = not spectator
		controlled.cancel_charge()
		flash("MODO TORCIDA • F2 PARA JOGAR" if spectator else "VOCÊ ESTÁ EM CAMPO", 2)

func live() -> bool:
	return phase == "playing"

func is_set_piece_taker(p) -> bool:
	return p != null and phase == "set_piece" and p == restart_taker

func team_label(side: int) -> String:
	return team_definitions[side].nome

func team_short(side: int) -> String:
	return team_definitions[side].sigla

func formation(team: int, slot: int) -> Vector3:
	var positions := [Vector3(-21.5, .05, 0), Vector3(-12, .05, 0), Vector3(-6, .05, -8), Vector3(-6, .05, 8), Vector3(-1.2, .05, 0)]
	var at: Vector3 = positions[slot]
	if team == 1: at.x = -at.x
	return at

func new_match() -> void:
	get_tree().paused = false
	score = [0, 0]; elapsed = 0; last_goal_team = -1
	stats = {"shots": [0,0], "passes": [0,0], "tackles": [0,0]}
	for p in players: p.stamina = 1.0
	controlled = players[4]
	begin_restart(0, Vector3.ZERO, "SAÍDA DE BOLA", true)

func toggle_pause() -> void:
	if phase in ["playing","foul","out","restart","set_piece","celebrate"]:
		paused_from = phase; paused_ball_frozen = ball.freeze
		phase = "paused"; ball.freeze = true; controlled.cancel_charge()
	elif phase == "paused": phase = paused_from; ball.freeze = paused_ball_frozen

func _physics_process(delta: float) -> void:
	ball_speed_before_step = ball.linear_velocity.length()
	if live(): recent_shot_time = maxf(0,recent_shot_time-delta)
	message_timer = maxf(message_timer-delta, 0)
	kick_lock = maxf(kick_lock-delta, 0)
	release_guard = maxf(release_guard-delta, 0)
	if released_by != null and release_guard <= 0:
		restore_ball_collision(released_by)
		released_by = null
	auto_switch_lock = maxf(auto_switch_lock-delta, 0)
	if phase in ["foul","out","restart","celebrate"] and not (phase == "celebrate" and goal_reveal_pending):
		phase_timer -= delta
		if phase_timer <= 0:
			if phase == "foul":
				var awarded := pending_restart.duplicate()
				begin_restart(awarded.team,awarded.spot,awarded.kind,false,false)
			elif phase == "out":
				var awarded := pending_restart.duplicate()
				begin_restart(awarded.team,awarded.spot,awarded.kind,false,false)
			elif phase == "celebrate": begin_restart(1-last_goal_team, Vector3.ZERO, "SAÍDA DE BOLA", true)
			else:
				phase = "playing" if restart_is_kickoff else "set_piece"
				ball.freeze = not restart_is_kickoff; kick_lock = 0
				restart_taker.cooldown = 0; restart_taker.brain_time = .4
				if restart_is_kickoff: restart_taker = null
				whistle()
	if live():
		elapsed += delta
		if elapsed >= DURATION:
			elapsed = DURATION; phase = "finished"; ball.freeze = true; _drop_carrier(); clear_reception(); whistle(true)
			restart_taker = null; pending_restart.clear()
		else:
			_update_reception(delta)
			_update_chasers()
			_possession(delta)
			_update_control()
			_check_lines()
			pass_target = receiving_player if receiving_time > 0 else choose_pass(controlled)
			if ball.position.y < -3: begin_restart(1-last_touch, Vector3.ZERO, "BOLA AO CHÃO", false)
	_update_camera(delta)
	Input.set_default_cursor_shape(Input.CURSOR_CROSS if live() or is_set_piece_taker(controlled) else Input.CURSOR_ARROW)
	hud.queue_redraw()

func _create_ball() -> void:
	ball = RigidBody3D.new(); ball.name = "BolaFisica"
	ball.mass = .43; ball.collision_layer = 4; ball.collision_mask = 3
	ball.continuous_cd = true; ball.contact_monitor = true; ball.max_contacts_reported = 8
	ball.linear_damp = .25; ball.angular_damp = .6
	var material := PhysicsMaterial.new(); material.friction = .75; material.bounce = .56
	ball.physics_material_override = material
	var shape := SphereShape3D.new(); shape.radius = BALL_RADIUS
	var collision := CollisionShape3D.new(); collision.shape = shape; ball.add_child(collision)
	var mesh := SphereMesh.new(); mesh.radius = BALL_RADIUS; mesh.height = BALL_RADIUS * 2
	mesh.radial_segments = 20; mesh.rings = 10
	var visual := MeshInstance3D.new(); visual.mesh = mesh
	var skin := StandardMaterial3D.new(); skin.roughness = .9
	var image := Image.create(128, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 128:
			var u := float(x) / 128; var v := float(y) / 64
			var row := int(v * 5)
			var cell := fposmod(u * 8 + (row % 2) * .5, 1.0)
			var vy := fposmod(v * 5, 1)
			var dark := pow((cell-.5)*2, 2) + pow((vy-.5)*2, 2) < .37 and (int(u*8) + row) % 3 == 0
			image.set_pixel(x, y, Color("273d39") if dark else Color("fff3d4"))
	skin.albedo_texture = ImageTexture.create_from_image(image); visual.material_override = skin
	ball.add_child(visual); ball.position = Vector3(0, .25, 0)
	add_child(ball)
	ball.body_entered.connect(_ball_contact)

func _goal_sensor(side: int) -> void:
	var area := Area3D.new(); area.name = "GolDireito" if side > 0 else "GolEsquerdo"
	area.collision_layer = 0; area.collision_mask = 4
	area.position = Vector3(side*24.75, 1.25, 0)
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new()
	shape.size = Vector3(1.4, 2.5, 6.6); collision.shape = shape; area.add_child(collision)
	add_child(area)
	area.body_entered.connect(func(body):
		if body == ball: goal_candidates[0 if side < 0 else 1] = true)
	area.body_exited.connect(func(body):
		if body == ball: goal_candidates[0 if side < 0 else 1] = false)

func _ball_contact(body: Node) -> void:
	juice.ball_fx.stop_trail()
	var impact_speed := maxf(ball.linear_velocity.length(),ball_speed_before_step)
	if phase in ["playing","out","celebrate"] and body.is_in_group("goal_net_body"):
		body.get_meta("goal_net").impact(ball.global_position,impact_speed,int(body.get_meta("net_panel")))
		if phase == "celebrate" and goal_reveal_pending and goal_hold_elapsed < 0:
			goal_hold_elapsed = 0
			juice.shot_net(ball.global_position)
	if phase in ["playing","out"] and body.is_in_group("pitch_fence_body") and impact_speed > 5:
		juice.ball_fx.contact("fence",ball.global_position,minf(impact_speed/24,1))
	if live() and body in players and impact_speed > 7:
		juice.ball_fx.contact("body",ball.global_position,minf(impact_speed/24,1))
	if live() and body.is_in_group("goal_frame") and maxf(ball.linear_velocity.length(),ball_speed_before_step) > 4:
		hud.push_reaction("woodwork",ball.global_position,last_touch)
		juice.impact("post",ball.global_position,minf(maxf(ball.linear_velocity.length(),ball_speed_before_step)/20,1))
		juice.shot_post(ball.global_position)
	if body in players:
		if body.stun > 0: return
		last_touch = body.team
		if carrier != null and carrier.team != body.team and ball.linear_velocity.length() > 6.5: _drop_carrier()
		if live() and carrier == null and kick_lock <= 0 and ball.position.y < .95 and _can_grab(body):
			take_possession(body)

func _can_grab(p) -> bool:
	if p.stun > 0 or (p == released_by and release_guard > 0): return false
	if p.goalkeeper != null and p.goalkeeper.blocks_foot_pickup(): return false
	return p.action.is_empty() or (p.action in ["tackle", "slide"] and p.contact_done)

func _drop_carrier() -> void:
	var previous = carrier
	carrier = null
	if previous != null and previous.goalkeeper != null: previous.goalkeeper.release()
	if previous != null and previous != released_by: restore_ball_collision(previous)

func restore_ball_collision(p, epoch := -1) -> void:
	if epoch < 0: epoch = collision_epoch
	if epoch != collision_epoch or not is_instance_valid(p) or not is_instance_valid(ball) or carrier == p: return
	# Re-enabling an overlapping capsule can fire the ball into the air. Wait for clearance.
	if p.stun > 0 or (flat_distance(p.position,ball.position) < .67 and ball.position.y < p.position.y+1.8):
		get_tree().create_timer(.08).timeout.connect(func(): restore_ball_collision(p,epoch))
		return
	ball.remove_collision_exception_with(p)

func take_possession(p) -> void:
	if p.goalkeeper != null and p.goalkeeper.blocks_foot_pickup(): return
	juice.ball_fx.stop_trail()
	var saved_shot: bool = carrier == null and p.goalkeeper != null and p.goalkeeper.contact_authorized and recent_shot_time > 0 and recent_shot_team != p.team and maxf(ball.linear_velocity.length(),ball_speed_before_step) > 5
	if saved_shot:
		hud.push_reaction("save",ball.global_position,p.team)
		juice.impact("save",ball.global_position,minf(maxf(ball.linear_velocity.length(),ball_speed_before_step)/24,1))
	elif live() and carrier != p and ball.linear_velocity.length() > 4.5:
		juice.ball_fx.contact("trap",ball.global_position,minf(ball.linear_velocity.length()/24,.65))
	recent_shot_time = 0
	_drop_carrier()
	carrier = p; last_touch = p.team; kick_lock = 0
	ball.add_collision_exception_with(p)
	# A first-touch impulse cushions the incoming ball, without parenting or teleporting it.
	var body_velocity: Vector3 = p.velocity; body_velocity.y = 0
	var offset: Vector3 = p.position + p.facing*.72 - ball.position; offset.y = 0
	var desired := body_velocity + offset.limit_length(1)*3.5
	desired.y = clampf(ball.linear_velocity.y, -3, -.2) if ball.position.y > .4 else minf(ball.linear_velocity.y, 0)
	if p.goalkeeper != null and p.goalkeeper.contact_authorized: desired = p.velocity
	ball.apply_central_impulse((desired-ball.linear_velocity)*ball.mass)
	ball.apply_torque_impulse(-ball.angular_velocity*(.28*ball.mass*BALL_RADIUS*BALL_RADIUS))
	p.brain_time = maxf(p.brain_time, .4)
	clear_reception()
	if p.team == 0 and not spectator: select_player(p)

func _possession(delta: float) -> void:
	if carrier != null and carrier.goalkeeper != null and carrier.goalkeeper.holding:
		carrier.goalkeeper.hold_ball(delta)
		return
	var grabbed_this_tick := false
	if carrier != null and (flat_distance(carrier.position, ball.position) > 2.2 or ball.position.y > 1.15 or carrier.stun > 0): _drop_carrier()
	if carrier == null and kick_lock <= 0 and ball.position.y < .95 and absf(ball.linear_velocity.y) < 7:
		var closest = null
		var best_score := INF
		for p in players:
			if not _can_grab(p): continue
			var d := flat_distance(p.position, ball.position)
			if d > (1.6 if p == receiving_player else 1.4): continue
			var relative: Vector3 = ball.linear_velocity-p.velocity; relative.y = 0
			if relative.length() > 29: continue
			var towards_player: Vector3 = p.position-ball.position; towards_player.y = 0
			if relative.length() > 4 and towards_player.dot(relative) < -.5: continue
			var score_value: float = d - (.12 if p == receiving_player else 0)
			if score_value < best_score: closest = p; best_score = score_value
		if closest != null: take_possession(closest); grabbed_this_tick = true
	if carrier != null and kick_lock <= 0 and not grabbed_this_tick:
		ball.add_collision_exception_with(carrier)
		var body_velocity: Vector3 = carrier.velocity; body_velocity.y = 0
		var target: Vector3 = carrier.position + carrier.facing * (.84 if carrier.sprinting else .72) + body_velocity*.035
		var ray_from: Vector3 = carrier.position + Vector3.UP*.32
		var ray_to := Vector3(target.x,ray_from.y,target.z)
		var query := PhysicsRayQueryParameters3D.create(ray_from,ray_to,2,[carrier.get_rid()])
		var obstruction := get_world_3d().direct_space_state.intersect_ray(query)
		if not obstruction.is_empty():
			target = obstruction.position - carrier.facing*(BALL_RADIUS+.12)
		var error := target - ball.position; error.y = 0
		var wanted := body_velocity + error * 11
		var correction := wanted - Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z)
		ball.apply_central_force(correction.limit_length(24) * ball.mass * 24)
		if ball.position.y > .4: ball.apply_central_force(Vector3.DOWN*ball.mass*12)
		if carrier.sprinting and rng.randf() < delta * 5: dust(carrier.position)
	# Rolling resistance with native force; gravity, bounce and collisions remain native.
	if ball.position.y < .29 and ball.linear_velocity.length() > .1:
		var rolling := Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z)
		ball.apply_central_force(-rolling * .13)

func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x-b.x, a.z-b.z).length()

func can_play_ball(p) -> bool:
	if not live() and not is_set_piece_taker(p): return false
	if carrier != null: return carrier == p
	if p == released_by and release_guard > 0: return false
	return kick_lock <= 0 and ball.position.y < 1.0 and flat_distance(p.position, ball.position) < 1.65

func select_player(next_player, lock_seconds := .6) -> void:
	if next_player == null or next_player == controlled: return
	if controlled != null: controlled.cancel_charge()
	controlled = next_player
	controlled.cancel_charge()
	controlled.control_direction = Vector3.ZERO
	auto_switch_lock = lock_seconds

func _update_control() -> void:
	if spectator: return
	# Receiving or recovering the ball takes priority over the distance cooldown.
	if carrier != null and carrier.team == 0:
		select_player(carrier)
		return
	if receiving_player == controlled and receiving_time > 0: return
	if auto_switch_lock > 0 or controlled == null: return
	# Finish an already-started kick before handing control away.
	if controlled.action in ["shot", "pass"] and not controlled.contact_done: return
	var current_distance := flat_distance(controlled.position, ball.position)
	if current_distance < 7.0: return
	var closest = null
	var best_distance := current_distance
	for p in players:
		# The keeper stays automatic until he actually controls the ball.
		if p.team != 0 or p.is_goalkeeper() or p.stun > 0: continue
		var distance := flat_distance(p.position, ball.position)
		if distance < best_distance: best_distance = distance; closest = p
	if closest != null and best_distance + 2.5 < current_distance:
		select_player(closest)

func _update_chasers() -> void:
	chasers = [null, null]
	for team in 2:
		var best := INF
		for p in players:
			if p.team != team or p.is_goalkeeper() or p.stun > 0: continue
			var d := flat_distance(p.position, ball.position)
			if d < best: best = d; chasers[team] = p

func ai_command(p, _delta: float) -> Dictionary:
	if is_set_piece_taker(p):
		if p.brain_time <= 0 and p.action.is_empty():
			var target := set_piece_target(p)
			var attack := 1.0 if p.team == 0 else -1.0
			var shot: bool = restart_kind.begins_with("FALTA") and p.position.x*attack > 12 and absf(p.position.z) < 9
			if shot: target = Vector3(25*attack,0,0)
			p.request_kick("shot" if shot else "pass",target,.75)
			p.brain_time = .5
		return {"move":Vector3.ZERO,"sprint":false}
	if p.goalkeeper != null: return p.goalkeeper.command()
	var reception := reception_command(p)
	if not reception.is_empty(): return reception
	var attack := 1.0 if p.team == 0 else -1.0
	var target: Vector3 = p.home
	var distance := flat_distance(p.position, ball.position)
	var can_decide: bool = p.brain_time <= 0
	if carrier == p:
		target = Vector3(24*attack, 0, p.position.z*.5)
		if can_decide:
			p.brain_time = rng.randf_range(.32, .65)
			var pressured := false
			for other in players:
				if other.team != p.team and flat_distance(p.position, other.position) < 2.5: pressured = true
			if p.position.x * attack > 10 and absf(p.position.z) < 10:
				p.request_kick("shot", Vector3(25*attack, 0, rng.randf_range(-2.6, 2.6)), rng.randf_range(.55, .9))
			elif pressured or rng.randf() < .18: p.request_kick("pass", pass_aim(p), .5)
	elif chasers[p.team] == p and (carrier == null or carrier.team != p.team):
		target = ball.position + ball.linear_velocity.limit_length(6) * .22
		if carrier != null and carrier.team != p.team and distance < 1.6 and can_decide:
			p.facing = (ball.position-p.position).normalized(); p.facing.y = 0
			p.request_tackle(distance > 1.25 and rng.randf() < .3)
			p.brain_time = .65
	else:
		var support: bool = carrier != null and carrier.team == p.team
		target.x = clampf(p.home.x + ball.position.x*.48 + attack*(5 if support else -1), -19, 19)
		target.z = clampf(p.home.z + ball.position.z*.25, -11.5, 11.5)
		if p.profile.posicao == 1: target.x = clampf(ball.position.x - attack*9, -17, 17)
	# Local separation helps the support players keep lanes without external pathfinding.
	var offset: Vector3 = target - p.position; offset.y = 0
	var move: Vector3 = offset.normalized() if offset.length() > .5 else Vector3.ZERO
	for other in players:
		if other == p: continue
		var away: Vector3 = p.position-other.position; away.y = 0
		if away.length() < 1.3 and away.length() > .05: move += away.normalized() * .65
	move = move.limit_length(1)
	return {"move":move, "sprint": distance > 4 and (chasers[p.team] == p or carrier == p)}

func choose_pass(p):
	if p == controlled and not spectator: return pass_receiver(p, mouse_aim(p))
	var best = null
	var best_score := -INF
	var intent: Vector3 = p.control_direction if p == controlled and not spectator and p.control_direction.length() > .25 else p.facing
	var attack := 1.0 if p.team == 0 else -1.0
	for mate in players:
		if mate == p or mate.team != p.team: continue
		var direction: Vector3 = mate.position - p.position; direction.y = 0
		var distance := direction.length()
		if distance < 2: continue
		var value: float = direction.normalized().dot(intent) * 8 - absf(distance-10)*.16 + direction.x*attack*.08
		if mate.is_goalkeeper(): value -= 2
		for other in players:
			if other.team == p.team: continue
			var nearest := Geometry3D.get_closest_point_to_segment(other.position, p.position, mate.position)
			if flat_distance(other.position, nearest) < 1.2: value -= 5
		if value > best_score: best_score = value; best = mate
	return best

func pass_aim(p) -> Vector3:
	if p == controlled and not spectator: return mouse_aim(p)
	var mate = choose_pass(p)
	if mate == null: return p.position + p.facing*9
	var lead: Vector3 = mate.velocity * .35; lead.y = 0
	return mate.position + lead

func shot_aim(p) -> Vector3:
	if p == controlled and not spectator: return mouse_aim(p)
	var attack := 1.0 if p.team == 0 else -1.0
	var aim_z: float = p.control_direction.z * 2.8 if p == controlled else 0.0
	return Vector3(25*attack, 0, clampf(aim_z, -3, 3))

func mouse_aim(p, screen_position := Vector2.INF) -> Vector3:
	if screen_position == Vector2.INF: screen_position = get_viewport().get_mouse_position()
	# Camera feedback is cosmetic: input rays use the unshaken broadcast lens.
	var projection: Camera3D = aim_camera if camera_fx_applied else camera
	var origin := projection.project_ray_origin(screen_position)
	var ray := projection.project_ray_normal(screen_position)
	var hit: Variant = Plane(Vector3.UP, .03).intersects_ray(origin, ray)
	if hit == null: return p.position + p.facing * 12
	var target: Vector3 = hit
	target.y = 0
	if flat_distance(target, p.position) < .3: return p.position + p.facing * 4
	return target

func pass_receiver(p, target: Vector3):
	# Selection follows the actual pass ray; it never bends the ball toward a teammate.
	var direction := target-ball.position; direction.y = 0; direction = direction.normalized()
	var best = null
	var best_cost := INF
	for mate in players:
		if mate == p or mate.team != p.team or mate.stun > 0 or not mate.action.is_empty(): continue
		var offset: Vector3 = mate.position-ball.position; offset.y = 0
		var along := offset.dot(direction)
		if along < 1.2 or along > 27: continue
		var lateral := (offset-direction*along).length()
		if lateral > 2.8: continue
		var cost := lateral*4 + absf(along-minf(flat_distance(ball.position,target),20))*.2
		if cost < best_cost: best_cost = cost; best = mate
	return best

func clear_reception() -> void:
	receiving_player = null; receiving_from = null
	receiving_time = 0; receiving_flight = false; receive_input_released = false

func prepare_reception(p, target: Vector3) -> void:
	clear_reception()
	var receiver = pass_receiver(p, target)
	if receiver == null: return
	receiving_player = receiver; receiving_from = p; receiving_time = 3.0
	var direction := target-ball.position; direction.y = 0; direction = direction.normalized()
	var along: float = maxf(0, (receiver.position-ball.position).dot(direction))
	receiving_spot = ball.position + direction*along; receiving_spot.y = 0
	# Brake the old support run as soon as the passer starts his wind-up.
	receiver.velocity.x *= .2; receiver.velocity.z *= .2
	receive_input_released = Input.get_vector("left","right","up","down").length() < .2

func _update_reception(delta: float) -> void:
	if receiving_player == null: return
	receiving_time -= delta
	if receiving_time <= 0 or receiving_player.stun > 0 or (carrier != null and carrier != receiving_from):
		clear_reception(); return
	if receiving_flight:
		var velocity := Vector3(ball.linear_velocity.x,0,ball.linear_velocity.z)
		var remaining: Vector3 = receiving_player.position-ball.position; remaining.y = 0
		if velocity.length() > 1 and remaining.dot(velocity.normalized()) < -1.0 and remaining.length() > 1.8:
			clear_reception()

func reception_command(p, human_move := Vector3.ZERO, human := false) -> Dictionary:
	if p != receiving_player or receiving_time <= 0 or carrier == p or p.stun > 0: return {}
	if human:
		if human_move.length() < .2: receive_input_released = true
		elif receive_input_released:
			clear_reception(); return {}
	var target := receiving_spot
	if receiving_flight:
		var velocity := Vector3(ball.linear_velocity.x,0,ball.linear_velocity.z)
		target = Geometry3D.get_closest_point_to_segment(p.position, ball.position, ball.position+velocity*1.2)
		for i in range(1,31):
			var t := i*.04
			var prediction := ball.position + velocity*((1.0-exp(-.55*t))/.55)
			if flat_distance(p.position,prediction) <= 5.8*t+.55:
				target = prediction; break
	target.x = clampf(target.x,-24,24); target.z = clampf(target.z,-14,14)
	var offset: Vector3 = target-p.position; offset.y = 0
	var move := offset.normalized()*minf(offset.length(),1.0) if offset.length() > .18 else Vector3.ZERO
	if move.length() < .2:
		var incoming: Vector3 = ball.position-p.position; incoming.y = 0
		if incoming.length() > .1: p.facing = incoming.normalized()
	return {"move":move,"sprint":offset.length() > 3.0}

func strike(p, target: Vector3, kind: String, power: float) -> void:
	var hand_release: bool = p.goalkeeper != null and p.goalkeeper.holding and p.goalkeeper.state == p.goalkeeper.State.THROW
	if (not live() and not is_set_piece_taker(p)) or flat_distance(p.position, ball.position) > 2.05 or (ball.position.y > 1.3 and not hand_release): return
	if p.stun > 0 or (carrier != null and carrier != p): return
	if is_set_piece_taker(p):
		phase = "playing"; ball.freeze = false; kick_lock = 0; restart_taker = null
	# The kicker must not immediately block his own backward or sideways launch.
	ball.add_collision_exception_with(p)
	var epoch := collision_epoch
	get_tree().create_timer(.18).timeout.connect(func():
		if is_instance_valid(ball): restore_ball_collision(p,epoch))
	var direction := target - ball.position; direction.y = 0; direction = direction.normalized()
	if kind == "pass":
		if receiving_from != p or receiving_player == null: prepare_reception(p,target)
	else: clear_reception()
	var receiver = receiving_player if kind == "pass" else null
	var speed := lerpf(15, 26, power) if kind == "shot" else clampf(16+flat_distance(ball.position, target)*.24, 18, 24)
	var vertical_speed := .35
	if kind == "shot":
		# Mouse aim chooses the horizontal heading; charge sets a ballistic arc.
		# These are rises above launch height, before native air damping.
		var charge := clampf(inverse_lerp(.3,1.0,power),0.0,1.0)
		var rise := lerpf(SHOT_MIN_RISE,SHOT_MAX_RISE,charge)
		var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))*ball.gravity_scale
		vertical_speed = sqrt(2.0*gravity*rise)
	var desired := direction*speed + Vector3.UP*vertical_speed
	ball.apply_central_impulse((desired-ball.linear_velocity) * ball.mass)
	if kind == "pass":
		# Start with matching rolling spin instead of spending the pass energy on skidding.
		var rolling_spin := Vector3(direction.z, 0, -direction.x) * speed / BALL_RADIUS
		ball.apply_torque_impulse((rolling_spin-ball.angular_velocity) * (.4*ball.mass*BALL_RADIUS*BALL_RADIUS))
	else: ball.apply_torque_impulse(Vector3(direction.z, 0, -direction.x) * .08)
	released_by = p; release_guard = .32
	_drop_carrier(); kick_lock = 0; last_touch = p.team
	if receiver != null:
		receiving_flight = true
		receiving_time = clampf(flat_distance(ball.position,receiver.position)/speed*1.5+.9,1.0,3.0)
	stats["shots" if kind == "shot" else "passes"][p.team] += 1
	if kind == "shot":
		recent_shot_team = p.team; recent_shot_time = 3.0
		if power >= PLAYER.STRONG_SHOT_MIN: juice.shot_kick(p,global_transform.basis*direction)
		if power >= .85: hud.push_reaction("power",ball.global_position,p.team)
	else: recent_shot_time = 0
	var impact_kind := "pass"
	if kind == "shot": impact_kind = "power" if power >= .85 else "shot"
	juice.impact(impact_kind,ball.global_position,.3+power*.7 if kind == "shot" else .65)
	dust(ball.position)
	if kind == "pass" and p == controlled:
		if receiver != null: select_player(receiver, .8)

func challenge(p, sliding: bool) -> void:
	if not live() or p.contact_done: return
	var reach := 1.65 if sliding else 1.18
	var delta_ball: Vector3 = ball.position-p.position; delta_ball.y = 0
	if delta_ball.length() < reach and delta_ball.normalized().dot(p.facing) > -.15 and ball.position.y < .9:
		var previous = carrier
		p.contact_done = true
		take_possession(p)
		stats.tackles[p.team] += 1; juice.impact("tackle",ball.global_position,.8 if sliding else .45); dust(p.position)
		if sliding:
			hud.push_reaction("slide",ball.global_position,p.team)
			if previous != p and (previous == null or previous.team != p.team): juice.slide_tackle(p,ball.global_position)
		elif previous != null and previous.team != p.team: hud.push_reaction("steal",ball.global_position,p.team)
		if previous != null and previous != p and previous.team != p.team:
			previous.stun = .7 if sliding else .25
			previous.cooldown = maxf(previous.cooldown, 1.2 if sliding else .8)
			previous.brain_time = maxf(previous.brain_time, .8 if sliding else .5)
			# The stunned player's standing capsule must not launch the won ball away.
			ball.add_collision_exception_with(previous)
			var epoch := collision_epoch
			get_tree().create_timer(previous.stun+.05).timeout.connect(func():
				if is_instance_valid(ball): restore_ball_collision(previous,epoch))
	elif sliding:
		for other in players:
			if other.team == p.team or other.stun > 0: continue
			var offset: Vector3 = other.position-p.position; offset.y = 0
			if offset.length() < .85 and offset.normalized().dot(p.facing) > .1:
				# Contact without getting the ball is a foul, never a free possession steal.
				p.contact_done = true
				begin_slide_foul(p,other)
				return

func begin_slide_foul(offender, victim) -> void:
	# Show contact and the original knockdown/get-up before arranging the free kick.
	juice.reset_presentation(); collision_epoch += 1
	var spot: Vector3 = victim.position
	pending_restart = {"team":victim.team,"spot":spot,"kind":"FALTA • BOLA PARADA"}
	restart_team = victim.team; restart_spot = spot; restart_kind = pending_restart.kind; restart_taker = null
	_drop_carrier(); clear_reception(); released_by = null; release_guard = 0; pass_target = null
	ball.freeze = true; recent_shot_time = 0; message_timer = 0
	for actor in players:
		actor.cancel_charge()
		if actor != offender: actor.action = ""
	victim.fall_from_tackle()
	phase = "foul"; phase_timer = victim.fall_duration()+.12
	hud.clear_reactions(); announce_restart(victim.team,spot,restart_kind)
	juice.impact("tackle",victim.global_position,.8); dust(spot); whistle()
	juice.foul_tackle(offender,victim.global_position)

func switch_player() -> void:
	clear_reception()
	var best = null; var distance := INF
	for p in players:
		if p.team != 0 or p == controlled or p.is_goalkeeper(): continue
		var d := flat_distance(p.position, ball.position)
		if d < distance: distance = d; best = p
	if best != null:
		select_player(best)

func _check_lines() -> void:
	if not live(): return
	var at := ball.position
	# Whole sphere must cross the white line, below the crossbar and between the posts.
	if absf(at.x) > 24 + BALL_RADIUS and absf(at.z) < 3.4-BALL_RADIUS and at.y < 2.5-BALL_RADIUS:
		var sensor_index := 1 if at.x > 0 else 0
		if goal_candidates[sensor_index]:
			goal(0 if at.x > 0 else 1); return
	if absf(at.z) > 14 + BALL_RADIUS:
		wait_for_out(1-last_touch,Vector3(clampf(at.x,-22.8,22.8),.24,signf(at.z)*13.6),"LATERAL")
	elif absf(at.x) > 24 + BALL_RADIUS:
		var defending := 1 if at.x > 0 else 0
		if last_touch == defending:
			wait_for_out(1-defending,Vector3(signf(at.x)*23.5,.24,(1 if at.z >= 0 else -1)*13.5),"ESCANTEIO")
		else: wait_for_out(defending,Vector3(signf(at.x)*21,.24,0),"TIRO DE META")

func wait_for_out(team: int, spot: Vector3, kind: String) -> void:
	if not live(): return
	pending_restart = {"team":team,"spot":spot,"kind":kind}
	restart_team = team; restart_spot = spot; restart_kind = kind; restart_taker = null
	phase = "out"; phase_timer = OUT_DURATION; collision_epoch += 1
	_drop_carrier(); clear_reception(); released_by = null; release_guard = 0
	ball.freeze = false; message_timer = 0; recent_shot_time = 0
	for p in players: p.cancel_charge(); p.action = ""; p.current_clip = ""
	announce_restart(team,spot,kind); whistle()

func set_piece_target(p) -> Vector3:
	var best = null; var cost := INF
	for mate in players:
		if mate == p or mate.team != p.team or mate.is_goalkeeper(): continue
		var distance := flat_distance(p.position,mate.position)
		if distance < 3: continue
		var candidate: float = distance+absf(mate.position.z)*.1
		if candidate < cost: cost = candidate; best = mate
	if best != null: return best.position
	return Vector3(0,0,0)

func goal(team: int) -> void:
	if not live(): return
	restart_taker = null; pending_restart.clear()
	score[team] += 1; last_goal_team = team; phase = "celebrate"; phase_timer = GOAL_DURATION
	_drop_carrier(); clear_reception(); controlled.cancel_charge()
	message = "GOOOL!  " + team_label(team).to_upper()
	message_timer = 0; goal_reveal_pending = true; goal_hold_elapsed = -1; goal_net_wait = 0
	hud.clear_reactions(); hud.goal_team = -1; hud.goal_age = 0
	juice.shot_goal(); juice.impact("goal",ball.global_position,1)

func _advance_goal_reveal(real_delta: float) -> void:
	if phase == "paused": return
	if phase != "celebrate": goal_reveal_pending = false; return
	if not goal_reveal_pending: return
	if goal_hold_elapsed < 0:
		goal_net_wait += real_delta
		# A goal that escapes the net still reaches its overlay; never fabricate a collision.
		if goal_net_wait >= GOAL_NET_WAIT_LIMIT: goal_hold_elapsed = 0
		return
	if juice.shot.active and juice.shot.net_seen:
		if not juice.shot.net_started: return
		if juice.shot.stage == "net": goal_hold_elapsed = juice.shot.stage_age
		elif juice.shot.stage == "net_hold": goal_hold_elapsed = juice.shot.SLOW_SECONDS+juice.shot.stage_age
		else: goal_hold_elapsed += real_delta
	else: goal_hold_elapsed += real_delta
	if goal_hold_elapsed < GOAL_NET_HOLD: return
	goal_reveal_pending = false; phase_timer = GOAL_DURATION; message_timer = GOAL_DURATION
	hud.celebrate_goal(last_goal_team); juice.shot.release()

func begin_restart(team: int, spot: Vector3, kind: String, kickoff: bool, announce := true) -> void:
	juice.reset_presentation()
	goal_reveal_pending = false; goal_hold_elapsed = -1; goal_net_wait = 0
	collision_epoch += 1
	pending_restart.clear(); restart_taker = null; restart_is_kickoff = kickoff
	recent_shot_time = 0; ball_speed_before_step = 0; hud.clear_reactions()
	phase = "restart"; phase_timer = 1.6 if kickoff else 1.15
	restart_team = team; restart_spot = spot; restart_kind = kind
	_drop_carrier(); clear_reception()
	released_by = null; release_guard = 0
	for p in players:
		ball.remove_collision_exception_with(p)
		p.cancel_fall()
		if p.goalkeeper != null: p.goalkeeper.reset()
	pass_target = null; goal_candidates = [false, false]
	ball.freeze = true
	ball.position = Vector3(spot.x, .25, spot.z)
	ball.linear_velocity = Vector3.ZERO; ball.angular_velocity = Vector3.ZERO
	var taker = players[team*5+4]
	if kickoff:
		for p in players: p.reset_at(formation(p.team, p.slot))
	else:
		var distance := INF
		for p in players:
			if kind == "TIRO DE META" and p.team == team and p.is_goalkeeper():
				taker = p; break
			if p.team == team and flat_distance(p.position, spot) < distance:
				taker = p; distance = flat_distance(p.position, spot)
		for p in players:
			if p != taker and flat_distance(p.position, spot) < 3.5:
				var away: Vector3 = (p.position-spot).normalized()
				if away.length() < .1: away = Vector3.FORWARD
				var at := spot+away*3.8; at.x = clampf(at.x,-22.5,22.5); at.z = clampf(at.z,-12.5,12.5); at.y = .05
				if flat_distance(at,spot) < 3.3:
					var inward := Vector3(-spot.x,0,-spot.z).normalized()
					if inward.length() < .1: inward = Vector3.FORWARD
					at = spot+inward*3.8; at.y = .05
				p.reset_at(at)
	var attack := 1.0 if team == 0 else -1.0
	var facing := Vector3(attack,0,0)
	if kind == "LATERAL": facing = Vector3(0,0,-signf(spot.z))
	elif kind == "ESCANTEIO": facing = Vector3(-spot.x,0,-spot.z).normalized()
	var taker_at := spot-facing*.75
	taker_at.x = clampf(taker_at.x, -24.8, 24.8); taker_at.y = .05
	taker.reset_at(taker_at)
	taker.facing = facing; taker.cooldown = 0; taker.contact_done = false
	taker.avatar.rotation.y = atan2(-facing.x,-facing.z)+taker.visual_offset
	restart_taker = taker; carrier = taker; last_touch = team
	ball.add_collision_exception_with(taker)
	if team == 0: select_player(taker)
	auto_switch_lock = .6
	kick_lock = 0
	if kickoff: flash(kind + " • " + team_label(team).to_upper(), phase_timer)
	else:
		message_timer = 0
		if announce: announce_restart(team,spot,kind)
	whistle()

func announce_restart(team: int, spot: Vector3, kind: String) -> void:
	var reaction := "drop"
	if kind.begins_with("FALTA"): reaction = "foul"
	elif kind == "LATERAL": reaction = "throw_in"
	elif kind == "ESCANTEIO": reaction = "corner"
	elif kind == "TIRO DE META": reaction = "goal_kick"
	hud.push_reaction(reaction,to_global(spot),team,kind.split(" • ")[0]+" / "+team_short(team))

func flash(text: String, time: float) -> void:
	message = text; message_timer = time

func _update_camera(delta: float) -> void:
	if phase == "paused": return
	# Lower broadcast angle, perspective depth and ball-led tracking across the pitch.
	var lead := Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).limit_length(10) * .12
	var focus := ball.position + lead
	focus.x = clampf(focus.x, -19, 19); focus.z = clampf(focus.z, -11, 11)
	focus.y = clampf(ball.position.y * .3, .35, 1.0)
	var blend := 1.0 - exp(-7.0 * delta)
	camera_focus = camera_focus.lerp(focus, blend)
	camera.position = camera_focus + Vector3(0, 16.5, 25)
	camera.look_at(camera_focus)
	camera.h_offset = 0; camera.v_offset = 0
	camera_base_fov = lerpf(camera_base_fov,43.0 if zoomed else 54.0,1.0-exp(-4.0*delta))
	camera.fov = camera_base_fov
	aim_camera.transform = camera.transform; aim_camera.fov = camera_base_fov
	aim_camera.projection = camera.projection; aim_camera.size = camera.size; aim_camera.far = camera.far
	var shot_weight: float = juice.camera_strength if juice.shot.active else 0.0
	if shot_weight > 0:
		var shot_view: Transform3D = juice.shot.frame(ball.global_position,camera.global_transform,camera_base_fov)
		camera.global_transform = camera.global_transform.interpolate_with(shot_view,shot_weight)
		camera.fov = lerpf(camera_base_fov,juice.shot.view_fov,shot_weight)
	var slide_weight: float = juice.slide.weight()*juice.camera_strength
	if slide_weight > 0:
		var focus_slide := camera_focus.lerp(to_local(juice.slide.origin),slide_weight)
		var orbit := Vector3(0,16.5,25).rotated(Vector3.RIGHT,-deg_to_rad(juice.slide.PITCH_DEGREES)*slide_weight)
		orbit = orbit.rotated(Vector3.UP,deg_to_rad(juice.slide.ORBIT_DEGREES)*juice.slide.direction*slide_weight)
		orbit *= lerpf(1,.86,slide_weight)
		camera.position = focus_slide+orbit; camera.look_at(focus_slide)
		camera.rotation.z -= deg_to_rad(juice.slide.ROLL_DEGREES)*juice.slide.direction*slide_weight
		camera.fov = lerpf(camera_base_fov,juice.slide.ZOOM_FOV,slide_weight)
	if phase not in ["playing","foul","celebrate"]: juice.camera_impacts.clear()
	var impulse: Vector4 = juice.sample_camera(delta)
	var slide_shake: Vector2 = (juice.slide.shake()+juice.shot.shake())*juice.camera_strength
	camera_fx_applied = impulse != Vector4.ZERO or slide_weight > 0 or shot_weight > 0
	camera.h_offset = clampf(impulse.x+slide_shake.x,-.09,.09)
	camera.v_offset = clampf(impulse.y+slide_shake.y,-.06,.06)
	camera.rotation.z += impulse.z; camera.fov += impulse.w

func dust(at: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 7; particles.lifetime = .4; particles.one_shot = true
	particles.explosiveness = .9; particles.position = Vector3(at.x, .12, at.z)
	var mesh := SphereMesh.new(); mesh.radius = .05; mesh.height = .08
	mesh.radial_segments = 4; mesh.rings = 2
	var m := StandardMaterial3D.new(); m.albedo_color = Color("c4a36f")
	mesh.material = m; particles.draw_pass_1 = mesh
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP; process.spread = 70
	process.initial_velocity_min = .5; process.initial_velocity_max = 1.6
	process.gravity = Vector3(0,-2,0)
	process.scale_min = .5; process.scale_max = 1.8
	particles.process_material = process
	add_child(particles); particles.emitting = true
	get_tree().create_timer(.7).timeout.connect(particles.queue_free)

func whistle(long := false) -> void:
	juice.whistle(long)
