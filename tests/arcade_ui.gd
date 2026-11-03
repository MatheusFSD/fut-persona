extends SceneTree
const FLAGS = preload("res://scripts/ui_flags.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL "+label)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.ball.freeze = true
	for p in game.players: p.set_physics_process(false)
	var hud = game.hud
	check(hud.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.ui_root.mouse_filter == Control.MOUSE_FILTER_IGNORE,"decorative HUD lets mouse actions reach the game")
	for side in 2:
		check(hud.team_choices[side].item_count == 4 and hud.team_choices[side].visible,"both country selectors available")
		for i in 4:
			var id: String = game.team_catalog.teams[i].id
			var icon: Texture2D = hud.team_choices[side].get_item_icon(i)
			check(icon != null and icon == FLAGS.texture(id) and icon.get_size() == Vector2(64,40),"selector uses shared flag: "+id)
	hud.team_choices[0].item_selected.emit(2); hud.team_choices[1].item_selected.emit(3)
	check(game.team_definitions[0].id == "alemanha" and game.team_definitions[1].id == "franca","redesigned selectors still change the actual match")
	hud.button.pressed.emit(); hud._process(0)
	check(game.phase == "restart" and not hud.button.visible and not hud.team_choices[0].visible,"start button starts and clears menu controls")
	game.phase = "playing"; game.elapsed = 10
	var camera_at: Vector3 = game.camera.position
	game.goal(1)
	check(game.score == [0,1] and hud.goal_team == -1 and game.goal_reveal_pending,"goal score is authoritative while overlay waits for net close")
	game.goal_hold_elapsed = 0; game._advance_goal_reveal(.75)
	check(game.score == [0,1] and hud.goal_team == 1 and hud.goal_serial == 1,"real away goal starts the matching celebration")
	game.goal(1)
	check(game.score == [0,1] and hud.goal_serial == 1,"same goal cannot retrigger score or presentation")
	game.phase_timer = game.GOAL_DURATION-.3; hud._process(0)
	check(hud.goal_letter_offset(0).y < hud.goal_letter_offset(4).y,"goal letters enter successively as a wave")
	check(game.camera.position == camera_at and game.elapsed == 10,"screen effects do not move camera or advance match time")
	game._physics_process(3); hud._process(0)
	check(game.phase == "restart" and hud.goal_team == -1,"celebration ends cleanly into kickoff")
	game.phase = "playing"; game.goal(0)
	game.goal_hold_elapsed = 0; game._advance_goal_reveal(.75)
	check(hud.goal_team == 0 and hud.goal_serial == 2,"next goal restarts animation for the other team")
	game.phase = "playing"; game.toggle_pause(); hud._process(0)
	check(hud.button.visible and hud.change_button.visible and not hud.team_choices[0].visible,"pause presents resume and team selection controls")
	hud.button.pressed.emit(); hud._process(0)
	check(game.live() and not hud.button.visible,"resume button returns to the game")
	game.phase = "finished"; hud._process(0)
	check(hud.button.visible and hud.change_button.visible,"results offer replay and new selection")
	hud.change_button.pressed.emit(); hud._process(0)
	check(game.phase == "menu" and hud.team_choices[0].visible,"return to selection restores country pickers")
	var clock: float = hud.animation_time; hud._process(.2)
	check(hud.animation_time > clock,"presentation animates independently of physics")
	for dimensions in [Vector2i(960,600),Vector2i(1600,900),Vector2i(1024,768)]:
		root.size = dimensions; await process_frame; hud._process(0)
		var final: Transform2D = root.get_final_transform()*hud.ui_transform
		var start: Vector2 = final*hud.button.position
		var end: Vector2 = final*(hud.button.position+hud.button.size)
		check(start.x >= 0 and start.y >= 0 and end.x <= root.size.x and end.y <= root.size.y,"primary control fits viewport "+str(dimensions))
	print("ARCADE_UI ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
