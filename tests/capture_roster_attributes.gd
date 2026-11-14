extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	for index in 4:
		var team: Dictionary = game.team_catalog.teams[index]
		var opponent: Dictionary = game.team_catalog.teams[(index+1)%4]
		game.phase = "menu"
		game.select_match([{"time":team.id,"uniforme":"titular"},{"time":opponent.id,"uniforme":"titular"}])
		game.hud.hide(); game.ball.hide(); game.ball.freeze = true
		for player in game.players:
			player.set_physics_process(false); player.visible = player.team == 0
			player.position = Vector3((player.slot-2)*2.35,0,0)
			player.avatar.rotation.y = 0; player.marker.hide(); player.number_label.hide()
			player.animation_tree.locomotion(0); player.animation_tree.tick(.2,false)
			var label := Label3D.new()
			label.text = player.profile.nome.to_upper()+"\nVEL %d / CHU %d / TEC %d" % [player.velocidade,player.chute,player.tecnica]
			label.position.y = 2.35; label.font_size = 23; label.pixel_size = .005
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.outline_size = 5
			label.modulate = Color("ffe049"); player.add_child(label)
		game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL; game.camera.size = 8.2
		game.camera.position = Vector3(0,3.4,14); game.camera.look_at(Vector3(0,.9,0))
		await capture("res://qa/elenco-"+team.id+"-atributos.png")
	game.hud.show(); game.phase = "playing"; game.show_attributes = true
	game.hud._process(0)
	await capture("res://qa/ficha-atributos.png")
	game.queue_free(); await process_frame; await process_frame
	print("ROSTER_ATTRIBUTE_CAPTURES_OK"); quit()
