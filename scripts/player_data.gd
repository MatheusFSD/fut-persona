class_name FootballPlayerData
extends Resource
## Lightweight player record. It references shared assets instead of owning a model/texture.
const BODY_KEYS := ["normal","magro","parrudo"]
const LEGACY_BODY_KEYS := ["normal","magro","parrudo","baixo_magro","baixo_parrudo"]
const DEFAULT_HEIGHT := 1.78
const ATTRIBUTE_KEYS := ["velocidade","chute","tecnica","passe","defesa","folego","reflexos"]
const ATTRIBUTE_NAMES := ["Velocidade","Chute","Técnica","Passe","Defesa","Fôlego","Reflexos"]
const DEFAULT_ATTRIBUTE := 70
const MIN_HEIGHT := 1.20
const MAX_HEIGHT := 2.30
const HAIR_KEYS := ["careca","raspado","curto","cacheado","moicano"]
const POSITION_KEYS := ["goleiro","zagueiro","ala_esquerda","ala_direita","atacante"]
const POSITION_NAMES := ["Goleiro","Zagueiro","Ala esquerda","Ala direita","Atacante"]
const SKIN_NAMES := ["Clara","Morena clara","Morena","Negra","Negra retinta"]
const SKIN_COLORS := [Color("f4d3b9"),Color("d5a276"),Color("aa6d49"),Color("75442f"),Color("42281f")]
const HAIR_COLORS := {"preto":Color("171615"),"castanho":Color("5b3523"),"loiro":Color("cfa95a"),"ruivo":Color("953e24"),"grisalho":Color("b6b6a8")}

@export var id: StringName
@export var nome := "Jogador"
@export_enum("Normal","Magro","Parrudo") var tipo_corpo := 0
@export_range(1.20,2.30,.01,"suffix:m") var altura := DEFAULT_HEIGHT
@export_range(0,4,1) var cor_pele := 0
@export_enum("Careca","Raspado","Curto","Cacheado","Moicano") var tipo_cabelo := 2
@export var cor_cabelo := Color("171615")
@export var time: StringName
@export_enum("Goleiro","Zagueiro","Ala esquerda","Ala direita","Atacante") var posicao := 0
@export_range(1,99,1) var numero := 1
@export_file("*.png","*.webp","*.jpg","*.jpeg","*.svg") var retrato := ""
@export var retrato_regiao := Rect2(0,0,1,1)
@export_file("*.png","*.webp","*.jpg","*.jpeg","*.svg") var comemoracao := ""
@export_range(1,99,1) var velocidade := DEFAULT_ATTRIBUTE
@export_range(1,99,1) var chute := DEFAULT_ATTRIBUTE
@export_range(1,99,1) var tecnica := DEFAULT_ATTRIBUTE
@export_range(1,99,1) var passe := DEFAULT_ATTRIBUTE
@export_range(1,99,1) var defesa := DEFAULT_ATTRIBUTE
@export_range(1,99,1) var folego := DEFAULT_ATTRIBUTE
@export_range(1,99,1) var reflexos := DEFAULT_ATTRIBUTE

static func attribute_scale(value: int, minimum := .8, maximum := 1.12) -> float:
	# 70 preserves the original tuning. Extremes stay bounded and deterministic.
	value = clampi(value,1,99)
	return lerpf(minimum,1.0,(value-1)/69.0) if value <= 70 else lerpf(1.0,maximum,(value-70)/29.0)

static func enum_value(value: Variant, keys: Array) -> int:
	if value is String: return keys.find(value)
	if value is int or value is float:
		var index := int(value)
		if float(index) == float(value) and index >= 0 and index < keys.size(): return index
	return -1

static func valid_height(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= MIN_HEIGHT and float(value) <= MAX_HEIGHT

static func valid_attribute(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 1 and float(value) <= 99 and float(value) == floorf(float(value))

static func from_dictionary(data: Dictionary) -> FootballPlayerData:
	for key in ["nome","tipo_corpo","cor_pele","tipo_cabelo","cor_cabelo","time","posicao"]:
		if not data.has(key): push_error("Missing player field: "+key); return null
	var result := FootballPlayerData.new()
	result.nome = String(data.nome).strip_edges()
	result.time = StringName(data.time)
	result.id = StringName(data.get("id",String(result.time)+"_"+result.nome.to_snake_case()))
	var body := enum_value(data.tipo_corpo,LEGACY_BODY_KEYS)
	result.tipo_corpo = body-2 if body >= 3 else body
	# Older short-body records migrate to a build plus a height in meters.
	var height: Variant = data.get("altura",1.53 if body >= 3 else DEFAULT_HEIGHT)
	if not valid_height(height):
		push_error("Player height must be a number between 1.20 and 2.30 meters"); return null
	result.altura = snappedf(float(height),.01)
	result.cor_pele = enum_value(data.cor_pele,SKIN_NAMES)
	result.tipo_cabelo = enum_value(data.tipo_cabelo,HAIR_KEYS)
	result.posicao = enum_value(data.posicao,POSITION_KEYS)
	result.numero = int(data.get("numero",result.posicao+1))
	var portrait: Variant = data.get("retrato","")
	if not portrait is String or (not portrait.is_empty() and (not portrait.begins_with("res://") or portrait.get_extension().to_lower() not in ["png","webp","jpg","jpeg","svg"])):
		push_error("Player portrait must be an image resource path"); return null
	result.retrato = portrait
	var celebration: Variant = data.get("comemoracao","")
	if not celebration is String or (not celebration.is_empty() and (not celebration.begins_with("res://") or celebration.get_extension().to_lower() not in ["png","webp","jpg","jpeg","svg"])):
		push_error("Player celebration must be an image resource path"); return null
	result.comemoracao = celebration
	var crop: Variant = data.get("retrato_regiao",[0,0,1,1])
	if not crop is Array or crop.size() != 4:
		push_error("Portrait region needs four normalized coordinates"); return null
	for component in crop:
		if not (component is int or component is float) or not is_finite(float(component)):
			push_error("Invalid portrait region coordinate"); return null
	if crop[0] < 0 or crop[1] < 0 or crop[2] <= 0 or crop[3] <= 0 or crop[0]+crop[2] > 1.00001 or crop[1]+crop[3] > 1.00001:
		push_error("Portrait region must fit inside the source image"); return null
	result.retrato_regiao = Rect2(float(crop[0]),float(crop[1]),float(crop[2]),float(crop[3]))
	for key in ATTRIBUTE_KEYS:
		var value: Variant = data.get(key,DEFAULT_ATTRIBUTE)
		if not valid_attribute(value):
			push_error("Player attribute must be an integer from 1 to 99: "+key); return null
		result.set(key,int(value))
	var hair := String(data.cor_cabelo)
	if HAIR_COLORS.has(hair): result.cor_cabelo = HAIR_COLORS[hair]
	elif Color.html_is_valid(hair): result.cor_cabelo = Color(hair)
	else: push_error("Unknown hair color: "+hair); return null
	if result.nome.is_empty() or result.time.is_empty() or result.tipo_corpo < 0 or result.cor_pele < 0 or result.tipo_cabelo < 0 or result.posicao < 0 or result.numero < 1 or result.numero > 99:
		push_error("Invalid player record: "+str(data)); return null
	return result

func position_name() -> String:
	return POSITION_NAMES[posicao]

func is_goalkeeper() -> bool:
	return posicao == 0
