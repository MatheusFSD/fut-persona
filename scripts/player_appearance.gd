extends RefCounted
const PROFILE = preload("res://scripts/player_data.gd")
const SHADER = preload("res://assets/characters/player_appearance.gdshader")
const MODELS := {"hero":preload("res://assets/characters/hero.glb"),"enemy_a":preload("res://assets/characters/enemy_a.glb")}
const MASKS := {"hero":preload("res://assets/characters/hero_regions.png"),"enemy_a":preload("res://assets/characters/enemy_a_regions.png")}
static var materials: Dictionary = {}

static func instantiate_model(team: Dictionary) -> Node3D:
	return MODELS[team.modelo].instantiate()

static func material_for(profile: Resource, team: Dictionary) -> ShaderMaterial:
	var goalkeeper: bool = profile.is_goalkeeper()
	var shirt := Color(team.camisa_goleiro if goalkeeper else team.camisa)
	var shorts := Color(team.get("short_goleiro",team.short) if goalkeeper else team.short)
	var socks := Color(team.get("meiao_goleiro",team.meiao) if goalkeeper else team.meiao)
	var trim := Color(team.get("detalhe","#f1eed8"))
	var secondary := Color(team.get("cor_secundaria",team.camisa))
	var pattern := ["liso","listras_verticais","faixa_peito"].find(team.get("padrao","liso"))
	# Name, number and body type do not duplicate textures or materials.
	var key := str([team.modelo,profile.cor_pele,profile.tipo_cabelo,profile.cor_cabelo.to_html(),goalkeeper,shirt.to_html(),shorts.to_html(),socks.to_html(),trim.to_html(),secondary.to_html(),pattern])
	if materials.has(key): return materials[key]
	var material := ShaderMaterial.new(); material.shader = SHADER
	material.set_shader_parameter("region_mask",MASKS[team.modelo])
	material.set_shader_parameter("skin_color",PROFILE.SKIN_COLORS[profile.cor_pele])
	material.set_shader_parameter("hair_color",profile.cor_cabelo)
	material.set_shader_parameter("hair_type",profile.tipo_cabelo)
	material.set_shader_parameter("shirt_color",shirt)
	material.set_shader_parameter("shorts_color",shorts)
	material.set_shader_parameter("socks_color",socks)
	material.set_shader_parameter("trim_color",trim)
	material.set_shader_parameter("secondary_color",secondary)
	material.set_shader_parameter("shirt_pattern",pattern)
	material.set_shader_parameter("goalkeeper",goalkeeper)
	materials[key] = material
	return material

static func apply(model: Node3D, profile: Resource, team: Dictionary) -> void:
	var material := material_for(profile,team)
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count(): mesh.set_surface_override_material(surface,material)
