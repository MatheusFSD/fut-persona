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
func mouse(down: bool) -> void:
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
	Input.parse_input_event(event)
func reset() -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception(); game.collision_epoch += 1
	game.phase = "playing"; game.kick_lock = 0; game.released_by = null; game.release_guard = 0; game.auto_switch_lock = 0
	for p in game.players:
		p.set_physics_process(false); p.reset_at(game.formation(p.team,p.slot)); p.contact_done = false
		game.ball.remove_collision_exception_with(p)
	game.controlled = game.players[4]; var p = game.controlled
	p.reset_at(Vector3(0,.05,0)); p.cooldown = 0; p.facing = Vector3.RIGHT
	game.ball.freeze = true; game.ball.position = Vector3(.75,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.carrier = p; game.ball.add_collision_exception_with(p)
	game.camera_focus = Vector3(0,.35,0); game.camera_base_fov = 43; game._update_camera(0)
	var motion := InputEventMouseMotion.new(); motion.position = root.get_final_transform()*game.camera.unproject_position(Vector3(20,0,0))
	Input.parse_input_event(motion)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.juice.set_process(false); game.hud.hide(); game.muted = true
	for p in game.players: p.set_physics_process(false)
	var p = game.players[4]
	for row in [[.3,"weak"],[.549,"weak"],[.55,"medium"],[.849,"medium"],[.85,"strong"],[1.0,"strong"]]:
		check(p.shot_style(row[0]) == row[1],"power threshold "+str(row[0]))
	check(p.animator.get_animation("custom/shot").length == .54,"weak shot keeps original authored animation")
	for actor in game.players:
		var rig: Skeleton3D = actor.avatar.find_children("*","Skeleton3D",true,false)[0]
		check(rig.get_bone_count() == 65,"65 original bones: "+str(actor.name))
		var rest := rig.get_bone_rest(0)
		actor.animator.play("football/Idle_Loop",0); actor.animator.seek(0,true); actor.animator.pause(); rig.force_update_all_bone_transforms()
		var foot := rig.find_bone("foot_l"); var root_bone := rig.find_bone("root")
		var planted: Vector3 = rig.get_bone_global_pose(foot).origin
		var root_pose := rig.get_bone_pose_rotation(root_bone)
		for clip in ["kicks/Kick_Medium","kicks/Kick_Strong"]:
			var animation: Animation = actor.animator.get_animation(clip)
			var safe := true; var plant_error := 0.0; var min_head := INF
			for i in 25:
				actor.animator.play(clip,0); actor.animator.seek(animation.length*i/24.0,true); actor.animator.pause(); rig.force_update_all_bone_transforms()
				plant_error = maxf(plant_error,rig.get_bone_global_pose(foot).origin.distance_to(planted))
				min_head = minf(min_head,rig.get_bone_global_pose(rig.find_bone("Head")).origin.y)
				for b in rig.get_bone_count(): safe = safe and rig.get_bone_global_pose(b).is_finite()
			check(safe and min_head > actor.profile.altura*.5,"new kick remains upright and finite across 25 poses: "+str(actor.name)+clip)
			check(plant_error < .025,"support foot stays planted: "+str(actor.name)+clip+" error="+str(plant_error))
			check(rig.get_bone_pose_rotation(root_bone).angle_to(root_pose) < .001 and rig.get_bone_rest(0) == rest,"Blender export never changes game root or rest bones")
	# Mechanical preparation and arm balance are visible before foot contact.
	var rig: Skeleton3D = p.avatar.find_children("*","Skeleton3D",true,false)[0]
	for row in [["Kick_Medium",.13,.22,.64],["Kick_Strong",.18,.27,.82]]:
		p.animator.play("kicks/"+row[0],0); p.animator.seek(row[1],true); p.animator.pause(); rig.force_update_all_bone_transforms()
		var back: Vector3 = rig.get_bone_global_pose(rig.find_bone("foot_r")).origin
		var left: Vector3 = rig.get_bone_global_pose(rig.find_bone("hand_l")).origin
		var right: Vector3 = rig.get_bone_global_pose(rig.find_bone("hand_r")).origin
		p.animator.seek(row[2],true); rig.force_update_all_bone_transforms()
		var contact: Vector3 = rig.get_bone_global_pose(rig.find_bone("foot_r")).origin
		check(contact.z-back.z > .4,"loaded backswing precedes forward strike "+row[0])
		var left_move := left.distance_to(rig.get_bone_global_pose(rig.find_bone("hand_l")).origin)
		var right_move := right.distance_to(rig.get_bone_global_pose(rig.find_bone("hand_r")).origin)
		print("ARM_SWEEP ",row[0]," left=",left_move," right=",right_move)
		check(left_move > .15 and right_move > .15,"both arms counterbalance through contact "+row[0])
		check(is_equal_approx(p.animator.current_animation_length,row[3]),"distinct recovery duration "+row[0])
	# Actual mouse input: holding never starts wind-up; release chooses the variant.
	for row in [[6,"weak","custom/shot",.19],[30,"medium","kicks/Kick_Medium",.22],[60,"strong","kicks/Kick_Strong",.27]]:
		reset(); p = game.controlled; p.set_physics_process(true)
		var shots: int = game.stats.shots[0]
		mouse(true); await ticks(row[0])
		check(p.charging > 0 and p.action.is_empty() and p.current_clip == "football/Idle_Loop","holding charge never plays anticipation: "+row[1])
		check(game.stats.shots[0] == shots and not game.juice.shot.active,"no launch or shot camera before mouse release")
		game.ball.freeze = false; mouse(false); await ticks(2)
		check(p.action == "shot" and p.kick_style == row[1] and p.current_clip == row[2],"release starts correct native animation: "+row[1])
		check(is_equal_approx(p.kick_contact,row[3]) and p.charging == 0,"contact timestamp and charge reset follow selected variant")
		while p.action_time < p.kick_contact-.034:
			check(game.stats.shots[0] == shots and not game.juice.shot.active,"no early impulse/camera during anticipation")
			await ticks(1)
		var count := 0
		while not p.contact_done and count < 30: await ticks(1); count += 1
		check(p.contact_done and p.action_time >= p.kick_contact and game.stats.shots[0] == shots+1,"exactly one native impulse at variant foot contact")
		check(game.juice.shot.active == (row[1] == "strong"),"behind-player camera only on strong shot")
		await ticks(10)
		check(game.stats.shots[0] == shots+1,"follow-through cannot kick again")
		mouse(false); p.set_physics_process(false)
	reset(); p = game.controlled
	for power in [.7,1.0]:
		reset(); p = game.controlled; game.ball.freeze = false
		p.request_kick("shot",Vector3(20,0,0),power)
		p._physics_process(p.kick_contact-.001)
		check(not p.contact_done,"quick anticipation does not release one millisecond early")
		p._physics_process(.002)
		check(p.contact_done and is_equal_approx(p.animation_tree.playback.get_current_play_position(),p.kick_contact),"tree contact explicitly synchronizes authored foot pose")
	reset(); p = game.controlled
	for power in [.3,.7,.849,.85,1.0]:
		game.juice.reset_presentation(); game.ball.freeze = false; game.ball.position = Vector3(.75,.25,0); game.carrier = p
		game.strike(p,Vector3(24,0,0),"shot",power)
		check(game.juice.shot.active == (power >= .85),"AI/direct/cobrança strength also gates cinematic: "+str(power))
	game.juice.reset_presentation(); game.queue_free(); await process_frame; await process_frame
	check(Engine.time_scale == 1,"new kick variants leave normal engine time on teardown")
	print("KICK_VARIANTS ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
