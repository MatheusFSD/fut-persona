extends SceneTree
const PLAYER = preload("res://scripts/footballer.gd")
const ROSTER = preload("res://scripts/roster_loader.gd")
var game
var samples: Array = []

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/selecoes-"+label+".png")

func actor(profile: Resource, team: Dictionary, at: Vector3):
	var p := PLAYER.new()
	p.setup(game,0,profile.posicao,at,profile,team); game.add_child(p)
	p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	p.avatar.rotation.y = 0; p.marker.hide(); p.number_label.hide()
	p.animator.play("football/Idle_Loop"); p.animator.seek(.25,true); p.animator.pause()
	samples.append(p)
	return p

func caption(at: Vector3, value: String, color := Color("f5eacb")) -> void:
	var label := Label3D.new(); label.text = value
	label.position = at; label.font_size = 30; label.pixel_size = .006; label.outline_size = 6
	label.modulate = color; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	game.add_child(label); samples.append(label)

func clear_samples() -> void:
	for sample in samples: sample.hide(); sample.queue_free()
	samples.clear()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.ball.freeze = true
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	await capture("menu")
	game.hud.team_choices[0].item_selected.emit(2)
	game.hud.kit_choices[0].item_selected.emit(1)
	await capture("menu-alemanha")
	game.select_match(game.team_catalog.selection)
	game.hud.hide(); game.ball.hide()
	for p in game.players: p.hide()
	var catalog: Dictionary = game.team_catalog
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	game.camera.size = 12; game.camera.position = Vector3(0,9,20); game.camera.look_at(Vector3(0,.7,-2.5))
	for i in 4:
		for kit in 2:
			var nation: Dictionary = catalog.teams[i]
			var data := ROSTER.assemble_match(catalog,[{"time":nation.id,"uniforme":nation.uniformes[kit].id},{"time":catalog.teams[(i+1)%4].id,"uniforme":"titular"}])
			var at := Vector3((i-1.5)*4.6,0,-kit*5.0)
			actor(data.players[1],data.teams[0],at+Vector3(-.8,0,0))
			actor(data.players[0],data.teams[0],at+Vector3(.8,0,0))
			caption(at+Vector3(0,2.3,0),nation.nome.to_upper()+"\n"+nation.uniformes[kit].nome)
	await capture("oito-uniformes")
	clear_samples()
	game.camera.size = 5.8; game.camera.position = Vector3(0,3.0,15); game.camera.look_at(Vector3(0,.8,0))
	for nation: Dictionary in catalog.teams:
		for kit in 2:
			var data := ROSTER.assemble_match(catalog,[{"time":nation.id,"uniforme":nation.uniformes[kit].id},{"time":catalog.teams[(catalog.teams.find(nation)+1)%4].id,"uniforme":"titular"}])
			actor(data.players[1],data.teams[0],Vector3(kit*4-3,0,0))
			actor(data.players[0],data.teams[0],Vector3(kit*4-1,0,0))
			caption(Vector3(kit*4-2,2.45,0),nation.nome.to_upper()+"\n"+nation.uniformes[kit].nome)
			caption(Vector3(kit*4-3,-.15,0),"LINHA",Color("c2d7ab"))
			caption(Vector3(kit*4-1,-.15,0),"GOLEIRO",Color("c2d7ab"))
		await capture(nation.id)
		clear_samples()
	print("NATIONS_CAPTURES_OK")
	game.queue_free(); await process_frame; await process_frame
	quit()
