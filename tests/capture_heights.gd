extends "res://tests/capture_nations.gd"

func capture(label: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/altura-"+label+".png")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.hud.hide(); game.ball.hide(); game.ball.freeze = true
	for p in game.players: p.set_physics_process(false); p.hide(); p.collision_layer = 0; p.collision_mask = 0
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL; game.camera.size = 9.2
	game.camera.position = Vector3(0,8,18); game.camera.look_at(Vector3(0,.8,-3.3))
	for side in 2:
		var actors: Array = []
		for height in 3:
			for body in 3:
				var profile: Resource = game.players[side*5+1].profile.duplicate(true)
				profile.tipo_corpo = body; profile.altura = [1.55,1.78,2.00][height]
				var at := Vector3((body-1)*3.2,0,-height*3.6)
				var p = actor(profile,game.team_definitions[side],at); actors.append(p)
				caption(at+Vector3(0,profile.altura+.40,0),p.BODIES.NAMES[body].to_upper()+"\n"+("%.2f m" % profile.altura).replace(".",","))
		await capture(game.team_definitions[side].id)
		if side == 0:
			for clip in ["football/Jog_Fwd_Loop","custom/shot","football/Slide_Loop"]:
				for p in actors: p.animator.play(clip); p.animator.seek(.19,true); p.animator.pause()
				await capture(clip.get_slice("/",1))
		clear_samples()
	# Check the in-game card with both physical attributes visible.
	game.select_match(game.match_selection)
	for p in game.players: p.set_physics_process(false)
	game.hud.show(); game.ball.show(); game.phase = "playing"
	game.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	game.camera.fov = 43; game.camera.position = Vector3(0,16.5,25); game.camera.look_at(Vector3(0,.35,0))
	game.hud.queue_redraw(); await capture("cartao")
	print("HEIGHT_CAPTURES_OK")
	game.queue_free(); await process_frame; await process_frame
	quit()
