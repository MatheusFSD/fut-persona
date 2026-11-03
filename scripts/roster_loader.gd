extends RefCounted
const PROFILE = preload("res://scripts/player_data.gd")
const DEFAULT_PATH := "res://data/match_roster.json"
const PATTERNS := ["liso", "listras_verticais", "faixa_peito"]

static func read_catalog(path := DEFAULT_PATH) -> Dictionary:
	if path == DEFAULT_PATH and not OS.has_feature("editor"):
		var external := OS.get_executable_path().get_base_dir().path_join("match_roster.json")
		if FileAccess.file_exists(external): path = external
	var text := FileAccess.get_file_as_string(path)
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		push_error("Cannot load match roster: "+path); return {}
	var document: Dictionary = parser.data
	if not document.get("times") is Array or not document.get("jogadores") is Array or document.times.size() < 2:
		push_error("A catalog needs at least two teams and their player records"); return {}
	var teams: Array = document.times
	var team_ids: Array[StringName] = []
	for entry in teams:
		if not entry is Dictionary: push_error("Invalid team record"); return {}
		var team: Dictionary = entry
		for key in ["id","nome","sigla","modelo"]:
			if not team.has(key): push_error("Missing team field: "+key); return {}
		if team.modelo not in ["hero","enemy_a"] or StringName(team.id) in team_ids:
			push_error("Invalid or duplicate team definition"); return {}
		# Older editable rosters with colors directly on the team remain usable.
		if not team.has("uniformes"):
			var kit := team.duplicate(true); kit.id = "titular"; kit.nome = "Titular"
			team.uniformes = [kit]
		if not team.uniformes is Array or team.uniformes.is_empty(): push_error("Missing kits"); return {}
		var kit_ids: Array = []
		for kit in team.uniformes:
			if not kit is Dictionary: push_error("Invalid kit record"); return {}
			for key in ["id","nome","camisa","short","meiao","camisa_goleiro"]:
				if not kit.has(key): push_error("Missing kit field: "+key); return {}
			if kit.id in kit_ids or kit.get("padrao","liso") not in PATTERNS: push_error("Invalid kit id or pattern"); return {}
			for key in ["camisa","short","meiao","camisa_goleiro","short_goleiro","meiao_goleiro","detalhe","cor_secundaria"]:
				if kit.has(key) and (not kit[key] is String or not Color.html_is_valid(kit[key])): push_error("Invalid kit color"); return {}
			kit_ids.append(kit.id)
		team_ids.append(StringName(team.id))
	var players: Dictionary = {}; var ids: Array[StringName] = []
	for team_id in team_ids:
		var lineup: Array = []; lineup.resize(5); players[team_id] = lineup
	for record in document.jogadores:
		if not record is Dictionary: push_error("Invalid player record"); return {}
		var profile := PROFILE.from_dictionary(record)
		if profile == null or profile.time not in team_ids or profile.id in ids:
			push_error("Invalid player/team or duplicate player id"); return {}
		if players[profile.time][profile.posicao] != null: push_error("Duplicate player position"); return {}
		players[profile.time][profile.posicao] = profile; ids.append(profile.id)
	for lineup: Array in players.values():
		if null in lineup: push_error("Each team needs exactly one player in each position"); return {}
	var selection: Array = document.get("partida",[
		{"time":teams[0].id,"uniforme":teams[0].uniformes[0].id},
		{"time":teams[1].id,"uniforme":teams[1].uniformes[0].id}])
	var catalog := {"teams":teams,"players":players,"selection":selection,"path":path}
	if assemble_match(catalog,selection).is_empty(): return {}
	return catalog

static func assemble_match(catalog: Dictionary, selection: Array) -> Dictionary:
	if selection.size() != 2 or not selection[0] is Dictionary or not selection[1] is Dictionary:
		push_error("Choose two teams and kits"); return {}
	if selection[0].get("time") == selection[1].get("time"):
		push_error("Choose different teams"); return {}
	var teams: Array = []; var players: Array = []
	for choice: Dictionary in selection:
		var found := false
		for team: Dictionary in catalog.teams:
			if team.id != choice.get("time"): continue
			for kit: Dictionary in team.uniformes:
				if kit.id != choice.get("uniforme"): continue
				var active := team.duplicate(true)
				for key in kit:
					if key not in ["id","nome"]: active[key] = kit[key]
				active.uniforme_id = kit.id; active.uniforme_nome = kit.nome
				teams.append(active); players.append_array(catalog.players[StringName(team.id)])
				found = true; break
			break
		if not found: push_error("Unknown team or kit in match selection"); return {}
	return {"teams":teams,"players":players}

static func read_match(path := DEFAULT_PATH) -> Dictionary:
	var catalog := read_catalog(path)
	if catalog.is_empty(): return {}
	var match_data := assemble_match(catalog,catalog.selection)
	if "--verify-roster" in OS.get_cmdline_user_args(): print("ROSTER_LOADED players=",match_data.players.size()," teams=",catalog.teams.size()," path=",catalog.path)
	return match_data
