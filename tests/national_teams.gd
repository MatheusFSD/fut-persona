extends SceneTree
const ROSTER = preload("res://scripts/roster_loader.gd")
const APPEARANCE = preload("res://scripts/player_appearance.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL "+label)

func run() -> void:
	var catalog := ROSTER.read_catalog()
	check(catalog.teams.size() == 4 and catalog.players.size() == 4,"four national rosters")
	var combinations := 0
	for home in 4:
		for away in 4:
			if home == away: continue
			for a in 2:
				for b in 2:
					var first: Dictionary = catalog.teams[home]; var second: Dictionary = catalog.teams[away]
					var selection := [{"time":first.id,"uniforme":first.uniformes[a].id},{"time":second.id,"uniforme":second.uniformes[b].id}]
					var data := ROSTER.assemble_match(catalog,selection)
					check(data.players.size() == 10 and data.teams[0].id == first.id and data.teams[1].id == second.id,"match assembly preserves sides")
					for side in 2:
						var team: Dictionary = data.teams[side]
						var bodies: Array = []; var skins: Array = []
						for slot in 5:
							var p: Resource = data.players[side*5+slot]
							check(String(p.time) == team.id and p.posicao == slot,"lineup keeps team and role")
							bodies.append(p.tipo_corpo); skins.append(p.cor_pele)
							var mat := APPEARANCE.material_for(p,team)
							check(mat.get_shader_parameter("shirt_color") == Color(team.camisa_goleiro if slot == 0 else team.camisa),"selected kit colors reach player material")
							check(mat.get_shader_parameter("goalkeeper") == (slot == 0),"goalkeeper sleeves follow role")
						bodies.sort(); skins.sort()
						check(bodies == [0,1,1,2,2] and skins == [0,1,2,3,4],"three body builds and all skin tones represented")
						check(team.camisa != team.camisa_goleiro,"goalkeeper has a different jersey")
					combinations += 1
	check(combinations == 48,"all ordered matchups and kit combinations")
	for team: Dictionary in catalog.teams:
		check(team.uniformes.size() == 2 and team.uniformes[0].camisa != team.uniformes[1].camisa,"two distinct kits per nation")
		var first := ROSTER.assemble_match(catalog,[{"time":team.id,"uniforme":"titular"},{"time":catalog.teams[(catalog.teams.find(team)+1)%4].id,"uniforme":"titular"}])
		var alternate: Dictionary = first.teams[0].duplicate(true)
		alternate.padrao = "faixa_peito" if first.teams[0].get("padrao") != "faixa_peito" else "liso"
		check(APPEARANCE.material_for(first.players[1],first.teams[0]) != APPEARANCE.material_for(first.players[1],alternate),"pattern participates in material cache")
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROSTER.DEFAULT_PATH))
	var default_match := ROSTER.assemble_match(catalog,catalog.selection)
	var legacy_document := {"times":default_match.teams.duplicate(true),"jogadores":[]}
	for team: Dictionary in legacy_document.times: team.erase("uniformes")
	for record: Dictionary in document.jogadores:
		if record.time in [default_match.teams[0].id,default_match.teams[1].id]: legacy_document.jogadores.append(record)
	var file := FileAccess.open("res://.runtime/legacy_roster.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy_document)); file.close()
	var legacy := ROSTER.read_match("res://.runtime/legacy_roster.json")
	check(legacy.players.size() == 10 and legacy.teams[0].id == "brasil","old editable roster remains supported")
	var game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true
	for p in game.players: p.set_physics_process(false)
	var profile: Resource = game.players[1].profile
	var mesh: Mesh = game.players[1].avatar.find_children("*","MeshInstance3D",true,false)[0].mesh
	game.hud.kit_choices[0].item_selected.emit(1)
	await process_frame
	check(game.match_selection[0].uniforme == "reserva" and game.team_definitions[0].camisa == "#1749ad","kit selector applies alternate kit")
	check(game.players[1].profile == profile and game.players[1].avatar.find_children("*","MeshInstance3D",true,false)[0].mesh == mesh,"kit change reuses profile and base mesh")
	game.hud.team_choices[0].item_selected.emit(1)
	await process_frame
	check(game.team_definitions[0].id == "argentina" and game.team_definitions[1].id == "brasil","choosing opponent swaps teams without duplicates")
	game.hud.team_choices[0].item_selected.emit(2)
	game.hud.team_choices[1].item_selected.emit(3)
	game.hud.kit_choices[1].item_selected.emit(1)
	await process_frame
	check(game.players.size() == 10 and game.get_children().filter(func(node): return node is CharacterBody3D).size() == 10,"selection leaves exactly ten live player objects")
	check(game.team_definitions[0].id == "alemanha" and game.team_definitions[1].id == "franca" and game.team_definitions[1].uniforme_id == "reserva","both national team selectors update match")
	game.new_match()
	check(game.phase == "restart" and game.controlled.profile.time == &"alemanha","new match starts with selected national roster")
	check(not game.select_match(catalog.selection),"cannot rebuild players during play")
	game.selection_menu()
	check(game.phase == "menu" and game.ball.freeze and game.carrier == null and game.receiving_player == null,"return to selection clears possession safely")
	game.hud.team_choices[0].item_selected.emit(0)
	game.new_match()
	check(game.score == [0,0] and game.elapsed == 0 and game.players[4].profile.time == &"brasil","next match resets with new selection")
	print("NATIONAL_TEAMS ",checks-failures.size(),"/",checks," passed; combinations=",combinations," failures=",failures)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
