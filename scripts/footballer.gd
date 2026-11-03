extends CharacterBody3D
## Locomotion and collision belong to CharacterBody3D. The UAL rig only animates.
const LIBRARY = preload("res://assets/animations/football.res")
const KICKS = preload("res://assets/animations/kicks.res")
const MEDIUM_SHOT_MIN := .55
const STRONG_SHOT_MIN := .85
const BODIES = preload("res://scripts/body_types.gd")
const APPEARANCE = preload("res://scripts/player_appearance.gd")
const PLAYER_ANIMATION = preload("res://scenes/player_animation.tscn")
const GOALKEEPER = preload("res://scripts/goalkeeper.gd")
const KEEPER_POSES = preload("res://scripts/goalkeeper_poses.gd")
static var custom_poses: Dictionary = {}
var game
var profile: Resource
var team_definition: Dictionary
var team := 0
var slot := 0
var body_type := 0
var body_height := 1.0
var home := Vector3.ZERO
var facing := Vector3.RIGHT
var stamina := 1.0
var cooldown := 0.0
var stun := 0.0
const FALL_RATE := 1.4
var fall_time := -1.0
var action := ""
var action_time := 0.0
var action_length := 0.0
var contact_done := false
var kick_target := Vector3.ZERO
var kick_power := .5
var kick_style := "weak"
var kick_contact := .19
var charging := 0.0
var shot_input := ""
var brain_time := 0.0
var sprinting := false
var avatar: Node3D
var animator: AnimationPlayer
var animation_tree: AnimationTree
var goalkeeper
var body_collision: CollisionShape3D
var marker: MeshInstance3D
var number_label: Label3D
var current_clip := ""
var visual_offset := PI
var control_direction := Vector3.ZERO

func setup(match_node, side: int, index: int, spawn: Vector3, player_profile: Resource = null, definition: Dictionary = {}) -> void:
	game = match_node; team = side; slot = index; home = spawn; position = spawn
	profile = player_profile if player_profile != null else game.roster_profiles[side*5+index]
	team_definition = definition if not definition.is_empty() else game.team_definitions[side]
	body_type = profile.tipo_corpo
	avatar = APPEARANCE.instantiate_model(team_definition)
	body_height = BODIES.apply_model(avatar,body_type,profile.altura)
	facing = Vector3.RIGHT if team == 0 else Vector3.LEFT
	name = String(profile.id)
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = .3
	var collision := CollisionShape3D.new()
	body_collision = collision
	var capsule := CapsuleShape3D.new(); capsule.radius = BODIES.RADII[body_type]*body_height; capsule.height = profile.altura*.94
	collision.shape = capsule; collision.position.y = capsule.height*.5+.005
	add_child(collision)
	add_child(avatar)
	var animators := avatar.find_children("*", "AnimationPlayer", true, false)
	if animators.is_empty():
		animator = AnimationPlayer.new(); animator.name = "AnimationPlayer"; avatar.add_child(animator)
	else: animator = animators[0]
	animator.add_animation_library("football", BODIES.animation_library(LIBRARY,body_height))
	animator.add_animation_library("kicks", BODIES.animation_library(KICKS,body_height))
	animator.add_animation_library("custom", _football_poses())
	animator.add_animation_library("keeper",KEEPER_POSES.library(animator.get_animation("football/Idle_Loop"),body_height))
	animation_tree = PLAYER_ANIMATION.instantiate()
	avatar.add_child(animation_tree)
	animation_tree.setup(animator)
	APPEARANCE.apply(avatar,profile,team_definition)
	if is_goalkeeper():
		goalkeeper = GOALKEEPER.new(); goalkeeper.name = "Goalkeeper"
		add_child(goalkeeper); goalkeeper.setup(self)
	var ring := TorusMesh.new(); ring.inner_radius = .43; ring.outer_radius = .51
	ring.rings = 16; ring.ring_segments = 6
	marker = MeshInstance3D.new(); marker.mesh = ring; marker.position.y = .045
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(team_definition.camisa).lightened(.2)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	add_child(marker)
	# Lightweight contact shadow remains readable even with Compatibility rendering.
	var shadow := MeshInstance3D.new(); var disk := CylinderMesh.new()
	disk.top_radius = .37; disk.bottom_radius = .37; disk.height = .006
	disk.radial_segments = 16; disk.rings = 1; shadow.mesh = disk
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.12, .10, .06, .25)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; shadow.material_override = sm
	shadow.position.y = .035; add_child(shadow)
	number_label = Label3D.new(); number_label.text = str(profile.numero)
	number_label.position.y = profile.altura+.25; number_label.font_size = 32; number_label.pixel_size = .011
	number_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number_label.modulate = Color(team_definition.camisa).lightened(.3)
	number_label.outline_size = 5; add_child(number_label)
	_play("football/Idle_Loop")

func is_goalkeeper() -> bool:
	return profile.is_goalkeeper()

func _physics_process(delta: float) -> void:
	if goalkeeper != null: goalkeeper.prepare(delta)
	_update_player(delta)
	animation_tree.tick(delta,game.phase == "paused")
	if goalkeeper != null: goalkeeper.finish(delta)

func _update_player(delta: float) -> void:
	marker.visible = game.controlled == self
	number_label.visible = game.controlled == self or game.pass_target == self
	if game.phase == "paused":
		return
	if fall_time >= 0:
		fall_time += delta
		velocity.x = 0; velocity.z = 0
		if not is_on_floor(): velocity.y -= 18*delta
		else: velocity.y = -.4
		move_and_slide()
		var down := animator.get_animation("football/Hit_Knockback").length/FALL_RATE
		if fall_time < fall_duration():
			_play("football/Hit_Knockback" if fall_time < down else "football/LayToIdle",FALL_RATE)
			return
		fall_time = -1; stun = 0; current_clip = ""
	cooldown = maxf(0, cooldown-delta)
	stun = maxf(0, stun-delta)
	brain_time = maxf(0, brain_time-delta)
	if goalkeeper != null and goalkeeper.defending():
		goalkeeper.move_defense(delta)
		return
	if not is_on_floor(): velocity.y -= 18 * delta
	else: velocity.y = -.4
	if not game.live() and not game.is_set_piece_taker(self):
		velocity.x = 0; velocity.z = 0
		move_and_slide()
		if game.phase == "foul" and action == "slide":
			action_time += delta
			if action_time >= action_length: action = ""
			_animate()
		elif game.phase == "celebrate" and not game.goal_reveal_pending and game.last_goal_team == team: _play("football/Yes")
		else: _play("football/Idle_Loop")
		return
	var move := Vector3.ZERO
	sprinting = false
	if stun > 0:
		cancel_charge()
		move = Vector3.ZERO
	elif game.controlled == self and not game.spectator:
		var input := Input.get_vector("left", "right", "up", "down")
		move = Vector3(input.x, 0, input.y)
		sprinting = Input.is_action_pressed("sprint") and stamina > .08
		var reception: Dictionary = game.reception_command(self,move,true)
		if not reception.is_empty():
			move = reception.move
			sprinting = reception.sprint and stamina > .08
		control_direction = move
		if Input.is_action_just_pressed("pass"): request_kick("pass", game.pass_aim(self), .5)
		if Input.is_action_just_pressed("mouse_primary"):
			if game.can_play_ball(self): shot_input = "mouse_primary"; charging = 0
			else: request_tackle(true)
		if Input.is_action_just_pressed("mouse_secondary"):
			if game.can_play_ball(self): request_kick("pass", game.pass_aim(self), .5)
			else: request_tackle(false)
		if Input.is_action_just_pressed("shoot") and game.can_play_ball(self):
			shot_input = "shoot"; charging = 0
		if not shot_input.is_empty():
			if not game.can_play_ball(self): cancel_charge()
			elif Input.is_action_just_released(shot_input):
				request_kick("shot", game.shot_aim(self), .3 + charging / 1.05 * .7)
				cancel_charge()
			elif Input.is_action_pressed(shot_input): charging = minf(charging + delta, 1.05)
			else: cancel_charge()
		if Input.is_action_just_pressed("tackle"): request_tackle(false)
		if Input.is_action_just_pressed("slide"): request_tackle(true)
	else:
		var command: Dictionary = game.ai_command(self, delta)
		move = command.get("move", Vector3.ZERO)
		sprinting = command.get("sprint", false) and stamina > .1
	if game.is_set_piece_taker(self):
		move = Vector3.ZERO; sprinting = false; control_direction = Vector3.ZERO
	if goalkeeper != null and goalkeeper.defending():
		_animate(); return
	stamina = clampf(stamina + (-.16 if sprinting and move.length() > .2 else .12) * delta, 0, 1)
	if not action.is_empty():
		action_time += delta
		if action in ["shot", "pass"] and action_time >= kick_contact and not contact_done:
			animation_tree.seek_contact(kick_contact)
			contact_done = true; game.strike(self, kick_target, action, kick_power)
		if action in ["slide", "tackle"] and action_time > .09 and action_time < (.55 if action == "slide" else .3):
			game.challenge(self, action == "slide")
		if action_time >= action_length:
			action = ""; current_clip = ""
	var desired := move * (7.4 if sprinting else 4.5)
	if action == "slide":
		desired = facing * lerpf(11, 2.5, clampf(action_time / .85, 0, 1))
	elif action in ["shot", "pass", "tackle"]: desired *= .22
	if stun > 0: desired = Vector3.ZERO
	velocity.x = move_toward(velocity.x, desired.x, 26 * delta)
	velocity.z = move_toward(velocity.z, desired.z, 26 * delta)
	if goalkeeper != null and game.carrier != self and action.is_empty() and stun <= 0:
		facing = facing.lerp(goalkeeper.look_direction(),minf(delta*12,1)).normalized()
	elif move.length() > .1 and action.is_empty() and stun <= 0:
		var look := move.normalized()
		facing = facing.lerp(look, minf(delta * 18, 1)).normalized()
	avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(-facing.x, -facing.z) + visual_offset, minf(delta*20, 1))
	move_and_slide()
	position.x = clampf(position.x, -25.4, 25.4)
	position.z = clampf(position.z, -15.4, 15.4)
	_animate()

func request_kick(kind: String, target: Vector3, power: float) -> bool:
	if not game.live() and not game.is_set_piece_taker(self): return false
	if goalkeeper != null and goalkeeper.holding: return goalkeeper.distribute(kind,target,power)
	if cooldown > 0 or not action.is_empty() or stun > 0: return false
	if game.carrier != null and game.carrier != self: return false
	if game.flat_distance(position, game.ball.position) > 1.9: return false
	if kind == "pass": game.prepare_reception(self,target)
	else: game.clear_reception()
	action = kind; action_time = 0; action_length = .54 if kind == "shot" else .42
	kick_target = target; kick_power = power; contact_done = false
	kick_style = shot_style(power) if kind == "shot" else "weak"
	kick_contact = .19
	if kind == "shot" and kick_style != "weak":
		var animation := animator.get_animation("kicks/Kick_Medium" if kick_style == "medium" else "kicks/Kick_Strong")
		kick_contact = float(animation.get_meta("contact_seconds"))
		action_length = animation.length
	facing = (target-position).normalized(); facing.y = 0
	cooldown = .65
	current_clip = ""
	_animate()
	return true

static func shot_style(power: float) -> String:
	return "strong" if power >= STRONG_SHOT_MIN else "medium" if power >= MEDIUM_SHOT_MIN else "weak"

func request_tackle(sliding: bool) -> bool:
	if not game.live(): return false
	if cooldown > 0 or not action.is_empty() or stun > 0: return false
	action = "slide" if sliding else "tackle"
	action_time = 0; action_length = 1.05 if sliding else .45; contact_done = false
	cooldown = 1.8 if sliding else .8
	cancel_charge(); current_clip = ""
	game.dust(position)
	return true

func reset_at(at: Vector3) -> void:
	position = at; velocity = Vector3.ZERO; action = ""; current_clip = ""
	fall_time = -1; stun = 0; cooldown = .35; cancel_charge()
	facing = Vector3.RIGHT if team == 0 else Vector3.LEFT
	animation_tree.reset()
	if goalkeeper != null: goalkeeper.reset()

func fall_duration() -> float:
	return (animator.get_animation("football/Hit_Knockback").length+animator.get_animation("football/LayToIdle").length)/FALL_RATE

func fall_from_tackle() -> void:
	fall_time = 0; stun = fall_duration(); cooldown = maxf(cooldown,stun)
	action = ""; contact_done = true; cancel_charge(); velocity = Vector3.ZERO
	current_clip = ""; _play("football/Hit_Knockback",FALL_RATE)

func cancel_fall() -> void:
	if fall_time < 0: return
	fall_time = -1; stun = 0; current_clip = ""
	_play("football/Idle_Loop")

func cancel_charge() -> void:
	charging = 0
	shot_input = ""

func _animate() -> void:
	if stun > 0: _play("football/Jump_Land", 1.4)
	elif goalkeeper != null and not goalkeeper.pose_clip().is_empty(): _play(goalkeeper.pose_clip())
	elif action == "slide":
		if action_time < .2: _play("football/Slide_Start", 1.5)
		elif action_time < .7: _play("football/Slide_Loop", 1)
		else: _play("football/Slide_Exit", 1.6)
	elif action == "shot" and kick_style != "weak":
		_play("kicks/Kick_Medium" if kick_style == "medium" else "kicks/Kick_Strong")
	elif not action.is_empty(): _play("custom/" + action)
	else:
		var speed := Vector2(velocity.x, velocity.z).length()
		animation_tree.locomotion(speed)
		# Diagnostic label; the live pose is a continuous blend of adjacent clips.
		if speed < .25: current_clip = "football/Idle_Loop"
		elif speed < 2.1: current_clip = "football/Walk_Loop"
		elif speed < 5.95: current_clip = "football/Jog_Fwd_Loop"
		else: current_clip = "football/Sprint_Loop"

func _play(clip: String, rate := 1.0) -> void:
	animation_tree.play_clip(clip,rate,current_clip.is_empty())
	current_clip = clip

func _football_poses() -> AnimationLibrary:
	if custom_poses.has(body_height): return custom_poses[body_height]
	# The packs have no football kicks. Author new bone keys on their actual idle pose.
	# All channels stay on the supplied 65-bone RioRig; no alternate character rig.
	var library := AnimationLibrary.new()
	for kind in ["shot", "pass", "tackle"]:
		var source := animator.get_animation("football/Idle_Loop")
		var animation := Animation.new()
		animation.length = .54 if kind == "shot" else (.42 if kind == "pass" else .45)
		var scale_factor := 1.0 if kind == "shot" else .65
		var bend: Dictionary = {
			"thigh_r": [Vector3(.7, 0, .08), Vector3(-1.0, 0, -.1)],
			"calf_r": [Vector3(1.3, 0, 0), Vector3(.12, 0, 0)],
			"foot_r": [Vector3(.25, 0, 0), Vector3(-.25, 0, 0)],
			"spine_02": [Vector3(-.15, -.3, .1), Vector3(.3, .25, -.1)],
			"upperarm_l": [Vector3(.15, .1, -.35), Vector3(-.2, 0, -.4)],
			"upperarm_r": [Vector3(-.15, 0, .4), Vector3(.2, 0, .3)]
		}
		if kind == "tackle":
			bend["thigh_r"] = [Vector3(.2, 0, .12), Vector3(-.55, .25, -.15)]
			bend["calf_r"] = [Vector3(.6, 0, 0), Vector3(.15, 0, 0)]
		for i in source.get_track_count():
			var type := source.track_get_type(i)
			if type not in [Animation.TYPE_ROTATION_3D, Animation.TYPE_POSITION_3D, Animation.TYPE_SCALE_3D]: continue
			var track := animation.add_track(type)
			animation.track_set_path(track, source.track_get_path(i))
			var value: Variant
			if type == Animation.TYPE_ROTATION_3D: value = source.rotation_track_interpolate(i, 0)
			elif type == Animation.TYPE_POSITION_3D: value = source.position_track_interpolate(i, 0)
			else: value = source.scale_track_interpolate(i, 0)
			animation.track_insert_key(track, 0, value)
			var bone := String(source.track_get_path(i)).get_slice(":", 1)
			if type == Animation.TYPE_ROTATION_3D and bend.has(bone):
				animation.track_insert_key(track, .11, value * Quaternion.from_euler(bend[bone][0] * scale_factor))
				animation.track_insert_key(track, .19, value * Quaternion.from_euler(bend[bone][1] * scale_factor))
			animation.track_insert_key(track, animation.length, value)
		library.add_animation(kind, animation)
	custom_poses[body_height] = library
	return library
