extends SceneTree
var game

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.phase = "playing"; game.ball.freeze = true
	for p in game.players: p.set_physics_process(false)
	var capture := AudioEffectCapture.new(); capture.buffer_length = 2.0
	AudioServer.add_bus_effect(game.juice.mix_bus,capture)
	var samples := PackedVector2Array()
	var schedule := [[.02,"whistle"],[.25,"pass"],[.85,"pass"],[1.5,"shot"],[2.3,"power"],[3.2,"post"],[4.4,"save"],[5.2,"tackle"],[5.7,"goal"]]
	var elapsed := 0.0; var index := 0
	var previous := Time.get_ticks_usec()
	while elapsed < 8.8:
		await process_frame
		var now := Time.get_ticks_usec()
		var delta := (now-previous)/1000000.0; previous = now; elapsed += delta
		game._update_camera(delta)
		if index < schedule.size() and elapsed >= schedule[index][0]:
			if schedule[index][1] == "whistle": game.whistle()
			else: game.juice.impact(schedule[index][1],game.ball.global_position,1)
			index += 1
		var available := capture.get_frames_available()
		if available > 0: samples.append_array(capture.get_buffer(available))
	var pcm := PackedByteArray(); pcm.resize(samples.size()*4)
	var peak := 0.0
	for i in samples.size():
		peak = maxf(peak,maxf(absf(samples[i].x),absf(samples[i].y)))
		pcm.encode_s16(i*4,int(clampf(samples[i].x,-1,1)*32767))
		pcm.encode_s16(i*4+2,int(clampf(samples[i].y,-1,1)*32767))
	var stream := AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = true; stream.mix_rate = int(AudioServer.get_mix_rate()); stream.data = pcm
	stream.save_to_wav("res://qa/juicy-sons.wav")
	print("JUICE_AUDIO_CAPTURE samples=",samples.size()," peak=",peak," seconds=",float(samples.size())/stream.mix_rate)
	game.juice.reset_presentation(); game.juice.ambience.stop()
	game.queue_free(); await process_frame; OS.delay_msec(120); await process_frame
	quit(0 if samples.size() > 100000 and peak > .01 and peak <= 1 else 1)
