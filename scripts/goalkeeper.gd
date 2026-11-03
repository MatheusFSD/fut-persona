extends Node3D
## Prediction chooses an attempt; only swept, animated glove contact saves a ball.
enum State { POSITION, PREPARE, REACH, DIVE, JUMP, CATCH, HOLD, THROW, RECOVER, LAND }
const REACTION_SECONDS := .12
const COMMIT_SECONDS := .34
const GLOVE_RADIUS := .16
const DIVE_SPEED := 7.6
const GRAVITY := 18.0
const DIVE_ROLL := 1.22
const RECOVERY_SECONDS := .60
var player
var game
var rig: Skeleton3D
var state := State.POSITION
var age := 0.0
var threat_age := 0.0
var prediction: Dictionary = {}
var intercept := Vector3.ZERO
var defense_velocity := Vector3.ZERO
var defense_facing := Vector3.RIGHT
var dive_side := 0.0
var commit_time := .3
var dive_landing := false
var landed_age := -1.0
var recovery_roll := 0.0
var recovery_drop := 0.0
var posture_drop := 0.0
var holding := false
var contact_authorized := false
var last_contact: Dictionary = {}
var saves := 0
var hands: Array[Vector3] = []
var previous_hands: Array[Vector3] = []
var previous_ball := Vector3.ZERO
var sample_epoch := -1
var targets: Array[Node3D] = []
var poles: Array[Node3D] = []
var solvers: Array[TwoBoneIK3D] = []
var leg_targets: Array[Node3D] = []
var leg_poles: Array[Node3D] = []
var leg_solvers: Array[TwoBoneIK3D] = []
var feet: Array[Vector3] = []
var throw_target := Vector3.ZERO
var throw_kind := "pass"
var throw_power := .5
var throw_released := false
var hold_anchor := Vector3.ZERO

func setup(actor) -> void:
	player = actor; game = actor.game
	rig = player.avatar.find_children("*","Skeleton3D",true,false)[0]
	rig.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	for side in ["l","r"]:
		var target := Node3D.new(); target.name = "GloveTarget_"+side; add_child(target); targets.append(target)
		var pole := Node3D.new(); pole.name = "ElbowPole_"+side; add_child(pole); poles.append(pole)
		var ik := TwoBoneIK3D.new(); ik.name = "KeeperArm_"+side; rig.add_child(ik)
		ik.set_setting_count(1)
		ik.set_root_bone_name(0,"upperarm_"+side); ik.set_middle_bone_name(0,"lowerarm_"+side); ik.set_end_bone_name(0,"hand_"+side)
		ik.set_target_node(0,ik.get_path_to(target)); ik.set_pole_node(0,ik.get_path_to(pole))
		ik.set_pole_direction(0,SkeletonModifier3D.SECONDARY_DIRECTION_PLUS_Z)
		ik.influence = 0; solvers.append(ik)
		var foot := Node3D.new(); foot.name = "PlantedFoot_"+side; add_child(foot); leg_targets.append(foot)
		var knee := Node3D.new(); knee.name = "KneePole_"+side; add_child(knee); leg_poles.append(knee)
		var leg := TwoBoneIK3D.new(); leg.name = "KeeperLeg_"+side; rig.add_child(leg); leg.set_setting_count(1)
		leg.set_root_bone_name(0,"thigh_"+side); leg.set_middle_bone_name(0,"calf_"+side); leg.set_end_bone_name(0,"foot_"+side)
		leg.set_target_node(0,leg.get_path_to(foot)); leg.set_pole_node(0,leg.get_path_to(knee))
		leg.set_pole_direction(0,SkeletonModifier3D.SECONDARY_DIRECTION_PLUS_Z)
		leg.influence = 0; leg_solvers.append(leg)
	rig.skeleton_updated.connect(_sample_hands)

func attack() -> float: return 1.0 if player.team == 0 else -1.0
func in_area() -> bool: return player.position.x*attack() < -16 and absf(player.position.z) < 6
func defending() -> bool: return state in [State.REACH,State.DIVE,State.JUMP,State.CATCH,State.THROW,State.RECOVER,State.LAND]

func ball_direction() -> Vector3:
	var direction: Vector3 = game.ball.global_position-player.global_position; direction.y = 0
	return direction.normalized() if direction.length() > .2 else player.facing

func look_direction() -> Vector3:
	if defending() and (state != State.RECOVER or absf(player.avatar.rotation.z) > .25): return defense_facing
	return ball_direction()

func position_target() -> Vector3:
	# The angle bisector from the ball to the two posts closes both shooting lanes.
	var goal := Vector3(-attack()*24,0,0)
	var ball_at: Vector3 = game.ball.global_position; ball_at.y = 0
	var relative := ball_at-goal
	var depth_to_ball := maxf(relative.x*attack(),0)
	var forwardness := depth_to_ball/maxf(relative.length(),.01)
	var depth := minf(lerpf(.35,2.4,forwardness*forwardness),maxf(.35,depth_to_ball-.7))
	var plane_x := goal.x+attack()*depth
	var bisector := ((goal+Vector3(0,0,-3.4)-ball_at).normalized()+(goal+Vector3(0,0,3.4)-ball_at).normalized()).normalized()
	var target := Vector3(plane_x,0,signf(ball_at.z)*3.05)
	if absf(bisector.x) > .001:
		var distance := (plane_x-ball_at.x)/bisector.x
		if distance > 0: target = ball_at+bisector*distance
	target.x = clampf(target.x,-23.65,23.65); target.z = clampf(target.z,-3.05,3.05)
	return target

func reset() -> void:
	state = State.POSITION; age = 0; threat_age = 0; holding = false; contact_authorized = false
	prediction.clear(); last_contact.clear(); previous_hands.clear(); hands.clear(); feet.clear(); sample_epoch = -1
	defense_velocity = Vector3.ZERO; defense_facing = Vector3(attack(),0,0)
	dive_side = 0; throw_released = false; dive_landing = false; landed_age = -1; posture_drop = 0
	if player != null:
		player.avatar.rotation.x = 0; player.avatar.rotation.z = 0; player.avatar.position = Vector3.ZERO
		_update_body_shape()
		if player.action == "keeper_throw": player.action = ""
	for ik in solvers: ik.influence = 0
	for ik in leg_solvers: ik.influence = 0

func change(next: State) -> void:
	if state == next: return
	if next == State.RECOVER:
		recovery_roll = player.avatar.rotation.z; recovery_drop = posture_drop
	if next == State.LAND: landed_age = -1
	state = next; age = 0
	if next != State.LAND: player.current_clip = ""
	if next == State.RECOVER: threat_age = 0; prediction.clear()

func predict_plane(plane_x: float) -> Dictionary:
	return _predict_plane(Vector3(plane_x,0,0),Vector3(attack(),0,0))

func _predict_plane(plane_point: Vector3, normal: Vector3) -> Dictionary:
	var at: Vector3 = game.ball.global_position
	var velocity: Vector3 = game.ball.linear_velocity
	if velocity.dot(normal) >= -.1 or (at-plane_point).dot(normal) <= 0: return {}
	var dt := 1.0/120.0
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))*game.ball.gravity_scale
	var damping: float = game.ball.linear_damp+float(ProjectSettings.get_setting("physics/3d/default_linear_damp"))
	for frame in 216:
		var before := at
		velocity.y -= gravity*dt; velocity *= maxf(0,1-damping*dt); at += velocity*dt
		if at.y < game.BALL_RADIUS:
			at.y = game.BALL_RADIUS
			if velocity.y < 0: velocity.y = -velocity.y*game.ball.physics_material_override.bounce
		var before_distance := (before-plane_point).dot(normal)
		var after_distance := (at-plane_point).dot(normal)
		if before_distance > 0 and after_distance <= 0:
			var fraction := before_distance/(before_distance-after_distance)
			return {"point":before.lerp(at,fraction),"time":(frame+fraction)*dt,"velocity":velocity}
	return {}

func prepare(delta: float) -> void:
	if game.phase == "paused": return
	if not game.live() or player.stun > 0 or player.fall_time >= 0:
		reset(); return
	age += delta
	if holding and game.carrier != player: release()
	if state == State.CATCH:
		if age > .28: change(State.HOLD)
		return
	if state == State.HOLD:
		if not in_area(): release_to_feet()
		return
	if state == State.THROW:
		if age >= .22 and not throw_released:
			game.strike(player,throw_target,throw_kind,throw_power)
			throw_released = game.carrier != player
		if age > .6: player.action = ""; change(State.RECOVER)
		return
	if state == State.RECOVER:
		if age > RECOVERY_SECONDS and player.is_on_floor(): change(State.POSITION)
		return
	if state == State.LAND:
		if player.is_on_floor() and player.velocity.y <= 0:
			landed_age = maxf(0,landed_age)+delta
			if landed_age > .30: change(State.RECOVER)
		return
	if state in [State.REACH,State.DIVE,State.JUMP]:
		if state != State.REACH and ((age > .18 and player.is_on_floor() and player.velocity.y <= 0) or age > .70): change(State.LAND)
		elif state == State.REACH and age > .65: change(State.RECOVER)
		return
	if not player.action.is_empty() or game.carrier != null or not in_area():
		prediction.clear(); threat_age = 0; change(State.POSITION); return
	var forward := ball_direction()
	prediction = _predict_plane(player.global_position+forward*.5,forward)
	if not prediction.is_empty():
		var goal := predict_plane(-attack()*24)
		var goal_threat: bool = not goal.is_empty() and absf(goal.point.z) <= 3.7 and goal.point.y <= 2.8
		var close_cross: bool = game.flat_distance(player.position,game.ball.position) < 4 and prediction.point.y < 2.8
		if not goal_threat and not close_cross: prediction.clear()
	# Pick up a nearby loose slow ball by reaching down, never by a body radius.
	if prediction.is_empty() and game.ball.linear_velocity.length() < 4 and game.flat_distance(player.position,game.ball.position) < 1.3:
		prediction = {"point":game.ball.position,"time":.3,"velocity":game.ball.linear_velocity}
	if prediction.is_empty():
		threat_age = 0; change(State.POSITION); return
	threat_age += delta; change(State.PREPARE)
	if threat_age < REACTION_SECONDS or prediction.time > COMMIT_SECONDS: return
	intercept = prediction.point
	defense_facing = ball_direction(); dive_landing = false
	var left := Vector3.UP.cross(defense_facing)
	var lateral: float = (intercept-player.global_position).dot(left)
	dive_side = signf(lateral)
	commit_time = prediction.time
	var body_target: Vector3 = intercept-defense_facing*.5
	var travel: Vector3 = body_target-player.global_position; travel.y = 0
	defense_velocity = (travel/maxf(prediction.time,.12)).limit_length(DIVE_SPEED)
	if intercept.y > player.position.y+player.profile.altura*.95:
		change(State.JUMP)
		var time: float = maxf(prediction.time,.16)
		player.velocity.y = clampf((intercept.y-player.position.y-player.profile.altura*.90+GRAVITY*time*time*.5)/time,2.8,6.0)
	elif absf(lateral) > .55:
		change(State.DIVE); player.velocity.y = 3.1; dive_landing = true
		# Rotate around the hips, so only the shoulder-to-hip span adds reach.
		body_target -= left*dive_side*player.profile.altura*.24
		travel = body_target-player.global_position; travel.y = 0
		defense_velocity = (travel/maxf(prediction.time,.12)).limit_length(DIVE_SPEED)
	else: change(State.REACH)
	player.cancel_charge()

func command() -> Dictionary:
	if holding:
		if age > .65 and (game.spectator or player.team == 1):
			player.request_kick("pass",game.pass_aim(player),.6)
		return {"move":Vector3.ZERO,"sprint":false}
	var target := position_target()
	if not prediction.is_empty():
		var forward := ball_direction()
		target = prediction.point-forward*.5
		target.z = clampf(target.z,-3.05,3.05)
	elif game.carrier == null and game.ball.linear_velocity.length() < 4 and game.flat_distance(player.position,game.ball.position) < 3 and game.ball.position.x*attack() < -17 and absf(game.ball.position.z) < 5:
		target = game.ball.position
	target.x = clampf(target.x,-23.65,23.65)
	var offset: Vector3 = target-player.position; offset.y = 0
	return {"move":offset.normalized()*minf(offset.length()*2,1) if offset.length() > .12 else Vector3.ZERO,"sprint":false}

func move_defense(delta: float) -> void:
	var desired := Vector3.ZERO
	if state in [State.REACH,State.DIVE,State.JUMP] and age < minf(commit_time+.08,.42): desired = defense_velocity
	player.velocity.x = move_toward(player.velocity.x,desired.x,40*delta)
	player.velocity.z = move_toward(player.velocity.z,desired.z,40*delta)
	if not player.is_on_floor(): player.velocity.y -= GRAVITY*delta
	elif player.velocity.y <= 0: player.velocity.y = -.4
	player.move_and_slide()
	player.position.x = clampf(player.position.x,-23.65,23.65); player.position.z = clampf(player.position.z,-5.5,5.5)
	player.facing = player.facing.lerp(look_direction(),minf(delta*12,1)).normalized()
	player.avatar.rotation.y = lerp_angle(player.avatar.rotation.y,atan2(-player.facing.x,-player.facing.z)+player.visual_offset,minf(delta*16,1))
	player._animate()

func pose_clip() -> String:
	match state:
		State.PREPARE: return "keeper/Ready"
		State.REACH: return "keeper/Reach"
		State.DIVE: return "keeper/Dive"
		State.JUMP: return "keeper/Jump"
		State.CATCH,State.HOLD: return "keeper/Catch"
		State.THROW: return "keeper/Throw"
		State.RECOVER: return "keeper/Recover"
		State.LAND: return "keeper/Land" if landed_age >= 0 else "keeper/Dive" if dive_landing else "keeper/Jump"
	return "keeper/Ready" if game.live() and player.action.is_empty() and game.carrier != player and Vector2(player.velocity.x,player.velocity.z).length() < .2 else ""

func _update_body_shape() -> void:
	# The standing capsule must not become an invisible wall above a diving torso.
	var tilt := clampf(absf(player.avatar.rotation.z)/DIVE_ROLL,0,1)
	var crouch := clampf(-posture_drop/(.55*player.body_height),0,1)
	var capsule: CapsuleShape3D = player.body_collision.shape
	capsule.height = maxf(capsule.radius*2,player.profile.altura*lerpf(.94,.5,maxf(tilt,crouch*.65)))
	player.body_collision.position.y = capsule.height*.5+.005

func finish(delta: float) -> void:
	if game.phase == "paused": return
	if not game.live() or player.stun > 0 or player.fall_time >= 0: return
	var active_hands := state not in [State.POSITION] or not pose_clip().is_empty()
	var reach := state in [State.REACH,State.DIVE,State.JUMP]
	var roll := -dive_side*DIVE_ROLL if state == State.DIVE or (state == State.LAND and dive_landing) else 0.0
	if state == State.RECOVER: roll = recovery_roll*(1-smoothstep(.08,RECOVERY_SECONDS,age))
	player.avatar.rotation.z = move_toward(player.avatar.rotation.z,roll,7*delta)
	var lower: float = -.55*player.body_height if state == State.REACH and intercept.y < .65 else 0.0
	if state == State.LAND:
		lower = -player.profile.altura*(.30 if dive_landing else .12)*smoothstep(0,.16,maxf(landed_age,0))
	if state == State.RECOVER: lower = recovery_drop*(1-smoothstep(.10,RECOVERY_SECONDS,age))
	posture_drop = move_toward(posture_drop,lower,4*delta)
	# Rotate about the pelvis, rather than sweeping the body like a clock hand.
	var pivot := Vector3(0,player.profile.altura*.53,0)
	player.avatar.position = pivot-player.avatar.basis*pivot+Vector3.UP*posture_drop
	_update_body_shape()
	var forward := Vector3(sin(player.avatar.rotation.y),0,cos(player.avatar.rotation.y))
	var left := Vector3.UP.cross(forward)
	var spacing: float = .30*player.body_height
	var aim: Vector3 = player.global_position+forward*.30+Vector3.UP*(player.profile.altura*.57)
	if reach: aim = intercept
	if reach or holding: spacing = .12*player.body_height
	if holding:
		hold_anchor = hold_anchor.move_toward(aim,3.5*delta); aim = hold_anchor
	if state == State.LAND or state == State.RECOVER:
		aim += Vector3.UP*posture_drop; spacing = .32*player.body_height
	if state == State.THROW: aim += forward*.25+Vector3.UP*sin(minf(age/.22,1)*PI)*.18
	for i in 2:
		var side := 1.0 if i == 0 else -1.0
		var wanted := aim+left*side*spacing
		if sample_epoch != game.collision_epoch: targets[i].global_position = wanted
		else: targets[i].global_position = targets[i].global_position.move_toward(wanted,12*delta)
		poles[i].global_position = player.global_position+forward*.03+Vector3.UP*(player.profile.altura*.63)+left*side*.8
		solvers[i].influence = move_toward(solvers[i].influence,1.0 if active_hands else 0.0,10*delta)
		# Lower the hips for a ground save while keeping both soles on the pitch.
		leg_targets[i].global_position = player.global_position+forward*.04+Vector3.UP*(.11*player.body_height)+left*side*.17*player.body_height
		leg_poles[i].global_position = player.global_position+forward*.75+Vector3.UP*.35+left*side*.20
		leg_solvers[i].influence = clampf(-posture_drop/(.10*player.body_height),0,1)*(1-smoothstep(.25,.65,absf(player.avatar.rotation.z)))
	rig.advance(delta)
	# Skeleton updates are otherwise deferred until the end of the frame.
	# Read the same post-IK pose that is applied to the skin, before collision tests.
	rig.notification(Skeleton3D.NOTIFICATION_UPDATE_SKELETON)
	var ball_now: Vector3 = game.ball.global_position
	if reach and not holding and game.carrier == null and in_area() and hands.size() == 2:
		var sweep: bool = sample_epoch == game.collision_epoch and previous_hands.size() == 2 and previous_ball.distance_to(ball_now) < 2
		for i in 2:
			var hand_from: Vector3 = previous_hands[i] if sweep else hands[i]
			var ball_from: Vector3 = previous_ball if sweep else ball_now
			var relative := ball_from-hand_from
			var motion := ball_now-hands[i]-relative
			var time := clampf(-relative.dot(motion)/motion.length_squared(),0,1) if motion.length_squared() > .000001 else 1.0
			var ball_at := ball_from.lerp(ball_now,time); var hand_at := hand_from.lerp(hands[i],time)
			if ball_at.distance_to(hand_at) <= game.BALL_RADIUS+GLOVE_RADIUS:
				_confirm(ball_at,hand_at); break
	previous_ball = ball_now; previous_hands = hands.duplicate(); sample_epoch = game.collision_epoch

func _sample_hands() -> void:
	hands.clear(); feet.clear()
	for side in ["l","r"]:
		var pose := rig.get_bone_global_pose(rig.find_bone("hand_"+side))
		var forward := Vector3(sin(player.avatar.rotation.y),0,cos(player.avatar.rotation.y))
		hands.append(rig.global_transform*pose.origin+forward*.06)
		feet.append(rig.global_transform*rig.get_bone_global_pose(rig.find_bone("foot_"+side)).origin)

func _confirm(ball_at: Vector3, hand_at: Vector3) -> void:
	var incoming: Vector3 = game.ball.linear_velocity
	last_contact = {"ball":ball_at,"hand":hand_at,"distance":ball_at.distance_to(hand_at),"epoch":game.collision_epoch}
	contact_authorized = true; saves += 1
	var catchable := incoming.length() < 20 and state != State.DIVE
	if catchable:
		game.take_possession(player)
		holding = game.carrier == player; hold_anchor = game.ball.global_position
		if holding: change(State.CATCH)
	else:
		var side := signf(ball_at.z)
		if is_zero_approx(side): side = 1 if hand_at.z > player.position.z else -1
		var outgoing := Vector3(attack(),0,side*.65).normalized()*clampf(incoming.length()*.55,7,14)+Vector3.UP*2.4
		game.ball.apply_central_impulse((outgoing-incoming)*game.ball.mass)
		# Let the glove response clear the recovering torso without a second hit.
		game.ball.add_collision_exception_with(player)
		var epoch: int = game.collision_epoch
		get_tree().create_timer(.10).timeout.connect(func():
			if is_instance_valid(game): game.restore_ball_collision(player,epoch))
		game.last_touch = player.team; game.clear_reception()
		game.hud.push_reaction("save",ball_at,player.team)
		game.juice.impact("save",ball_at,minf(incoming.length()/24,1))
		game.recent_shot_time = 0
		change(State.LAND if state in [State.DIVE,State.JUMP] else State.RECOVER)
	contact_authorized = false

func blocks_foot_pickup() -> bool:
	return not contact_authorized and in_area() and (defending() or game.ball.linear_velocity.length() > 4 or (game.recent_shot_time > 0 and game.recent_shot_team != player.team))

func hold_ball(_delta: float) -> void:
	if not holding: return
	if game.ball.global_position.distance_to(player.global_position) > 3.0:
		game._drop_carrier(); return
	var target: Vector3 = (hands[0]+hands[1])*.5 if hands.size() == 2 else hold_anchor
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))*game.ball.gravity_scale
	var force: Vector3 = (target-game.ball.global_position)*110+(player.velocity-game.ball.linear_velocity)*18+Vector3.UP*gravity
	game.ball.apply_central_force(force.limit_length(180)*game.ball.mass)

func distribute(kind: String, target: Vector3, power: float) -> bool:
	if not holding or state != State.HOLD or player.cooldown > 0 or game.ball.position.y > 1.3: return false
	throw_kind = kind; throw_target = target; throw_power = power; throw_released = false
	defense_facing = (target-player.global_position).normalized(); defense_facing.y = 0
	defense_facing = defense_facing.normalized()
	player.cancel_charge()
	player.action = "keeper_throw"; player.cooldown = .75; change(State.THROW)
	return true

func release() -> void:
	holding = false
	if state in [State.CATCH,State.HOLD]: change(State.RECOVER)

func release_to_feet() -> void:
	holding = false; change(State.RECOVER)
