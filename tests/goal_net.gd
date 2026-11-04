extends SceneTree
var game
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func ticks(count: int) -> void:
	for i in count: await physics_frame
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.hud.hide()
	for actor in game.players: actor.set_physics_process(false); actor.collision_layer = 0; actor.collision_mask = 0
	var frame := get_nodes_in_group("goal_frame")
	check(frame.size() == 6,"two goals each have two posts and a crossbar")
	for body in frame:
		var shape: CylinderShape3D = body.get_child(0).shape
		check(is_equal_approx(shape.radius,.06),"posts and crossbar have official 12cm diameter")
		if absf(body.position.z) > 1:
			check(is_equal_approx(absf(body.position.z)-shape.radius,3.66),"inner post faces provide 7.32m clear width")
		else:
			check(is_equal_approx(body.position.y-shape.radius,2.44),"crossbar underside provides 2.44m clear height")
	var nets := get_nodes_in_group("goal_net_visual"); var walls := get_nodes_in_group("goal_net_body")
	check(nets.size() == 2 and walls.size() == 6,"both goals have animated wires and three native containment walls")
	var right = nets.filter(func(net): return net.position.x > 0)[0]
	var left = nets.filter(func(net): return net.position.x < 0)[0]
	check(right.net_mesh.mesh == left.net_mesh.mesh and right.material != left.material,"goals share geometry but have independent GPU impact uniforms")
	check(right.net_mesh.mesh.get_surface_count() == 1,"all three panels use one mesh surface per goal")
	var arrays: Array = right.net_mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]; var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	check(vertices.size() < 16000 and vertices.size() > 3000,"static segmented net stays within small mesh budget")
	var anchored := 0; var moving := 0; var panels := [0,0,0]
	for color in colors:
		if color.r < .001: anchored += 1
		if color.r > .8: moving += 1
		panels[roundi(color.a*2)] += 1
	check(anchored > 100 and moving > 100 and panels.all(func(n): return n > 100),"real vertices encode fixed borders, free centers and all three panels")
	for panel in 3:
		var edges := [Vector3(0,2.5,0),Vector3(1.8,.06,0),Vector3(.9,1.28,3.72)] if panel == 0 else [Vector3(0,1,0),Vector3(.5,.035,0),Vector3(.9,1.28,0)]
		check(edges.all(func(p): return right.pin_weight(p,panel) < .001),"frame and ground anchors remain pinned on panel "+str(panel))
	game.phase = "playing"; game.ball.freeze = false
	var center: Vector3 = right.to_global(Vector3(.9,1.28,0))
	check(right.impact(center,20,0) and right.hits.size() == 1 and left.hits.is_empty(),"impact activates only its own goal")
	check(is_equal_approx(right.material.get_shader_parameter("pulses")[0].x,.95),"speed sets bounded strong-shot amplitude")
	check(not right.impact(center,20,0) and right.hits.size() == 1,"same contact cannot spam overlapping pulses")
	check(not right.impact(center,.5,0),"resting slow ball does not vibrate net repeatedly")
	var mesh_id: int = right.net_mesh.mesh.get_instance_id(); var ball_at: Vector3 = game.ball.position; var velocity: Vector3 = game.ball.linear_velocity
	right._physics_process(.12)
	check(is_equal_approx(right.material.get_shader_parameter("impacts")[0].w,.12),"GPU age follows scaled physics delta")
	check(right.net_mesh.mesh.get_instance_id() == mesh_id and game.ball.position == ball_at and game.ball.linear_velocity == velocity,"animation does not rebuild mesh or move physical ball")
	game.phase = "paused"; var before: float = right.hits[0].age; right._physics_process(.5)
	check(right.hits[0].age == before and is_equal_approx(right.material.get_shader_parameter("impacts")[0].w,before),"pause freezes CPU clock and GPU uniforms")
	game.phase = "celebrate"; right._physics_process(.1*.3)
	check(is_equal_approx(right.hits[0].age,before+.03),"slow-motion delta advances net three times less than normal 0.1 seconds")
	right.reset(); right.impact(center,2,0)
	check(right.hits[0].amplitude < .2,"weak impact makes a smaller deformation")
	right.reset()
	for i in 7: right.impact(right.to_global(Vector3(.9,1.1,-2.4+i*.8)),12,0)
	check(right.hits.size() == 4 and right.material.get_shader_parameter("impacts").size() == 4,"overlapping impacts and uniform storage are bounded at four")
	right._physics_process(1.71)
	check(right.hits.is_empty() and not right.is_physics_processing() and right.material.get_shader_parameter("impact_count") == 0,"settled net stops CPU updates entirely")
	for wall in walls:
		var net = wall.get_meta("goal_net"); var panel: int = wall.get_meta("net_panel")
		check(wall is StaticBody3D and wall.collision_layer == 1 and wall.collision_mask == 4,"native ball collision remains on wall")
		if panel > 0:
			var point: Vector3 = net.contact_point(net.to_local(wall.global_position),panel)
			check(signf(point.z) == (-1 if panel == 1 else 1),"mirrored goal maps physical side wall to correct shader panel")
	right.impact(center,18,0); game.begin_restart(0,Vector3.ZERO,"LATERAL",false)
	check(right.hits.is_empty(),"restart clears pending vibration")
	game.phase = "playing"; right.impact(center,18,0); game.selection_menu()
	check(right.hits.is_empty(),"selection menu clears old net waves")
	# Native collisions after the sphere enters the goal: no synthetic goal-impact hook.
	for side in [-1,1]:
		game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
		game.phase = "playing"; game.kick_lock = 0; game.score = [0,0]; game.elapsed = 0
		for p in game.players: p.position.z = 12
		game.goal_candidates = [false,false]; game.ball.freeze = true
		game.ball.position = Vector3(side*22,.6,0); game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
		await ticks(2)
		var net = right if side > 0 else left; var serial: int = net.impact_serial
		game.ball.freeze = false; game.ball.linear_velocity = Vector3(side*18,1,0); game.set_physics_process(true)
		var waited := 0
		while net.impact_serial == serial and waited < 90: await ticks(1); waited += 1
		check(net.impact_serial > serial and net.hits.size() > 0,"real native ball collision triggers net in goal "+str(side))
		check(game.phase == "celebrate" and game.score[0]+game.score[1] == 1,"goal counts once and vibration continues through celebration")
		check(net.hits[0].panel == 0 and not game.ball.freeze,"back-panel collision supplies actual impact with live rigid body")
		game.set_physics_process(false)
	game.queue_free(); await process_frame; await process_frame
	print("GOAL_NET ",checks-failures.size(),"/",checks," passed; vertices_per_goal=",vertices.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
