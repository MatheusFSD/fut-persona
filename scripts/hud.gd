extends Control
## Arcade cut-paper presentation: young, loud and torn by hand, set in Rio.
## All effects stay in CanvasItem space; shapes come from ui_shapes.gd.
const FLAGS = preload("res://scripts/ui_flags.gd")
const PORTRAITS = preload("res://scripts/player_portraits.gd")
const SHAPES = preload("res://scripts/ui_shapes.gd")
const DESIGN := Vector2(1440,900)
const BLACK := Color("10101c")
const PAPER := Color("fff6e7")
const PINK := Color("ff287e")
const CYAN := Color("35edf0")
const GOLD := Color("ffe049")
const MUTED := Color("b6b7cd")
const SLATE := Color("303047")
# `shape` picks the silhouette of the on-field reaction; `symbol` what flies around it.
const REACTIONS := {
	"dribble":{"text":"ENTORTOU!","color":CYAN,"duration":1.1,"shape":"burst","symbol":"bolt"},
	"slide":{"text":"NA BOLA!","color":CYAN,"duration":1.25,"shape":"burst","symbol":"star"},
	"steal":{"text":"É NOSSA!","color":CYAN,"duration":1.15,"shape":"balloon","symbol":"heart"},
	"woodwork":{"text":"NA TRAVEEE!","color":GOLD,"duration":1.6,"shape":"burst","symbol":"bolt"},
	"save":{"text":"MILAGRE!","color":GOLD,"duration":1.4,"shape":"burst","symbol":"star"},
	"power":{"text":"WOOOOW!","color":PINK,"duration":1.1,"shape":"burst","symbol":"star"},
	"foul":{"text":"FOI MAL!","color":PINK,"duration":1.45,"shape":"balloon","symbol":"bang"},
	"throw_in":{"text":"SAIU!","color":CYAN,"duration":1.3,"shape":"torn","symbol":"bang"},
	"corner":{"text":"NO CANTO!","color":GOLD,"duration":1.3,"shape":"torn","symbol":"star"},
	"goal_kick":{"text":"PRA FORA!","color":CYAN,"duration":1.3,"shape":"torn","symbol":"bang"},
	"drop":{"text":"OPA!","color":PAPER,"duration":1.25,"shape":"balloon","symbol":"ask"}}
const MAX_REACTIONS := 4
const DIGITS := {
	"0":["01110","10001","10001","10001","10001","10001","01110"],
	"1":["00100","01100","00100","00100","00100","00100","01110"],
	"2":["11110","00001","00001","11110","10000","10000","11111"],
	"3":["11110","00001","00001","01110","00001","00001","11110"],
	"4":["10010","10010","10010","11111","00010","00010","00010"],
	"5":["11111","10000","10000","11110","00001","00001","11110"],
	"6":["01111","10000","10000","11110","10001","10001","01110"],
	"7":["11111","00001","00010","00100","01000","01000","01000"],
	"8":["01110","10001","10001","01110","10001","10001","01110"],
	"9":["01110","10001","10001","01111","00001","00001","11110"],
	":":["00000","00100","00100","00000","00100","00100","00000"]}
var game
var font: Font
var body_font: Font
var faces: Array[Font] = []
var button: Button
var change_button: Button
var team_choices: Array[OptionButton] = []
var kit_choices: Array[OptionButton] = []
var ui_root: Control
var ui_transform := Transform2D.IDENTITY
var animation_time := 0.0
var goal_team := -1
var goal_age := 0.0
var goal_serial := 0
var message_age := 0.0
var previous_message := ""
var reactions: Array[Dictionary] = []
var reaction_serial := 0
var score_pop := [1.0,1.0]
var shown_score := [0,0]
var grown_cache: Dictionary = {}
var triangle_cache: Dictionary = {}
var shape_cache: Dictionary = {}
var batch_points := PackedVector2Array()
var batch_colors := PackedColorArray()
var batch_indices := PackedInt32Array()
var confetti_shapes: Array[PackedVector2Array] = [SHAPES.star(Vector2.ZERO,9),SHAPES.shard(Vector2(-9,0),Vector2(11,0),11),SHAPES.pipa(Vector2.ZERO,8),SHAPES.heart(Vector2.ZERO,6)]
var _current_frame := Transform2D.IDENTITY

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The same art appears from thumbnail to full cut-in size.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	body_font = ThemeDB.fallback_font
	# Resolve installed typefaces; no proprietary font files are redistributed.
	font = _system_font(["Impact","Arial Black","DejaVu Sans"])
	# Ransom-note letters mix a condensed, a wide and a serif face.
	faces = [font,_system_font(["Arial Black","Impact","DejaVu Sans"]),_system_font(["Georgia","Times New Roman","DejaVu Serif"])]
	ui_root = Control.new(); ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(ui_root)
	button = Button.new(); _button_skin(button,29)
	button.pressed.connect(func():
		if game.phase == "paused": game.toggle_pause()
		else: game.new_match())
	ui_root.add_child(button)
	change_button = Button.new(); change_button.text = "TROCAR SELEÇÕES / UNIFORMES"
	_button_skin(change_button,18)
	change_button.pressed.connect(game.selection_menu); ui_root.add_child(change_button)
	for side in 2:
		var teams := OptionButton.new(); var kits := OptionButton.new()
		for team: Dictionary in game.team_catalog.teams: teams.add_icon_item(FLAGS.texture(team.id),team.nome.to_upper())
		for choice in [teams,kits]:
			choice.mouse_filter = Control.MOUSE_FILTER_STOP
			_selector_skin(choice,CYAN if side == 0 else PINK)
			ui_root.add_child(choice)
		team_choices.append(teams); kit_choices.append(kits)
		teams.item_selected.connect(func(index: int): _choose_team(side,index))
		kits.item_selected.connect(func(index: int): _choose_kit(side,index))
	sync_selection(); _layout()

func _system_font(names: Array) -> Font:
	var result := SystemFont.new()
	result.font_names = PackedStringArray(names)
	result.font_weight = 900
	return result

func _box(color: Color, border := PAPER, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = color
	style.border_color = border; style.set_border_width_all(width)
	style.content_margin_left = 18; style.content_margin_right = 18
	style.content_margin_top = 8; style.content_margin_bottom = 8
	return style

# Native controls keep their behavior; their silhouette is drawn underneath in _draw.
func _button_skin(control: Button, size: int) -> void:
	var clear := _box(Color(0,0,0,0),Color(0,0,0,0),0)
	control.add_theme_font_override("font",font)
	control.add_theme_font_size_override("font_size",size)
	for state in ["normal","hover","pressed","focus"]: control.add_theme_stylebox_override(state,clear)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: control.add_theme_color_override(key,BLACK)
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _selector_skin(control: OptionButton, color: Color) -> void:
	var clear := _box(Color(0,0,0,0),Color(0,0,0,0),0)
	control.add_theme_font_override("font",font)
	control.add_theme_font_size_override("font_size",22)
	control.add_theme_constant_override("icon_max_width",42)
	control.add_theme_constant_override("h_separation",14)
	for state in ["normal","hover","pressed","focus"]: control.add_theme_stylebox_override(state,clear)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: control.add_theme_color_override(key,PAPER)
	var popup := control.get_popup()
	popup.add_theme_font_override("font",font); popup.add_theme_font_size_override("font_size",22)
	popup.add_theme_stylebox_override("panel",_box(BLACK,PAPER,2))
	popup.add_theme_stylebox_override("hover",_box(color,BLACK,1))
	popup.add_theme_color_override("font_color",PAPER); popup.add_theme_color_override("font_hover_color",BLACK)
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func sync_selection() -> void:
	clear_reactions()
	for side in 2:
		var index := 0
		for i in game.team_catalog.teams.size():
			if game.team_catalog.teams[i].id == game.match_selection[side].time: index = i; break
		team_choices[side].select(index); kit_choices[side].clear()
		var kits: Array = game.team_catalog.teams[index].uniformes
		for kit: Dictionary in kits: kit_choices[side].add_item(kit.nome.to_upper())
		for i in kits.size():
			if kits[i].id == game.match_selection[side].uniforme: kit_choices[side].select(i); break
	queue_redraw()

func _choose_team(side: int, index: int) -> void:
	var selection: Array = game.match_selection.duplicate(true)
	var team: Dictionary = game.team_catalog.teams[index]
	var previous: Dictionary = selection[side].duplicate(true)
	selection[side] = {"time":team.id,"uniforme":team.uniformes[0].id}
	if selection[1-side].time == team.id: selection[1-side] = previous
	game.select_match(selection)

func _choose_kit(side: int, index: int) -> void:
	var selection: Array = game.match_selection.duplicate(true)
	var team: Dictionary = game.team_catalog.teams[team_choices[side].selected]
	selection[side].uniforme = team.uniformes[index].id
	game.select_match(selection)

func celebrate_goal(side: int) -> void:
	clear_reactions()
	goal_team = side; goal_age = 0; goal_serial += 1
	queue_redraw()

func _process(delta: float) -> void:
	if game == null: return
	animation_time += delta
	if game.phase in ["menu","finished","celebrate"]: clear_reactions()
	elif game.phase in ["playing","foul","restart","out","set_piece"]:
		for i in range(reactions.size()-1,-1,-1):
			reactions[i].age += delta
			if reactions[i].age >= reactions[i].duration: reactions.remove_at(i)
	if game.message != previous_message:
		previous_message = game.message; message_age = 0
	else: message_age += delta
	if game.phase == "celebrate" and not game.goal_reveal_pending: goal_age = clampf(game.GOAL_DURATION-game.phase_timer,0,game.GOAL_DURATION)
	elif game.phase not in ["celebrate","paused"]: goal_team = -1
	for side in 2:
		if game.score[side] != shown_score[side]:
			# Lowering the score is a new match, not a moment to celebrate.
			score_pop[side] = 0.0 if game.score[side] > shown_score[side] else 1.0
			shown_score[side] = game.score[side]
		score_pop[side] = minf(score_pop[side]+delta/.45,1)
	_layout(); queue_redraw()

func clear_reactions() -> void:
	reactions.clear()

func push_reaction(kind: String, world: Vector3, side: int, detail := "") -> bool:
	if game.phase not in ["playing","foul","restart","out","set_piece"] or not REACTIONS.has(kind): return false
	# Suppress repeated contacts at the same spot, but allow simultaneous distant plays.
	for active: Dictionary in reactions:
		if active.kind == kind and active.origin.distance_to(world) < 3 and active.age < .7: return false
	var event: Dictionary = REACTIONS[kind].duplicate()
	event.merge({"kind":kind,"origin":world,"side":side,"detail":detail,"age":0.0,"serial":reaction_serial})
	reaction_serial += 1
	if reactions.size() >= MAX_REACTIONS: reactions.pop_front()
	reactions.append(event); queue_redraw()
	return true

func reaction_screen_position(event: Dictionary) -> Vector2:
	var inverse := ui_transform.affine_inverse()
	var at: Vector2 = inverse*game.camera.unproject_position(event.origin+Vector3.UP*1.1)
	# Far enough from the spot for the lightning tail to read as a pointer.
	at += Vector2(62,-66-event.age*20)
	at.x = clampf(at.x,175,1265); at.y = clampf(at.y,191,748)
	if at.y > 649 and (at.x < 450 or at.x > 1080): at.y = 649
	return at

func _layout() -> void:
	var view := get_viewport_rect().size
	var scale_factor := minf(view.x/DESIGN.x,view.y/DESIGN.y)
	var offset := (view-DESIGN*scale_factor)*.5
	ui_transform = Transform2D(0,Vector2.ONE*scale_factor,0,offset)
	ui_root.position = offset; ui_root.scale = Vector2.ONE*scale_factor
	for side in team_choices.size():
		var left := 92.0+side*736.0
		team_choices[side].visible = game.phase == "menu"; kit_choices[side].visible = game.phase == "menu"
		team_choices[side].position = Vector2(left,336); team_choices[side].size = Vector2(290,48)
		kit_choices[side].position = Vector2(left+228,392); kit_choices[side].size = Vector2(290,38)
		if side == 1: team_choices[side].position.x = left+228; kit_choices[side].position.x = left
	button.visible = game.phase in ["menu","paused","finished"]
	change_button.visible = game.phase in ["paused","finished"]
	button.size = Vector2(456,64); change_button.size = Vector2(440,42)
	button.position = Vector2(492,716)
	if game.phase == "paused":
		button.position.y = 604; button.text = "CONTINUAR  >>"
	elif game.phase == "finished":
		button.position.y = 696; button.text = "MAIS UMA PARTIDA  >>"
	else: button.text = "ENTRAR EM CAMPO  >>"
	change_button.position = Vector2(500,690 if game.phase == "paused" else 780)

# ---- text ----

func text(at: Vector2, value: String, size := 18, color := PAPER) -> void:
	_flush(); draw_string(body_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func centered(at: Vector2, value: String, size := 18, color := PAPER) -> void:
	text(at-Vector2(body_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5,0),value,size,color)

func _shout(at: Vector2, value: String, size: int, color := PAPER, angle := 0.0) -> void:
	# Quick italic label: condensed face leaning into the direction of play.
	_set_frame(ui_transform*Transform2D(angle,Vector2.ONE,-.12,at))
	_flush(); draw_string_outline(font,Vector2.ZERO,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,BLACK)
	_flush(); draw_string(font,Vector2.ZERO,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
	_set_frame(ui_transform)

func _shout_center(at: Vector2, value: String, size: int, color := PAPER, angle := 0.0) -> void:
	_shout(at-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5,0),value,size,color,angle)

func _loud(at: Vector2, value: String, size: int, color := PAPER, angle := 0.0) -> void:
	_set_frame(ui_transform*Transform2D(angle,at))
	if color == BLACK:
		_flush(); draw_string(font,Vector2.ZERO,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,BLACK)
		_set_frame(ui_transform); return
	_flush(); draw_string_outline(font,Vector2(6,7),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,7,BLACK)
	_flush(); draw_string(font,Vector2(5,5),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,PINK)
	_flush(); draw_string_outline(font,Vector2.ZERO,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,6,BLACK)
	_flush(); draw_string(font,Vector2.ZERO,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
	_set_frame(ui_transform)

func _loud_center(at: Vector2, value: String, size: int, color := PAPER, angle := 0.0) -> void:
	_loud(at-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5,0),value,size,color,angle)

# One letter cut from a different magazine: style 0-3 picks tile and ink.
func _letter(at: Vector2, letter: String, size: int, style: int, accent: Color, angle: float, seed_value: int, frame := Transform2D.IDENTITY, opacity := 1.0) -> float:
	var face: Font = faces[absi(seed_value)%faces.size()]
	var width := face.get_string_size(letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	_set_frame(ui_transform*frame*Transform2D(angle,at))
	var tile := _torn(Rect2(-size*.07,-size*.84,width+size*.14,size*1.0),seed_value,size*.07)
	var ink := PAPER
	match style:
		0: _fill(tile,Color(BLACK,opacity)); ink = PAPER
		1: _fill(tile,Color(PAPER,opacity)); ink = BLACK
		2: _fill(tile,Color(accent,opacity)); ink = BLACK
		_:
			_flush(); draw_string_outline(face,Vector2(size*.04,size*.05),letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size,maxi(int(size*.1),3),Color(accent,opacity))
			_flush(); draw_string_outline(face,Vector2.ZERO,letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size,maxi(int(size*.1),3),Color(BLACK,opacity))
	_flush(); draw_string(face,Vector2.ZERO,letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(ink,opacity))
	_set_frame(ui_transform*frame)
	return width

func _ransom_width(value: String, size: int, seed_value: int, quick := false) -> float:
	var width := 0.0
	for i in value.length():
		var letter := value.substr(i,1)
		if letter == " ": width += size*.34; continue
		var face: Font = font if quick else faces[absi(seed_value+i)%faces.size()]
		width += face.get_string_size(letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x+size*.2
	return width

# A title made of cut-out letters, each with its own face, tile and tilt. All the paper
# goes down first, so one batch covers it and no tile can hide its neighbor's letter.
# `quick` text is read mid-play: one face and less tilt, keeping only the cut paper.
func _ransom(at: Vector2, value: String, size: int, seed_value: int, accent := PINK, frame := Transform2D.IDENTITY, opacity := 1.0, center := false, quick := false) -> void:
	var start := at.x-(_ransom_width(value,size,seed_value,quick)*.5 if center else 0.0)
	var lean := .05 if quick else .13
	_set_frame(ui_transform*frame)
	for inking in [false,true]:
		var x := start
		var previous := -1
		for i in value.length():
			var letter := value.substr(i,1)
			if letter == " ": x += size*.34; continue
			var style := int(absf(SHAPES.noise(seed_value,i))*4.0)%4
			if style == previous: style = (style+1)%4
			previous = style
			var place := Transform2D(SHAPES.noise(seed_value,i+60)*lean,Vector2(x,at.y+SHAPES.noise(seed_value,i+30)*size*.07))
			var face: Font = font if quick else faces[absi(seed_value+i)%faces.size()]
			var width := face.get_string_size(letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
			if inking: _ink(face,letter,size,style,accent,place,frame,opacity)
			elif style != 3: _fill(_torn(Rect2(-size*.07,-size*.84,width+size*.14,size*1.0),seed_value+i,size*.07),Color([BLACK,PAPER,accent][style],opacity),place)
			x += width+size*.2
		_flush()
	_set_frame(ui_transform*frame)

func _ink(face: Font, letter: String, size: int, style: int, accent: Color, place: Transform2D, frame: Transform2D, opacity: float) -> void:
	draw_set_transform_matrix(ui_transform*frame*place)
	if style == 3:
		draw_string_outline(face,Vector2(size*.04,size*.05),letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size,maxi(int(size*.1),3),Color(accent,opacity))
		draw_string_outline(face,Vector2.ZERO,letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size,maxi(int(size*.1),3),Color(BLACK,opacity))
	elif style in [1,2]:
		# A bite in the tile must not swallow black ink against a black background.
		draw_string_outline(face,Vector2.ZERO,letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size,maxi(int(size*.12),4),Color(PAPER if style == 1 else accent,opacity))
	draw_string(face,Vector2.ZERO,letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(BLACK if style in [1,2] else PAPER,opacity))

func _wave(at: Vector2, value: String, size: int, color: Color, amplitude := 3.0) -> void:
	var x := at.x-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5
	for i in value.length():
		var letter := value.substr(i,1)
		_loud(Vector2(x,at.y+sin(animation_time*3.2-i*.48)*amplitude),letter,size,color,-.025)
		x += font.get_string_size(letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x

func _pixel(at: Vector2, value: String, scale_factor: float, color: Color) -> void:
	var x := at.x-value.length()*6.0*scale_factor*.5
	for letter in value:
		if DIGITS.has(letter):
			var rows: Array = DIGITS[letter]
			for y in 7:
				for column in 5:
					if rows[y].substr(column,1) == "1":
						var rect := Rect2(x+column*scale_factor,at.y+y*scale_factor,scale_factor,scale_factor)
						_flush(); draw_rect(Rect2(rect.position+Vector2(2,3),rect.size),PINK.darkened(.4))
						_flush(); draw_rect(rect,color)
		x += scale_factor*6

# ---- cut paper ----

# Every polygon would otherwise be its own draw call. Consecutive fills share one
# triangle array, so anything else drawn in between must call _flush() first.
func _fill(points: PackedVector2Array, color: Color, shift := Transform2D.IDENTITY) -> void:
	if color.a <= 0 or points.size() < 3: return
	var key := hash(points)
	var triangles: PackedInt32Array
	if triangle_cache.has(key): triangles = triangle_cache[key]
	else:
		triangles = Geometry2D.triangulate_polygon(points)
		if triangle_cache.size() > 4000: triangle_cache.clear()
		triangle_cache[key] = triangles
	var base := batch_points.size()
	batch_points.append_array(points if shift == Transform2D.IDENTITY else shift*points)
	for i in points.size(): batch_colors.append(color)
	for index in triangles: batch_indices.append(base+index)

func _flush() -> void:
	if batch_indices.is_empty(): return
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(),batch_indices,batch_points,batch_colors)
	batch_points.clear(); batch_colors.clear(); batch_indices.clear()

func _set_frame(frame: Transform2D) -> void:
	_flush(); draw_set_transform_matrix(frame)

func _torn(rect: Rect2, seed_value := 0, bite := 16.0) -> PackedVector2Array:
	var key := hash([rect,seed_value,bite])
	if not shape_cache.has(key): shape_cache[key] = SHAPES.torn(rect,seed_value,bite)
	return shape_cache[key]

func _burst(center: Vector2, radius: Vector2, spikes := 11, seed_value := 0, depth := .52) -> PackedVector2Array:
	var key := hash([center,radius,spikes,seed_value,depth])
	if not shape_cache.has(key): shape_cache[key] = SHAPES.burst(center,radius,spikes,seed_value,depth)
	return shape_cache[key]

func _balloon(rect: Rect2, tip: Vector2, seed_value := 0, sides := 14) -> PackedVector2Array:
	var key := hash([rect,tip,seed_value,sides])
	if not shape_cache.has(key): shape_cache[key] = SHAPES.balloon(rect,tip,seed_value,sides)
	return shape_cache[key]

func _grown(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var key := hash(points)+int(amount*16)
	if grown_cache.has(key): return grown_cache[key]
	var result := Geometry2D.offset_polygon(points,amount,Geometry2D.JOIN_MITER)
	var outer: PackedVector2Array = result[0] if not result.is_empty() else points
	if grown_cache.size() > 3000: grown_cache.clear()
	grown_cache[key] = outer
	return outer

# Fill, a hard outline around it and a shadow thrown off to one side.
func _cut(points: PackedVector2Array, color: Color, outline := PAPER, shadow := BLACK, drop := Vector2(7,8), thickness := 3.0) -> void:
	var edge := _grown(points,thickness) if thickness > 0 else points
	if shadow.a > 0: _fill(edge,shadow,Transform2D(0,drop))
	if thickness > 0: _fill(edge,outline)
	_fill(points,color)

func _flag(rect: Rect2, id: String, seed_value := 0) -> void:
	var shape := _torn(rect,seed_value,minf(rect.size.y*.16,7))
	_cut(shape,BLACK,PAPER,BLACK,Vector2(4,5),2)
	var uvs := PackedVector2Array()
	for point in shape: uvs.append(((point-rect.position)/rect.size).clampf(0,1))
	_flush(); draw_colored_polygon(shape,Color.WHITE,uvs,FLAGS.texture(id))

func _halftone(rect: Rect2, color: Color, step := 20) -> void:
	for y in range(int(rect.position.y),int(rect.end.y),step):
		for x in range(int(rect.position.x),int(rect.end.x),step):
			# Dots shrink towards the far edge, like an enlarged magazine print.
			var fade := 1.0-(x-rect.position.x)/rect.size.x
			if fade > .05: _fill(SHAPES.pipa(Vector2(x,y),1.4+fade*3.4),color)

func _screen_rect() -> Rect2:
	return Rect2(-ui_transform.origin/ui_root.scale,get_viewport_rect().size/ui_root.scale)

func _symbol(kind: String, at: Vector2, size: float, color: Color, opacity := 1.0, spin := 0.0) -> void:
	var tint := Color(color,opacity); var ink := Color(BLACK,opacity)
	match kind:
		"star": _cut(SHAPES.star(at,size,spin),tint,ink,Color(0,0,0,0),Vector2.ZERO,2)
		"heart": _cut(SHAPES.heart(at,size*.82,spin),tint,ink,Color(0,0,0,0),Vector2.ZERO,2)
		"bolt":
			var axis := Vector2.from_angle(spin+PI*.5)*size; var cross := axis.orthogonal()*.42
			_cut(PackedVector2Array([at-axis+cross*.3,at+cross,at+cross*.1,at+axis-cross*.3,at-cross,at-cross*.1]),tint,ink,Color(0,0,0,0),Vector2.ZERO,2)
		"bang","ask":
			var glyph := "!" if kind == "bang" else "?"
			var pixels := int(size*1.9)
			_set_frame(_current_frame*Transform2D(spin,at))
			_flush(); draw_string_outline(font,Vector2(-size*.3,size*.62),glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,5,ink)
			_flush(); draw_string(font,Vector2(-size*.3,size*.62),glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,tint)
			_set_frame(_current_frame)

func _pipa(center: Vector2, size: float, angle: float, color: Color, seed_value: int) -> void:
	var tail := PackedVector2Array()
	var bottom := center+Vector2(0,size*1.05).rotated(angle)
	for i in 8:
		var t := i/7.0
		tail.append(bottom+Vector2(sin(animation_time*2.1+t*5+seed_value)*12*t,t*size*2.6).rotated(angle*.5))
	_flush(); draw_polyline(tail,Color(PAPER,.8),2,true)
	for i in [2,4,6]:
		_fill(SHAPES.shard(tail[i]+Vector2(-7,0),tail[i]+Vector2(7,0),8),color)
	var shape := SHAPES.pipa(center,size,angle)
	_cut(shape,color,BLACK,Color(0,0,0,0),Vector2.ZERO,2)
	var top: Vector2 = shape[0]; var low: Vector2 = shape[2]
	_flush(); draw_line(top,low,BLACK,2,true); _flush(); draw_line(shape[1],shape[3],BLACK,2,true)

# ---- portraits ----

func _portrait(profile: Resource, rect: Rect2, color: Color, seed_value := 0) -> void:
	var shape := _torn(rect,seed_value,minf(rect.size.y*.14,8))
	_cut(shape,Color("202033"),color,BLACK,Vector2(4,5),2)
	var image: Texture2D = PORTRAITS.texture(profile)
	if image != null:
		var source: Rect2 = PORTRAITS.source_rect(profile,image.get_size(),rect.size)
		var uvs := PackedVector2Array()
		for point in shape:
			var inside: Vector2 = ((point-rect.position)/rect.size).clampf(0,1)
			uvs.append((source.position+inside*source.size)/image.get_size())
		_flush(); draw_colored_polygon(shape,Color.WHITE,uvs,image)
	else:
		# Deliberate placeholder for players whose portrait art has not arrived yet.
		var center := rect.position+rect.size*Vector2(.5,.35)
		_flush(); draw_circle(center,rect.size.x*.15,Color(color,.32))
		var shoulders := PackedVector2Array([
			rect.position+rect.size*Vector2(.18,.90),rect.position+rect.size*Vector2(.23,.65),
			rect.position+rect.size*Vector2(.40,.55),rect.position+rect.size*Vector2(.60,.55),
			rect.position+rect.size*Vector2(.77,.65),rect.position+rect.size*Vector2(.82,.90)])
		_fill(shoulders,Color(color,.22))
		centered(rect.position+rect.size*Vector2(.5,.88),"%02d" % profile.numero,14,PAPER)

# Whole transparent bust. Its flat lower edge must end up behind a panel.
func _bust(image: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	if image != null: _flush(); draw_texture_rect(image,rect,false,tint)

# ---- screen ----

func _draw() -> void:
	if game == null or font == null: return
	_compose()
	_flush()

func _compose() -> void:
	_current_frame = ui_transform
	_set_frame(ui_transform)
	if game.phase == "menu":
		_menu()
		if game.show_attributes: _attributes()
		return
	_scoreboard()
	if game.phase == "paused": _pause(); return
	if game.phase == "finished": _results(); return
	# The goal cut-in owns the screen; the card would only compete with it.
	if goal_team < 0: _footer(); _player_card(); _minimap()
	if game.live() or game.is_set_piece_taker(game.controlled): _aim_guide()
	_ball_contacts()
	_draw_reactions()
	if game.message_timer > 0 and game.phase != "celebrate": _toast()
	if game.phase == "restart": _countdown()
	if game.spectator: _shout_center(Vector2(720,226),"MODO TORCIDA  /  F2 PARA JOGAR",17,CYAN)
	if game.show_attributes: _attributes()
	if game.show_help: _help()
	if game.phase == "celebrate" and goal_team >= 0: _goal_overlay()

func _ball_contacts() -> void:
	if game.phase not in ["playing","foul","out","celebrate"]: return
	var inverse := ui_transform.affine_inverse()
	for event: Dictionary in game.juice.ball_fx.contacts:
		if game.camera.is_position_behind(event.position): continue
		var at: Vector2 = inverse*game.camera.unproject_position(event.position)
		if not _screen_rect().grow(24).has_point(at): continue
		var age: float = event.age; var progress: float = age/event.duration
		var opacity := minf(age/.012,1)*pow(1-clampf(progress,0,1),1.3)
		var strong: bool = event.kind in ["power","post","goal"]
		var inner: float = 8+progress*12
		var outer: float = inner+lerpf(9,24,event.strength)*(1-progress*.5)
		var color := GOLD if strong else CYAN
		var rays := 7 if strong else 5
		for i in rays:
			var angle: float = i*TAU/rays+.38+event.serial*.31+SHAPES.noise(event.serial,i)*.25
			var axis := Vector2.from_angle(angle)
			var reach: float = outer*(1+SHAPES.noise(event.serial,i+9)*.35)
			_fill(SHAPES.shard(at+axis*inner,at+axis*(reach+3),9),Color(BLACK,opacity))
			_fill(SHAPES.shard(at+axis*inner,at+axis*reach,5.5),Color(PAPER if i%2 == 0 else color,opacity))
		if strong: _symbol("star",at+Vector2(outer*.9,-outer*.8),6+6*event.strength,GOLD,opacity,age*5)

func _draw_reactions() -> void:
	if game.phase not in ["playing","foul","restart","out","set_piece"]: return
	var inverse := ui_transform.affine_inverse()
	for event: Dictionary in reactions:
		var world: Vector3 = event.origin
		if game.camera.is_position_behind(world): continue
		var target: Vector2 = inverse*game.camera.unproject_position(world)
		if not _screen_rect().grow(24).has_point(target): continue
		var age: float = event.age
		var opacity := minf(clampf(age/.06,0,1),clampf((event.duration-age)/.26,0,1))
		var arrival := clampf(age/.18,0,1)-1.0
		var pop := .5+.5*(1+2.70158*pow(arrival,3)+1.70158*pow(arrival,2))
		var at := reaction_screen_position(event)
		var color: Color = event.color
		var seed_value: int = event.serial%37+int(hash(event.kind))%50
		var tilt := (-.075 if event.serial%2 == 0 else .06)+sin(age*13)*.014*exp(-age*3)
		var frame := Transform2D(tilt,Vector2.ONE*pop,0,at)
		var label: String = event.text
		var font_size := 34
		var width := _ransom_width(label,font_size,seed_value,true)
		var half := Vector2(width*.5+26,36)
		var tip: Vector2 = frame.affine_inverse()*target
		# Boiling outline: redrawn a few times per second, like hand-cut animation frames.
		var boil := seed_value+int(age*7)%3
		_flush(); draw_circle(target,6,Color(BLACK,opacity)); _flush(); draw_circle(target,4,Color(color,opacity))
		_set_frame(ui_transform*frame); _current_frame = ui_transform*frame
		var shape: PackedVector2Array
		match event.shape:
			"burst":
				shape = _burst(Vector2.ZERO,half*1.32,maxi(11,int(width/14)),boil,.74)
				_bolt(tip,color,opacity)
			"balloon":
				var box := Rect2(-half*1.08,half*2.16)
				shape = _balloon(box,_tip_outside(tip,box),seed_value)
			_:
				shape = _torn(Rect2(-half,half*2),seed_value,11)
				_bolt(tip,color,opacity)
		_cut(shape,Color(BLACK,opacity),Color(PAPER,opacity),Color(color,opacity),Vector2(7,8),3)
		var flown := clampf((age-.06)/.3,0,1)
		for i in 3:
			var fly := Vector2(half.x*(1.08+.16*i)*(-1 if i == 1 else 1),half.y*(-1.3+i*.7))*(.7+.3*flown)
			_symbol(event.symbol,fly,11.0-i*2,color if i != 1 else PAPER,opacity*flown,sin(age*5+i)*.4)
		_ransom(Vector2(0,12+sin(age*10)*2*exp(-age*2)),label,font_size,seed_value,color,frame,opacity,true,true)
		if not event.detail.is_empty():
			var detail_width := body_font.get_string_size(event.detail,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			_fill(_torn(Rect2(-detail_width*.5-10,half.y-4,detail_width+20,22),seed_value,4),Color(BLACK,opacity))
			_flush(); draw_string(body_font,Vector2(-detail_width*.5,half.y+12),event.detail,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(color,opacity))
		_current_frame = ui_transform
		_set_frame(ui_transform)

# The balloon tail needs a tip outside its body even when the spot is right behind it.
func _tip_outside(tip: Vector2, box: Rect2) -> Vector2:
	var center := box.get_center()
	if not box.grow(14).has_point(tip): return tip
	var axis := (tip-center).normalized() if tip != center else Vector2.DOWN
	var reach := minf(absf((box.size.x*.5+26)/maxf(absf(axis.x),.01)),absf((box.size.y*.5+26)/maxf(absf(axis.y),.01)))
	return center+axis*reach

func _bolt(tip: Vector2, color: Color, opacity: float) -> void:
	var mid := tip*.55
	var kink := tip.orthogonal().normalized()*10
	var path := PackedVector2Array([Vector2.ZERO,mid+kink,mid-kink*.4,tip])
	_flush(); draw_polyline(path,Color(BLACK,opacity),7,true)
	_flush(); draw_polyline(path,Color(color,opacity),3,true)

func _scoreboard() -> void:
	# Logo.
	_cut(_torn(Rect2(14,16,258,84),75,11),BLACK,PAPER,PINK,Vector2(6,7),2)
	_ransom(Vector2(30,62),"VÁRZEA FC",29,12,PINK)
	_shout(Vector2(36,90),"TAÇA PRAÇA XV  /  RIO",14,CYAN,-.015)
	# Shards spray out of the score towards each team's side.
	for side in 2:
		var away := -1.0 if side == 0 else 1.0
		var color := CYAN if side == 0 else PINK
		for i in 3:
			var from := Vector2(720+away*140,58+i*14)
			_fill(SHAPES.shard(from,Vector2(720+away*(345-i*22),26+i*32),26-i*5),color)
	var plate := _torn(Rect2(478,18,484,84),7,13)
	_cut(plate,BLACK,PAPER,BLACK,Vector2(8,9),3)
	_flag(Rect2(494,42,58,36),game.team_definitions[0].id,3)
	_flag(Rect2(888,42,58,36),game.team_definitions[1].id,5)
	_shout(Vector2(564,76),game.team_short(0),27,CYAN)
	var right: String = game.team_short(1)
	_shout(Vector2(868-font.get_string_size(right,HORIZONTAL_ALIGNMENT_LEFT,-1,27).x,76),right,27,PINK)
	_fill(SHAPES.shard(Vector2(737,20),Vector2(703,104),12),PINK)
	_score_digit(Vector2(668,60),str(game.score[0]),CYAN,0)
	_score_digit(Vector2(772,60),str(game.score[1]),GOLD,1)
	var remaining := maxi(0,ceili(game.DURATION-game.elapsed))
	var urgent := remaining <= 30
	var clock := _torn(Rect2(650,104,140,38),11,8)
	if urgent: _fill(_burst(Vector2(720,123),Vector2(112,44)*(1+sin(animation_time*9)*.05),13,2,.72),PINK)
	_cut(clock,BLACK,CYAN if not urgent else PAPER,BLACK,Vector2(5,6),2)
	_pixel(Vector2(723,113),"%02d:%02d" % [remaining/60,remaining%60],2.8,GOLD if not urgent else PINK)
	# Top right speaks instead of sitting in another box.
	_cut(_balloon(Rect2(1180,18,240,74),Vector2(1128,104),21),BLACK,PAPER,BLACK,Vector2(5,6),2)
	_shout(Vector2(1224,50),"1P  VS  CPU",19,CYAN)
	text(Vector2(1224,74),"PRAÇA XV / RIO",14,PAPER)

func _score_digit(at: Vector2, value: String, color: Color, side: int) -> void:
	var pop: float = score_pop[side]
	var kick := 1.0+sin(pop*PI)*.55
	if pop < 1:
		_fill(_burst(at+Vector2(0,-4),Vector2(58,50)*kick,11,side+6,.6),Color(GOLD,1-pop))
	var size := int(60*kick)
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	_loud(at+Vector2(-width*.5,size*.36),value,size,color if pop >= 1 else PAPER,-.05 if side == 0 else .05)

func _menu() -> void:
	_flush(); draw_rect(_screen_rect(),Color(.05,.025,.09,.94))
	# Morning sun over the bay: uneven rays behind everything, then the skyline.
	var sun := Vector2(720,330)
	for i in 18:
		var width := .10+absf(SHAPES.noise(3,i))*.14
		var angle := i*TAU/18.0+animation_time*.018
		var a := sun+Vector2.from_angle(angle-width)*1300; var b := sun+Vector2.from_angle(angle+width)*1300
		_fill(PackedVector2Array([sun,a,b]),Color(PINK if i%2 == 0 else GOLD,.075))
	_fill(SHAPES.sugarloaf(Vector2(470,700),520,235),Color("1b1030"))
	_halftone(Rect2(-40,190,430,110),Color(CYAN,.13),19)
	_pipa(Vector2(1392,172)+Vector2(sin(animation_time*.8)*9,cos(animation_time*.6)*6),21,.4+sin(animation_time*1.1)*.09,GOLD,1)
	_pipa(Vector2(716,222)+Vector2(cos(animation_time*.7)*7,sin(animation_time)*5),17,-.35+sin(animation_time*1.4)*.1,CYAN,4)
	# Title, cut from magazines and stuck on a torn pink banner.
	_cut(_torn(Rect2(-90,48,688,148),6,24),PINK,BLACK,CYAN,Vector2(14,12),4)
	_ransom(Vector2(44,170),"VÁRZEA FC",96,12,GOLD)
	_cut(_torn(Rect2(40,16,304,36),13,8),BLACK,PAPER,BLACK,Vector2(4,5),2)
	_shout(Vector2(58,43),"TAÇA PRAÇA XV  /  RIO DE JANEIRO",15,CYAN)
	_cut(_balloon(Rect2(796,28,560,118),Vector2(664,142),9,16),PAPER,BLACK,PINK,Vector2(9,10),3)
	_loud(Vector2(840,86),"O SONHO COMEÇA NA VÁRZEA.",34,BLACK,-.015)
	_flush(); draw_string(font,Vector2(843,116),"DO CENTRO À PRAIA, A BOLA É DA GALERA.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,PINK)
	for side in 2: _team_panel(side)
	var bob := sin(animation_time*2.3)*4
	_fill(_burst(Vector2(726,462),Vector2(122,112),13,int(animation_time*6)%3+20,.62),BLACK)
	_cut(_burst(Vector2(720,452),Vector2(116,106),13,int(animation_time*6)%3+20,.62),PINK,PAPER,Color(0,0,0,0),Vector2.ZERO,3)
	_ransom(Vector2(720,474+bob),"VS",72,31,GOLD,Transform2D.IDENTITY,1.0,true)
	# Copacabana sidewalk along the bottom, then the start button on top of it.
	_calcadao(Rect2(0,770,1440,86))
	_action_button(button,GOLD if not button.is_hovered() else PAPER,PINK,17)
	_symbol("star",Vector2(474,742),20,CYAN,1,sin(animation_time*2)*.3)
	_symbol("star",Vector2(968,772),15,PINK,1,sin(animation_time*2+1)*.3)
	_cut(_torn(Rect2(46,736,400,58),77,10),BLACK,PAPER,CYAN,Vector2(6,7),2)
	_shout(Vector2(66,762),"5 CONTRA 5  /  3 MINUTOS",20,PAPER,-.015)
	text(Vector2(68,783),"ELENCOS FICTÍCIOS",13,CYAN)
	_cut(_torn(Rect2(994,736,400,58),79,10),BLACK,PAPER,PINK,Vector2(6,7),2)
	_shout(Vector2(1014,762),"ENTER PARA COMEÇAR",20,PAPER,.012)
	text(Vector2(1016,783),"VOCÊ CONTROLA "+game.team_label(0).to_upper(),13,PINK)
	_footer()

func _calcadao(rect: Rect2) -> void:
	var drift := animation_time*12
	_flush(); draw_rect(rect,BLACK)
	# Parallel bands in phase: the black-and-white sidewalk of Copacabana.
	for i in 5:
		var y := rect.position.y+6+i*19
		_flush(); draw_polyline(SHAPES.calcadao(Vector2(rect.position.x-40,y),rect.end.x+40,9,150,drift),PAPER,9.5,true)

func _team_panel(side: int) -> void:
	var left := 56.0+side*736.0
	var color := CYAN if side == 0 else PINK
	var team: Dictionary = game.team_definitions[side]
	var away := 1.0 if side == 0 else -1.0
	# The two panels lean into the VS: they share a clash, not a grid.
	var panel := _torn(Rect2(left,252,592,428),side+23,22)
	_cut(panel,Color(BLACK,.96),PAPER,color,Vector2(11,12),3)
	var anchor := left+(30.0 if side == 0 else 300.0)
	_cut(_torn(Rect2(anchor-8,238,206,44),side+41,9),color,BLACK,BLACK,Vector2(4,5),2)
	_loud(Vector2(anchor+14,271),"PLAYER 01" if side == 0 else "COMPUTADOR",25,BLACK,-.02)
	_flag(Rect2(left+(304.0 if side == 0 else 34.0),284,92,56),team.id,side+2)
	_ransom(Vector2(left+(412.0 if side == 0 else 138.0),334),game.team_short(side),48,side*7+40,color)
	# Selector plates sit under the native controls.
	for choice in [team_choices[side],kit_choices[side]]:
		var plate := _torn(Rect2(choice.position,choice.size),choice.get_instance_id()%90,7)
		var over: bool = choice.is_hovered()
		_cut(plate,color.darkened(.55) if over else Color("202033"),color if over else PAPER,BLACK,Vector2(4,5),2)
	# The squad stands together, heads over the top of the name strip.
	var start := left+(46.0 if side == 0 else 26.0)
	var strip := _torn(Rect2(left+6,596,580,78),side+55,11)
	for slot in [0,2,4,1,3]:
		var profile: Resource = game.roster_profiles[side*5+slot]
		var size := 164.0 if slot%2 == 1 else 150.0
		var x: float = start+slot*102.0
		var image: Texture2D = PORTRAITS.texture(profile)
		_fill(_burst(Vector2(x+56,520-(slot%2)*6),Vector2(60,58),9,slot+side*5,.68),Color(color,.20+.1*(slot%2)))
		if image != null: _bust(image,Rect2(x-size*.5+56,470-(size-150),size,size))
		else: _portrait(profile,Rect2(x+6,500,100,92),color,slot)
	_cut(strip,color,BLACK,BLACK,Vector2(5,6),3)
	for slot in 5:
		var profile: Resource = game.roster_profiles[side*5+slot]
		var x: float = start+slot*102.0+56
		var name_tilt := SHAPES.noise(side+2,slot)*.05
		_loud_center(Vector2(x,630),profile.nome.to_upper(),21,BLACK,name_tilt)
		_flush(); draw_string(font,Vector2(x-font.get_string_size(["GOL","ZAG","ALA E","ALA D","ATA"][slot],HORIZONTAL_ALIGNMENT_LEFT,-1,14).x*.5,654),["GOL","ZAG","ALA E","ALA D","ATA"][slot],HORIZONTAL_ALIGNMENT_LEFT,-1,14,BLACK)
	_symbol("star",Vector2(left+(574.0 if side == 0 else 18.0),260),16,GOLD,1,away*.3)

func _action_button(control: Button, color: Color, shadow: Color, seed_value: int) -> void:
	if not control.visible: return
	var rect := Rect2(control.position,control.size)
	var pulse := 1.0+sin(animation_time*3.4)*.012
	var shape := _torn(Rect2(rect.position-rect.size*(pulse-1)*.5,rect.size*pulse).grow(6),seed_value,12)
	if control.is_pressed(): color = CYAN
	_cut(shape,color,BLACK,shadow,Vector2(9,10),4)

func _footer() -> void:
	var edge := PackedVector2Array([Vector2(-400,900),Vector2(-400,862)])
	var x := -400.0; var i := 0
	while x < 1860:
		x += 58+SHAPES.noise(5,i)*30; i += 1
		edge.append(Vector2(x,856+SHAPES.noise(9,i)*7))
	edge.append(Vector2(1860,900))
	_fill(edge,BLACK)
	centered(Vector2(720,882),"WASD MOVER   SHIFT CORRER   E DRIBLE   ESQ. CHUTE / CARRINHO   DIR. PASSE / DESARME   SCROLL TROCAR   V CÂMERA   P PAUSA   M ÁUDIO   I ATRIBUTOS   F1 AJUDA",13,PAPER)
	if game.phase == "menu":
		var value := "BRASIL   /   ARGENTINA   /   ALEMANHA   /   FRANÇA   /   "
		var width := body_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		for n in 4: text(Vector2(n*width-fposmod(animation_time*35,width),899),value,11,Color(CYAN,.55))

func _player_card() -> void:
	var p = game.controlled
	if p == null: return
	var color := CYAN if p.team == 0 else PINK
	# The head breaks out of the card; the panel hides where the art ends.
	_fill(_burst(Vector2(112,692),Vector2(104,88),11,int(animation_time*5)%3+3,.66),color)
	var image: Texture2D = PORTRAITS.texture(p.profile)
	if image != null: _bust(image,Rect2(16,608,192,192))
	var panel := _torn(Rect2(24,734,368,104),3,13)
	_cut(panel,BLACK,PAPER,color,Vector2(8,9),3)
	if image == null: _portrait(p.profile,Rect2(50,650,100,92),color,4)
	_cut(_torn(Rect2(214,700,172,32),19,7),color,BLACK,BLACK,Vector2(4,5),2)
	_flush(); draw_string(font,Vector2(228,723),game.team_label(p.team).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,18,BLACK)
	_flag(Rect2(336,744,44,28),game.team_definitions[p.team].id,8)
	_cut(SHAPES.star(Vector2(190,690),25,.2),GOLD,BLACK,Color(0,0,0,0),Vector2.ZERO,3)
	var number := str(p.profile.numero)
	_flush(); draw_string(font,Vector2(190-font.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x*.5,698),number,HORIZONTAL_ALIGNMENT_LEFT,-1,20,BLACK)
	_loud(Vector2(44,778),p.profile.nome.to_upper(),34,PAPER,-.02)
	_shout(Vector2(46,801),p.profile.position_name().to_upper(),14,color)
	text(Vector2(190,800),p.BODIES.NAMES[p.body_type].to_upper()+" / "+("%.2f m" % p.profile.altura).replace(".",","),13,PAPER)
	var stamina_color := CYAN if p.stamina > .5 else (GOLD if p.stamina > .2 else PINK)
	var from := Vector2(92,826)
	text(Vector2(40,828),"FÔLEGO",11,MUTED)
	_fill(SHAPES.wedge(from,284,2,9),SLATE)
	if p.stamina > .01: _fill(SHAPES.wedge(from,284*p.stamina,2,lerpf(2,9,p.stamina)),stamina_color)
	if p.charging > 0: _charge_meter(p)
	else: _action_fan(p,color)

func _charge_meter(p) -> void:
	var style: String = p.shot_style(.3+p.charging/1.05*.7)
	var shot_label: String = {"weak":"FRACO","medium":"MÉDIO","strong":"FORTE"}[style]
	var shot_color: Color = {"weak":CYAN,"medium":GOLD,"strong":PINK}[style]
	var power: float = clampf(p.charging/1.05,0,1)
	var shake := Vector2(sin(animation_time*61),cos(animation_time*47))*(3.0 if style == "strong" else 0.0)
	var from := Vector2(500,808)+shake
	_cut(SHAPES.wedge(from,430,4,30),BLACK,PAPER,BLACK,Vector2(6,7),3)
	if power > .02:
		_fill(SHAPES.wedge(from,430*power,4,lerpf(4,30,power)),shot_color)
	if style == "strong":
		_fill(_burst(from+Vector2(430*power,-10),Vector2(50,44),10,int(animation_time*10)%3,.55),PAPER)
	_ransom(Vector2(500,764)+shake,shot_label+"!",38,hash(style)%40,shot_color)
	_shout(Vector2(690,762)+shake,"SOLTA!",24,PAPER,-.03)
	_pixel(Vector2(905,748)+shake,str(int(power*100)),2.4,GOLD)

# Context actions fan out of the player like a hand of cards.
func _action_fan(p,color: Color) -> void:
	var status := ""
	var actions: Array = []
	if game.phase == "out": status = "BOLA FORA / AGUARDE"
	elif game.phase == "foul": status = "FALTA / BOLA PARADA"
	elif game.phase == "restart": status = "PREPARANDO COBRANÇA"
	elif game.phase == "set_piece":
		if game.is_set_piece_taker(p) and not game.spectator: actions = [["esq","CHUTE"],["dir","PASSE"]]
		else: status = "COBRANÇA ADVERSÁRIA" if not game.spectator else "COBRANÇA AUTOMÁTICA"
	elif game.receiving_player == p: status = "RECEBENDO PASSE >>"
	elif p.goalkeeper != null and p.goalkeeper.holding: actions = [["esq","ARREMESSO"],["dir","REPOR"]]
	elif game.can_play_ball(p): actions = [["esq","CHUTE"],["dir","PASSE"],["E","DRIBLE"]]
	else: actions = [["esq","CARRINHO"],["dir","DESARME"],["mid","TROCAR"]]
	if not status.is_empty():
		var width := font.get_string_size(status,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x+46
		_cut(_balloon(Rect2(452,772,width,52),Vector2(408,800),hash(status)%30),BLACK,PAPER,color,Vector2(6,7),2)
		_shout(Vector2(475,806),status,21,PAPER)
		return
	var hub := Vector2(286,812)
	var count := actions.size()
	for i in count:
		var angle := lerpf(-.46,.02,float(i)/maxf(count-1,1))
		var frame := Transform2D(angle,hub)
		_set_frame(ui_transform*frame); _current_frame = ui_transform*frame
		var length := font.get_string_size(actions[i][1],HORIZONTAL_ALIGNMENT_LEFT,-1,23).x+64
		var reach := 128.0+i*14.0
		_cut(_torn(Rect2(reach,-18,length,36),i+27,6),BLACK,PAPER,color,Vector2(5,6),2)
		_input_glyph(actions[i][0],Vector2(reach+22,0))
		_flush(); draw_string(font,Vector2(reach+42,9),actions[i][1],HORIZONTAL_ALIGNMENT_LEFT,-1,23,PAPER)
		_current_frame = ui_transform
		_set_frame(ui_transform)

func _input_glyph(kind: String, at: Vector2) -> void:
	if kind in ["esq","dir","mid"]:
		var mouse := PackedVector2Array()
		for i in 14: mouse.append(at+Vector2(cos(i*TAU/14)*10,sin(i*TAU/14)*13))
		_fill(mouse,PAPER)
		var half := PackedVector2Array([at+Vector2(0,-13),at+Vector2(-10,-5),at+Vector2(-9,-1),at+Vector2(0,-1)])
		if kind == "dir": half = PackedVector2Array([at+Vector2(0,-13),at+Vector2(10,-5),at+Vector2(9,-1),at+Vector2(0,-1)])
		if kind == "mid": half = PackedVector2Array([at+Vector2(-3,-11),at+Vector2(3,-11),at+Vector2(3,-3),at+Vector2(-3,-3)])
		_fill(half,PINK)
	else:
		_flush(); draw_circle(at,13,PAPER)
		_flush(); draw_string(font,at+Vector2(-font.get_string_size(kind,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x*.5,7),kind,HORIZONTAL_ALIGNMENT_LEFT,-1,20,BLACK)

func _attributes() -> void:
	var player = game.controlled
	if player == null: return
	var image: Texture2D = PORTRAITS.texture(player.profile)
	var panel := _torn(Rect2(1022,170,392,478),33,20)
	_cut(panel,BLACK,PAPER,PINK,Vector2(-10,11),3)
	# The head leans over the panel; the rule below hides where the art ends.
	if image != null:
		_fill(_burst(Vector2(1316,190),Vector2(106,92),11,int(animation_time*5)%3+14,.66),GOLD)
		_bust(image,Rect2(1226,94,170,170))
	else: _portrait(player.profile,Rect2(1270,150,110,110),GOLD,5)
	_fill(PackedVector2Array([Vector2(1016,270),Vector2(1420,258),Vector2(1420,266),Vector2(1016,274)]),PAPER)
	_cut(_torn(Rect2(1040,150,200,32),37,7),CYAN,BLACK,BLACK,Vector2(4,5),2)
	_flush(); draw_string(font,Vector2(1054,173),"FICHA / I FECHAR",HORIZONTAL_ALIGNMENT_LEFT,-1,18,BLACK)
	_ransom(Vector2(1046,232),player.profile.nome.to_upper(),40,hash(player.profile.nome)%60,GOLD)
	_shout(Vector2(1048,256),player.profile.position_name().to_upper()+" / "+game.team_short(player.team),15,GOLD)
	for index in player.profile.ATTRIBUTE_KEYS.size():
		var key: String = player.profile.ATTRIBUTE_KEYS[index]
		var value: int = player.get(key)
		# Rows step sideways like a staircase instead of stacking in a column.
		var y: int = 304+index*46
		var x: int = 1040+(index%2)*10
		_shout(Vector2(x,y),player.profile.ATTRIBUTE_NAMES[index].to_upper(),15,PAPER)
		var from := Vector2(x+96,y+2)
		_fill(SHAPES.wedge(from,182,2,11),SLATE)
		_fill(SHAPES.wedge(from,182*value/99.0,2,lerpf(2,11,value/99.0)),CYAN if value < 85 else GOLD)
		_loud(Vector2(x+296,y+4),str(value),24,GOLD if value >= 85 else PAPER,-.04)
	_shout(Vector2(1040,632),"REFLEXOS AFETAM O GOLEIRO",14,MUTED)

func _minimap() -> void:
	_cut(_torn(Rect2(1160,686,250,142),43,12),BLACK,PAPER,PINK,Vector2(-7,8),3)
	var origin := Vector2(1181,709)
	_flush(); draw_rect(Rect2(origin,Vector2(206,100)),Color("39394e"),false,1)
	_flush(); draw_line(origin+Vector2(103,0),origin+Vector2(103,100),Color("5b5b71"),1)
	_flush(); draw_arc(origin+Vector2(103,50),16,0,TAU,28,Color("5b5b71"),1)
	for p in game.players:
		var at: Vector2 = origin+Vector2((p.position.x+24)/48*206,(p.position.z+14)/28*100)
		_fill(SHAPES.pipa(at,6.5),CYAN if p.team == 0 else PINK)
		if p == game.controlled: _flush(); draw_arc(at,10,0,TAU,16,PAPER,2,true)
	var ball_at: Vector2 = origin+Vector2((game.ball.position.x+24)/48*206,(game.ball.position.z+14)/28*100)
	_fill(SHAPES.star(ball_at,7,animation_time*2),GOLD)

func _toast() -> void:
	var width := clampf(font.get_string_size(game.message,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x+90,340,1000)
	var slide := -45*exp(-message_age*9)
	_cut(_balloon(Rect2(720-width*.5+slide,158,width,58),Vector2(720-width*.28+slide,238),17),BLACK,PAPER,PINK,Vector2(6,7),2)
	_shout_center(Vector2(720+slide,196),game.message,23,PAPER)

func _countdown() -> void:
	var seconds := str(maxi(1,ceili(game.phase_timer)))
	var beat := fposmod(game.phase_timer,1.0)
	var kick := 1.0+pow(beat,3)*.3
	var at := Vector2(700,440)
	_cut(_burst(at+Vector2(10,-44),Vector2(116,112)*kick,12,int(game.phase_timer)+3,.66),BLACK,PAPER,PINK,Vector2(9,10),3)
	_loud_center(at+Vector2(8,22),seconds,int(136*kick),PAPER,-.07)
	var word := "VALENDO!" if game.restart_is_kickoff else "PREPARA!"
	_cut(_torn(Rect2(at+Vector2(58,14),Vector2(_ransom_width(word,40,41)+24,62)),81,9),BLACK,PAPER,GOLD,Vector2(6,7),2)
	_ransom(at+Vector2(70,62),word,40,41,GOLD)

func _dim() -> void:
	_flush(); draw_rect(_screen_rect(),Color(.04,.02,.08,.82))
	for i in 10:
		var angle := i*TAU/10.0+.2+animation_time*.02
		var center := Vector2(720,450)
		_fill(PackedVector2Array([center,center+Vector2.from_angle(angle-.09)*1200,center+Vector2.from_angle(angle+.09)*1200]),Color(PINK,.05))

func _pause() -> void:
	_dim()
	var p = game.controlled
	var image: Texture2D = PORTRAITS.texture(p.profile) if p != null else null
	_cut(_torn(Rect2(365,212,720,540),47,30),BLACK,PAPER,PINK,Vector2(14,14),4)
	if image != null:
		_fill(_burst(Vector2(300,500),Vector2(230,240),13,int(animation_time*5)%3+8,.68),CYAN)
		_bust(image,Rect2(92,262,420,420))
		_cut(_torn(Rect2(40,640,430,120),49,20),BLACK,PAPER,CYAN,Vector2(8,9),3)
		_loud(Vector2(84,708),p.profile.nome.to_upper(),52,PAPER,-.02)
		_shout(Vector2(88,738),p.profile.position_name().to_upper()+"  /  "+game.team_label(p.team).to_upper(),17,CYAN)
	_ransom(Vector2(760,304),"PAUSA NA RESENHA",54,62,PINK,Transform2D.IDENTITY,1.0,true)
	_cut(_balloon(Rect2(500,342,540,92),Vector2(390,440),29),PAPER,BLACK,CYAN,Vector2(6,7),3)
	_loud_center(Vector2(770,400),"RESPIRA. O CLÁSSICO CONTINUA.",29,BLACK,-.01)
	_shout_center(Vector2(765,484),"P / ESC  CONTINUAR     R  RECOMEÇAR",20,PAPER)
	_shout_center(Vector2(765,524),"V  CÂMERA     M  ÁUDIO     F1  AJUDA",17,MUTED)
	_action_button(button,GOLD if not button.is_hovered() else PAPER,PINK,51)
	_action_button(change_button,CYAN if not change_button.is_hovered() else PAPER,BLACK,53)

func _results() -> void:
	_dim()
	var winner_side := 0 if game.score[0] > game.score[1] else (1 if game.score[1] > game.score[0] else -1)
	for side in 2:
		var hero = game.top_scorer(side)
		var image: Texture2D = PORTRAITS.celebration(hero.profile)
		var won: bool = side == winner_side or winner_side < 0
		var x := -30.0 if side == 0 else 900.0
		_fill(_burst(Vector2(x+285,470),Vector2(290,330),15,side+int(animation_time*4)%3,.7),Color(CYAN if side == 0 else PINK,.9 if won else .25))
		# The side that lost stays on the pitch as a silhouette, waiting for the rematch.
		_bust(image,Rect2(x,240,570,570),Color.WHITE if won else Color(.2,.14,.28))
		_cut(_torn(Rect2(x-20,770,620,90),side+57,16),BLACK,PAPER,Color(0,0,0,0),Vector2.ZERO,3)
		_loud_center(Vector2(x+285,828),hero.profile.nome.to_upper(),42,GOLD if won else MUTED,-.02)
	_cut(_torn(Rect2(370,132,700,650),59,34),BLACK,PAPER,PINK,Vector2(14,14),4)
	_ransom(Vector2(720,222),"APITO FINAL!",64,18,PINK,Transform2D.IDENTITY,1.0,true)
	var winner: String = "DEU "+game.team_short(0)+"!" if game.score[0] > game.score[1] else ("DEU "+game.team_short(1)+"!" if game.score[1] > game.score[0] else "EMPATOU!")
	_loud_center(Vector2(720,298),winner,52,GOLD,-.035)
	_flag(Rect2(432,328,96,60),game.team_definitions[0].id,3)
	_flag(Rect2(912,328,96,60),game.team_definitions[1].id,5)
	_pixel(Vector2(642,322),str(game.score[0]),7,PAPER); _pixel(Vector2(798,322),str(game.score[1]),7,PAPER)
	_fill(SHAPES.shard(Vector2(742,316),Vector2(698,392),14),PINK)
	_shout_center(Vector2(480,420),game.team_label(0).to_upper(),18,CYAN)
	_shout_center(Vector2(960,420),game.team_label(1).to_upper(),18,PINK)
	for index in 3:
		var key: String = ["shots","passes","tackles"][index]
		var y := 476+index*62
		var left_value: int = game.stats[key][0]; var right_value: int = game.stats[key][1]
		var total := maxf(left_value+right_value,1)
		_shout_center(Vector2(720,y-14),["CHUTES","PASSES","DESARMES"][index],19,PAPER)
		# Two wedges meet at the middle: whoever had more pushes further into the other.
		_fill(SHAPES.shard(Vector2(420,y+6),Vector2(420+600*left_value/total,y+6),24),CYAN)
		_fill(SHAPES.shard(Vector2(1020,y+6),Vector2(1020-600*right_value/total,y+6),24),PINK)
		_loud(Vector2(396,y+16),str(left_value),28,CYAN,-.03)
		_loud(Vector2(1022,y+16),str(right_value),28,PINK,-.03)
	_shout_center(Vector2(720,672),"O PRÓXIMO CLÁSSICO JÁ TEM HORA MARCADA.",16,MUTED)
	_action_button(button,GOLD if not button.is_hovered() else PAPER,PINK,61)
	_action_button(change_button,CYAN if not change_button.is_hovered() else PAPER,BLACK,63)

func _help() -> void:
	_dim()
	_cut(_torn(Rect2(300,208,840,470),67,28),BLACK,PAPER,CYAN,Vector2(12,13),4)
	_ransom(Vector2(720,290),"MANUAL DO CRAQUE",48,28,GOLD,Transform2D.IDENTITY,1.0,true)
	var lines := ["APONTE O MOUSE: CHUTE E PASSE SEGUEM A MIRA.","ESQUERDO: SEGURE PARA CHUTAR / SEM BOLA, CARRINHO.","DIREITO: PASSE / DESARME. SCROLL: TROCAR JOGADOR.","WASD: MOVER. SHIFT: CORRER. SOLTE PARA RECUPERAR FÔLEGO.","E + DIREÇÃO LATERAL: CORTE COM A BOLA. GASTA FÔLEGO."]
	for i in lines.size():
		_shout_center(Vector2(720+(-16 if i%2 == 0 else 16),352+i*46),lines[i],20,PAPER if i%2 == 0 else CYAN)
	_shout_center(Vector2(720,632),"I ATRIBUTOS   /   F1 FECHAR   /   F2 TORCIDA   /   M ÁUDIO   /   R RECOMEÇAR",16,GOLD)

func goal_letter_offset(index: int) -> Vector2:
	var local := goal_age-index*.075
	var arrival := clampf(local/.40,0,1)
	var y := 190*pow(1-arrival,3)+sin(local*9)*exp(-maxf(local,0)*2.4)*17
	return Vector2(0,y)

func _goal_overlay() -> void:
	var age := goal_age
	var exit_alpha := clampf((game.GOAL_DURATION-age)/.35,0,1)
	var color := CYAN if goal_team == 0 else PINK
	var from_left := goal_team == 0
	_flush(); draw_rect(_screen_rect(),Color(BLACK,.32*exit_alpha))
	# One impact wash, then flowing rays and confetti; no repeating strobe.
	if age < .22: _flush(); draw_rect(_screen_rect(),Color(PAPER,.34*(1-age/.22)))
	var center := Vector2(720,420)
	for i in 22:
		var angle := i*TAU/22.0+age*.05
		var spread := .05+absf(SHAPES.noise(8,i))*.08
		_fill(PackedVector2Array([center+Vector2.from_angle(angle)*(160+age*20),center+Vector2.from_angle(angle-spread)*1100,center+Vector2.from_angle(angle+spread)*1100]),Color(color if i%2 == 0 else GOLD,.20*exit_alpha))
	var entry := clampf(age/.27,0,1)
	var slide := -1600*pow(1-entry,3)*(1 if from_left else -1)
	var band := _torn(Rect2(-160,300,1760,236),5,34)
	_set_frame(ui_transform*Transform2D(-.035,Vector2(slide,0)))
	_cut(band,Color(BLACK,.97*exit_alpha),Color(PAPER,exit_alpha),Color(color,exit_alpha),Vector2(0,16),5)
	_set_frame(ui_transform)
	var scorer = game.last_goal_scorer
	var profile: Resource = scorer.profile if scorer != null else null
	var art: Texture2D = PORTRAITS.celebration(profile) if profile != null else null
	# The scorer jumps in from their own side with a little overshoot, over the band.
	var pose := clampf((age-.1)/.3,0,1)-1.0
	var overshoot := 1+2.70158*pow(pose,3)+1.70158*pow(pose,2)
	var art_x := lerpf(-720.0,-30.0,overshoot) if from_left else lerpf(1480.0,790.0,overshoot)
	if art != null:
		_bust(art,Rect2(art_x+(50 if from_left else -50),110,680,680),Color(color,.5*exit_alpha))
		_bust(art,Rect2(art_x,120,680,680),Color(1,1,1,exit_alpha))
	var plate_x := art_x-20
	_cut(_torn(Rect2(plate_x,690,720,128),71,22),Color(BLACK,exit_alpha),Color(PAPER,exit_alpha),Color(color,exit_alpha),Vector2(8,10),3)
	if profile != null:
		_ransom(Vector2(plate_x+64,768),profile.nome.to_upper(),58,hash(profile.nome)%40,color,Transform2D.IDENTITY,exit_alpha)
	_flag(Rect2(plate_x+560,716,84,52),game.team_definitions[goal_team].id,6)
	_shout(Vector2(plate_x+68,804),game.team_label(goal_team).to_upper(),18,color)
	# The score travels on the plate, under the name of who changed it.
	_pixel(Vector2(plate_x+404,722),str(game.score[0]),6,Color(PAPER,exit_alpha))
	_pixel(Vector2(plate_x+520,722),str(game.score[1]),6,Color(GOLD,exit_alpha))
	_fill(SHAPES.shard(Vector2(plate_x+472,712),Vector2(plate_x+446,778),11),Color(PINK,exit_alpha))
	var value := "GOOOL!"
	var size := 158
	var word_center := 930.0 if from_left else 510.0
	var word_width := 0.0
	for i in value.length(): word_width += font.get_string_size(value.substr(i,1),HORIZONTAL_ALIGNMENT_LEFT,-1,size).x+8
	var x := word_center-word_width*.5
	for i in value.length():
		var local := age-i*.075
		var letter := value.substr(i,1)
		var width := font.get_string_size(letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		if local >= 0:
			var bounce := goal_letter_offset(i)
			var style: int = [0,1,2,1,0,2][i]
			_letter(Vector2(x,486)+bounce,letter,size,style,GOLD if i%2 == 0 else color,sin(local*5+i)*.05+SHAPES.noise(3,i)*.06,i*3,Transform2D.IDENTITY,exit_alpha)
		x += width+8
	if age > .40:
		var rise := 30*exp(-(age-.4)*8)
		var box := Rect2(word_center-250,150+rise,500,92)
		var tip := Vector2(word_center+(-300 if from_left else 300),300+rise)
		_cut(_balloon(box,tip,13),Color(PAPER,exit_alpha),Color(BLACK,exit_alpha),Color(GOLD,exit_alpha),Vector2(7,8),3)
		var who: String = profile.nome.to_upper()+" BALANÇOU A REDE!" if profile != null else "A REDE BALANÇOU!"
		_flush(); draw_string(font,Vector2(word_center-font.get_string_size(who,HORIZONTAL_ALIGNMENT_LEFT,-1,29).x*.5,206+rise),who,HORIZONTAL_ALIGNMENT_LEFT,-1,29,Color(BLACK,exit_alpha))
	for i in 42:
		var phase := fmod(i*.618,1.0)
		var t := age*.6+phase
		var at := Vector2(fposmod(i*143.7+sin(i)*age*42,1440),fposmod(t*t*235+i*31,1100)-100)
		var tint := Color([PINK,CYAN,GOLD,PAPER][i%4],exit_alpha)
		_fill(confetti_shapes[i%4],tint,Transform2D(age*1.7+i,at))

func _aim_guide() -> void:
	var p = game.controlled
	if p == null or game.spectator or not game.can_play_ball(p): return
	var target: Vector3 = game.mouse_aim(p)
	var direction: Vector3 = target-game.ball.position; direction.y = 0
	if direction.length() < .1: return
	direction = direction.normalized()
	var inverse := ui_transform.affine_inverse()
	var start: Vector2 = inverse*game.camera.unproject_position(game.ball.position+Vector3.UP*.12)
	var end: Vector2 = inverse*game.camera.unproject_position(game.ball.position+direction*2.5+Vector3.UP*.12)
	var axis := (end-start).normalized(); var perpendicular := Vector2(-axis.y,axis.x)
	# A blade that sharpens towards the ball's future direction, then a cut arrowhead.
	_fill(SHAPES.shard(end-axis*6,start+axis*12,7),Color(BLACK,.75))
	_fill(SHAPES.shard(end-axis*6,start+axis*12,4),CYAN)
	_cut(PackedVector2Array([end+axis*5,end-axis*11+perpendicular*8,end-axis*6,end-axis*11-perpendicular*8]),CYAN,BLACK,Color(0,0,0,0),Vector2.ZERO,1.5)
	var mouse: Vector2 = inverse*get_viewport().get_mouse_position()
	for i in 4:
		var spoke := Vector2.from_angle(i*TAU/4+animation_time*1.1)
		_fill(SHAPES.shard(mouse+spoke*15,mouse+spoke*6,6),CYAN)
	_flush(); draw_arc(mouse,8,0,TAU,24,PAPER,1.5,true)
