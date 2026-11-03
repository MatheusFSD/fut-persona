extends SceneTree
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)

func foot_positions(rig: Skeleton3D) -> Array[Vector3]:
	rig.force_update_all_bone_transforms()
	return [rig.get_bone_global_pose(rig.find_bone("foot_l")).origin,rig.get_bone_global_pose(rig.find_bone("foot_r")).origin]

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	for p in game.players: p.set_physics_process(false)
	for p in game.players:
		var tree = p.animation_tree
		var rig: Skeleton3D = p.avatar.find_children("*","Skeleton3D",true,false)[0]
		for speed in [.75,1.5,3.0,4.5,6.0,7.4]:
			tree.reset(); tree.locomotion(speed)
			tree.tick(.05,false)
			var first := foot_positions(rig); var excursion := 0.0; var clock_moved := false
			for frame in 60:
				tree.locomotion(speed); tree.tick(1.0/60.0,false)
				var feet := foot_positions(rig)
				for foot in 2: excursion = maxf(excursion,feet[foot].distance_to(first[foot]))
				clock_moved = clock_moved or tree.playback.get_current_play_position() > .05
			check(clock_moved and excursion > .15,"feet actually cycle while moving: "+str(p.name)+" speed="+str(speed)+" excursion="+str(excursion))
		# Changing speed must keep the shared stride phase, including acceleration.
		tree.reset(); tree.locomotion(1.5); tree.tick(.2,false)
		var phase: float = tree.playback.get_current_play_position()
		tree.locomotion(7.4)
		check(is_equal_approx(phase,tree.playback.get_current_play_position()),"changing gait preserves phase: "+str(p.name))
		var frozen := foot_positions(rig)
		tree.tick(.5,true)
		check(foot_positions(rig) == frozen,"pause freezes cycling feet")
		tree.tick(.05,false)
		check(foot_positions(rig) != frozen,"resume animates feet again")
	# Exercise the same per-frame path as human input, beyond isolated tree poses.
	var p = game.players[4]
	var rig: Skeleton3D = p.avatar.find_children("*","Skeleton3D",true,false)[0]
	game.phase = "playing"; game.controlled = p; game.spectator = false; game._drop_carrier()
	game.ball.freeze = true; game.ball.position = Vector3(15,.25,12)
	for actor in game.players: actor.position = Vector3(-15+actor.slot*4,.05,10 if actor.team == 0 else -10)
	for sprint in [false,true]:
		p.reset_at(Vector3(0,.05,0)); p.stamina = 1
		var first := foot_positions(rig); var excursion := 0.0
		Input.action_press("right")
		if sprint: Input.action_press("sprint")
		Input.flush_buffered_events()
		p.set_physics_process(true)
		for frame in 45:
			await physics_frame
			var feet := foot_positions(rig)
			for foot in 2: excursion = maxf(excursion,feet[foot].distance_to(first[foot]))
		Input.action_release("right"); Input.action_release("sprint")
		p.set_physics_process(false)
		check(p.position.x > (4.0 if sprint else 2.5) and excursion > .4,"live movement advances legs as well as body; sprint="+str(sprint)+" distance="+str(p.position.x)+" excursion="+str(excursion))
	game.queue_free(); await process_frame; await process_frame
	print("LOCOMOTION ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
