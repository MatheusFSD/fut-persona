extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.muted = true; game.spectator = true; game.new_match()
	var ticks := 0
	while game.phase != "finished" and ticks < 18000:
		await physics_frame
		ticks += 1
		if ticks % 1800 == 0: print("SOAK ", ticks," elapsed=",snappedf(game.elapsed,.1)," ball=",game.ball.position," score=",game.score," stats=",game.stats)
	var valid: bool = game.phase == "finished" and game.stats.shots[0]+game.stats.shots[1] > 0 and game.stats.passes[0]+game.stats.passes[1] > 0
	for p in game.players:
		valid = valid and p.position.is_finite() and absf(p.position.x) < 26 and absf(p.position.z) < 16 and p.position.y < 2
	print("FULL_MATCH ","PASS" if valid else "FAIL"," ticks=",ticks," score=",game.score," stats=",game.stats)
	quit(0 if valid else 1)
