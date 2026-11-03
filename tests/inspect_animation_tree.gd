extends SceneTree
## Temporary render inspection; does not replace final previews in qa/.
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.juice.set_process(false); game.hud.hide(); game.muted = true
	game.ball.freeze = true; game.ball.hide()
	for actor in game.players: actor.set_physics_process(false); actor.hide()
	var actors: Array = [game.players[0],game.players[2],game.players[6],game.players[9]]
	var labels: Array[Label3D] = []
	for i in actors.size():
		var p = actors[i]; p.show(); p.position = Vector3((i-1.5)*2.6,.03,0)
		p.avatar.rotation.y = 0; p.marker.hide(); p.number_label.hide()
		var label := Label3D.new(); label.position = Vector3(p.position.x,2.5,0)
		label.font_size = 52; label.pixel_size = .006
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		game.add_child(label); labels.append(label)
	game.camera.position = Vector3(1.5,4.2,12); game.camera.fov = 48
	game.camera.look_at(Vector3(0,1,0))
	if "--record-locomotion" in OS.get_cmdline_user_args():
		var montage := Image.create(1920,800,false,Image.FORMAT_RGBA8)
		var sample := 0
		for i in actors.size():
			actors[i].animation_tree.reset()
			actors[i].animation_tree.locomotion([.75,3.0,4.5,7.4][i])
		for frame in 51:
			for i in actors.size():
				actors[i].animation_tree.tick(1.0/60.0,false)
				labels[i].text = str([.75,3.0,4.5,7.4][i])+" m/s | "+str(snappedf(frame/60.0,.01))+" s"
			if frame%10 != 0: continue
			await process_frame; await RenderingServer.frame_post_draw
			var snapshot := root.get_texture().get_image()
			snapshot.resize(640,400,Image.INTERPOLATE_LANCZOS)
			montage.blit_rect(snapshot,Rect2i(0,0,640,400),Vector2i((sample%3)*640,(sample/3)*400))
			sample += 1
		montage.save_png("res://.runtime/locomotion-motion.png")
		game.queue_free(); await process_frame; await process_frame
		print("INSPECT_LOCOMOTION_MOTION PASS samples=",sample)
		quit(); return
	for entry in ["locomotion","actions"]:
		for i in actors.size():
			var tree = actors[i].animation_tree; tree.reset()
			if entry == "locomotion":
				var speed: float = [0.0,.75,3.0,6.0][i]
				tree.locomotion(speed); labels[i].text = str(speed)+" m/s"
			else:
				var clip: String = ["kicks/Kick_Strong","custom/pass","football/Slide_Loop","football/Hit_Knockback"][i]
				tree.play_clip(clip); labels[i].text = ["CHUTE FORTE","PASSE","CARRINHO","QUEDA"][i]
			for frame in 20: tree.tick(1.0/60.0,false)
			if entry == "actions": tree.seek_contact([.27,.19,.12,.7][i])
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://.runtime/animation-tree-"+entry+".png")
		if result != OK: quit(result); return
	game.queue_free(); await process_frame; await process_frame
	print("INSPECT_ANIMATION_TREE PASS")
	quit()
