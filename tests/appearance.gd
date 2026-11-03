extends SceneTree
const PROFILE = preload("res://scripts/player_data.gd")
const ROSTER = preload("res://scripts/roster_loader.gd")
const APPEARANCE = preload("res://scripts/player_appearance.gd")
const PLAYER = preload("res://scripts/footballer.gd")
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("PASS ",label)
	else: failures.append(label); push_error("FAIL "+label)

func mesh_of(p) -> MeshInstance3D:
	return p.avatar.find_children("*","MeshInstance3D",true,false)[0]

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.hud.hide(); game.ball.freeze = true
	for p in game.players: p.set_physics_process(false)
	check(game.players.size() == 10 and game.roster_profiles.size() == 10,"match assembles ten players from records")
	check(PROFILE.SKIN_COLORS.size() == 5 and PROFILE.HAIR_KEYS.size() == 5,"five skin tones and five hair choices")
	var ordered := true
	for i in range(1,5): ordered = ordered and PROFILE.SKIN_COLORS[i].get_luminance() < PROFILE.SKIN_COLORS[i-1].get_luminance()
	check(ordered,"skin palette ranges from light to dark with five distinct tones")
	for p in game.players:
		var label: String = p.profile.nome
		var material := mesh_of(p).get_surface_override_material(0) as ShaderMaterial
		check(p.profile is FootballPlayerData and p.profile == game.roster_profiles[p.team*5+p.slot] and p.body_type == p.profile.tipo_corpo,"record drives identity and body: "+label)
		check(p.team_definition.id == String(p.profile.time) and p.slot == p.profile.posicao and p.number_label.text == str(p.profile.numero),"record drives team, position and number: "+label)
		check(material != null and material.shader == APPEARANCE.SHADER and material.get_shader_parameter("region_mask") == APPEARANCE.MASKS[p.team_definition.modelo],"shared shader and shared region atlas: "+label)
		check(material.get_shader_parameter("skin_color") == PROFILE.SKIN_COLORS[p.profile.cor_pele] and material.get_shader_parameter("hair_color") == p.profile.cor_cabelo and material.get_shader_parameter("hair_type") == p.profile.tipo_cabelo,"record drives skin and hair colors and style: "+label)
		var keeper: bool = p.profile.is_goalkeeper()
		var shirt: Color = material.get_shader_parameter("shirt_color")
		check(material.get_shader_parameter("goalkeeper") == keeper and shirt == Color(p.team_definition.camisa_goleiro if keeper else p.team_definition.camisa),"role drives long sleeves and goalkeeper kit: "+label)
	for team in 2:
		var skins: Array = []; var roles: Array = []
		var base := mesh_of(game.players[team*5])
		var shared := true
		for i in 5:
			var p = game.players[team*5+i]
			skins.append(p.profile.cor_pele); roles.append(p.profile.posicao)
			shared = shared and mesh_of(p).mesh == base.mesh
			skins.sort()
		check(skins == [0,1,2,3,4] and roles == [0,1,2,3,4],"roster has all tones and roles in team "+str(team))
		check(shared,"all five body variants share one mesh in team "+str(team))
		var keeper_material: ShaderMaterial = base.get_surface_override_material(0)
		var field_material: ShaderMaterial = mesh_of(game.players[team*5+1]).get_surface_override_material(0)
		check(keeper_material.get_shader_parameter("shirt_color") != field_material.get_shader_parameter("shirt_color"),"goalkeeper jersey differs from teammates: "+str(team))
	var p = game.players[2]
	var copied: Resource = p.profile.duplicate(true)
	copied.nome = "Outro nome"; copied.numero = 18; copied.tipo_corpo = (copied.tipo_corpo+1)%3; copied.altura = 1.99
	var original_material := APPEARANCE.material_for(p.profile,p.team_definition)
	check(APPEARANCE.material_for(copied,p.team_definition) == original_material,"name, number, height and body changes reuse identical visual materials")
	copied.cor_pele = (p.profile.cor_pele+1)%5
	var other_material := APPEARANCE.material_for(copied,p.team_definition)
	check(other_material != original_material and other_material.get_shader_parameter("region_mask") == original_material.get_shader_parameter("region_mask"),"new skin color shares the same bitmap without mutating another player")
	var normal = game.players[0]; var other_normal = game.players[5]
	check(normal.animator.get_animation_library("football") == normal.BODIES.animation_library(PLAYER.LIBRARY,normal.body_height),"football clips cached by skeleton height")
	check(normal.animator.get_animation_library("custom") == PLAYER.custom_poses[normal.body_height],"authored kick/pass/tackle clips cached by skeleton height")
	check(game.players[3].animator.get_animation_library("custom") == PLAYER.custom_poses[game.players[3].body_height],"short player custom animation clips are cached too")
	var temporary: Resource = p.profile.duplicate(true)
	temporary.nome = "Goleiro por cadastro"; temporary.posicao = 0; temporary.tipo_corpo = 1
	var extra := PLAYER.new()
	extra.setup(game,0,4,Vector3(30,0,20),temporary,game.team_definitions[0]); game.add_child(extra); extra.set_physics_process(false)
	check(extra.is_goalkeeper() and extra.body_type == 1 and mesh_of(extra).get_surface_override_material(0).get_shader_parameter("goalkeeper"),"appearance uses record role/body rather than the old slot-based look")
	extra.queue_free()
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROSTER.DEFAULT_PATH))
	document.jogadores.reverse()
	var file := FileAccess.open("res://.runtime/shuffled_roster.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(document)); file.close()
	var shuffled := ROSTER.read_match("res://.runtime/shuffled_roster.json")
	var ordering: bool = shuffled.players.size() == 10
	for i in 10: ordering = ordering and shuffled.players[i].id == game.roster_profiles[i].id
	check(ordering,"record order does not change player positions or team membership")
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/player_appearance_manifest.json"))
	var mask_bytes := 0; var model_before := 0; var model_after := 0
	for model in ["hero","enemy_a"]:
		var data: Dictionary = report[model]
		mask_bytes += int(data.mask.bytes); model_before += int(data.before_bytes); model_after += int(data.after_bytes)
		var image: Image = APPEARANCE.MASKS[model].get_image()
		check(image.get_width() == 256 and image.get_height() == 256 and data.mask.regions == [1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0],"atlas contains skin, clothing, boots, face, sleeve and collar regions: "+model)
		check(data.topology_uv_weights_bones_and_body_morphs_unchanged and data.photo_textures_removed and data.unused_gun_clips_removed,"optimized model preserves geometry and removes unused photo/clip data: "+model)
	check(mask_bytes < 100000,"only two small shared mask textures are needed")
	check(model_after < model_before*.4,"shared model files are over sixty percent smaller")
	print("APPEARANCE ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
