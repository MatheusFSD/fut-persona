extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.juice.set_process(false); game.muted = true; game.hud.hide()
	game.phase = "playing"; game.ball.freeze = true
	for actor in game.players: actor.set_physics_process(false); actor.hide()
	var p = game.players[4]; p.show(); p.marker.hide(); p.number_label.hide()
	p.position = Vector3(0,.03,0); p.avatar.rotation.y = 0
	game.camera.fov = 34; game.camera.position = Vector3(3.5,2.1,5.3); game.camera.look_at(Vector3(0,.9,0))
	game.ball.position = Vector3(0,.22,.7)
	for entry in [["fraco","custom/shot",.11,.19,.30],["medio","kicks/Kick_Medium",.13,.22,.32],["forte","kicks/Kick_Strong",.18,.27,.39]]:
		for i in 3:
			p.animator.play(entry[1],0); p.animator.seek(entry[i+2],true); p.animator.pause()
			await process_frame; await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://qa/chute-pose-%s-%d.png" % [entry[0],i])
	print("KICK_POSE_CAPTURE PASS")
	game.queue_free(); await process_frame; await process_frame; quit()
