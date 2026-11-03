extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func frame(label: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/gola-"+label+".png")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.hud.hide(); game.ball.hide(); game.ball.freeze = true
	for p in game.players:
		p.set_physics_process(false); p.hide(); p.position = Vector3.ZERO
		p.marker.hide(); p.number_label.hide(); p.avatar.rotation.y = 0
		p.animator.play("football/Idle_Loop"); p.animator.seek(.25,true); p.animator.pause()
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL; game.camera.size = .95
	game.camera.position = Vector3(0,1.65,4); game.camera.look_at(Vector3(0,1.32,0))
	var tag := "antes" if "--before" in OS.get_cmdline_user_args() else "depois"
	for side in 2:
		var p = game.players[side*5+1]; p.show()
		await frame(tag+("-morro" if side == 0 else "-uniao"))
		p.hide()
	print("COLLAR_CAPTURES_OK")
	game.queue_free(); await process_frame; await process_frame; quit()
