extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")

func frame(path: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/"+path+".png")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frame("menu")
	game.new_match()
	for i in 105: await physics_frame
	await frame("partida")
	game.set_physics_process(false)
	for p in game.players: p.set_physics_process(false)
	game.hud.hide()
	game.ball.freeze = true
	game.hud.show()
	game.phase = "playing"; game.carrier = game.controlled; game.kick_lock = 0
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * game.camera.unproject_position(Vector3(8,.03,-3))
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await frame("mira")
	game.carrier = null; game.receiving_player = game.controlled; game.receiving_time = 1.0
	game.hud.queue_redraw()
	await frame("recebendo")
	game.clear_reception()
	game.hud.hide()
	game.camera.position = Vector3(19,5.5,10)
	game.camera.look_at(Vector3(24.5,1,0)); game.camera.fov = 43
	await frame("redes")
	var p = game.players[4]
	p.position = Vector3(-1,0,0); p.avatar.rotation.y = PI/2
	game.players[9].position = Vector3(1.7,0,0)
	game.camera.position = Vector3(1.8,3.7,6)
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	game.camera.look_at(Vector3(.2,.7,0)); game.camera.size = 4.7
	p.animator.play("football/Jog_Fwd_Loop"); p.animator.seek(.18,true); p.animator.pause()
	await frame("personagens")
	for action in ["shot","pass","slide"]:
		p.animator.play("custom/"+action if action != "slide" else "football/Slide_Loop")
		p.animator.seek(.19 if action != "slide" else .12,true); p.animator.pause()
		await frame(action)
	print("CAPTURE_OK")
	quit()
