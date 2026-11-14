extends SceneTree
const HIT_STOP = preload("res://scripts/hit_stop.gd")
var game
var juice
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL "+label)

func reset(at := Vector3(.75,.4,0)) -> void:
	juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.released_by = null; game.release_guard = 0; game.kick_lock = 0
	game.recent_shot_time = 0; game.ball_speed_before_step = 0
	game.ball.freeze = true; game.ball.position = at
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.controlled = game.players[4]; game.controlled.position = Vector3(at.x-.75,.05,at.z)
	game.ball.freeze = false
	juice.cooldowns.clear()

func step(seconds: float) -> void:
	juice._process(seconds*Engine.time_scale)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	juice = game.juice
	game.set_physics_process(false); game.set_process(false); juice.set_process(false)
	game.muted = true; game.hud.hide()
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	juice.shot_cinematic_enabled = false

	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",1)
	check(Engine.time_scale == 1 and HIT_STOP.remaining > 0,"contact only arms the freeze; speed never changes inside a physics step")
	var armed: float = HIT_STOP.remaining
	check(is_equal_approx(armed,HIT_STOP.SECONDS.power),"strong shot uses its full freeze")
	step(.016)
	check(is_equal_approx(Engine.time_scale,HIT_STOP.FREEZE_SCALE),"next frame freezes the world")
	var velocity: Vector3 = game.ball.linear_velocity
	step(.016)
	check(is_equal_approx(HIT_STOP.remaining,armed-.032),"freeze counts real time, not the frozen time")
	check(game.ball.linear_velocity == velocity,"freeze does not change ball velocity")
	step(armed)
	check(Engine.time_scale == 1 and HIT_STOP.freeze == 1,"world returns to exactly normal speed")

	reset(); game.strike(game.controlled,Vector3(20,0,0),"pass",.5); step(.016)
	check(Engine.time_scale == 1,"routine passes never freeze")
	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",.3); var weak: float = HIT_STOP.remaining
	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",.7); var medium: float = HIT_STOP.remaining
	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",1)
	check(weak == 0 and medium > 0 and medium < HIT_STOP.remaining,"harder kicks freeze longer and weak ones stay fluid")
	reset(); juice.impact("tackle",Vector3.ZERO,.45)
	check(HIT_STOP.remaining == 0,"standing tackle does not freeze")
	reset(); juice.impact("tackle",Vector3.ZERO,.8)
	check(HIT_STOP.remaining > 0,"sliding tackle freezes")
	check(not HIT_STOP.hit("unknown"),"unlisted events are ignored")

	reset(); juice.impact("goal",Vector3.ZERO,1)
	check(HIT_STOP.remaining == 0,"crossing the line is not a contact and does not freeze")
	reset(); game.phase = "celebrate"; juice.shot_net(Vector3.ZERO)
	check(is_equal_approx(HIT_STOP.remaining,HIT_STOP.SECONDS.net),"net contact freezes")

	reset(); juice.impact("save",Vector3.ZERO,1)
	check(HIT_STOP.remaining > 0 and HIT_STOP.cooldown > 0,"save freezes and starts the cooldown")
	var kept: float = HIT_STOP.remaining
	juice.cooldowns.clear(); juice.impact("post",Vector3.ZERO,1)
	check(HIT_STOP.remaining == kept,"contacts during cooldown cannot chain freezes")
	step(.3)
	check(HIT_STOP.cooldown == 0 and HIT_STOP.hit("post"),"freezes work again after the cooldown")

	# Slow motion started during a freeze must save the real speed, not the frozen one.
	reset(); HIT_STOP.hit("post"); step(.016)
	check(HIT_STOP.freeze < 1,"freeze is active before the cinematic")
	juice.slide.begin(Vector3.ZERO,1)
	check(is_equal_approx(juice.slide.previous_time_scale,1),"cinematic saves unfrozen speed")
	step(.016)
	check(is_equal_approx(Engine.time_scale,juice.slide.SLOW_SCALE*HIT_STOP.FREEZE_SCALE),"freeze multiplies slow motion")
	step(.2)
	check(is_equal_approx(Engine.time_scale,juice.slide.SLOW_SCALE),"slow motion resumes after the freeze")
	step(2)
	check(Engine.time_scale == 1 and not juice.slide.active,"everything settles at normal speed")

	juice.shot_cinematic_enabled = true
	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",1)
	check(juice.shot.active and is_equal_approx(juice.shot.previous_time_scale,1),"strong shot cinematic starts with normal saved speed")
	step(.016)
	check(HIT_STOP.freeze < 1 and is_equal_approx(juice.shot.age,.016),"shot camera clock keeps running during the freeze")
	step(.2)
	check(is_equal_approx(Engine.time_scale,juice.shot.SLOW_SCALE),"shot slow motion follows the freeze")
	juice.shot_cinematic_enabled = false

	reset(); HIT_STOP.hit("post"); step(.016)
	game.toggle_pause(); step(.016)
	check(Engine.time_scale == 1 and HIT_STOP.remaining == 0,"pause drops the freeze so menus never crawl")
	game.toggle_pause(); step(.016)
	check(Engine.time_scale == 1,"resuming does not restart an old freeze")

	reset(); HIT_STOP.hit("post"); step(.016); juice.reset_presentation()
	check(Engine.time_scale == 1 and HIT_STOP.freeze == 1 and HIT_STOP.remaining == 0,"reset clears the freeze")
	reset(); juice.hit_stop_enabled = false
	game.strike(game.controlled,Vector3(24,0,0),"shot",1); juice.shot_net(Vector3.ZERO); step(.016)
	check(Engine.time_scale == 1 and HIT_STOP.remaining == 0,"freeze can be configured off")
	juice.hit_stop_enabled = true
	reset(); juice.set_muted(true); juice.impact("save",Vector3.ZERO,1); step(.016)
	check(HIT_STOP.freeze < 1,"silent game keeps the visual freeze")

	reset(); Engine.time_scale = .8; HIT_STOP.hit("post"); step(.016)
	check(is_equal_approx(Engine.time_scale,.8*HIT_STOP.FREEZE_SCALE),"freeze respects preexisting world speed")
	step(.3)
	check(is_equal_approx(Engine.time_scale,.8),"freeze restores preexisting world speed")
	Engine.time_scale = 1

	reset(); HIT_STOP.hit("post"); step(.016)
	game.queue_free(); await process_frame; await process_frame
	check(Engine.time_scale == 1 and HIT_STOP.freeze == 1,"teardown never leaves the engine frozen")
	print("HIT_STOP ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
