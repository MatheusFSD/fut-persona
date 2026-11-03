extends SceneTree
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("PASS ", label)
	else: failures.append(label); push_error("FAIL " + label)

func ticks(count: int) -> void:
	for i in count: await physics_frame

func mouse(button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button; event.pressed = pressed; event.position = Vector2(900,400)
	Input.parse_input_event(event)

func reset_players() -> void:
	for p in game.players:
		p.set_physics_process(false)
		p.reset_at(Vector3(-15+p.slot*4,.05,10 if p.team == 0 else -10))
	game.controlled = game.players[4]
	game.controlled.reset_at(Vector3(0,.05,0)); game.controlled.cooldown = 0
	game.phase = "playing"; game.carrier = null; game.kick_lock = 0
	game.ball.freeze = true; game.ball.position = Vector3(.85,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.spectator = false
	game.auto_switch_lock = 0

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.juice.slide_cinematic_enabled = false # Baseline controls/framing; cinematic timing is tested separately.
	game.juice.shot_cinematic_enabled = false
	game.set_physics_process(false); game.hud.hide(); game.muted = true
	reset_players(); await ticks(2)
	for entry in [[MOUSE_BUTTON_LEFT,"mouse_primary"],[MOUSE_BUTTON_RIGHT,"mouse_secondary"],[MOUSE_BUTTON_MIDDLE,"switch"]]:
		var event := InputEventMouseButton.new(); event.button_index = entry[0]
		check(InputMap.event_is_action(event,entry[1]),"physical mouse binding " + entry[1])
	var p = game.controlled
	game.carrier = p; p.set_physics_process(true)
	mouse(MOUSE_BUTTON_LEFT,true); await ticks(8)
	check(p.charging > .08 and p.action.is_empty(),"left hold charges shot with possession")
	mouse(MOUSE_BUTTON_LEFT,false); await ticks(2)
	check(p.action == "shot" and p.shot_input.is_empty(),"left release shoots and clears charge")
	reset_players(); p = game.controlled; p.set_physics_process(true)
	game.ball.position.x = 8
	mouse(MOUSE_BUTTON_LEFT,true); await ticks(2)
	check(p.action == "slide" and p.charging == 0,"left press without possession slides immediately")
	mouse(MOUSE_BUTTON_LEFT,false); await ticks(2)
	reset_players(); p = game.controlled; game.carrier = p; p.set_physics_process(true)
	mouse(MOUSE_BUTTON_RIGHT,true); await ticks(2)
	check(p.action == "pass","right press with possession passes")
	mouse(MOUSE_BUTTON_RIGHT,false); await ticks(2)
	reset_players(); p = game.controlled; game.ball.position.x = 8; p.set_physics_process(true)
	mouse(MOUSE_BUTTON_RIGHT,true); await ticks(2)
	check(p.action == "tackle","right press without possession tackles")
	mouse(MOUSE_BUTTON_RIGHT,false); await ticks(2)
	reset_players(); p = game.controlled
	mouse(MOUSE_BUTTON_MIDDLE,true); await ticks(2)
	check(game.controlled != p,"middle mouse click switches player")
	mouse(MOUSE_BUTTON_MIDDLE,false); await ticks(2)
	reset_players(); p = game.controlled; game.carrier = p; p.set_physics_process(true)
	mouse(MOUSE_BUTTON_LEFT,true); await ticks(6)
	var next_player = game.players[2]
	game.select_player(next_player)
	check(p.charging == 0 and p.shot_input.is_empty(),"handoff cancels outgoing shot charge")
	p.set_physics_process(false); next_player.position = Vector3.ZERO
	game.carrier = next_player; next_player.cooldown = 0; next_player.set_physics_process(true)
	await ticks(2); mouse(MOUSE_BUTTON_LEFT,false); await ticks(2)
	check(next_player.action.is_empty(),"mouse release never shoots accidentally after handoff")
	reset_players(); p = game.controlled; p.position.x = -15
	next_player = game.players[2]; next_player.position = Vector3(.4,.05,0)
	game.ball.position = Vector3(0,.25,0)
	game._update_control()
	check(game.controlled == next_player,"distant control moves to nearest outfield player")
	reset_players(); p = game.controlled; p.position.x = 7.5
	next_player = game.players[2]; next_player.position = Vector3(6,.05,0)
	game.ball.position = Vector3(0,.25,0); game._update_control()
	check(game.controlled == p,"small distance advantage does not cause control flicker")
	p.position.x = 10; next_player.position.x = .4; game.auto_switch_lock = .5
	game._update_control(); check(game.controlled == p,"manual and pass handoffs have a distance cooldown")
	game.carrier = next_player; game._update_control()
	check(game.controlled == next_player,"receiving possession overrides switch cooldown immediately")
	game.carrier = game.players[0]; game._update_control()
	check(game.controlled == game.players[0],"keeper possession transfers control too")
	reset_players(); p = game.controlled; p.position.x = -15; game.spectator = true
	game.carrier = game.players[2]; game._update_control()
	check(game.controlled == p,"spectator mode keeps the AI in control")
	game.ball.position = Vector3(18,.25,-8)
	for i in 120: game._update_camera(1.0/60)
	check(game.camera.projection == Camera3D.PROJECTION_PERSPECTIVE,"broadcast camera uses perspective")
	check(game.camera.fov < 48,"default view is close")
	check(absf(game.camera.rotation_degrees.x) > 25 and absf(game.camera.rotation_degrees.x) < 40,"broadcast camera has a lower pitch angle")
	check(game.camera_focus.x > 17 and game.camera_focus.z < -7,"camera follows ball rather than controlled player")
	check(game.camera.is_position_in_frustum(game.ball.position),"ball stays visible on far flank")
	game.ball.position = Vector3(-24,.25,13)
	for i in 120: game._update_camera(1.0/60)
	check(game.camera.is_position_in_frustum(game.ball.position),"ball stays visible near opposite corner")
	print("CONTROL_CAMERA ", checks-failures.size(),"/",checks," passed; failures=",failures)
	await ticks(60); game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
