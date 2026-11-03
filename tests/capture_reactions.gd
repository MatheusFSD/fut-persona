extends SceneTree
var game
var hud

func _initialize() -> void:
	call_deferred("run")

func frame(label: String) -> void:
	hud.queue_redraw()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/reacao-"+label+".png")

func focus(at: Vector3) -> void:
	game.camera.position = at+Vector3(0,16.5,25)
	game.camera.look_at(at+Vector3.UP*.35)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.ball.freeze = true
	game.phase = "playing"; game.message_timer = 0
	hud = game.hud; hud.set_process(false); hud.animation_time = .6
	var p = game.controlled; var victim = game.players[9]
	for actor in game.players:
		actor.set_physics_process(false); actor.collision_layer = 0; actor.collision_mask = 0
		actor.marker.visible = actor == p; actor.number_label.visible = actor == p
	p.position = Vector3(-1,.05,0); p.facing = Vector3.RIGHT; p.avatar.rotation.y = PI/2
	victim.position = Vector3(1.1,.05,0); victim.facing = Vector3.LEFT; victim.avatar.rotation.y = -PI/2
	game.ball.position = Vector3(.35,.25,0); game.take_possession(victim)
	game.challenge(p,true)
	p.animator.play("football/Slide_Loop"); p.animator.seek(.12,true); p.animator.pause()
	victim.animator.play("football/Jump_Land"); victim.animator.seek(.15,true); victim.animator.pause()
	hud._process(.3); await frame("na-bola")
	if "--record-reaction" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://.runtime/reaction-frames")
		var event: Dictionary = hud.reactions[0].duplicate(true)
		for i in 32:
			var age := i/20.0
			hud.clear_reactions(); event.age = age; hud.reactions.append(event.duplicate(true))
			hud._process(0); game.camera.position.x = age*.8; hud.queue_redraw()
			await process_frame; await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image(); image.resize(800,500,Image.INTERPOLATE_LANCZOS)
			image.save_png("res://.runtime/reaction-frames/%03d.png" % i)
	focus(Vector3.ZERO); hud.clear_reactions(); game._drop_carrier()
	game.ball.position = Vector3(.4,.25,0); p.contact_done = false
	p.animator.play("custom/shot"); p.animator.seek(.19,true); p.animator.pause()
	game.strike(p,Vector3(24,0,0),"shot",1)
	hud._process(.25); await frame("woooow")
	hud.clear_reactions(); focus(Vector3(20,0,0))
	game.ball.position = Vector3(23.7,1,3.4); game.ball.linear_velocity = Vector3(15,0,0)
	var closest: Node; var distance := INF
	for post in get_nodes_in_group("goal_frame"):
		var d: float = post.position.distance_to(game.ball.position)
		if d < distance: distance = d; closest = post
	game._ball_contact(closest); hud._process(.25); await frame("na-traveee")
	hud.clear_reactions(); game.ball.position = Vector3(21.3,.45,0)
	var keeper = game.players[5]; keeper.position = Vector3(22,.05,0)
	keeper.avatar.rotation.y = -PI/2; keeper.animator.play("football/Idle_Loop"); keeper.animator.seek(.25,true); keeper.animator.pause()
	game.recent_shot_team = 0; game.recent_shot_time = 2; game.ball.linear_velocity = Vector3(18,0,0)
	game.take_possession(keeper); hud._process(.25); await frame("milagre")
	focus(Vector3.ZERO)
	game.begin_restart(1,Vector3(8,.05,-5),"FALTA • BOLA PARADA",false)
	hud._process(.25); await frame("foi-mal")
	game.begin_restart(0,Vector3(4,.24,13.6),"LATERAL",false)
	hud._process(.25); await frame("saiu")
	print("REACTION_CAPTURES_OK")
	game.queue_free(); await process_frame; await process_frame
	quit()
