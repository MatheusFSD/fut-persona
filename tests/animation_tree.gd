extends SceneTree
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)

func pose(rig: Skeleton3D) -> Array[Quaternion]:
	rig.force_update_all_bone_transforms()
	var result: Array[Quaternion] = []
	for bone in rig.get_bone_count(): result.append(rig.get_bone_pose_rotation(bone))
	return result

func prepare(p) -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.kick_lock = 0; game.spectator = false; game.controlled = p
	p.reset_at(Vector3(0,.05,0)); p.cooldown = 0
	game.ball.freeze = true; game.ball.position = Vector3(.75,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.carrier = p

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	game.juice.shot_cinematic_enabled = false; game.juice.slide_cinematic_enabled = false
	for p in game.players: p.set_physics_process(false)
	for p in game.players:
		var tree = p.animation_tree
		var rig: Skeleton3D = p.avatar.find_children("*","Skeleton3D",true,false)[0]
		check(tree.active and tree.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL,"manual tree active: "+str(p.name))
		# Intermediate velocity must produce a real blend, beyond changing a label.
		var samples: Array = []
		for speed in [0.0,.75,1.5]:
			tree.reset(); tree.locomotion(speed); tree.seek_contact(0.0)
			samples.append(pose(rig))
		var mixed := true; var motion := 0.0
		for bone in rig.get_bone_count():
			var distance: float = samples[0][bone].angle_to(samples[2][bone])
			motion = maxf(motion,distance)
			if distance > .1:
				var from_idle: float = samples[1][bone].angle_to(samples[0][bone])
				var from_walk: float = samples[1][bone].angle_to(samples[2][bone])
				mixed = mixed and from_idle > distance*.3 and from_idle < distance*.7 and from_walk > distance*.3 and from_walk < distance*.7
		check(motion > .1 and mixed,"actual idle/walk half blend on metric skeleton: "+str(p.name))
		tree.reset(); tree.play_clip("custom/pass"); tree.tick(.05,false)
		check(tree.playback.get_current_node() == "Pass" and tree.playback.get_fading_from_node() == "Locomotion","pass crossfades from locomotion")
		tree.tick(.08,false)
		check(tree.playback.get_fading_from_node().is_empty(),"crossfade completes")
		var age: float = tree.playback.get_current_play_position(); var frozen := pose(rig)
		tree.tick(.3,true)
		check(is_equal_approx(tree.playback.get_current_play_position(),age) and pose(rig) == frozen,"pause freezes playback and skeleton")
		tree.play_clip("custom/pass"); tree.tick(.02,false)
		check(tree.playback.get_current_play_position() > age,"resume continues same action")
		tree.play_clip("football/Hit_Knockback",1.4); tree.tick(.04,false)
		check(tree.playback.get_current_node() == "Fall","foul interrupts any action directly")
		tree.play_clip("football/LayToIdle",1.4); tree.tick(.15,false)
		check(tree.playback.get_current_node() == "GetUp","get-up follows fall through tree")
		tree.play_clip("football/Yes"); tree.tick(.15,false)
		check(tree.playback.get_current_node() == "Celebrate","celebration interrupts through tree")
		p.reset_at(p.home)
		check(tree.playback.get_current_node() == "Locomotion" and tree.playback.get_fading_from_node().is_empty(),"restart clears previous action and fade")
	# Independent playback despite shared graph and clip resources.
	var p = game.players[4]; var other = game.players[9]
	p.animation_tree.play_clip("kicks/Kick_Strong"); p.animation_tree.tick(.1,false)
	check(other.animation_tree.playback.get_current_node() == "Locomotion" and other.animation_tree.get("parameters/States/Locomotion/blend_position") == 0,"teammates/opponents never share playback parameters")
	for power in [.3,.7,1.0]:
		prepare(p)
		var rig: Skeleton3D = p.avatar.find_children("*","Skeleton3D",true,false)[0]
		check(p.request_kick("shot",Vector3(20,0,0),power),"shot accepted: "+str(power))
		var clip: String = p.current_clip
		p.animator.play(clip,0); p.animator.seek(p.kick_contact,true); p.animator.pause()
		var expected := pose(rig)
		p.animation_tree.reset(); p._animate()
		var shots: int = game.stats.shots[0]
		p._physics_process(p.kick_contact-.001)
		check(not p.contact_done and game.stats.shots[0] == shots,"no impulse before foot contact")
		p._physics_process(.002)
		var actual := pose(rig); var error := 0.0
		for bone in rig.get_bone_count(): error = maxf(error,actual[bone].angle_to(expected[bone]))
		check(p.contact_done and game.stats.shots[0] == shots+1 and error < .003,"single impulse at exact authored pose: "+clip+" error="+str(error))
		p._physics_process(.05)
		check(game.stats.shots[0] == shots+1 and p.animation_tree.playback.get_current_play_position() > p.kick_contact,"follow-through advances without another kick")
	prepare(p); p.request_tackle(true)
	p._physics_process(.1)
	check(p.animation_tree.playback.get_current_node() == "SlideStart","slide start state")
	p._physics_process(.2)
	check(p.animation_tree.playback.get_current_node() == "SlideLoop","slide loop state")
	p._physics_process(.45)
	check(p.animation_tree.playback.get_current_node() == "SlideExit","slide exit state")
	game.selection_menu(); p._physics_process(.016)
	check(p.animation_tree.playback.get_current_node() == "Locomotion","menu clears cinematic/action animation")
	game.queue_free(); await process_frame; await process_frame
	print("ANIMATION_TREE ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
