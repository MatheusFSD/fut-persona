extends Node3D
const BALL_FX = preload("res://scripts/ball_fx.gd")
const SLIDE = preload("res://scripts/slide_moment.gd")
const SHOT = preload("res://scripts/shot_moment.gd")
## Presentation only. Own random source, cached WAVs, native spatial voices.
const SFX_VOLUME_DB := -5.0
const CROWD_VOLUME_DB := -27.0
const VOICE_COUNT := 8
const CLIPS := {
	"pass":[preload("res://assets/audio/pass_1.wav"),preload("res://assets/audio/pass_2.wav"),preload("res://assets/audio/pass_3.wav")],
	"shot":[preload("res://assets/audio/shot_1.wav"),preload("res://assets/audio/shot_2.wav"),preload("res://assets/audio/shot_3.wav")],
	"power":[preload("res://assets/audio/power_1.wav"),preload("res://assets/audio/power_2.wav"),preload("res://assets/audio/power_3.wav")],
	"post":[preload("res://assets/audio/post_1.wav"),preload("res://assets/audio/post_2.wav"),preload("res://assets/audio/post_3.wav")],
	"save":[preload("res://assets/audio/save_1.wav"),preload("res://assets/audio/save_2.wav"),preload("res://assets/audio/save_3.wav")],
	"tackle":[preload("res://assets/audio/tackle_1.wav"),preload("res://assets/audio/tackle_2.wav"),preload("res://assets/audio/tackle_3.wav")],
	"goal":[preload("res://assets/audio/goal_1.wav"),preload("res://assets/audio/goal_2.wav"),preload("res://assets/audio/goal_3.wav")]}
const WHISTLE = preload("res://assets/audio/whistle.wav")
const LONG_WHISTLE = preload("res://assets/audio/whistle_long.wav")
const AMBIENCE = preload("res://assets/audio/crowd_ambience.wav")
const CHANCE = preload("res://assets/audio/crowd_chance.wav")
const CHEER = preload("res://assets/audio/crowd_cheer.wav")
# [duration, lateral displacement, vertical displacement, roll radians, FOV punch]
const CAMERA := {
	"shot":Vector4(.22,.030,.017,.0008),"power":Vector4(.30,.055,.035,.0013),
	"post":Vector4(.31,.075,.045,.0020),"save":Vector4(.27,.045,.030,.0010),
	"tackle":Vector4(.17,.020,.012,.0006),"goal":Vector4(.42,.080,.045,.0022)}
const FOV_PUNCH := {"shot":.30,"power":.65,"post":.70,"save":-.55,"tackle":0.0,"goal":-1.25}
@export_range(0,1,.05) var camera_strength := 1.0
@export var slide_cinematic_enabled := true
@export var shot_cinematic_enabled := true
var game
var muted := false
var voices: Array[AudioStreamPlayer3D] = []
var referee: AudioStreamPlayer
var crowd: AudioStreamPlayer
var ambience: AudioStreamPlayer
var camera_impacts: Array[Dictionary] = []
var cooldowns: Dictionary = {}
var event_counts: Dictionary = {}
var variant_cursor: Dictionary = {}
var audio_rng := RandomNumberGenerator.new()
var voice_cursor := 0
var impact_serial := 0
var mix_bus := -1
var owns_mix_bus := false
var was_paused := false
var ball_fx
var slide = SLIDE.new()
var shot = SHOT.new()

func _ready() -> void:
	ball_fx = BALL_FX.new(); ball_fx.name = "ExpressaoDaBola"; ball_fx.game = game; add_child(ball_fx)
	audio_rng.seed = 54819
	mix_bus = AudioServer.get_bus_index("VarzeaJuice")
	if mix_bus < 0:
		owns_mix_bus = true
		AudioServer.add_bus(); mix_bus = AudioServer.bus_count-1
		AudioServer.set_bus_name(mix_bus,"VarzeaJuice")
		var limiter := AudioEffectLimiter.new(); limiter.ceiling_db = -1; limiter.threshold_db = -2
		AudioServer.add_bus_effect(mix_bus,limiter)
	for i in VOICE_COUNT:
		var voice := AudioStreamPlayer3D.new(); voice.name = "Impacto"+str(i)
		voice.bus = "VarzeaJuice"; voice.unit_size = 24; voice.max_distance = 90
		voice.panning_strength = .65; voice.max_db = 0
		add_child(voice); voices.append(voice)
	referee = AudioStreamPlayer.new(); referee.bus = "VarzeaJuice"; referee.volume_db = -12; add_child(referee)
	crowd = AudioStreamPlayer.new(); crowd.bus = "VarzeaJuice"; add_child(crowd)
	ambience = AudioStreamPlayer.new(); ambience.bus = "VarzeaJuice"; ambience.volume_db = -80
	var loop := AMBIENCE.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD; loop.loop_begin = 0
	loop.loop_end = int(loop.get_length()*loop.mix_rate)
	ambience.stream = loop; add_child(ambience)

func _exit_tree() -> void:
	reset_presentation()
	if ambience != null: ambience.stop()
	if owns_mix_bus and AudioServer.get_bus_index("VarzeaJuice") == mix_bus: AudioServer.remove_bus(mix_bus)

func set_muted(value: bool) -> void:
	muted = value
	if mix_bus >= 0: AudioServer.set_bus_mute(mix_bus,value)
	if value:
		for voice in voices: voice.stop()
		if referee != null: referee.stop()
		if crowd != null: crowd.stop()
		if ambience != null: ambience.stop()

func reset_presentation() -> void:
	slide.cancel()
	shot.cancel()
	for net in get_tree().get_nodes_in_group("goal_net_visual"): net.reset()
	if is_instance_valid(ball_fx): ball_fx.reset()
	camera_impacts.clear(); cooldowns.clear()
	for voice in voices: voice.stop()
	if referee != null: referee.stop()
	if crowd != null: crowd.stop()

func _process(delta: float) -> void:
	if game == null: return
	var paused: bool = game.phase == "paused"
	var real_delta := delta/maxf(Engine.time_scale,.001)
	if game.phase not in ["playing","foul","paused"]: slide.cancel()
	slide.advance(real_delta,paused)
	if game.phase not in ["playing","out","celebrate","paused"]: shot.cancel()
	shot.advance(real_delta,paused)
	shot.observe(game.ball.global_position,game.ball.linear_velocity,game.carrier != null,game.phase)
	game._advance_goal_reveal(real_delta)
	if paused and not was_paused:
		for voice in voices: voice.stop()
		referee.stop(); crowd.stop()
	was_paused = paused
	if not paused:
		for key in cooldowns: cooldowns[key] = maxf(0,cooldowns[key]-delta)
	var target := CROWD_VOLUME_DB if game.phase in ["playing","foul","set_piece","restart","out","celebrate"] else -80.0
	if paused: target = CROWD_VOLUME_DB-12
	ambience.volume_db = lerpf(ambience.volume_db,target,1-exp(-delta*3))
	if not muted and target > -70 and not ambience.playing: ambience.play()
	elif (muted or ambience.volume_db < -69) and ambience.playing: ambience.stop()

func slide_tackle(player, world: Vector3) -> bool:
	if not slide_cinematic_enabled or not game.live() or game.ball.freeze: return false
	if slide.active: return false
	shot.cancel()
	var center: Vector3 = (world+player.global_position)*.5+Vector3.UP*.65
	return slide.begin(center,1.0 if player.team == 0 else -1.0)

func foul_tackle(player, world: Vector3) -> bool:
	if not slide_cinematic_enabled or game.phase != "foul": return false
	if slide.active: return false
	shot.cancel()
	var center: Vector3 = (world+player.global_position)*.5+Vector3.UP*.65
	return slide.begin(center,1.0 if player.team == 0 else -1.0)

func shot_kick(player, axis: Vector3) -> bool:
	if not shot_cinematic_enabled or not game.live() or game.ball.freeze or slide.active: return false
	return shot.begin_shot(player.global_position,axis,game.camera.global_transform,game.camera.fov)

func shot_post(world: Vector3) -> bool:
	if not shot_cinematic_enabled or slide.active or not game.live(): return false
	if not shot.active and game.recent_shot_time <= 0: return false
	return shot.post_impact(world,game.camera.global_transform,game.camera.fov)

func shot_goal() -> void:
	if not shot_cinematic_enabled: return
	slide.cancel()
	shot.goal_scored(game.ball.global_position,game.camera.global_transform,game.camera.fov)

func shot_net(world: Vector3) -> bool:
	if not shot_cinematic_enabled: return false
	return shot.net_impact(world,game.camera.global_transform,game.camera.fov)

func whistle(long := false) -> void:
	if muted: return
	referee.stream = LONG_WHISTLE if long else WHISTLE
	referee.pitch_scale = audio_rng.randf_range(.985,1.015); referee.play()

func impact(kind: String, world: Vector3, strength := 1.0) -> bool:
	if not CLIPS.has(kind) or cooldowns.get(kind,0.0) > 0: return false
	cooldowns[kind] = .20 if kind == "post" else .10 if kind == "save" else .04
	event_counts[kind] = event_counts.get(kind,0)+1
	strength = clampf(strength,.25,1.0)
	ball_fx.contact(kind,world,strength)
	if kind == "power": ball_fx.start_trail()
	elif kind in ["post","save","tackle","goal"]: ball_fx.stop_trail()
	if CAMERA.has(kind):
		if camera_impacts.size() >= 3: camera_impacts.pop_front()
		camera_impacts.append({"kind":kind,"age":0.0,"strength":strength,"serial":impact_serial})
		impact_serial += 1
	if muted: return true
	var index: int = variant_cursor.get(kind,0)%CLIPS[kind].size()
	variant_cursor[kind] = index+1
	var voice: AudioStreamPlayer3D = voices[voice_cursor%voices.size()]
	for candidate in voices:
		if not candidate.playing: voice = candidate; break
	voice_cursor += 1
	voice.stop(); voice.global_position = world; voice.stream = CLIPS[kind][index]
	voice.pitch_scale = audio_rng.randf_range(.985,1.015)
	voice.volume_db = SFX_VOLUME_DB+lerpf(-4,0,strength); voice.play()
	if kind in ["post","save","goal"]:
		crowd.stream = CHEER if kind == "goal" else CHANCE
		crowd.volume_db = -11 if kind == "goal" else -17
		crowd.pitch_scale = audio_rng.randf_range(.98,1.02); crowd.play()
	return true

func sample_camera(delta: float) -> Vector4:
	var result := Vector4.ZERO
	for i in range(camera_impacts.size()-1,-1,-1):
		var impact: Dictionary = camera_impacts[i]
		impact.age += delta
		var setting: Vector4 = CAMERA[impact.kind]
		if impact.age >= setting.x: camera_impacts.remove_at(i); continue
		var age: float = impact.age
		var envelope: float = pow(1-age/setting.x,2)*(1-exp(-age*65))*impact.strength*camera_strength
		var phase: float = impact.serial*2.37
		result.x += sin(age*91+phase)*setting.y*envelope
		result.y += sin(age*73+phase*.8)*setting.z*envelope
		result.z += sin(age*67+phase)*setting.w*envelope
		result.w += float(FOV_PUNCH[impact.kind])*envelope
	return Vector4(clampf(result.x,-.08,.08),clampf(result.y,-.05,.05),clampf(result.z,-.0025,.0025),clampf(result.w,-1.25,.8))
