extends Control
## Original arcade / cut-paper presentation. All effects stay in CanvasItem space.
const FLAGS = preload("res://scripts/ui_flags.gd")
const DESIGN := Vector2(1440,900)
const BLACK := Color("10101c")
const PAPER := Color("fff6e7")
const PINK := Color("ff287e")
const CYAN := Color("35edf0")
const GOLD := Color("ffe049")
const MUTED := Color("b6b7cd")
const REACTIONS := {
	"slide":{"text":"NA BOLA!","color":CYAN,"duration":1.25},
	"steal":{"text":"É NOSSA!","color":CYAN,"duration":1.15},
	"woodwork":{"text":"NA TRAVEEE!","color":GOLD,"duration":1.6},
	"save":{"text":"MILAGRE!","color":GOLD,"duration":1.4},
	"power":{"text":"WOOOOW!","color":PINK,"duration":1.1},
	"foul":{"text":"FOI MAL!","color":PINK,"duration":1.45},
	"throw_in":{"text":"SAIU!","color":CYAN,"duration":1.3},
	"corner":{"text":"NO CANTO!","color":GOLD,"duration":1.3},
	"goal_kick":{"text":"PRA FORA!","color":CYAN,"duration":1.3},
	"drop":{"text":"OPA!","color":PAPER,"duration":1.25}}
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

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body_font = ThemeDB.fallback_font
	# Resolve installed typefaces; no proprietary font files are redistributed.
	var display := SystemFont.new()
	display.font_names = PackedStringArray(["Impact","Arial Black","DejaVu Sans"])
	display.font_weight = 900
	font = display
	ui_root = Control.new(); ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(ui_root)
	button = Button.new(); _button_skin(button,GOLD,24)
	button.pressed.connect(func():
		if game.phase == "paused": game.toggle_pause()
		else: game.new_match())
	ui_root.add_child(button)
	change_button = Button.new(); change_button.text = "TROCAR SELEÇÕES / UNIFORMES"
	_button_skin(change_button,CYAN,18)
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

func _box(color: Color, border := PAPER, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = color
	style.border_color = border; style.set_border_width_all(width)
	style.content_margin_left = 18; style.content_margin_right = 18
	style.content_margin_top = 8; style.content_margin_bottom = 8
	return style

func _button_skin(control: Button, color: Color, size: int) -> void:
	control.add_theme_font_override("font",font)
	control.add_theme_font_size_override("font_size",size)
	control.add_theme_stylebox_override("normal",_box(color,BLACK,3))
	control.add_theme_stylebox_override("hover",_box(PAPER,color,3))
	control.add_theme_stylebox_override("pressed",_box(CYAN,BLACK,3))
	control.add_theme_stylebox_override("focus",_box(Color(0,0,0,0),PINK,3))
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: control.add_theme_color_override(key,BLACK)
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _selector_skin(control: OptionButton, color: Color) -> void:
	control.add_theme_font_override("font",body_font)
	control.add_theme_font_size_override("font_size",21)
	control.add_theme_constant_override("icon_max_width",42)
	control.add_theme_constant_override("h_separation",14)
	control.add_theme_stylebox_override("normal",_box(Color("202033"),PAPER,2))
	control.add_theme_stylebox_override("hover",_box(Color("30304b"),color,3))
	control.add_theme_stylebox_override("pressed",_box(Color("30304b"),color,3))
	control.add_theme_stylebox_override("focus",_box(Color(0,0,0,0),color,3))
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: control.add_theme_color_override(key,PAPER)
	var popup := control.get_popup()
	popup.add_theme_font_override("font",body_font); popup.add_theme_font_size_override("font_size",21)
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
	at += Vector2(34,-28-event.age*20)
	at.x = clampf(at.x,155,1285); at.y = clampf(at.y,191,748)
	if at.y > 649 and (at.x < 410 or at.x > 1080): at.y = 649
	return at

func _layout() -> void:
	var view := get_viewport_rect().size
	var scale_factor := minf(view.x/DESIGN.x,view.y/DESIGN.y)
	var offset := (view-DESIGN*scale_factor)*.5
	ui_transform = Transform2D(0,Vector2.ONE*scale_factor,0,offset)
	ui_root.position = offset; ui_root.scale = Vector2.ONE*scale_factor
	for side in team_choices.size():
		var left := 112.0+side*724.0
		team_choices[side].visible = game.phase == "menu"; kit_choices[side].visible = game.phase == "menu"
		team_choices[side].position = Vector2(left,448); team_choices[side].size = Vector2(488,54)
		kit_choices[side].position = Vector2(left,516); kit_choices[side].size = Vector2(488,46)
	button.visible = game.phase in ["menu","paused","finished"]
	change_button.visible = game.phase in ["paused","finished"]
	button.size = Vector2(456,64); change_button.size = Vector2(440,42)
	button.position = Vector2(492,710)
	if game.phase == "paused":
		button.position.y = 596; button.text = "CONTINUAR  >>"
	elif game.phase == "finished":
		button.position.y = 688; button.text = "MAIS UMA PARTIDA  >>"
	else: button.text = "ENTRAR EM CAMPO  >>"
	change_button.position = Vector2(500,675 if game.phase == "paused" else 765)

func text(at: Vector2, value: String, size := 18, color := PAPER) -> void:
	draw_string(body_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func centered(at: Vector2, value: String, size := 18, color := PAPER) -> void:
	text(at-Vector2(body_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5,0),value,size,color)

func _slash(rect: Rect2, color: Color, cut := 16.0, edge := BLACK, width := 3.0) -> void:
	var p := rect.position; var s := rect.size
	var points := PackedVector2Array([p+Vector2(cut,0),p+Vector2(s.x,0),p+Vector2(s.x-cut,s.y),p+Vector2(0,s.y)])
	draw_colored_polygon(points,color)
	points.append(points[0]); draw_polyline(points,edge,width,true)

func _sticker(rect: Rect2, color: Color, cut := 16.0) -> void:
	_slash(Rect2(rect.position+Vector2(7,8),rect.size),BLACK,cut,BLACK,4)
	_slash(rect,color,cut,PAPER,2)

func _loud(at: Vector2, value: String, size: int, color := PAPER, angle := 0.0) -> void:
	draw_set_transform_matrix(ui_transform*Transform2D(angle,at))
	if color == BLACK:
		draw_string(font,Vector2.ZERO,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,BLACK)
		draw_set_transform_matrix(ui_transform); return
	draw_string_outline(font,Vector2(6,7),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,7,BLACK)
	draw_string(font,Vector2(5,5),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,PINK)
	draw_string_outline(font,Vector2.ZERO,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,6,BLACK)
	draw_string(font,Vector2.ZERO,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
	draw_set_transform_matrix(ui_transform)

func _loud_center(at: Vector2, value: String, size: int, color := PAPER, angle := 0.0) -> void:
	_loud(at-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5,0),value,size,color,angle)

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
						draw_rect(Rect2(rect.position+Vector2(2,3),rect.size),PINK.darkened(.4))
						draw_rect(rect,color)
		x += scale_factor*6

func _flag(rect: Rect2, id: String) -> void:
	draw_rect(Rect2(rect.position+Vector2(3,4),rect.size),BLACK)
	draw_texture_rect(FLAGS.texture(id),rect,false)
	draw_rect(rect,PAPER,false,2)

func _halftone(rect: Rect2, color: Color, step := 20) -> void:
	for y in range(int(rect.position.y),int(rect.end.y),step):
		for x in range(int(rect.position.x),int(rect.end.x),step):
			draw_circle(Vector2(x,y),1.5,color)

func _screen_rect() -> Rect2:
	return Rect2(-ui_transform.origin/ui_root.scale,get_viewport_rect().size/ui_root.scale)

func _draw() -> void:
	if game == null or font == null: return
	draw_set_transform_matrix(ui_transform)
	if game.phase == "menu": _menu(); return
	_scoreboard()
	if game.phase == "paused": _pause(); return
	if game.phase == "finished": _results(); return
	_player_card(); _minimap(); _footer()
	if game.live() or game.is_set_piece_taker(game.controlled): _aim_guide()
	_ball_contacts()
	_draw_reactions()
	if game.message_timer > 0 and game.phase != "celebrate": _toast()
	if game.phase == "restart":
		_wave(Vector2(720,472),str(maxi(1,ceili(game.phase_timer))),100,GOLD,5)
	if game.spectator: centered(Vector2(720,226),"MODO TORCIDA  /  F2 PARA JOGAR",15,CYAN)
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
		var inner: float = 7+progress*8
		var outer: float = inner+lerpf(4,9,event.strength)*(1-progress*.5)
		var color := GOLD if event.kind in ["power","post","goal"] else CYAN
		var rays := 6 if event.kind in ["power","post","goal"] else 4
		for i in rays:
			var angle: float = i*TAU/rays+.38+event.serial*.31
			var axis := Vector2.from_angle(angle)
			draw_line(at+axis*inner,at+axis*outer,Color(BLACK,opacity),4,true)
			draw_line(at+axis*inner,at+axis*outer,Color(PAPER if i%2 == 0 else color,opacity),2,true)

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
		# A short pointer identifies the actual world spot, not the player after moving.
		draw_line(target,at+Vector2(-18,18),Color(BLACK,opacity),6,true)
		draw_line(target,at+Vector2(-18,18),Color(color,opacity),2,true)
		draw_circle(target,4,Color(color,opacity))
		var tilt := (-.065 if event.serial%2 == 0 else .05)+sin(age*13)*.012*exp(-age*3)
		draw_set_transform_matrix(ui_transform*Transform2D(tilt,Vector2.ONE*pop,0,at))
		var label: String = event.text
		var font_size := 33
		var text_width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var width := text_width+42
		var height := 66.0 if not event.detail.is_empty() else 51.0
		_slash(Rect2(-width*.5+5,-23,width,height),Color(color,opacity),12,Color(BLACK,opacity),3)
		_slash(Rect2(-width*.5,-29,width,height),Color(BLACK,opacity),12,Color(PAPER,opacity),2)
		_slash(Rect2(-width*.5+14,-34,width*.38,8),Color(color,opacity),3,Color(BLACK,opacity),1)
		for side in [-1,1]:
			draw_line(Vector2(side*(width*.5+5),-22),Vector2(side*(width*.5+15),-36),Color(color,opacity),4,true)
		var baseline := Vector2(-text_width*.5,9+sin(age*10)*2*exp(-age*2))
		draw_string_outline(font,baseline+Vector2(3,3),label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,5,Color(PINK,opacity))
		draw_string_outline(font,baseline,label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,4,Color(BLACK,opacity))
		draw_string(font,baseline,label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(GOLD if event.kind in ["woodwork","save"] else PAPER,opacity))
		if not event.detail.is_empty():
			var detail_width := body_font.get_string_size(event.detail,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
			draw_string(body_font,Vector2(-detail_width*.5,29),event.detail,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(color,opacity))
		draw_set_transform_matrix(ui_transform)

func _scoreboard() -> void:
	_sticker(Rect2(25,23,235,70),BLACK,13)
	_loud(Vector2(42,65),"VÁRZEA FC",32,GOLD,-.035)
	text(Vector2(46,84),"ARCADE FUTEBOL / 5V5",10,CYAN)
	_slash(Rect2(450,25,540,85),PINK,18)
	_slash(Rect2(457,21,526,80),BLACK,16,PAPER,2)
	_flag(Rect2(479,45,54,34),game.team_definitions[0].id)
	_flag(Rect2(905,45,54,34),game.team_definitions[1].id)
	_loud(Vector2(547,78),game.team_short(0),29,CYAN)
	_loud(Vector2(822,78),game.team_short(1),29,PAPER)
	_pixel(Vector2(669,43),str(game.score[0]),5,PAPER)
	_pixel(Vector2(767,43),str(game.score[1]),5,GOLD)
	draw_line(Vector2(722,42),Vector2(709,80),PINK,4,true)
	_slash(Rect2(645,109,150,41),BLACK,10,CYAN,2)
	var remaining := maxi(0,ceili(game.DURATION-game.elapsed))
	_pixel(Vector2(723,119),"%02d:%02d" % [remaining/60,remaining%60],2.8,GOLD if remaining > 30 else PINK)
	_slash(Rect2(1155,25,257,70),BLACK,12)
	text(Vector2(1170,48),"1P  VS  CPU",15,CYAN)
	text(Vector2(1170,72),"PRAÇA XV / RIO",15,PAPER)
	draw_line(Vector2(1170,83),Vector2(1400,83),PINK,3)

func _menu() -> void:
	draw_rect(_screen_rect(),Color(.035,.025,.085,.89))
	# Offset paper cuts, moving diagonal dashes and a restrained halftone backdrop.
	_slash(Rect2(-120,32,690,195),PINK,75,BLACK,5)
	_slash(Rect2(930,90,630,86),CYAN,55,BLACK,5)
	_halftone(Rect2(810,185,570,85),Color(PAPER,.12),18)
	for i in 8:
		var x := fposmod(i*210.0-animation_time*24,1640)-100
		draw_line(Vector2(x,252),Vector2(x+62,218),Color(PINK,.23),4,true)
	text(Vector2(80,43),"TAÇA PRAÇA XV  /  RIO",15,PAPER)
	_wave(Vector2(300,151),"VÁRZEA FC",96,PAPER,3)
	text(Vector2(82,201),"DO CENTRO À PRAIA. A BOLA É DO RIO.",17,PAPER)
	_loud(Vector2(1005,148),"KICK OFF!",48,BLACK,-.055)
	text(Vector2(1000,205),"4 SELEÇÕES  /  2 UNIFORMES",16,CYAN)
	for side in 2:
		var left := 80.0+side*724.0
		var color := CYAN if side == 0 else PINK
		var team: Dictionary = game.team_definitions[side]
		_sticker(Rect2(left,296,560,322),BLACK,22)
		_slash(Rect2(left+10,264,245,43),color,13)
		_loud(Vector2(left+34,295),"PLAYER 01" if side == 0 else "COMPUTADOR",25,BLACK)
		_halftone(Rect2(left+330,322,198,95),Color(color,.13),18)
		_flag(Rect2(left+34,329,142,88),team.id)
		_loud(Vector2(left+204,401),game.team_short(side),73,PAPER,-.035)
		text(Vector2(left+204,428),"SUA SELEÇÃO" if side == 0 else "ADVERSÁRIO",13,color)
		for i in 3: _slash(Rect2(left+36+i*30,582,25,13),Color(team[["camisa","short","meiao"][i]]),3,PAPER,1)
		text(Vector2(left+138,594),"CAMISA / SHORT / MEIÃO",12,MUTED)
	_slash(Rect2(656,377,130,101),PINK,18,BLACK,5)
	_loud_center(Vector2(720,449+sin(animation_time*2.3)*4),"VS",76,PAPER,-.09)
	centered(Vector2(720,662),"5 CONTRA 5  /  3 MINUTOS  /  ELENCOS FICTÍCIOS",15,PAPER)
	var pulse := .4+.6*(sin(animation_time*3.4)*.5+.5)
	_slash(Rect2(477,700,486,84),Color(PINK,pulse),18,BLACK,3)
	centered(Vector2(720,806),"ENTER PARA COMEÇAR  /  VOCÊ CONTROLA "+game.team_label(0).to_upper(),14,CYAN)
	_footer()

func _footer() -> void:
	draw_rect(Rect2(0,856,1440,44),BLACK)
	draw_rect(Rect2(0,856,1440,2),PINK)
	centered(Vector2(720,882),"WASD MOVER   SHIFT CORRER   ESQ. CHUTE / CARRINHO   DIR. PASSE / DESARME   SCROLL TROCAR   V CÂMERA   P PAUSA   M ÁUDIO   F1 AJUDA",13,PAPER)
	if game.phase == "menu":
		var value := "BRASIL   /   ARGENTINA   /   ALEMANHA   /   FRANÇA   /   "
		var width := body_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		for i in 4: text(Vector2(i*width-fposmod(animation_time*35,width),899),value,11,Color(CYAN,.55))

func _player_card() -> void:
	var p = game.controlled
	if p == null: return
	_sticker(Rect2(25,681,350,151),BLACK,16)
	_slash(Rect2(31,674,208,29),CYAN,8)
	text(Vector2(49,695),game.team_label(p.team).to_upper(),14,BLACK)
	_flag(Rect2(307,695,43,27),game.team_definitions[p.team].id)
	_slash(Rect2(35,722,64,65),PINK,9)
	_loud_center(Vector2(68,771),"%02d" % p.profile.numero,43,PAPER)
	_loud(Vector2(111,746),p.profile.nome.to_upper(),30,PAPER)
	text(Vector2(112,770),p.profile.position_name().to_upper(),14,CYAN)
	text(Vector2(112,793),p.BODIES.NAMES[p.body_type].to_upper()+"  /  "+("%.2f m" % p.profile.altura).replace(".",","),13,PAPER)
	var stamina_color := CYAN if p.stamina > .5 else (GOLD if p.stamina > .2 else PINK)
	text(Vector2(44,818),"FÔLEGO",10,MUTED)
	for i in 12:
		_slash(Rect2(101+i*20,807,16,11),stamina_color if p.stamina*12 > i else Color("303047"),3,BLACK,1)
	if p.charging > 0:
		_sticker(Rect2(515,739,410,88),BLACK,20)
		var style: String = p.shot_style(.3+p.charging/1.05*.7)
		var shot_label: String = {"weak":"FRACO","medium":"MÉDIO","strong":"FORTE"}[style]
		var shot_color: Color = {"weak":CYAN,"medium":GOLD,"strong":PINK}[style]
		_wave(Vector2(720,768),shot_label+" / SOLTA!",25,shot_color,2)
		var power: float = clampf(p.charging/1.05,0,1)
		_slash(Rect2(542,782,350,21),Color("303047"),6)
		if power > .02: _slash(Rect2(542,782,350*power,21),shot_color,6,BLACK,1)
		_pixel(Vector2(950,775),str(int(power*100)),2,GOLD)
	else:
		var label := "DIR. DESARME   /   ESQ. CARRINHO"
		if game.phase == "out": label = "BOLA FORA / AGUARDE"
		elif game.phase == "foul": label = "FALTA / BOLA PARADA"
		elif game.phase == "restart": label = "PREPARANDO COBRANÇA"
		elif game.phase == "set_piece": label = "ESQ. CHUTE / DIR. PASSE" if game.is_set_piece_taker(p) and not game.spectator else "COBRANÇA ADVERSÁRIA" if not game.spectator else "COBRANÇA AUTOMÁTICA"
		elif game.receiving_player == p: label = "RECEBENDO PASSE >>"
		elif p.goalkeeper != null and p.goalkeeper.holding: label = "DIR. REPOR   /   ESQ. ARREMESSO"
		elif game.can_play_ball(p): label = "DIR. PASSE   /   ESQ. CHUTE"
		_slash(Rect2(490,791,460,37),BLACK,11,CYAN,1)
		centered(Vector2(720,816),label,15,PAPER)

func _minimap() -> void:
	_sticker(Rect2(1157,685,255,144),BLACK,14)
	var origin := Vector2(1181,709)
	draw_rect(Rect2(origin,Vector2(206,100)),Color("39394e"),false,1)
	draw_line(origin+Vector2(103,0),origin+Vector2(103,100),Color("5b5b71"),1)
	draw_arc(origin+Vector2(103,50),16,0,TAU,28,Color("5b5b71"),1)
	for p in game.players:
		var at: Vector2 = origin+Vector2((p.position.x+24)/48*206,(p.position.z+14)/28*100)
		draw_rect(Rect2(at-Vector2(3,3),Vector2(6,6)),CYAN if p.team == 0 else PINK)
		if p == game.controlled: draw_arc(at,7,0,TAU,16,PAPER,1.5,true)
	var ball_at: Vector2 = origin+Vector2((game.ball.position.x+24)/48*206,(game.ball.position.z+14)/28*100)
	draw_circle(ball_at,2.5,GOLD)

func _toast() -> void:
	var width := clampf(body_font.get_string_size(game.message,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+70,340,1000)
	var slide := -45*exp(-message_age*9)
	_slash(Rect2(720-width*.5+slide,174,width,42),BLACK,12,PINK,2)
	centered(Vector2(720+slide,201),game.message,18,PAPER)

func _dim() -> void:
	draw_rect(_screen_rect(),Color(.025,.015,.06,.8))

func _pause() -> void:
	_dim(); _sticker(Rect2(331,219,778,526),BLACK,35)
	_slash(Rect2(379,246,682,92),PINK,30)
	_wave(Vector2(720,320),"PAUSA NA RESENHA",54,PAPER,3)
	centered(Vector2(720,406),"RESPIRA. O CLÁSSICO CONTINUA.",21,CYAN)
	centered(Vector2(720,453),"P / ESC  CONTINUAR     R  RECOMEÇAR",17,PAPER)
	centered(Vector2(720,495),"V  CÂMERA     M  ÁUDIO     F1  AJUDA",15,MUTED)

func _results() -> void:
	_dim(); _sticker(Rect2(307,174,826,659),BLACK,36)
	_slash(Rect2(385,199,670,61),PINK,22)
	_wave(Vector2(720,247),"APITO FINAL!",43,PAPER,3)
	var winner: String = "DEU "+game.team_short(0)+"!" if game.score[0] > game.score[1] else ("DEU "+game.team_short(1)+"!" if game.score[1] > game.score[0] else "EMPATOU!")
	_loud_center(Vector2(720,331),winner,62,GOLD,-.035)
	_flag(Rect2(416,359,96,60),game.team_definitions[0].id)
	_flag(Rect2(928,359,96,60),game.team_definitions[1].id)
	_pixel(Vector2(645,363),str(game.score[0]),7,PAPER); _pixel(Vector2(795,363),str(game.score[1]),7,PAPER)
	_loud_center(Vector2(720,412),"/",52,PINK)
	centered(Vector2(469,454),game.team_label(0).to_upper(),17,CYAN)
	centered(Vector2(974,454),game.team_label(1).to_upper(),17,PINK)
	for index in 3:
		var key: String = ["shots","passes","tackles"][index]
		var y := 505+index*46
		_slash(Rect2(417,y-26,606,36),Color("242439"),8)
		centered(Vector2(472,y),str(game.stats[key][0]),23,CYAN)
		centered(Vector2(720,y-2),["CHUTES","PASSES","DESARMES"][index],15,PAPER)
		centered(Vector2(969,y),str(game.stats[key][1]),23,PINK)
	centered(Vector2(720,652),"O PRÓXIMO CLÁSSICO JÁ TEM HORA MARCADA.",14,MUTED)

func _help() -> void:
	_dim(); _sticker(Rect2(335,230,770,424),BLACK,24)
	_loud_center(Vector2(720,293),"MANUAL DO CRAQUE",41,GOLD,-.03)
	var lines := ["APONTE O MOUSE: CHUTE E PASSE SEGUEM A MIRA.","ESQUERDO: SEGURE PARA CHUTAR / SEM BOLA, CARRINHO.","DIREITO: PASSE / DESARME. SCROLL: TROCAR JOGADOR.","WASD: MOVER. SHIFT: CORRER. SOLTE PARA RECUPERAR FÔLEGO.","A TROCA ACOMPANHA QUEM RECEBE A BOLA."]
	for i in lines.size(): centered(Vector2(720,352+i*44),lines[i],16,PAPER if i%2 == 0 else CYAN)
	centered(Vector2(720,617),"F1 FECHAR   /   F2 TORCIDA   /   M ÁUDIO   /   R RECOMEÇAR",14,GOLD)

func goal_letter_offset(index: int) -> Vector2:
	var local := goal_age-index*.075
	var arrival := clampf(local/.40,0,1)
	var y := 190*pow(1-arrival,3)+sin(local*9)*exp(-maxf(local,0)*2.4)*17
	return Vector2(0,y)

func _goal_overlay() -> void:
	var age := goal_age
	var exit_alpha := clampf((game.GOAL_DURATION-age)/.35,0,1)
	draw_rect(_screen_rect(),Color(BLACK,.26*exit_alpha))
	# One impact wash, then flowing rays and confetti; no repeating strobe.
	if age < .22: draw_rect(_screen_rect(),Color(PAPER,.28*(1-age/.22)))
	var center := Vector2(720,420)
	for i in 22:
		var angle := i*TAU/22.0+age*.035
		var axis := Vector2.from_angle(angle); var perpendicular := axis.orthogonal()
		var inner := center+axis*(250+age*20)
		var outer := center+axis*1000
		draw_colored_polygon(PackedVector2Array([inner,outer+perpendicular*25,outer-perpendicular*25]),Color(CYAN if i%2 == 0 else PINK,.14*exit_alpha))
	var slide := -1500*pow(1-clampf(age/.27,0,1),3)
	_slash(Rect2(-110+slide,305,1660,230),Color(BLACK,.97),120,PINK,6)
	_slash(Rect2(350+slide,270,740,46),GOLD,20,BLACK,3)
	centered(Vector2(720+slide,300),"A REDE BALANÇOU!",21,BLACK)
	var value := "GOOOL!"
	var size := 166
	var x := 720-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5
	for i in value.length():
		var local := age-i*.075
		var letter := value.substr(i,1)
		if local >= 0:
			var bounce := goal_letter_offset(i)
			_loud(Vector2(x,486)+bounce,letter,size,GOLD if i%2 == 0 else PAPER,sin(local*5+i)*.035)
		x += font.get_string_size(letter,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	if age > .40:
		var rise := 30*exp(-(age-.4)*8)
		_flag(Rect2(529,565+rise,75,47),game.team_definitions[goal_team].id)
		_loud(Vector2(626,605+rise),game.team_label(goal_team).to_upper(),42,PAPER,-.035)
		_pixel(Vector2(675,636+rise),str(game.score[0]),4,PAPER)
		_pixel(Vector2(765,636+rise),str(game.score[1]),4,GOLD)
		draw_line(Vector2(724,640+rise),Vector2(713,661+rise),PINK,3)
	for i in 42:
		var phase := fmod(i*.618,1.0)
		var t := age*.6+phase
		var at := Vector2(fposmod(i*143.7+sin(i)*age*42,1440),fposmod(t*t*235+i*31,1100)-100)
		var color: Color = [PINK,CYAN,GOLD,PAPER][i%4]
		draw_set_transform_matrix(ui_transform*Transform2D(age*1.7+i,at))
		draw_rect(Rect2(-4,-8,8,16),Color(color,exit_alpha))
	draw_set_transform_matrix(ui_transform)

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
	draw_line(start+axis*12,end,CYAN,2,true)
	draw_line(end,end-axis*9+perpendicular*5,CYAN,2,true)
	draw_line(end,end-axis*9-perpendicular*5,CYAN,2,true)
	draw_arc(inverse*get_viewport().get_mouse_position(),8,0,TAU,24,CYAN,1.5,true)
