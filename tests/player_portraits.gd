extends SceneTree
const PROFILE = preload("res://scripts/player_data.gd")
const ROSTER = preload("res://scripts/roster_loader.gd")
const PORTRAITS = preload("res://scripts/player_portraits.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func run() -> void:
	var catalog := ROSTER.read_catalog()
	var loaded: Array = []
	var poses: Array = []
	var by_id: Dictionary = {}
	for team_id in catalog.players:
		for profile: Resource in catalog.players[team_id]:
			var texture: Texture2D = PORTRAITS.texture(profile)
			var pose: Texture2D = PORTRAITS.celebration(profile)
			check(texture != null and profile.retrato.begins_with("res://assets/portraits/"+String(team_id)+"/"),"portrait comes from the player's own national folder: "+profile.id)
			check(pose != null and profile.comemoracao.get_file() == profile.retrato.get_file(),"portrait and celebration show the same character: "+profile.id)
			check(not "expressoes" in profile.retrato and not "expressoes" in profile.comemoracao,"visual novel expressions stay out of the game: "+profile.id)
			if texture == null or pose == null: continue
			check(texture not in loaded and pose not in poses,"each player has their own art: "+profile.id)
			loaded.append(texture); poses.append(pose); by_id[profile.id] = texture
			check(PORTRAITS.texture(profile) == texture and PORTRAITS.celebration(profile) == pose,"repeated draws share cached textures")
			for frame in [Vector2(88,80),Vector2(68,78),Vector2(74,76)]:
				var region := PORTRAITS.source_rect(profile,texture.get_size(),frame)
				check(Rect2(Vector2.ZERO,texture.get_size()).encloses(region) and is_equal_approx(region.size.x/region.size.y,frame.x/frame.y),"portrait stays in source bounds without stretching")
	check(loaded.size() == 20 and poses.size() == 20,"all twenty players have a portrait and a celebration")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROSTER.DEFAULT_PATH)).jogadores[0].duplicate(true)
	source.erase("retrato"); source.erase("retrato_regiao"); source.erase("comemoracao")
	var legacy := PROFILE.from_dictionary(source)
	check(legacy.retrato.is_empty() and legacy.comemoracao.is_empty() and legacy.retrato_regiao == Rect2(0,0,1,1),"old records load without art fields")
	check(PORTRAITS.texture(legacy) == null and PORTRAITS.celebration(legacy) == null,"records without art fall back safely")
	var future: Resource = catalog.players[&"franca"][0].duplicate(true)
	future.retrato = "res://assets/portraits/not-supplied.png"
	check(PORTRAITS.texture(future) == null and PORTRAITS.texture(future) == null,"missing art safely falls back and caches the result")
	source.comemoracao = "not-a-resource.png"
	check(PROFILE.from_dictionary(source) == null,"invalid celebration path is rejected")
	var game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	for player in game.players: player.set_physics_process(false)
	check(PORTRAITS.texture(game.players[4].profile) == by_id[game.players[4].profile.id],"initial striker uses his own portrait")
	var brazil_striker: StringName = game.players[4].profile.id
	game.hud.team_choices[0].item_selected.emit(1)
	check(game.team_definitions[1].id == "brasil" and game.players[9].profile.id == brazil_striker and PORTRAITS.texture(game.players[9].profile) == by_id[brazil_striker],"swapping sides moves portraits with the player")
	check(PORTRAITS.texture(game.players[4].profile) != by_id[brazil_striker],"new home team does not retain the old art")
	game.hud.kit_choices[1].item_selected.emit(1)
	check(PORTRAITS.texture(game.players[9].profile) == by_id[brazil_striker],"alternate kit preserves player portrait identity")
	game.hud.team_choices[0].item_selected.emit(0)
	game.new_match(); game.phase = "playing"
	game.controlled = game.players[0]
	check(PORTRAITS.texture(game.controlled.profile) == by_id[game.players[0].profile.id],"in-game goalkeeper card follows selected player")
	game.controlled = game.players[4]; game.show_attributes = true; game.hud._process(0)
	check(PORTRAITS.texture(game.controlled.profile) == by_id[game.players[4].profile.id],"attribute sheet and live card share selected striker portrait")
	game.queue_free(); await process_frame; await process_frame
	print("PLAYER_PORTRAITS ",checks-failures.size(),"/",checks," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
