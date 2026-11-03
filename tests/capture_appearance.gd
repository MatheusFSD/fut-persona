extends SceneTree
const PROFILE = preload("res://scripts/player_data.gd")
const APPEARANCE = preload("res://scripts/player_appearance.gd")
var game

func _initialize() -> void:
	call_deferred("run")

func frame(label: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/aparencia-"+label+".png")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.hud.hide(); game.ball.hide(); game.ball.freeze = true
	for p in game.players:
		p.set_physics_process(false); p.avatar.rotation.y = 0
		p.position = Vector3((p.slot-2)*2.4,0,-p.team*5)
		p.marker.hide(); p.number_label.hide()
		var label := Label3D.new()
		label.text = p.profile.nome.to_upper()+"\n"+p.profile.position_name().to_upper()
		label.font_size = 28; label.pixel_size = .0055; label.outline_size = 5
		label.modulate = Color("ffdf8f") if p.team == 0 else Color("a4f2ff")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.position.y = 2.15; p.add_child(label)
		p.animator.play("football/Idle_Loop"); p.animator.seek(.25,true); p.animator.pause()
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL; game.camera.size = 8.5
	game.camera.position = Vector3(0,8,14); game.camera.look_at(Vector3(0,.7,-2.5))
	await frame("elencos")
	# Close front/side views show blank faces, skin tones, sleeves and boots.
	for side in 2:
		for p in game.players:
			p.visible = p.team == side
			p.position.z = 0
		game.camera.size = 6.9; game.camera.position = Vector3(0,3.4,14)
		game.camera.look_at(Vector3(0,.8,0))
		await frame("morro" if side == 0 else "uniao")
	for p in game.players: p.hide()
	var samples: Array = []
	for i in 5:
		var record: Resource = game.players[0].profile.duplicate(true)
		record.cor_pele = i; record.tipo_corpo = 0; record.tipo_cabelo = i
		record.cor_cabelo = PROFILE.HAIR_COLORS[["preto","castanho","loiro","preto","ruivo"][i]]
		record.posicao = 4
		var p = load("res://scripts/footballer.gd").new()
		p.setup(game,0,i,Vector3((i-2)*2.4,0,0),record,game.team_definitions[0])
		game.add_child(p); p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0; p.avatar.rotation.y = 0
		p.marker.hide(); p.number_label.hide(); p.animator.play("football/Idle_Loop"); p.animator.seek(.25,true); p.animator.pause()
		samples.append(p)
		var label := Label3D.new(); label.text = PROFILE.SKIN_NAMES[i].to_upper()+"\n"+PROFILE.HAIR_KEYS[i].to_upper()
		label.font_size = 26; label.pixel_size = .0055; label.outline_size = 5; label.position.y = 2.15
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; p.add_child(label)
	await frame("tons-e-cabelos")
	for p in samples: p.queue_free()
	print("APPEARANCE_CAPTURES_OK")
	game.queue_free(); await process_frame; await process_frame
	quit()
