extends SceneTree
var game
var fx
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL "+label)

func reset(at := Vector3(.75,.4,0)) -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.released_by = null; game.release_guard = 0; game.kick_lock = 0
	game.recent_shot_time = 0; game.ball_speed_before_step = 0
	game.ball.freeze = true; game.ball.position = at
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.controlled = game.players[4]; game.controlled.position = Vector3(at.x-.75,.05,at.z)
	game.ball.freeze = false

func advance(count: int) -> void:
	for i in count: await physics_frame; fx._physics_process(1.0/60)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.juice.shot_cinematic_enabled = false # Measure physical trail at normal speed.
	game.set_physics_process(false); game.muted = true; game.hud.hide()
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	fx = game.juice.ball_fx; fx.set_physics_process(false)
	check(fx.trail_node.mesh is ImmediateMesh and fx.trail_material.albedo_texture == null,"trail is one native mesh with no texture")
	check(fx.find_children("*","CollisionObject3D",true,false).is_empty(),"visual effect adds no physics bodies")
	reset(); game.strike(game.controlled,Vector3(20,0,0),"pass",.5)
	check(fx.trail_remaining == 0 and fx.contacts.size() == 1 and fx.contacts[0].kind == "pass","pass has a small contact mark and no strong-shot trail")
	await advance(4)
	check(not fx.trail_node.visible,"fast passes never activate trail just because of speed")
	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",.6)
	check(fx.trail_remaining == 0 and fx.contacts[0].kind == "shot","normal shot remains trail-free")
	reset(); var origin: Vector3 = game.ball.global_position
	game.strike(game.controlled,Vector3(24,0,0),"shot",1)
	check(fx.trail_remaining > 0 and fx.contacts.size() == 1 and fx.contacts[0].kind == "power","real strong shot arms trail and impact even when sound is muted")
	var observed: Array[Vector3] = [origin]
	for i in 9:
		await physics_frame; observed.append(game.ball.global_position); fx._physics_process(1.0/60)
	check(fx.points.size() >= 2 and fx.trail_node.visible and fx.trail_mesh.get_surface_count() == 1,"moving rigid body creates visible tapered ribbon")
	var actual := true; var length := 0.0
	for point: Dictionary in fx.points:
		actual = actual and observed.any(func(at): return at.distance_to(point.position) < .001)
	for i in range(1,fx.points.size()): length += fx.points[i].position.distance_to(fx.points[i-1].position)
	check(actual,"trail samples the real ball path instead of predicting an arc")
	check(length <= fx.TRAIL_LENGTH+.001 and fx.points.size() <= fx.MAX_POINTS,"tail length and point budget are bounded")
	check(fx.contacts[0].position == origin and game.ball.global_position.distance_to(origin) > .5,"contact mark stays at kick point after ball travels")
	var age: float = fx.points[0].age
	game.toggle_pause(); fx._physics_process(.5)
	check(fx.points[0].age == age and fx.trail_node.visible,"pause freezes tail and contact clocks")
	game.toggle_pause()
	var ball_at: Vector3 = game.ball.position; var velocity: Vector3 = game.ball.linear_velocity
	fx.contact("fence",Vector3(3,.3,2),.5); fx._physics_process(.01)
	check(game.ball.position == ball_at and game.ball.linear_velocity == velocity,"graphics cannot move ball or alter its velocity")
	game.take_possession(game.players[2])
	check(fx.trail_remaining == 0,"receiving the ball stops new trail emission immediately")
	fx._physics_process(.3)
	check(fx.points.is_empty() and fx.contacts.is_empty() and not fx.trail_node.visible,"old tail and contact disappear completely")
	reset(Vector3(22,.7,3.4)); game.strike(game.controlled,Vector3(25,0,3.4),"shot",1)
	await advance(7)
	check(fx.trail_remaining == 0 and fx.contacts.any(func(event): return event.kind == "post"),"native ball/post collision ends trail and creates contact burst")
	reset(); fx.start_trail(); game.ball.linear_velocity = Vector3(20,0,0)
	game.ball.position += Vector3(8,0,0); fx._physics_process(.016)
	check(fx.points.is_empty() and not fx.trail_node.visible,"teleport cannot stretch ribbon across the pitch")
	reset(); fx.contact("body",Vector3.ZERO,.5); fx.contact("save",Vector3.ZERO,1)
	check(fx.contacts.size() == 1 and fx.contacts[0].kind == "save","collision and trap notifications merge into one contact")
	for i in 12: fx.contact("pass",Vector3(i*2,0,3),.4)
	check(fx.contacts.size() == fx.MAX_CONTACTS,"contact effects use bounded storage")
	reset(); game.ball.linear_velocity = Vector3(14,0,0); game.take_possession(game.players[2])
	check(fx.contacts.size() == 1 and fx.contacts[0].kind == "trap","fast reception gets a small first-touch mark")
	reset(); game.ball.linear_velocity = Vector3(1,0,0); game.take_possession(game.players[2])
	check(fx.contacts.is_empty(),"routine slow dribbling does not spam contact graphics")
	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",1)
	game.begin_restart(0,Vector3(6,.05,0),"FALTA • BOLA PARADA",false)
	check(fx.points.is_empty() and fx.contacts.is_empty() and fx.trail_remaining == 0,"set piece clears old graphics before repositioning")
	game.phase = "playing"; fx.contact("post",Vector3.ZERO,1); game.selection_menu()
	check(fx.contacts.is_empty() and not fx.trail_node.visible,"leaving match clears all ball visuals")
	print("BALL_FX ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
