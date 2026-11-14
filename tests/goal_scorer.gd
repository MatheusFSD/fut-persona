extends SceneTree
var game
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func reset(at := Vector3(.75,.4,0)) -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.released_by = null; game.release_guard = 0; game.kick_lock = 0
	game.ball.freeze = true; game.ball.position = at
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.controlled = game.players[4]; game.controlled.position = Vector3(at.x-.75,.05,at.z)
	game.ball.freeze = false
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.hud.hide()
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	# Pausing used to erase the ball's motion: it fell straight down after resuming.
	reset(Vector3(0,2,0)); await physics_frame
	game.ball.linear_velocity = Vector3(20,1,-3); game.ball.angular_velocity = Vector3(0,5,0)
	await physics_frame
	var velocity: Vector3 = game.ball.linear_velocity; var spin: Vector3 = game.ball.angular_velocity
	var held: Vector3 = game.ball.position
	game.toggle_pause()
	for i in 4: await physics_frame
	check(game.ball.position.distance_to(held) < .001,"pause holds the ball in place")
	game.toggle_pause()
	check(game.ball.linear_velocity.is_equal_approx(velocity) and game.ball.angular_velocity.is_equal_approx(spin),"resume restores the exact motion")
	await physics_frame; await physics_frame
	check(game.ball.linear_velocity.distance_to(velocity) < 1 and game.ball.position.x > held.x+.3,"ball keeps flying after resume")
	reset(); game.ball.freeze = true; game.toggle_pause(); game.toggle_pause()
	check(game.ball.freeze,"ball frozen before the pause stays frozen")
	game.ball.freeze = false
	# Whoever touched it last scores, and the art of that player is the one celebrating.
	game.new_match(); reset()
	check(game.last_goal_scorer == null and game.goals_by_player.is_empty(),"new match has no scorer")
	game.players[3].position = Vector3(0,.05,0); game.strike(game.players[3],Vector3(24,0,0),"shot",1); game.goal(0)
	check(game.last_goal_scorer == game.players[3] and game.goals_by_player.get(game.players[3],0) == 1,"last kicker of the scoring team is credited")
	reset(); game.take_possession(game.players[2]); game._drop_carrier(); game.goal(0)
	check(game.last_goal_scorer == game.players[2],"possession also counts as last touch")
	reset(); game.players[3].position = Vector3(0,.05,0); game.strike(game.players[3],Vector3(24,0,0),"shot",1); game.goal(0)
	check(game.top_scorer(0) == game.players[3],"top scorer has the most goals")
	reset(); game.players[1].position = Vector3(0,.05,0); game.strike(game.players[1],Vector3(-24,0,0),"shot",1); game.goal(1)
	check(game.last_touch_player == game.players[1],"defender really was the last to touch the own goal")
	check(game.last_goal_scorer == game.players[9] and not game.goals_by_player.has(game.players[1]),"own goal is celebrated by the attacker and not credited to the defender")
	check(game.top_scorer(1) == game.players[9],"team without goals shows its striker")
	game.new_match()
	check(game.last_goal_scorer == null and game.last_touch_player == null and game.goals_by_player.is_empty(),"new match clears goals")
	game.queue_free(); await process_frame; await process_frame
	print("GOAL_SCORER ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
