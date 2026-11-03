extends Node3D
## Cosmetic samples of the real rigid body's path. No forces or predicted arcs.
const TRAIL_SECONDS := .75
const TRAIL_MEMORY := .11
const TRAIL_LENGTH := 2.0
const TRAIL_MIN_SPEED := 16.0
const MAX_POINTS := 16
const MAX_CONTACTS := 6
const CREAM := Color("fff6e7")
const CYAN := Color("35edf0")
const GOLD := Color("ffe049")
const PINK := Color("ff287e")
const PRIORITY := {"body":0,"fence":0,"trap":1,"pass":1,"shot":2,"tackle":2,"power":3,"save":3,"post":4,"goal":4}
var game
var points: Array[Dictionary] = []
var contacts: Array[Dictionary] = []
var trail_remaining := 0.0
var trail_age := 0.0
var trail_mesh: ImmediateMesh
var trail_node: MeshInstance3D
var trail_material: StandardMaterial3D
var contact_serial := 0

func _ready() -> void:
	trail_mesh = ImmediateMesh.new()
	trail_material = StandardMaterial3D.new()
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	trail_material.vertex_color_use_as_albedo = true
	trail_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	trail_node = MeshInstance3D.new(); trail_node.name = "RastroDoChute"
	trail_node.mesh = trail_mesh; trail_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trail_node); trail_node.hide()

func reset() -> void:
	trail_remaining = 0; trail_age = 0; points.clear(); contacts.clear()
	if trail_mesh != null: trail_mesh.clear_surfaces(); trail_node.hide()

func start_trail() -> void:
	if game.phase != "playing" or game.ball.freeze: return
	points.clear(); trail_remaining = TRAIL_SECONDS; trail_age = 0
	points.append({"position":game.ball.global_position,"age":0.0})

func stop_trail(clear := false) -> void:
	trail_remaining = 0
	if clear:
		points.clear()
		if trail_mesh != null: trail_mesh.clear_surfaces(); trail_node.hide()

func contact(kind: String, world: Vector3, strength := 1.0) -> bool:
	if game.phase not in ["playing","foul","out","celebrate"] or not PRIORITY.has(kind): return false
	# One mark for the same physical contact, even when collision and trap both fire.
	for active: Dictionary in contacts:
		if active.age < .055 and active.position.distance_to(world) < .55:
			if PRIORITY[kind] > PRIORITY[active.kind]:
				active.kind = kind; active.strength = maxf(active.strength,strength)
			return false
	if contacts.size() >= MAX_CONTACTS: contacts.pop_front()
	contacts.append({"kind":kind,"position":world,"age":0.0,"duration":.22 if kind in ["power","post","goal"] else .16,"strength":clampf(strength,.2,1.0),"serial":contact_serial})
	contact_serial += 1
	return true

func _physics_process(delta: float) -> void:
	if game == null or game.phase == "paused": return
	if game.phase not in ["playing","foul","out","celebrate"]: reset(); return
	for i in range(contacts.size()-1,-1,-1):
		contacts[i].age += delta
		if contacts[i].age >= contacts[i].duration: contacts.remove_at(i)
	for point: Dictionary in points: point.age += delta
	while not points.is_empty() and points[0].age > TRAIL_MEMORY: points.pop_front()
	if trail_remaining > 0:
		trail_remaining = maxf(0,trail_remaining-delta); trail_age += delta
		if game.ball.freeze or game.carrier != null or (trail_age > .035 and game.ball.linear_velocity.length() < TRAIL_MIN_SPEED):
			stop_trail()
		else:
			var at: Vector3 = game.ball.global_position
			var distance: float = points.back().position.distance_to(at) if not points.is_empty() else 0.0
			if distance > 3: stop_trail(true) # Never bridge a reposition/teleport.
			elif points.is_empty() or distance > .025: points.append({"position":at,"age":0.0})
	while points.size() > MAX_POINTS: points.pop_front()
	var length := 0.0
	for i in range(points.size()-1,0,-1):
		length += points[i].position.distance_to(points[i-1].position)
		if length > TRAIL_LENGTH:
			for j in i: points.pop_front()
			break
	_render_trail()

func _render_trail() -> void:
	trail_mesh.clear_surfaces(); trail_node.visible = points.size() >= 2
	if not trail_node.visible: return
	trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,trail_material)
	for layer in 2:
		for i in range(1,points.size()):
			var a: Vector3 = points[i-1].position; var b: Vector3 = points[i].position
			var axis := (b-a).normalized()
			var across := axis.cross((game.camera.global_position-(a+b)*.5).normalized()).normalized()
			if across.length_squared() < .1: across = game.camera.global_transform.basis.x
			var ratio_a := float(i-1)/(points.size()-1); var ratio_b := float(i)/(points.size()-1)
			var width := .13 if layer == 0 else .055
			var ca := Color(CYAN if layer == 0 else CREAM,(.48 if layer == 0 else .9)*clampf(1-float(points[i-1].age)/TRAIL_MEMORY,0,1))
			var cb := Color(CYAN if layer == 0 else CREAM,(.48 if layer == 0 else .9)*clampf(1-float(points[i].age)/TRAIL_MEMORY,0,1))
			var vertices := [a-across*width*ratio_a,b-across*width*ratio_b,b+across*width*ratio_b,a-across*width*ratio_a,b+across*width*ratio_b,a+across*width*ratio_a]
			for j in 6:
				trail_mesh.surface_set_color(ca if j in [0,3,5] else cb)
				trail_mesh.surface_add_vertex(to_local(vertices[j]))
	trail_mesh.surface_end()
