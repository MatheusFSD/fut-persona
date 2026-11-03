extends SceneTree
var game
var actor
var keeper
var skeleton: Skeleton3D
var bones: Dictionary = {}
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func ticks(count: int) -> void:
	for i in count: await physics_frame
func setup(side: int) -> void:
	if game != null: game.queue_free(); await process_frame; await process_frame
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.spectator = true
	game.juice.shot_cinematic_enabled = false; game.juice.slide_cinematic_enabled = false
	for p in game.players:
		p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0; p.position.z = 12
	actor = game.players[side*5]; keeper = actor.goalkeeper
	actor.reset_at(Vector3(-keeper.attack()*21.6,.05,0)); actor.collision_layer = 2; actor.collision_mask = 3
	actor.avatar.rotation.y = atan2(-actor.facing.x,-actor.facing.z)+actor.visual_offset
	skeleton = keeper.rig; bones.clear()
	skeleton.skeleton_updated.connect(sample_bones)
	game.phase = "playing"; game.ball.freeze = true
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
func sample_bones() -> void:
	for name in ["pelvis","upperarm_l","lowerarm_l","hand_l","upperarm_r","lowerarm_r","hand_r","calf_l"]:
		bones[name] = skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone(name))
func check_hands(label: String) -> void:
	var left := Vector3.UP.cross(actor.facing).normalized()
	var center: Vector3 = actor.position
	check(keeper.hands.size() == 2 and (keeper.hands[0]-center).dot(left) > .15 and (keeper.hands[1]-center).dot(left) < -.15,"each idle hand stays on its own side: "+label)
	check(keeper.hands.size() == 2 and keeper.hands[0].distance_to(keeper.hands[1]) > .38,"idle gloves remain separated: "+label)
	for side in ["l","r"]:
		var upper: Vector3 = bones["upperarm_"+side].origin-bones["lowerarm_"+side].origin
		var lower: Vector3 = bones["hand_"+side].origin-bones["lowerarm_"+side].origin
		var flex := PI-upper.angle_to(lower)
		check(flex > .35 and flex < 2.4,"ready elbow is bent rather than locked or crossed: "+label+side+" flex="+str(flex))
func run() -> void:
	for side in 2:
		await setup(side)
		var attack: float = keeper.attack()
		game.ball.position = Vector3(0,.25,0)
		game.carrier = game.players[(1-side)*5+4]
		actor.set_physics_process(true); await ticks(90)
		check_hands(str(side)+"/center")
		var central: Vector3 = keeper.position_target()
		check(absf(central.z) < .01 and absf(central.x) < 22,"central ball permits an advanced central position")
		for lateral in [-8.0,8.0]:
			game.ball.position = Vector3(-attack*23,.25,lateral)
			var target: Vector3 = keeper.position_target()
			check(absf(target.x) > absf(central.x)+1 and target.z*signf(lateral) > 2.7,"end-line angle closes near post in both axes")
			await ticks(110)
			check(game.flat_distance(actor.position,target) < .25,"keeper physically reaches the near-post position")
			check(actor.facing.dot(keeper.ball_direction()) > .98,"body turns to ball at end line")
			var visual := Vector3(sin(actor.avatar.rotation.y),0,cos(actor.avatar.rotation.y))
			check(visual.dot(keeper.ball_direction()) > .98 and absf(visual.z) > .9,"rendered torso faces down the end line")
			check_hands(str(side)+"/endline"+str(lateral))
		# The keeper must turn while standing, not only while taking a step.
		actor.set_physics_process(false); actor.reset_at(Vector3(-attack*21.6,.05,0))
		game.ball.position = Vector3(-attack*20,.25,4)
		for frame in 25:
			keeper.prepare(1.0/60)
			actor.facing = actor.facing.lerp(keeper.look_direction(),.25).normalized()
			actor.avatar.rotation.y = atan2(-actor.facing.x,-actor.facing.z)+actor.visual_offset
			actor._animate(); actor.animation_tree.tick(1.0/60,false); keeper.finish(1.0/60)
		check(actor.facing.dot(keeper.ball_direction()) > .99,"stationary ready stance tracks ball orientation")
	# A cross parallel to the end line still causes an interception attempt.
	await setup(1); actor.reset_at(Vector3(23.1,.05,3))
	game.carrier = null; game.ball.position = Vector3(22.8,1.5,7)
	await ticks(2); game.ball.freeze = false; game.ball.linear_velocity = Vector3(0,2,-14)
	actor.set_physics_process(true)
	var attempted := false
	for frame in 40:
		await physics_frame
		attempted = attempted or keeper.state in [keeper.State.REACH,keeper.State.DIVE,keeper.State.JUMP]
	check(attempted,"near-post cross does not require a global-X ball velocity")
	# Hold the physics body fixed: only the animation may move the hip.
	await setup(1); actor.position.y = 1; game.ball.position = Vector3(12,.25,0)
	keeper.defense_facing = actor.facing; keeper.dive_side = 1; keeper.dive_landing = true
	keeper.change(keeper.State.DIVE)
	var anchor := Vector3.ZERO; var drift := 0.0; var leg_motion := 0.0; var original_leg := Basis.IDENTITY
	for frame in 20:
		keeper.age = frame/60.0
		actor._animate(); actor.animation_tree.tick(1.0/60,false); keeper.finish(1.0/60)
		var hip: Vector3 = bones.pelvis.origin
		if frame == 0: anchor = hip; original_leg = bones.calf_l.basis
		drift = maxf(drift,hip.distance_to(anchor))
		leg_motion = maxf(leg_motion,original_leg.get_rotation_quaternion().angle_to(bones.calf_l.basis.get_rotation_quaternion()))
	check(absf(actor.avatar.rotation.z) > 1 and drift < .05,"dive rotates around hips instead of orbiting the feet; drift="+str(drift))
	check(leg_motion > .2,"dive includes changing leg poses instead of a rigid pointer")
	# Real landing: stay in flight pose, absorb impact, then get up.
	await setup(1); var shooter = game.players[4]; shooter.position = Vector3(12,.05,0)
	game.ball.position = Vector3(12.75,.25,0); await ticks(2)
	game.ball.freeze = false; game.strike(shooter,Vector3(25,0,3),"shot",.7)
	actor.set_physics_process(true)
	var states: Array[int] = []; var held_roll := false; var absorbed := false
	for frame in 140:
		await physics_frame
		if keeper.state not in states: states.append(keeper.state)
		if keeper.state == keeper.State.LAND and not actor.is_on_floor(): held_roll = held_roll or absf(actor.avatar.rotation.z) > .8
		if keeper.state == keeper.State.LAND and keeper.landed_age > .15: absorbed = absorbed or keeper.posture_drop < -.4
		if keeper.saves > 0 and keeper.state == keeper.State.POSITION: break
	check(keeper.saves == 1 and held_roll,"parry retains dive posture until landing")
	check(absorbed and states.find(keeper.State.LAND) >= 0 and states.find(keeper.State.RECOVER) > states.find(keeper.State.LAND),"ground impact precedes getting up")
	check(keeper.state == keeper.State.POSITION and absf(actor.avatar.rotation.z) < .02 and actor.avatar.position.length() < .03,"recovery finishes with a balanced upright stance")
	game.queue_free(); await process_frame; await process_frame
	print("KEEPER_POSITIONING ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
