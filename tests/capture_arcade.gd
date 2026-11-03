extends SceneTree
var game
var hud

func _initialize() -> void:
	call_deferred("run")

func frame(label: String) -> void:
	hud.queue_redraw()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/arcade-"+label+".png")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.ball.freeze = true
	for p in game.players: p.set_physics_process(false)
	hud = game.hud; hud.set_process(false); hud.animation_time = 1.2
	await frame("menu")
	hud.team_choices[0].show_popup()
	await frame("bandeiras")
	hud.team_choices[0].get_popup().hide()
	hud.team_choices[0].item_selected.emit(2)
	hud.team_choices[1].item_selected.emit(3)
	hud.kit_choices[0].item_selected.emit(1)
	await frame("alemanha-franca")
	game.select_match(game.team_catalog.selection)
	game.new_match()
	for p in game.players: p.set_physics_process(false)
	game.phase = "playing"; game.message_timer = 0; game.elapsed = 37
	hud._process(0); await frame("partida")
	game.controlled.charging = .8
	await frame("chute")
	game.controlled.cancel_charge()
	game.toggle_pause(); hud._process(0); await frame("pausa")
	game.toggle_pause(); game.goal(0)
	for age in [.15,.55,1.1,2.25]:
		game.phase_timer = game.GOAL_DURATION-age; hud._process(0)
		await frame("gol-"+str(age).replace(".","-"))
	if "--record-goal" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://.runtime/goal-frames")
		for i in 56:
			game.phase_timer = game.GOAL_DURATION-float(i)/20.0
			hud.animation_time = 1.2+float(i)/20.0; hud._process(0); hud.queue_redraw()
			await process_frame; await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image(); image.resize(800,500,Image.INTERPOLATE_LANCZOS)
			image.save_png("res://.runtime/goal-frames/%03d.png" % i)
	game.phase = "playing"; game.goal(1); game.phase_timer = 1.7; hud._process(0)
	await frame("gol-argentina")
	game.phase = "finished"; hud._process(0); await frame("resultado")
	root.size = Vector2i(960,600); game.phase = "menu"; hud._process(0)
	await frame("menu-960")
	root.size = Vector2i(1600,900); await process_frame; hud._process(0); await frame("menu-16-9")
	root.size = Vector2i(1024,768); await process_frame; hud._process(0); await frame("menu-4-3")
	print("ARCADE_CAPTURES_OK")
	game.queue_free(); await process_frame; await process_frame
	quit()
