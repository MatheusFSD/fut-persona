extends Node3D
const GOAL = preload("res://scripts/goal_dimensions.gd")
const GOAL_NET = preload("res://scripts/goal_net.gd")
const DISTRICT = preload("res://scripts/praca_xv.gd")
var game
## Entire ground uses native Godot meshes, materials, lighting and collision.
var rng := RandomNumberGenerator.new()
var chalk: StandardMaterial3D
var rust: StandardMaterial3D
var cream: StandardMaterial3D

func mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = .95
	return m

func box(at: Vector3, dimensions: Vector3, material: Material, solid := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.material_override = material
	node.position = at
	add_child(node)
	if solid:
		var body := StaticBody3D.new()
		body.position = at
		body.collision_layer = 1
		body.collision_mask = 6
		var shape := CollisionShape3D.new()
		var data := BoxShape3D.new()
		data.size = dimensions
		shape.shape = data
		body.add_child(shape)
		add_child(body)
	return node

func bar(a: Vector3, b: Vector3, radius: float, material: Material, solid := false, collision_group: StringName = &"") -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 32 if collision_group == &"goal_frame" else 6
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	add_child(node)
	node.position = (a + b) / 2
	var direction := (b - a).normalized()
	var axis := Vector3.UP.cross(direction)
	if axis.length() > .001: node.quaternion = Quaternion(axis.normalized(), Vector3.UP.angle_to(direction))
	if solid:
		var body := StaticBody3D.new()
		body.transform = node.transform
		body.collision_layer = 1
		if collision_group != &"": body.add_to_group(collision_group)
		var shape := CollisionShape3D.new()
		var data := CylinderShape3D.new()
		data.radius = radius
		data.height = mesh.height
		shape.shape = data
		body.add_child(shape)
		add_child(body)
	return node

func label(text: String, at: Vector3, color: Color, font_size := 72, pixel := .008) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.position = at
	node.font_size = font_size
	node.pixel_size = pixel
	node.modulate = color
	node.outline_size = 0
	node.no_depth_test = false
	add_child(node)
	return node

func _ready() -> void:
	rng.seed = 1988
	chalk = mat(Color("f0e4c4"))
	rust = mat(Color("6c6558"))
	cream = mat(Color("e4d8b9"))
	_environment()
	_pitch()
	for side in [-1, 1]: _goal(side)
	_fence()
	_neighborhood()

func _environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("97acb0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c6d1cf")
	env.ambient_light_energy = .35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff1d9")
	sun.light_energy = .85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 110
	add_child(sun)

func _pitch() -> void:
	box(Vector3(0, -.27, 0), Vector3(90, .5, 85), mat(Color("487238")), true)
	var noise := FastNoiseLite.new()
	noise.seed = 19
	noise.frequency = .12
	var image := Image.create(512, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 512:
			var n := noise.get_noise_2d(x, y) * .5 + .5
			var c := Color("2d6828").lerp(Color("397d2d"), n)
			# Broad mowing bands and subtle fine variation, with no bare dirt patches.
			var world_x := float(x) / 512 * 53 - 26.5
			if int(floor((world_x + 24) / 6)) % 2 == 0: c *= 1.08
			image.set_pixel(x, y, c)
	var lawn := mat(Color.WHITE)
	lawn.albedo_texture = ImageTexture.create_from_image(image)
	lawn.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var surface := box(Vector3(0, -.025, 0), Vector3(53, .06, 32), lawn)
	surface.name = "Gramado"
	for z in [-14.0, 14.0]:
		line(Vector3(-24, .04, z), Vector3(24, .04, z), .09)
	for x in [-24.0, 0.0, 24.0]:
		line(Vector3(x, .04, -14), Vector3(x, .04, 14), .09)
	_circle(Vector3(0, .04, 0), 4, .08)
	_circle(Vector3(0, .043, 0), .18, .13)
	for side in [-1, 1]:
		for z in [-7.0, 7.0]: line(Vector3(side * 24, .04, z), Vector3(side * 17, .04, z), .09)
		line(Vector3(side * 17, .04, -7), Vector3(side * 17, .04, 7), .09)
		for z in [-4.5, 4.5]: line(Vector3(side * 24, .04, z), Vector3(side * 21, .04, z), .08)
		line(Vector3(side * 21, .04, -4.5), Vector3(side * 21, .04, 4.5), .08)
		_circle(Vector3(side * 19.3, .04, 0), .14, .11)
		for z in [-14.0, 14.0]:
			bar(Vector3(side * 24, 0, z), Vector3(side * 24, 1.1, z), .025, cream)
			box(Vector3(side * 24 + side * .21, 1, z), Vector3(.43, .28, .015), mat(Color("e9bb52")))
	_grass_tufts()

func _grass_tufts() -> void:
	# Four tapered blades per tuft, drawn in one MultiMesh instead of thousands of nodes.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in 4:
		var angle := blade * 2.4
		var base := Vector3(cos(angle), 0, sin(angle)) * .055
		var across := Vector3(cos(angle+.7), 0, sin(angle+.7)) * .024
		var tip := base + Vector3(cos(angle)*.065, .15 + blade*.018, sin(angle)*.065)
		for vertex in [base-across, base+across, tip]: surface.add_vertex(vertex)
	surface.generate_normals()
	var blades := surface.commit()
	var material := mat(Color.WHITE)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.backlight_enabled = true
	material.backlight = Color(.18, .24, .08)
	blades.surface_set_material(0, material)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = blades
	multimesh.instance_count = 2600
	var grass_rng := RandomNumberGenerator.new(); grass_rng.seed = 6942
	for i in multimesh.instance_count:
		var at := Vector3.ZERO
		for attempt in 12:
			at = Vector3(grass_rng.randf_range(-26,26), .018, grass_rng.randf_range(-15.7,15.7))
			if absf(at.x) > .17 and absf(absf(at.x)-24) > .17 and absf(absf(at.z)-14) > .17 and absf(Vector2(at.x,at.z).length()-4) > .17: break
		var size := grass_rng.randf_range(.7, 1.2)
		var basis := Basis(Vector3.UP, grass_rng.randf_range(0, TAU)).scaled(Vector3(size, grass_rng.randf_range(.65,1.1),size))
		multimesh.set_instance_transform(i, Transform3D(basis, at))
		multimesh.set_instance_color(i, Color("49852d").lerp(Color("80a43b"), grass_rng.randf()*.6))
	var tufts := MultiMeshInstance3D.new()
	tufts.name = "Graminhas"; tufts.multimesh = multimesh
	tufts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tufts)

func line(a: Vector3, b: Vector3, width: float) -> void:
	var node := box((a + b) / 2, Vector3(width, .012, a.distance_to(b)), chalk)
	node.rotation.y = atan2((b-a).x, (b-a).z)

func _circle(at: Vector3, radius: float, width: float) -> void:
	for i in 64:
		var a := TAU * i / 64
		var b := TAU * (i + 1) / 64
		line(at + Vector3(cos(a), 0, sin(a)) * radius, at + Vector3(cos(b), 0, sin(b)) * radius, width)

func _goal(side: int) -> void:
	var x := side * 24.0
	for z in [-GOAL.POST_Z, GOAL.POST_Z]:
		bar(Vector3(x, 0, z), Vector3(x, GOAL.CROSSBAR_Y, z), GOAL.POST_RADIUS, chalk, true, &"goal_frame")
		bar(Vector3(x, GOAL.CROSSBAR_Y, z), Vector3(x + side * 1.8, 0, z), .035, rust)
	bar(Vector3(x, GOAL.CROSSBAR_Y, -GOAL.POST_Z), Vector3(x, GOAL.CROSSBAR_Y, GOAL.POST_Z), GOAL.POST_RADIUS, chalk, true, &"goal_frame")
	var net = GOAL_NET.new(); net.name = "RedeDireita" if side > 0 else "RedeEsquerda"
	net.game = game; net.position.x = x; net.rotation.y = PI if side < 0 else 0
	add_child(net)
	# The ground cords stay fixed. The three wire panels share a single static mesh.
	for z in [-GOAL.POST_Z, GOAL.POST_Z]:
		bar(Vector3(x,.04,z),Vector3(x+side*1.8,.04,z),.018,mat(Color("dedfcb")))
	# Native collision contains shots inside the net after the goal sensor fires.
	for z in [-(GOAL.POST_Z+.1), GOAL.POST_Z+.1]:
		var body := _invisible_wall(Vector3(x+side*.95,1,z),Vector3(1.9,2,.06))
		body.add_to_group("goal_net_body"); body.set_meta("goal_net",net)
		body.set_meta("net_panel",1 if side*z < 0 else 2)
	var back := _invisible_wall(Vector3(x+side*1.9,1.3,0),Vector3(.08,2.6,GOAL.WIDTH+.32))
	back.add_to_group("goal_net_body"); back.set_meta("goal_net",net); back.set_meta("net_panel",0)

func _invisible_wall(at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 4
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions; collision.shape = shape
	body.add_child(collision); add_child(body)
	return body

func _neighborhood() -> void:
	# Change only the sky background: existing sun/ambient and the lawn keep their lighting.
	for child in get_children():
		if child is WorldEnvironment: child.environment.background_color = Color("a5c5d0")
	var district = DISTRICT.new(); district.game = game; add_child(district)

func _fence() -> void:
	# Four complete sides. Real openings between coarse diamond wires, no alpha texture.
	var metal := mat(Color("304748")); metal.cull_mode = BaseMaterial3D.CULL_DISABLED
	var height := 4.0
	var corners := [Vector3(-27.2,0,-16.6),Vector3(27.2,0,-16.6),Vector3(27.2,0,16.6),Vector3(-27.2,0,16.6)]
	var frames: Array[Transform3D] = []
	for side in 4:
		var start: Vector3 = corners[side]; var finish: Vector3 = corners[(side+1)%4]
		var axis := (finish-start).normalized(); var length := start.distance_to(finish)
		var sections := ceili(length/4.0)
		for i in sections:
			var at := start+axis*(length*i/sections)+Vector3.UP*height*.5
			frames.append(Transform3D(Basis.from_scale(Vector3(.12,height,.12)),at))
		for y in [.18,2.0,height]:
			var dimensions := Vector3(length,.07,.07) if absf(axis.x) > .5 else Vector3(.07,.07,length)
			frames.append(Transform3D(Basis.from_scale(dimensions),(start+finish)*.5+Vector3.UP*y))
		var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for direction in [-1.0,1.0]:
			for i in range(-7,ceili(length/.8)+8):
				var u := i*.8; var du: float = direction*height
				var enter := maxf(0,minf(-u/du,(length-u)/du))
				var leave := minf(1,maxf(-u/du,(length-u)/du))
				if enter >= leave: continue
				var a := start+axis*(u+du*enter)+Vector3.UP*(height*enter)
				var b := start+axis*(u+du*leave)+Vector3.UP*(height*leave)
				var across := (axis*height-Vector3.UP*du).normalized()*.010
				for point in [a-across,b-across,b+across,a-across,b+across,a+across]:
					surface.set_normal(axis.cross(Vector3.UP)); surface.add_vertex(point)
		var mesh := MeshInstance3D.new(); mesh.name = "AlambradoLosangos"+str(side)
		mesh.mesh = surface.commit(); mesh.material_override = metal
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.add_to_group("pitch_fence_mesh"); add_child(mesh)
		var body := StaticBody3D.new(); body.name = "ContencaoAlambrado"+str(side)
		body.position = (start+finish)*.5+Vector3.UP*height*.5
		body.collision_layer = 1; body.collision_mask = 4
		var collider := CollisionShape3D.new(); var shape := BoxShape3D.new()
		shape.size = Vector3(length,height,.12) if absf(axis.x) > .5 else Vector3(.12,height,length)
		collider.shape = shape; body.add_child(collider); body.add_to_group("pitch_fence_body"); add_child(body)
	var multi := MultiMesh.new(); multi.transform_format = MultiMesh.TRANSFORM_3D
	var unit := BoxMesh.new(); unit.size = Vector3.ONE; multi.mesh = unit; multi.instance_count = frames.size()
	for i in frames.size(): multi.set_instance_transform(i,frames[i])
	var structure := MultiMeshInstance3D.new(); structure.name = "PostesETravessasAlambrado"
	structure.multimesh = multi; structure.material_override = metal; structure.add_to_group("pitch_fence_frame"); add_child(structure)
