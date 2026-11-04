extends "res://tests/goalkeeper.gd"

func run() -> void:
	for side in 2:
		await setup(side)
		game.ball.position = Vector3(-keeper.attack()*18,.4,0)
		game.ball.linear_velocity = Vector3(-keeper.attack()*26,0,0)
		game.recent_shot_team = 1-side; game.recent_shot_time = 3
		for frame in 20: keeper.prepare(.01)
		check(keeper.state == keeper.State.PREPARE,"power shot delays commitment on both sides")
		check(is_equal_approx(keeper.reaction_seconds(),.40),"full-speed shot adds 220ms of reaction delay")
		game.ball.linear_velocity *= .85
		keeper.prepare(.01)
		check(is_equal_approx(keeper.reaction_seconds(),.40),"drag does not erase the reaction penalty")
		for frame in 21: keeper.prepare(.01)
		check(keeper.defending(),"keeper still attempts a save after the delay")
		keeper.reset()
		check(is_equal_approx(keeper.reaction_seconds(),keeper.REACTION_SECONDS),"reset clears the power penalty")
		game.ball.linear_velocity = Vector3(-keeper.attack()*18,0,0)
		for frame in 20: keeper.prepare(.01)
		check(keeper.defending(),"ordinary shot retains normal reaction")
		keeper.reset(); game.recent_shot_time = 0
		game.ball.linear_velocity = Vector3(-keeper.attack()*26,0,0)
		keeper.prepare(.01)
		check(is_equal_approx(keeper.reaction_seconds(),keeper.REACTION_SECONDS),"fast passes do not receive a shot penalty")
	game.queue_free(); await process_frame
	print("KEEPER_POWER_REACTION ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
