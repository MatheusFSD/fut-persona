extends Node3D
## A fictional Rio square, built only from static native meshes. No gameplay collision.
const STONE = preload("res://assets/shaders/praca_stone.gdshader")
const WATER = preload("res://assets/shaders/rio_water.gdshader")
const IVORY := Color("e2d6b8")
const CHALK := Color("efe6cc")
const STONE_GRAY := Color("9a998b")
const BASALT := Color("444d4c")
const WOOD := Color("654b35")
const SHUTTER := Color("294e49")
const TILE := Color("b56743")
const COPPER := Color("548d85")
const IRON := Color("344a49")
var rng := RandomNumberGenerator.new()
var material: StandardMaterial3D
var surface: SurfaceTool
var batch_name := ""
var batch_group := ""
var triangle_count := 0
var game
var water_material: ShaderMaterial
var sea_time := 0.0

func _ready() -> void:
	name = "PracaXV"; add_to_group("rio_district"); rng.seed = 1501888
	material = StandardMaterial3D.new(); material.vertex_color_use_as_albedo = true; material.vertex_color_is_srgb = true; material.roughness = .95
	_ground()
	_paco(); _arco(); _fountain(); _ferry_terminal(); _ferry()
	_colonial_street(); _side_street(); _suburb(); _waterfront(); _beach(); _plaza_life(); _bay_background()
	set_meta("triangles",triangle_count)

func _process(delta: float) -> void:
	if game != null and game.phase == "paused": return
	sea_time += delta
	if water_material != null: water_material.set_shader_parameter("sea_time",sea_time)

func _begin(label: String, group := "rio_scenery") -> void:
	batch_name = label; batch_group = group; surface = SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)

func _end(shadows := true) -> MeshInstance3D:
	surface.index()
	var node := MeshInstance3D.new(); node.name = batch_name; node.mesh = surface.commit(); node.material_override = material
	if not shadows: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_to_group(batch_group); add_child(node)
	return node

func _tri(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var normal := (b-a).cross(c-a).normalized()
	for v in [a,c,b]:
		surface.set_normal(normal); surface.set_color(color); surface.add_vertex(v)
	triangle_count += 1

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	_tri(a,b,c,color); _tri(a,c,d,color)

func _box(at: Vector3, size: Vector3, color: Color, basis := Basis.IDENTITY) -> void:
	var p: Array[Vector3] = []
	for corner in [Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,1,-1),Vector3(-1,1,-1),Vector3(-1,-1,1),Vector3(1,-1,1),Vector3(1,1,1),Vector3(-1,1,1)]:
		p.append(at+basis*(corner*size*.5))
	for face in [[4,5,6,7],[1,0,3,2],[0,4,7,3],[5,1,2,6],[3,7,6,2],[0,1,5,4]]:
		_quad(p[face[0]],p[face[1]],p[face[2]],p[face[3]],color)

func _pole(a: Vector3, b: Vector3, radius: float, color: Color, sides := 7, tip_radius := -1.0) -> void:
	var along := (b-a).normalized()
	var across := along.cross(Vector3.FORWARD).normalized()
	if across.length_squared() < .01: across = along.cross(Vector3.RIGHT).normalized()
	var other := along.cross(across).normalized()
	var top_radius := radius if tip_radius < 0 else tip_radius
	for i in sides:
		var u := across*cos(TAU*i/sides)+other*sin(TAU*i/sides)
		var v := across*cos(TAU*(i+1)/sides)+other*sin(TAU*(i+1)/sides)
		_quad(a+u*radius,a+v*radius,b+v*top_radius,b+u*top_radius,color)
		_tri(a,a+v*radius,a+u*radius,color); _tri(b,b+u*top_radius,b+v*top_radius,color)

func _oval(at: Vector3, radius: Vector3, color: Color, sides := 7, rings := 4) -> void:
	for row in rings:
		var phi := PI*row/rings; var next := PI*(row+1)/rings
		for col in sides:
			var a := TAU*col/sides; var b := TAU*(col+1)/sides
			var p := at+Vector3(sin(phi)*cos(a),cos(phi),sin(phi)*sin(a))*radius
			var q := at+Vector3(sin(phi)*cos(b),cos(phi),sin(phi)*sin(b))*radius
			var r := at+Vector3(sin(next)*cos(b),cos(next),sin(next)*sin(b))*radius
			var t := at+Vector3(sin(next)*cos(a),cos(next),sin(next)*sin(a))*radius
			if row == 0: _tri(p,r,t,color)
			elif row == rings-1: _tri(p,q,r,color)
			else: _quad(p,q,r,t,color)

func _roof(at: Vector3, width: float, depth: float, rise: float, color := TILE) -> void:
	var a := at+Vector3(-width/2,0,-depth/2); var b := at+Vector3(width/2,0,-depth/2)
	var c := at+Vector3(width/2,0,depth/2); var d := at+Vector3(-width/2,0,depth/2)
	var e := at+Vector3(-maxf(.2,(width-depth)/2),rise,0); var f := at+Vector3(maxf(.2,(width-depth)/2),rise,0)
	_quad(a,e,f,b,color.darkened(.10)); _quad(d,c,f,e,color.lightened(.08))
	_tri(a,d,e,color.darkened(.17)); _tri(b,f,c,color)
	_box(at+Vector3(0,-.10,0),Vector3(width,.22,depth),IVORY)
	_pole(e,f,.095,color.lightened(.18),6)

func _text(value: String, at: Vector3, size := 48, pixel := .011, color := CHALK, angle := 0.0) -> void:
	var label := Label3D.new(); label.text = value; label.position = at; label.rotation.y = angle
	label.font_size = size; label.pixel_size = pixel; label.modulate = color; label.outline_size = 2
	label.outline_modulate = Color("344a49"); label.no_depth_test = false
	label.add_to_group("rio_sign"); add_child(label)

func _window(at: Vector3, width := 1.15, height := 2.1, balcony := false, shutter := SHUTTER) -> void:
	_box(at,Vector3(width+.32,height+.28,.20),STONE_GRAY)
	_box(at+Vector3(0,0,.12),Vector3(width,height,.06),shutter)
	_box(at+Vector3(0,0,.17),Vector3(.075,height,.04),WOOD.lightened(.1))
	_box(at+Vector3(0,-height*.5-.10,.17),Vector3(width+.50,.15,.37),CHALK)
	_box(at+Vector3(0,height*.5+.13,.10),Vector3(width+.45,.12,.26),CHALK)
	if balcony:
		_box(at+Vector3(0,-height*.5-.25,.36),Vector3(width+.6,.16,.80),STONE_GRAY)
		_box(at+Vector3(0,-height*.5+.40,.72),Vector3(width+.55,.045,.045),IRON)
		for i in 7:
			_box(at+Vector3((i-3)*(width+.42)/6,-height*.5+.10,.72),Vector3(.035,.65,.035),IRON)

func _ground() -> void:
	_begin("CalcamentoDaPraca","rio_plaza")
	# Four rectangles leave the existing lawn and the complete cage untouched.
	for rect: Rect2 in [Rect2(-96,-95,153.5,77.65),Rect2(-96,17.35,140,55.65),Rect2(-96,-17.35,68.25,34.7),Rect2(27.75,-17.35,29.75,34.7)]:
		var a := Vector3(rect.position.x,.008,rect.position.y); var b := Vector3(rect.end.x,.008,rect.position.y)
		var c := Vector3(rect.end.x,.008,rect.end.y); var d := Vector3(rect.position.x,.008,rect.end.y)
		_quad(a,d,c,b,Color.WHITE)
	var ground := _end(false); var stone := ShaderMaterial.new(); stone.shader = STONE; ground.material_override = stone
	_begin("PasseioDaOrla","rio_promenade")
	_box(Vector3(39,.025,43),Vector3(10,.045,58),Color.WHITE)
	var promenade := _end(false); var mosaic := ShaderMaterial.new(); mosaic.shader = STONE; mosaic.set_shader_parameter("promenade",true); promenade.material_override = mosaic
	_begin("AguaDaBaia","rio_water")
	for rect: Rect2 in [Rect2(58.3,-130,150,300),Rect2(-96,73,154.3,97)]:
		for row in 20:
			for col in 18:
				var x := rect.position.x+rect.size.x*col/18; var z := rect.position.y+rect.size.y*row/20
				var dx := rect.size.x/18; var dz := rect.size.y/20
				var tint := Color(.40,0,0)
				_quad(Vector3(x,-.42,z),Vector3(x,-.42,z+dz),Vector3(x+dx,-.42,z+dz),Vector3(x+dx,-.42,z),tint)
	var sea := _end(false); water_material = ShaderMaterial.new(); water_material.shader = WATER; sea.material_override = water_material

func _paco() -> void:
	_begin("PacoDaPraca","rio_landmark")
	var center := Vector3(-18,0,-38)
	_box(center+Vector3(0,4.15,0),Vector3(38,8.3,10),IVORY)
	_box(center+Vector3(0,.22,5.2),Vector3(40,.45,1.8),STONE_GRAY)
	_box(center+Vector3(0,.52,5.05),Vector3(39,.17,1.0),CHALK)
	for y in [.65,4.15,7.95,8.35]: _box(center+Vector3(0,y,5.12),Vector3(38.7,.18,.36),CHALK)
	for x in [-18.5,-9.3,0.0,9.3,18.5]: _box(center+Vector3(x,4.1,5.08),Vector3(.4,7.65,.27),STONE_GRAY.lightened(.2))
	for i in 11:
		var x := -16.9+i*3.38
		_window(center+Vector3(x,5.95,5.12),1.25,2.3,true,SHUTTER)
		if i != 5: _window(center+Vector3(x,2.15,5.12),1.18,2.55,false,WOOD)
	_box(center+Vector3(0,2.0,5.19),Vector3(2.15,3.2,.25),STONE_GRAY)
	_box(center+Vector3(0,1.85,5.35),Vector3(1.68,2.9,.1),WOOD.darkened(.18))
	_box(center+Vector3(0,1.85,5.42),Vector3(.07,2.9,.04),IRON)
	_roof(center+Vector3(0,8.45,0),39.5,11.5,1.65)
	_box(center+Vector3(0,9.1,4.5),Vector3(4.0,1.4,.6),CHALK)
	_tri(center+Vector3(-2.5,9.4,4.84),center+Vector3(2.5,9.4,4.84),center+Vector3(0,10.6,4.84),CHALK)
	_oval(center+Vector3(0,9.55,4.94),Vector3(.33,.38,.10),Color("bdac72"))
	_end(); _text("PAÇO DA PRAÇA",center+Vector3(0,4.40,5.4),38,.009)

func _arch_sector(at: Vector3, inner: float, outer: float, spring: float, depth: float) -> void:
	for i in 12:
		var a := PI*i/12; var b := PI*(i+1)/12
		var p := at+Vector3(cos(a)*inner,spring+sin(a)*inner,0)
		var q := at+Vector3(cos(b)*inner,spring+sin(b)*inner,0)
		var r := at+Vector3(cos(b)*outer,spring+sin(b)*outer,0)
		var t := at+Vector3(cos(a)*outer,spring+sin(a)*outer,0)
		_quad(p,t,r,q,STONE_GRAY.lightened(.08 if i%2 else -.04))
		_quad(p,q,q-Vector3(0,0,depth),p-Vector3(0,0,depth),STONE_GRAY.darkened(.25))
		# Spandrels above the curved opening, with a real gap through the building.
		var u := Vector3(p.x,at.y+4.8,p.z-.15); var v := Vector3(q.x,at.y+4.8,q.z-.15)
		_quad(p-Vector3(0,0,.15),u,v,q-Vector3(0,0,.15),CHALK)

func _arco() -> void:
	_begin("ArcoDaTravessa","rio_landmark")
	var c := Vector3(17,0,-37)
	_box(c+Vector3(-6.7,2.35,0),Vector3(8.0,4.7,7),CHALK)
	_box(c+Vector3(6.7,2.35,0),Vector3(8.0,4.7,7),CHALK)
	_box(c+Vector3(0,7.0,0),Vector3(21.4,4.6,7),CHALK)
	for y in [4.75,7.1,9.35]: _box(c+Vector3(0,y,3.55),Vector3(21.9,.18,.35),STONE_GRAY)
	for x in [-8.5,-5.1,-1.7,1.7,5.1,8.5]:
		for y in [5.9,8.1]: _window(c+Vector3(x,y,3.6),1.15,1.8,true,WOOD)
	for x in [-8.3,-5.0,5.0,8.3]: _window(c+Vector3(x,1.85,3.6),1.35,3.0,false,WOOD)
	for x in [-2.32,2.32]: _box(c+Vector3(x,1.4,3.65),Vector3(.65,2.8,.40),STONE_GRAY)
	_arch_sector(c+Vector3(0,0,3.92),2.0,2.65,2.35,7.2)
	_roof(c+Vector3(0,9.5,0),22.6,8.2,1.7)
	_end(); _text("TRAVESSA DO COMÉRCIO",c+Vector3(0,4.63,4.04),28,.008)
	# The alley is visible through the arch, with little colored shop fronts.
	_begin("BecoDoArco")
	for side in [-1,1]:
		for i in 4:
			var p := Vector3(17+side*4.0,0,-45-i*5.2)
			_box(p+Vector3(0,3.1,0),Vector3(3,6.2,5),Color("cdac87") if i%2 else Color("99b4a8"))
			_roof(p+Vector3(0,6.3,0),3.5,5.3,.9)
	_end()

func _fountain() -> void:
	_begin("ChafarizDaPraca","rio_landmark")
	var c := Vector3(-4.5,0,-24)
	for i in 3: _box(c+Vector3(0,.13+i*.2,0),Vector3(5.0-i*.65,.22,4.3-i*.55),STONE_GRAY)
	_box(c+Vector3(0,2.0,0),Vector3(2.7,2.8,2.55),Color("a9a58f"))
	for y in [.8,3.30,3.55]: _box(c+Vector3(0,y,0),Vector3(3.1,.20,2.95),CHALK.darkened(.12))
	for x in [-1.20,1.20]:
		for z in [-1.15,1.15]: _box(c+Vector3(x,2, z),Vector3(.23,2.5,.23),STONE_GRAY.darkened(.15))
	for side in [-1,1]:
		_box(c+Vector3(0,1.68,side*1.32),Vector3(1.2,1.45,.1),BASALT)
		_box(c+Vector3(0,.88,side*1.58),Vector3(1.6,.30,.65),STONE_GRAY)
		_oval(c+Vector3(0,1.36,side*1.4),Vector3(.16,.15,.12),Color("867d62"))
	_roof(c+Vector3(0,3.65,0),3.45,3.1,1.9,Color("999787"))
	_pole(c+Vector3(0,5.4,0),c+Vector3(0,5.9,0),.15,Color("a49a68"),6)
	# Angular armillary finial: two open rings, not a solid sphere.
	for axis in [0,1]:
		for i in 12:
			var a := TAU*i/12; var b := TAU*(i+1)/12
			var p := Vector3(cos(a)*.33, sin(a)*.33 if axis == 0 else 0,sin(a)*.33 if axis == 1 else 0)
			var q := Vector3(cos(b)*.33, sin(b)*.33 if axis == 0 else 0,sin(b)*.33 if axis == 1 else 0)
			_pole(c+Vector3(0,6.0,0)+p,c+Vector3(0,6.0,0)+q,.035,Color("b9ac6e"),4)
	_end()

func _ferry_terminal() -> void:
	_begin("EstacaoDasBarcas","rio_landmark")
	var c := Vector3(47,0,-31)
	_box(c+Vector3(0,2.5,0),Vector3(13,5,18),Color("d2d6bd"))
	for z in [-6.7,-3.3,0.0,3.3,6.7]:
		_box(c+Vector3(-6.58,2.2,z),Vector3(.15,3.7,2.0),SHUTTER)
		for dz in [-1.05,1.05]: _box(c+Vector3(-6.7,2.25,z+dz),Vector3(.25,4.0,.22),CHALK)
	# Long copper roof and clock pavilion, read clearly from the field.
	_roof(c+Vector3(0,5.1,0),14.4,19.8,1.8,COPPER)
	_box(c+Vector3(-3.7,6.5,0),Vector3(4.0,3.6,4.3),CHALK)
	_roof(c+Vector3(-3.7,8.4,0),4.8,5.0,1.65,COPPER)
	_pole(c+Vector3(-5.74,7.0,0),c+Vector3(-5.79,7.0,0),.76,IRON,12)
	_pole(c+Vector3(-5.76,7.0,0),c+Vector3(-5.83,7.0,0),.66,CHALK,12)
	_pole(c+Vector3(-5.85,7.0,0),c+Vector3(-5.85,7.40,.02),.025,IRON,4)
	_pole(c+Vector3(-5.85,7.0,0),c+Vector3(-5.85,6.95,.40),.025,IRON,4)
	for z in [-7.0,-2.3,2.3,7.0]: _pole(c+Vector3(-9,0,z),c+Vector3(-9,4.0,z),.12,IRON,6)
	_box(c+Vector3(-7.8,4.0,0),Vector3(4,.22,18.5),COPPER)
	_box(c+Vector3(-6.8,.25,0),Vector3(5,.5,19.5),STONE_GRAY)
	for x in [-3.5,0.0,3.5]: _window(c+Vector3(x,2.4,9.05),1.5,3.2,false,SHUTTER)
	_end(); _text("BARCAS",c+Vector3(-6.90,5.15,0),60,.013,CHALK,-PI/2)
	_begin("PierDasBarcas")
	_box(Vector3(60,-.08,-31),Vector3(13,.30,5.5),STONE_GRAY)
	for x in [55.0,60.0,65.0]:
		for z in [-33.6,-28.4]: _pole(Vector3(x,-.7,z),Vector3(x,.65,z),.16,WOOD,7)
	_end()

func _side_street() -> void:
	_begin("RuaLateralDaPraca","rio_colonial_street")
	var colors := [Color("b28b72"),Color("b8c0a7"),Color("cbb46a"),Color("9baca8"),Color("bd8b80")]
	for i in 6:
		var p := Vector3(-44,0,-19+i*11)
		var h := 6.0+(i%3)*.9
		_box(p+Vector3(0,h*.5,0),Vector3(8,h,9.5),colors[i%5])
		_roof(p+Vector3(0,h+.1,0),8.8,10.1,1.1)
		for z in [-2.65,0.0,2.65]:
			for y in [1.7,h-1.6]:
				_box(p+Vector3(4.05,y,z),Vector3(.18,2.35,1.50),STONE_GRAY)
				_box(p+Vector3(4.16,y,z),Vector3(.06,2.05,1.18),SHUTTER if y > 3 else WOOD)
				_box(p+Vector3(4.22,y-1.16,z),Vector3(.30,.14,1.7),CHALK)
		_box(p+Vector3(4.7,3.25,0),Vector3(1.6,.16,8.1),Color("b38159") if i%2 else COPPER)
	# A quiet street behind the plaza frontage, with a parked municipal-style bus.
	_box(Vector3(-55,.015,10),Vector3(7,.03,83),Color("65706b"))
	for z in range(-26,49,6): _box(Vector3(-55,.035,z),Vector3(.13,.012,2.4),CHALK)
	var bus := Vector3(-55,.7,13)
	_box(bus+Vector3(0,1.1,0),Vector3(2.65,2.2,7.8),Color("dfd8bd"))
	_box(bus+Vector3(0,.35,0),Vector3(2.72,.55,7.9),Color("49858b"))
	for side in [-1,1]:
		for z in [-2.7,-1.4,0.0,1.4,2.7]: _box(bus+Vector3(side*1.36,1.6,z),Vector3(.06,.85,1.0),SHUTTER)
		for z in [-2.4,2.4]: _pole(bus+Vector3(side*1.25,-.12,z),bus+Vector3(side*1.48,-.12,z),.49,IRON,8)
	_box(bus+Vector3(0,1.55,3.96),Vector3(2.2,.9,.06),SHUTTER)
	_end(); _text("ARMAZÉM DA PRAÇA",Vector3(-39.1,3.05,-19),29,.010,CHALK,PI/2)

func _ferry() -> void:
	_begin("BarcaDaBaia","rio_ferry")
	var c := Vector3(69,0,-31)
	var outline := [Vector2(-3.4,-6),Vector2(-2.6,-8.5),Vector2(2.6,-8.5),Vector2(3.4,-6),Vector2(3.4,6),Vector2(2.0,8.5),Vector2(-2.0,8.5),Vector2(-3.4,6)]
	for i in outline.size():
		var a: Vector2 = outline[i]; var b: Vector2 = outline[(i+1)%outline.size()]
		_quad(c+Vector3(a.x*.75,-.7,a.y*.9),c+Vector3(b.x*.75,-.7,b.y*.9),c+Vector3(b.x,.4,b.y),c+Vector3(a.x,.4,a.y),Color("b76148"))
		_tri(c+Vector3(0,.42,0),c+Vector3(a.x,.42,a.y),c+Vector3(b.x,.42,b.y),CHALK)
	_box(c+Vector3(0,1.20,0),Vector3(5.9,1.5,12.5),CHALK)
	_box(c+Vector3(0,2.45,-1.0),Vector3(4.4,1.0,7.0),CHALK)
	for side in [-1,1]:
		for i in 7: _box(c+Vector3(side*3.0,1.3,-5.1+i*1.65),Vector3(.04,.66,1.10),SHUTTER)
		_box(c+Vector3(side*2.23,2.55,-1),Vector3(.04,.50,5.6),Color("376b72"))
	_box(c+Vector3(0,3.05,-1),Vector3(5.1,.18,8.4),Color("d7bc6b"))
	for z in [-3,1.0]: _pole(c+Vector3(0,3.1,z),c+Vector3(0,4.0,z),.26,IRON,7)
	_end()

func _colonial_street() -> void:
	_begin("SobradosDaPraca","rio_colonial_street")
	var colors := [Color("c59873"),Color("b5c7bc"),Color("e0c979"),Color("c18b80"),Color("a0b5b6")]
	for i in 6:
		var c := Vector3(-50-i*6,0,-34-rng.randf_range(0,7))
		var height := 6.8+(i%3)*1.5
		_box(c+Vector3(0,height*.5,0),Vector3(5.7,height,6.5),colors[i%colors.size()])
		_roof(c+Vector3(0,height+.1,0),6.1,7.1,1.1)
		for x in [-1.35,1.35]:
			_window(c+Vector3(x,height-1.8,3.3),.9,1.9,true,SHUTTER)
			_window(c+Vector3(x,1.7,3.3),1.0,2.6,false,WOOD)
		_box(c+Vector3(0,3.35,3.6),Vector3(5.7,.25,1.2),colors[(i+2)%colors.size()])
	# A small clock/bell tower and distant downtown blocks complete the skyline.
	var c := Vector3(-40,0,-59)
	_box(c+Vector3(0,6,0),Vector3(7.0,12,6),Color("c1c5b2"))
	_box(c+Vector3(0,13.2,0),Vector3(5.0,2.4,4.8),CHALK)
	for x in [-1.3,1.3]: _box(c+Vector3(x,13.0,2.45),Vector3(1.0,1.65,.1),IRON)
	_roof(c+Vector3(0,14.5,0),5.5,5.3,2.8,COPPER)
	_pole(c+Vector3(0,17.1,0),c+Vector3(0,18.2,0),.05,IRON,5)
	_pole(c+Vector3(-.35,17.85,0),c+Vector3(.35,17.85,0),.05,IRON,5)
	for i in 8:
		var p := Vector3(-28+i*9,0,-75-rng.randf_range(0,12)); var h := rng.randf_range(12,23)
		_box(p+Vector3(0,h*.5,0),Vector3(6,h,7),Color("839d9b").lightened(rng.randf_range(0,.18)))
		for y in range(3,int(h)-1,3): _box(p+Vector3(0,y,3.53),Vector3(4.9,.65,.05),Color("516c6c"))
	_end()

func _hill_height(x: float, z: float) -> float:
	var d := Vector2((x+69)/28.0,(z+63)/28.0).length()
	return maxf(0,1-d)*15

func _suburb() -> void:
	_begin("MorroDoSuburbio","rio_suburb")
	for row in 8:
		for col in 9:
			var x := -98+col*6.5; var z := -91+row*6.5
			var a := Vector3(x,_hill_height(x,z),z); var b := Vector3(x+6.5,_hill_height(x+6.5,z),z)
			var c := Vector3(x+6.5,_hill_height(x+6.5,z+6.5),z+6.5); var d := Vector3(x,_hill_height(x,z+6.5),z+6.5)
			_quad(a,d,c,b,Color("64806a").lightened(rng.randf_range(-.08,.12)))
	var colors := [Color("b78362"),Color("cfb77c"),Color("9eaf9b"),Color("be9688")]
	for i in 26:
		var x := rng.randf_range(-91,-49); var z := rng.randf_range(-85,-49); var y := _hill_height(x,z)
		var h := rng.randf_range(2.5,5.5); var p := Vector3(x,y,z)
		_box(p+Vector3(0,h*.5,0),Vector3(4.3,h,4.0),colors[i%4])
		_box(p+Vector3(0,h,0),Vector3(4.6,.18,4.3),Color("a0957a"))
		for dx in [-1.0,1.0]: _box(p+Vector3(dx,h*.6,2.04),Vector3(.7,1.1,.05),SHUTTER)
		if i%3 == 0: _pole(p+Vector3(.7,h,0),p+Vector3(.7,h+.8,0),.55,Color("48555b"),6)
	_end(false)

func _bench(at: Vector3, angle: float) -> void:
	var basis := Basis(Vector3.UP,angle)
	for z in [-.24,0.0,.24]: _box(at+basis*Vector3(0,.55,z),Vector3(2,.10,.18),WOOD.lightened(.2),basis)
	for x in [-.72,.72]: _box(at+basis*Vector3(x,.25,0),Vector3(.12,.5,.55),IRON,basis)
	for y in [.88,1.1]: _box(at+basis*Vector3(0,y,-.32),Vector3(2,.14,.10),WOOD.lightened(.2),basis)

func _lamp(at: Vector3) -> void:
	_pole(at,at+Vector3.UP*.45,.17,IRON,7)
	_pole(at,at+Vector3.UP*4.1,.065,IRON,7)
	_pole(at+Vector3.UP*3.9,at+Vector3.UP*4.4,.20,Color("e4d496"),6,.14)
	_pole(at+Vector3.UP*4.4,at+Vector3.UP*4.65,.30,IRON,6,0)

func _palm(at: Vector3, height: float, angle: float) -> void:
	var lean := Vector3(cos(angle),0,sin(angle))*.65
	for i in 5:
		var t := i/5.0; var u := (i+1)/5.0
		_pole(at+Vector3.UP*height*t+lean*t*t,at+Vector3.UP*height*u+lean*u*u,.19-t*.10,Color("927e5a"),6,.19-u*.10)
	var crown := at+Vector3.UP*height+lean
	for i in 7:
		var dir := Vector3(cos(angle+i*TAU/7),0,sin(angle+i*TAU/7)); var side := Vector3(-dir.z,0,dir.x)*.43
		var mid := crown+dir*1.5+Vector3.UP*.55; var tip := crown+dir*3.2-Vector3.UP*.65
		_quad(crown,mid-side,tip,mid+side,Color("3d7553") if i%2 else Color("5b8a52"))
		_tri(crown,mid+side,mid+Vector3.UP*.12,Color("729b5b"))

func _waterfront() -> void:
	_begin("CaisEPasseio","rio_waterfront")
	_box(Vector3(56.9,-.35,-16),Vector3(3,1,106),STONE_GRAY)
	for z in range(-65,31,5):
		_pole(Vector3(58.4,0,z),Vector3(58.4,1.15,z),.055,IRON,6)
		_pole(Vector3(58.4,.55,z),Vector3(58.4,.55,z+5),.035,IRON,5)
		_pole(Vector3(58.4,1.12,z),Vector3(58.4,1.12,z+5),.035,IRON,5)
	for z in [-55,-42,-18,-3,12]: _bench(Vector3(54.4,0,z),PI/2); _lamp(Vector3(55.0,0,z-2))
	for x in [-26,-17,5,28]: _lamp(Vector3(x,0,-21))
	for x in [-18,-10,3,12]: _bench(Vector3(x,0,-20),0)
	_end()

func _beach() -> void:
	_begin("PraiaDaEnseada","rio_beach")
	var points := [Vector3(44,.04,17.5),Vector3(58,.04,27),Vector3(62,.04,48),Vector3(68,.04,73),Vector3(25,.04,73),Vector3(33,.04,45)]
	var center := Vector3(46,.04,49)
	for i in points.size(): _tri(center,points[(i+1)%points.size()],points[i],Color("d4bf85").lightened(i*.018))
	for i in 7:
		var p := Vector3(46+(i%2)*7,0,27+i*5.6)
		_pole(p,p+Vector3.UP*2.15,.04,WOOD,6)
		for j in 10:
			var a := TAU*j/10; var b := TAU*(j+1)/10
			_tri(p+Vector3(0,2.45,0),p+Vector3(cos(b)*1.8,1.95,sin(b)*1.8),p+Vector3(cos(a)*1.8,1.95,sin(a)*1.8),CHALK if j%2 else Color("d68864") if i%2 else COPPER)
		_box(p+Vector3(1,.24,1.6),Vector3(.65,.14,1.7),CHALK)
		_box(p+Vector3(1,.45,.8),Vector3(.65,.5,.18),CHALK,Basis(Vector3.RIGHT,.35))
	for p in [Vector3(39,0,22),Vector3(39,0,37),Vector3(34,0,56),Vector3(50,0,64),Vector3(57,0,46)]: _palm(p,rng.randf_range(6.2,8.0),rng.randf()*TAU)
	_end()

func _person(at: Vector3, shirt: Color, skin: Color, turn: float) -> void:
	var basis := Basis(Vector3.UP,turn); var size := rng.randf_range(.90,1.10)
	_box(at+Vector3(0,.99*size,0),Vector3(.44,.60,.27)*size,shirt,basis)
	for x in [-.12,.12]: _box(at+basis*Vector3(x,.35*size,0),Vector3(.14,.70,.19)*size,BASALT,basis)
	for x in [-.29,.29]: _box(at+basis*Vector3(x,.90*size,0),Vector3(.13,.55,.15)*size,skin,basis)
	_oval(at+Vector3(0,1.50*size,0),Vector3(.16,.21,.16)*size,skin,6,3)

func _plaza_life() -> void:
	_begin("QuiosqueDoTorneio","rio_tournament")
	_box(Vector3(-21,1.15,-22),Vector3(5.2,2.3,3.0),Color("c8ab75"))
	_box(Vector3(-21,1.2,-20.45),Vector3(4.2,1.2,.12),SHUTTER)
	_box(Vector3(-21,1,-20.0),Vector3(5.0,.20,.8),WOOD)
	_roof(Vector3(-21,2.4,-22),6,3.8,.75)
	_box(Vector3(12,2.1,-18.1),Vector3(13,1.8,.14),SHUTTER)
	for x in [5.3,18.7]: _pole(Vector3(x,0,-18.2),Vector3(x,3.6,-18.2),.07,IRON,6)
	# Native tournament floodlight silhouettes outside the unmodified cage.
	for x in [-29.5,29.5]:
		for z in [-18.6,18.6]:
			_pole(Vector3(x,0,z),Vector3(x,8.4,z),.11,IRON,6)
			_box(Vector3(x,8.3,z),Vector3(1.5,.22,.35),IRON)
			for dx in [-.46,.46]: _box(Vector3(x+dx,8.35,z+.18),Vector3(.58,.40,.12),CHALK)
	_end(); _text("TAÇA PRAÇA XV",Vector3(12,2.35,-17.98),64,.014)
	_text("RIO DE JANEIRO",Vector3(12,1.75,-17.98),34,.012,Color("ebc26b"))
	_text("CALDO & BOLA",Vector3(-21,2.07,-20.40),36,.011)
	_begin("TorcidaDaPraca","rio_crowd")
	var shirts := [Color("e4c96e"),Color("549b9a"),Color("b36767"),Color("e8ddbd"),Color("65718d")]
	var skins := [Color("e2be8e"),Color("b77c54"),Color("8e593f"),Color("5c3c2c")]
	for i in 28:
		var x := -24+i*1.8
		if x > -8 and x < -1: continue
		_person(Vector3(x,0,-18.9-rng.randf_range(0,.8)),shirts[i%5],skins[i%4],rng.randf_range(-.35,.35))
	for i in 18:
		var at := Vector3(rng.randf_range(29,54),0,rng.randf_range(-18,12))
		_person(at,shirts[(i+1)%5],skins[(i+2)%4],rng.randf()*TAU)
	for p in [Vector3(-38,0,19),Vector3(-38,0,-20),Vector3(-44,0,5)]: _palm(p,6.7,rng.randf()*TAU)
	_end()

func _bay_background() -> void:
	_begin("IlhasDaBaia","rio_islands")
	for entry in [[Vector3(113,-4,-78),Vector3(19,22,24)],[Vector3(139,-5,-18),Vector3(23,18,31)],[Vector3(112,-4,76),Vector3(17,16,24)]]:
		var at: Vector3 = entry[0]; var size: Vector3 = entry[1]
		var rings: Array = []
		for layer in 5:
			var points: Array[Vector3] = []
			for i in 11:
				var angle := TAU*i/11; var t := layer/4.0
				var radius: float = [1.0,.93,.70,.35,0.0][layer]
				radius *= 1+.12*sin(i*2.4+at.x)
				points.append(at+Vector3(cos(angle)*size.x*radius+size.y*t*.23,size.y*t,sin(angle)*size.z*radius+size.y*t*.12))
			rings.append(points)
		for layer in 4:
			for i in 11:
				_quad(rings[layer][i],rings[layer+1][i],rings[layer+1][(i+1)%11],rings[layer][(i+1)%11],Color("527a6c").lightened(.03*((i+layer)%3)))
	_end(false)
	_begin("NuvensDaOrla","rio_sky")
	for p in [Vector3(-8,29,-109),Vector3(58,27,-100),Vector3(111,26,-23),Vector3(98,29,88)]:
		for i in 3: _oval(p+Vector3((i-1)*7,(i%2)*1.4,0),Vector3(10,2.5+i*.25,4),Color("d0ddda"),7,4)
	var clouds := _end(false)
	var cloud_material := material.duplicate() as StandardMaterial3D
	cloud_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; clouds.material_override = cloud_material
