extends SceneTree
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL "+label)

func reset() -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.ball.freeze = true; game.ball.position = Vector3(.75,.25,0)
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.kick_lock = 0; game.recent_shot_time = 0; game.ball_speed_before_step = 0
	game.released_by = null; game.release_guard = 0
	for p in game.players: p.reset_at(game.formation(p.team,p.slot)); p.contact_done = false
	game.controlled = game.players[4]; game.controlled.position = Vector3(0,.05,0)
	game.camera_focus = Vector3(.75,.35,0); game.camera_base_fov = 43; game.zoomed = true; game._update_camera(0)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.hud.hide()
	for p in game.players: p.set_physics_process(false)
	var juice = game.juice
	check(juice.voices.size() == 8 and juice.voices.all(func(voice): return voice is AudioStreamPlayer3D),"eight native spatial impact voices")
	check(AudioServer.get_bus_effect_count(juice.mix_bus) == 1 and AudioServer.get_bus_effect(juice.mix_bus,0) is AudioEffectLimiter,"dedicated native limiter protects impact mix")
	check(juice.ambience.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,"ambience is a seamless native loop")
	for kind in juice.CLIPS:
		var clips: Array = juice.CLIPS[kind]
		check(clips.size() == 3 and clips[0] != clips[1] and clips.all(func(clip): return clip is AudioStreamWAV and clip.get_length() > .05),"three shared sound variants: "+kind)
	reset(); game.muted = false
	var rng_state: int = game.rng.state
	juice.impact("pass",Vector3.ZERO,.7)
	juice.cooldowns.clear(); juice.impact("pass",Vector3.ZERO,.7); juice.whistle()
	var streams: Array = []
	for voice in juice.voices:
		if voice.stream != null and voice.stream not in streams: streams.append(voice.stream)
	check(streams.size() >= 2,"successive sounds vary without cutting the previous impact")
	check(game.rng.state == rng_state,"audio does not consume gameplay RNG")
	game.muted = true
	check(AudioServer.is_bus_mute(juice.mix_bus) and juice.voices.all(func(voice): return not voice.playing) and not juice.referee.playing,"mute immediately silences all impact and referee voices")
	juice.cooldowns.clear(); juice.impact("power",Vector3.ZERO,1)
	check(not juice.voices.any(func(voice): return voice.playing) and not juice.camera_impacts.is_empty(),"mute keeps camera feedback without starting sounds")
	game.muted = false
	check(not AudioServer.is_bus_mute(juice.mix_bus),"unmute restores mix")
	reset()
	var p = game.controlled; var screen := Vector2(980,470)
	var expected: Vector3 = game.mouse_aim(p,screen)
	var original: Transform3D = game.camera.transform
	var ball_at: Vector3 = game.ball.position; var velocity: Vector3 = game.ball.linear_velocity
	juice.impact("power",game.ball.global_position,1); game._update_camera(1.0/60)
	check(game.camera_fx_applied and absf(game.camera.h_offset)+absf(game.camera.v_offset) > .005,"strong impact produces a short camera impulse")
	check(absf(game.camera.h_offset) <= .08 and absf(game.camera.v_offset) <= .05 and absf(game.camera.rotation.z) <= .0025,"camera shake stays bounded and subtle")
	check(game.mouse_aim(p,screen).distance_to(expected) < .002,"fixed cursor keeps identical world aim during shake and FOV punch")
	check(game.camera.current and not game.aim_camera.current and root.get_camera_3d() == game.camera,"only broadcast camera renders and listens")
	check(game.ball.position == ball_at and game.ball.linear_velocity == velocity,"presentation cannot move or accelerate physical ball")
	game.toggle_pause()
	var paused: Transform3D = game.camera.transform; var age: float = juice.camera_impacts[0].age
	game._update_camera(.2); juice._process(.2)
	check(game.camera.transform == paused and juice.camera_impacts[0].age == age,"pause freezes camera envelope and view")
	check(juice.voices.all(func(voice): return not voice.playing) and not juice.crowd.playing and not juice.referee.playing,"pause silences one-shot playback")
	game.toggle_pause(); game._update_camera(.6)
	check(juice.camera_impacts.is_empty() and not game.camera_fx_applied and is_zero_approx(game.camera.h_offset) and is_zero_approx(game.camera.v_offset),"impulse settles completely without drift")
	check(game.camera.transform.is_equal_approx(original) and is_equal_approx(game.camera.fov,43),"camera returns to original broadcast framing")
	reset(); juice.camera_strength = 0; juice.impact("goal",Vector3.ZERO)
	game._update_camera(.04)
	check(not game.camera_fx_applied,"camera intensity can be disabled separately from audio")
	juice.camera_strength = 1
	reset(); var before: int = juice.event_counts.get("pass",0)
	game.strike(game.controlled,Vector3(12,0,0),"pass",.5)
	check(juice.event_counts.get("pass",0) == before+1 and juice.camera_impacts.is_empty(),"real pass plays dry impact without shaking aim")
	reset(); before = juice.event_counts.get("power",0)
	game.strike(game.controlled,Vector3(24,0,0),"shot",1)
	check(juice.event_counts.get("power",0) == before+1 and not juice.camera_impacts.is_empty(),"real charged shot triggers strong sound and camera")
	reset(); before = juice.event_counts.get("post",0)
	game.ball.linear_velocity = Vector3(15,0,0)
	var post := get_nodes_in_group("goal_frame")[0]
	game._ball_contact(post); game._ball_contact(post)
	check(juice.event_counts.get("post",0) == before+1 and juice.crowd.stream == juice.CHANCE,"woodwork contact gives one metallic impact and crowd reaction")
	reset(); before = juice.event_counts.get("save",0)
	game.recent_shot_team = 0; game.recent_shot_time = 2; game.ball.linear_velocity = Vector3(18,0,0)
	game.take_possession(game.players[5])
	check(juice.event_counts.get("save",0) == before+1,"real keeper save gives glove impact and camera")
	reset(); before = juice.event_counts.get("goal",0)
	game.goal(0)
	check(juice.event_counts.get("goal",0) == before+1 and juice.crowd.stream == juice.CHEER and game.score == [1,0],"goal uses net impact and celebration crowd with existing score")
	game.begin_restart(0,Vector3.ZERO,"SAÍDA DE BOLA",true)
	check(juice.camera_impacts.is_empty() and not juice.crowd.playing,"restart clears old cheer and camera impulse")
	game.selection_menu()
	check(juice.camera_impacts.is_empty() and juice.voices.all(func(voice): return not voice.playing),"selection clears outstanding sound and camera effects")
	print("JUICE ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.juice.reset_presentation(); game.juice.ambience.stop()
	game.queue_free(); await process_frame
	# Fixed-FPS tests can outrun the audio driver's real-time disposal queue.
	OS.delay_msec(120); await process_frame
	quit(0 if failures.is_empty() else 1)
