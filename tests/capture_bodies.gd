extends SceneTree
const BODIES = preload("res://scripts/body_types.gd")
var game

func _initialize() -> void:
	call_deferred("run")

func frame(label: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/biotipos-"+label+".png")

func pose(clip: String, at: float) -> void:
	for p in game.players:
		p.animator.play(clip); p.animator.seek(at,true); p.animator.pause()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.hud.hide(); game.ball.hide(); game.ball.freeze = true
	for p in game.players:
		p.set_physics_process(false)
		p.position = Vector3((p.slot-2)*2.4,0,-p.team*5)
		p.avatar.rotation.y = 0; p.marker.hide(); p.number_label.hide()
		var label := Label3D.new()
		label.text = BODIES.NAMES[p.body_type].to_upper()+"  "+("%.2f m" % p.profile.altura).replace(".",",")+"\n"+p.team_definition.nome.to_upper()
		label.font_size = 28; label.pixel_size = .0055; label.outline_size = 5
		label.modulate = Color("ffdf8f") if p.team == 0 else Color("a4f2ff")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position.y = 2.15; p.add_child(label)
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL; game.camera.size = 8.5
	game.camera.position = Vector3(0,8,14); game.camera.look_at(Vector3(0,.7,-2.5))
	pose("football/Idle_Loop",.25); await frame("frente")
	pose("football/Jog_Fwd_Loop",.15); await frame("trote")
	pose("custom/shot",.19); await frame("chute")
	pose("football/Slide_Loop",.12); await frame("carrinho")
	for p in game.players: p.avatar.rotation.y = PI/2
	pose("football/Idle_Loop",.25); await frame("lado")
	print("BODY_CAPTURES_OK")
	game.queue_free(); await process_frame; await process_frame
	quit()
