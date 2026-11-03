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

func move_mouse(world: Vector3) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * game.camera.unproject_position(world)
	motion.global_position = motion.position
	Input.parse_input_event(motion)

func place_ball() -> void:
	game.ball.freeze = true; game.ball.position = Vector3(.85,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	await ticks(2)
	game.ball.freeze = false; game.carrier = null; game.kick_lock = 0
	await ticks(2)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.juice.shot_cinematic_enabled = false # Measure mouse aim and pass travel at normal speed.
	game.set_physics_process(false); game.hud.hide(); game.muted = true; game.phase = "playing"
	for p in game.players:
		p.set_physics_process(false); p.reset_at(Vector3(-15+p.slot*4,.05,10 if p.team == 0 else -10))
	var p = game.players[4]; game.controlled = p; p.reset_at(Vector3(0,.05,0)); p.cooldown = 0
	var lawn: MeshInstance3D = game.find_child("Gramado",true,false)
	var texture: Texture2D = lawn.material_override.albedo_texture
	var color := texture.get_image().get_pixel(40,40)
	check(color.g > color.r*1.5 and color.g > color.b*1.5,"green lawn replaces dirt")
	var tufts: MultiMeshInstance3D = game.find_child("Graminhas",true,false)
	check(tufts.multimesh.instance_count == 2600,"2600 native MultiMesh grass tufts")
	check(tufts.multimesh.mesh.surface_get_array_len(0) == 12,"grass uses tapered triangle blades")
	var panels: Array = []
	for net in get_nodes_in_group("goal_net_visual"): panels.append_array(net.wire_counts.slice(1))
	check(panels == [20,20,20,20],"all four lateral net panels have both grid directions")
	var target := Vector3(12,.03,5)
	var projected: Vector2 = game.camera.unproject_position(target)
	var hit: Vector3 = game.mouse_aim(p,projected)
	check(game.flat_distance(hit,target) < .01,"screen ray maps cursor to the field")
	move_mouse(target); await ticks(2)
	check(game.flat_distance(game.shot_aim(p),target) < .05,"human shot follows actual mouse position")
	check(game.flat_distance(game.pass_aim(p),target) < .05,"human pass follows actual mouse position")
	await place_ball()
	var backwards := Vector3(-9,0,-7)
	game.strike(p,backwards,"shot",.8); await ticks(2)
	var wanted := backwards-Vector3(.85,.25,0); wanted.y = 0; wanted = wanted.normalized()
	var actual: Vector3 = game.ball.linear_velocity; actual.y = 0
	check(actual.normalized().dot(wanted) > .995,"shot can go backward toward cursor without goal auto-aim")
	await ticks(14); await place_ball()
	game.strike(p,Vector3(10,0,0),"pass",.5); await ticks(2)
	check(game.ball.linear_velocity.x > 16,"short pass launches firmly above 16 metres per second")
	check(game.ball.angular_velocity.z < -30,"pass starts with matching forward rolling spin")
	await ticks(43)
	print("PASS_DISTANCE_AT_075S ",game.ball.position.x-.85)
	check(game.ball.position.x-.85 > 9,"firm pass travels over nine metres in 0.75 seconds")
	await ticks(14); await place_ball()
	var diagonal := Vector3(10,0,8)
	game.players[2].position = Vector3(10,.05,-5)
	game.players[3].position = Vector3(10,.05,8)
	var receiver = game.pass_receiver(p,diagonal)
	check(receiver == game.players[3],"receiver selection follows pass ray")
	game.controlled = p; game.strike(p,diagonal,"pass",.5); await ticks(2)
	wanted = diagonal-Vector3(.85,.25,0); wanted.y = 0; wanted = wanted.normalized()
	actual = game.ball.linear_velocity; actual.y = 0
	check(actual.normalized().dot(wanted) > .995,"pass travels exactly toward target without bending to a teammate")
	check(game.controlled == game.players[3],"pass hands control to the teammate in its actual path")
	game.players[2].position.z = -10; game.players[3].position.z = -10
	check(game.pass_receiver(p,diagonal) == null,"empty-space pass never chooses an off-direction receiver")
	await ticks(14)
	check(not game.ball.get_collision_exceptions().has(p),"kicker collision is restored after launch")
	game.spectator = true
	check(game.pass_aim(p) != game.mouse_aim(p),"AI pass selection remains independent from cursor")
	print("PITCH_AIM ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.phase = "finished"; await ticks(60); game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
