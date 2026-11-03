extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func frame(label: String) -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.runtime/praca-"+label+".png")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.phase = "playing"; game.message_timer = 0; game.ball.freeze = true
	for p in game.players: p.set_physics_process(false)
	game.camera_focus = Vector3(0,.35,0); game._update_camera(0)
	await frame("partida")
	game.hud.hide(); game.camera.far = 260
	for entry in [
		["geral",Vector3(76,72,99),Vector3(0,0,-17),56],
		["historico",Vector3(2,10,-10),Vector3(-14,4,-36),57],
		["orla",Vector3(25,14,19),Vector3(53,2,-25),58],
		["praia",Vector3(18,20,78),Vector3(44,1,35),55]]:
		game.camera.position = entry[1]; game.camera.look_at(entry[2]); game.camera.fov = entry[3]
		await frame(entry[0])
	var district = get_nodes_in_group("rio_district")[0]
	print("PRACA_INSPECT triangles=",district.get_meta("triangles")," meshes=",district.find_children("*","MeshInstance3D",true,false).size())
	game.queue_free(); await process_frame; await process_frame; quit()
