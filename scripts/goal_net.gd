extends Node3D
const GOAL = preload("res://scripts/goal_dimensions.gd")
## Shared static wire geometry; only four small impact records are updated at runtime.
const NET_SHADER = preload("res://assets/shaders/goal_net.gdshader")
const MAX_HITS := 4
const HIT_SECONDS := 1.7
const SPEED_TO_AMPLITUDE := .055
const MAX_AMPLITUDE := .95
const IMPACT_RADIUS := 1.35
const SEGMENT_LENGTH := .20
const RADIUS := .012
static var shared_mesh: ArrayMesh
var game
var material: ShaderMaterial
var net_mesh: MeshInstance3D
var hits: Array[Dictionary] = []
var impact_serial := 0
var wire_counts := [27,20,20]

func _ready() -> void:
	add_to_group("goal_net_visual")
	material = ShaderMaterial.new(); material.shader = NET_SHADER
	if shared_mesh == null: shared_mesh = _build_mesh()
	net_mesh = MeshInstance3D.new(); net_mesh.name = "FiosDaRede"
	net_mesh.mesh = shared_mesh; net_mesh.material_override = material
	net_mesh.extra_cull_margin = 1; net_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(net_mesh); reset()

func reset() -> void:
	hits.clear(); set_physics_process(false)
	if material != null: material.set_shader_parameter("impact_count",0)

func impact(world: Vector3, speed: float, panel: int) -> bool:
	if game == null or game.phase not in ["playing","out","celebrate"] or speed < 1.2: return false
	var at := contact_point(to_local(world),panel)
	for hit: Dictionary in hits:
		if hit.panel == panel and hit.age < .12 and hit.position.distance_to(at) < .35: return false
	if hits.size() >= MAX_HITS: hits.pop_front()
	hits.append({"position":at,"age":0.0,"panel":panel,"amplitude":clampf(speed*SPEED_TO_AMPLITUDE,.08,MAX_AMPLITUDE)})
	impact_serial += 1; _sync(); set_physics_process(true)
	return true

func contact_point(at: Vector3, panel: int) -> Vector3:
	if panel == 0:
		var top := Vector3(0,GOAL.CROSSBAR_Y,0); var diagonal := Vector3(1.8,-2.44,0)
		var t := clampf((at-top).dot(diagonal)/diagonal.length_squared(),.015,.985)
		var projected := top+diagonal*t; projected.z = clampf(at.z,-(GOAL.POST_Z-.05),(GOAL.POST_Z-.05))
		return projected
	var depth := clampf(at.x,.02,1.78)
	return Vector3(depth,clampf(at.y,.04,maxf(.04,GOAL.CROSSBAR_Y-depth*2.44/1.8-.015)),-GOAL.POST_Z if panel == 1 else GOAL.POST_Z)

func _physics_process(delta: float) -> void:
	if game == null or game.phase == "paused": return
	if game.phase not in ["playing","out","celebrate"]: reset(); return
	for i in range(hits.size()-1,-1,-1):
		hits[i].age += delta
		if hits[i].age >= HIT_SECONDS: hits.remove_at(i)
	if hits.is_empty(): reset()
	else: _sync()

func _sync() -> void:
	var positions := PackedVector4Array(); var pulses := PackedVector4Array()
	positions.resize(MAX_HITS); pulses.resize(MAX_HITS)
	for i in hits.size():
		var hit: Dictionary = hits[i]; var p: Vector3 = hit.position
		positions[i] = Vector4(p.x,p.y,p.z,hit.age)
		pulses[i] = Vector4(hit.amplitude,hit.panel*.5,IMPACT_RADIUS,0)
	material.set_shader_parameter("impacts",positions)
	material.set_shader_parameter("pulses",pulses)
	material.set_shader_parameter("impact_count",hits.size())

static func pin_weight(p: Vector3, panel: int) -> float:
	if panel == 0:
		var v := clampf(p.x/1.8,0,1)
		var edge := minf(minf(p.z+GOAL.POST_Z,GOAL.POST_Z-p.z),minf(v,1-v)*3.032)
		return smoothstep(0,.23,maxf(edge,0))
	var diagonal_distance := (GOAL.CROSSBAR_Y-p.y-p.x*2.44/1.8)/1.684
	var edge := minf(minf(p.x,p.y-.035),diagonal_distance)
	return smoothstep(0,.20,maxf(edge,0))

func _wire(surface: SurfaceTool, a: Vector3, b: Vector3, panel: int) -> void:
	var length := a.distance_to(b)
	if length < .001: return
	var along := (b-a).normalized()
	var normal := Vector3.RIGHT if panel == 0 else (Vector3.FORWARD if panel == 1 else Vector3.BACK)
	var across := along.cross(normal).normalized()
	var sections := maxi(1,ceili(length/SEGMENT_LENGTH))
	# Two crossing opaque strips keep every strand visible from either side.
	for i in sections:
		var p := a.lerp(b,float(i)/sections); var q := a.lerp(b,float(i+1)/sections)
		for axis in [across,normal]:
			var face_normal: Vector3 = along.cross(axis).normalized()
			for corner in [0,1,2,0,2,3]:
				var center: Vector3 = p if corner in [0,3] else q
				var sign_side := -1 if corner in [0,1] else 1
				surface.set_normal(face_normal)
				surface.set_color(Color(pin_weight(center,panel),(normal.x+1)*.5,(normal.z+1)*.5,panel*.5))
				surface.add_vertex(center+axis*RADIUS*sign_side)

func _build_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 18:
		var z := lerpf(-GOAL.POST_Z,GOAL.POST_Z,i/17.0)
		_wire(surface,Vector3(0,GOAL.CROSSBAR_Y,z),Vector3(1.8,.06,z),0)
	for i in 9:
		var t := i/8.0
		_wire(surface,Vector3(1.8*t,GOAL.CROSSBAR_Y*(1-t)+.06*t,-GOAL.POST_Z),Vector3(1.8*t,GOAL.CROSSBAR_Y*(1-t)+.06*t,GOAL.POST_Z),0)
	for panel in [1,2]:
		var z := -GOAL.POST_Z if panel == 1 else GOAL.POST_Z
		for i in range(1,10):
			var d := 1.8*i/10.0
			_wire(surface,Vector3(d,.035,z),Vector3(d,GOAL.CROSSBAR_Y-d*2.44/1.8,z),panel)
		for i in range(1,12):
			var h := GOAL.CROSSBAR_Y*i/12.0; var d := 1.8*(GOAL.CROSSBAR_Y-h)/2.44
			_wire(surface,Vector3(0,h,z),Vector3(d,h,z),panel)
	return surface.commit()
