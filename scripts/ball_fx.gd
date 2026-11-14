extends Node3D
## Cosmetic samples of the real rigid body's path. No forces or predicted arcs.
const TRAIL_SECONDS := .75
const TRAIL_MEMORY := .11
const TRAIL_LENGTH := 2.0
const TRAIL_MIN_SPEED := 16.0
const MAX_POINTS := 16
const MAX_CONTACTS := 6
# Squash comes from the velocity change of one step, so every real hit counts.
const SQUASH_MAX := .34
const SQUASH_MIN_KICK := 3.0
const SQUASH_MIN_KICK_CARRIED := 8.0
const SQUASH_FULL_KICK := 26.0
const SQUASH_SPRING := 320.0
const SQUASH_DAMPING := 18.0
const STRETCH_MAX := .16
const STRETCH_MIN_SPEED := 12.0
const STRETCH_FULL_SPEED := 30.0
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
var last_velocity := Vector3.ZERO
var resuming := false
var squash := 0.0
var squash_speed := 0.0
var squash_axis := Vector3.UP
var stretch := 0.0
var deformed := false

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
	squash = 0; squash_speed = 0; stretch = 0
	if game.ball != null: last_velocity = game.ball.linear_velocity
	if deformed: game.ball_visual.transform = Transform3D.IDENTITY; deformed = false

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
	if game == null: return
	if game.phase == "paused": resuming = true; return
	if game.phase not in ["playing","foul","out","celebrate"]: reset(); return
	_update_deformation(delta)
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

func _update_deformation(delta: float) -> void:
	var ball = game.ball
	var velocity: Vector3 = ball.linear_velocity
	# Repositioning a frozen ball or leaving the pause is not a physical hit.
	if not ball.freeze and not resuming:
		var kick := velocity-last_velocity
		# Square root: one step only sees part of a bounce, so soft hits still read.
		var amount := sqrt(clampf(kick.length()/SQUASH_FULL_KICK,0,1))*SQUASH_MAX
		# Dribbling forces keep nudging a carried ball; only a real hit should show.
		var minimum := SQUASH_MIN_KICK_CARRIED if game.carrier != null else SQUASH_MIN_KICK
		if kick.length() >= minimum and amount > squash:
			squash = amount; squash_speed = 0; squash_axis = kick.normalized()
	last_velocity = velocity; resuming = false
	var step := minf(delta,1.0/30)
	squash_speed += (-SQUASH_SPRING*squash-SQUASH_DAMPING*squash_speed)*step
	squash += squash_speed*step
	var target := 0.0
	if game.carrier == null and not ball.freeze:
		target = clampf(inverse_lerp(STRETCH_MIN_SPEED,STRETCH_FULL_SPEED,velocity.length()),0,1)*STRETCH_MAX
	stretch = lerpf(stretch,target,1-exp(-step*30))
	if absf(squash) < .002 and absf(squash_speed) < .05 and stretch < .002:
		squash = 0; squash_speed = 0; stretch = 0
		if deformed: game.ball_visual.transform = Transform3D.IDENTITY; deformed = false
		return
	# World-axis deformation over the body's rotation keeps the rolling pattern.
	var world := _axis_scale(squash_axis,1-squash)
	if stretch > 0 and velocity.length_squared() > .01: world = world*_axis_scale(velocity.normalized(),1+stretch)
	var body: Basis = ball.global_transform.basis.orthonormalized()
	# The side that took the hit stays where it is instead of lifting off the surface.
	var shift: Vector3 = -squash_axis*maxf(squash,0)*game.BALL_RADIUS
	game.ball_visual.transform = Transform3D(body.inverse()*world*body,body.inverse()*shift)
	deformed = true

func _axis_scale(axis: Vector3, along: float) -> Basis:
	# Same volume: what shrinks along the axis grows around it.
	var around := 1.0/sqrt(maxf(along,.01))
	var result := Basis.IDENTITY
	for i in 3:
		var unit := Vector3.ZERO; unit[i] = 1
		result[i] = unit*around+axis*axis.dot(unit)*(along-around)
	return result

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
