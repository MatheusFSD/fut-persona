extends SceneTree
var game
var frames := 0

func _initialize() -> void:
	call_deferred("run")

func setup(at := Vector3(.75,.25,0)) -> void:
	game.begin_restart(0,Vector3.ZERO,"SAÍDA DE BOLA",true)
	game.phase = "playing"; game.restart_taker = null; game.message_timer = 0
	game.ball.position = at
	var p = game.controlled
	p.position = Vector3(at.x-.75,.05,at.z); p.facing = Vector3.RIGHT; p.avatar.rotation.y = PI/2
	for other in game.players:
		other.set_physics_process(false)
		other.marker.visible = other == p; other.number_label.visible = other == p
		if other != p: other.position.z = -8 if other.team == 0 else 8
	game.camera_focus = Vector3(clampf(at.x,-19,19),.35,at.z)
	game._update_camera(0)
	await physics_frame; await physics_frame
	game.ball.freeze = false

func frame(label := "", record := true) -> void:
	game._update_camera(1.0/30); game.hud.queue_redraw()
	await process_frame; await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if not label.is_empty(): image.save_png("res://qa/bola-"+label+".png")
	if record:
		image.resize(800,500,Image.INTERPOLATE_LANCZOS)
		image.save_png("res://.runtime/ball-fx-frames/%03d.png" % frames); frames += 1

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	DirAccess.make_dir_recursive_absolute("res://.runtime/ball-fx-frames")
	await setup()
	game.flash("PASSE / CONTATO CURTO",.7)
	game.strike(game.controlled,Vector3(18,0,0),"pass",.5)
	game.controlled.animator.play("custom/pass"); game.controlled.animator.seek(.19,true); game.controlled.animator.pause()
	for i in 18: await frame("contato-passe" if i == 0 else "")
	await setup(); var p = game.controlled
	game.flash("CHUTE FORTE / RASTRO CURTO",1.2)
	game.strike(p,Vector3(24,0,0),"shot",1)
	p.animator.play("custom/shot"); p.animator.seek(.19,true); p.animator.pause()
	for i in 32: await frame("contato-chute" if i == 0 else "rastro" if i == 5 else "")
	await setup(Vector3(22,.7,3.4))
	game.strike(game.controlled,Vector3(25,0,3.4),"shot",1)
	var post_seen := false
	for i in 16:
		await frame("",false)
		if game.juice.ball_fx.contacts.any(func(event): return event.kind == "post"):
			await frame("contato-trave",false); post_seen = true; break
	print("BALL_FX_CAPTURES_OK frames=",frames)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if post_seen else 1)
