extends "res://tests/body_types.gd"
const PROFILE = preload("res://scripts/player_data.gd")
const PLAYER = preload("res://scripts/footballer.gd")

func bounds(points: PackedVector3Array) -> AABB:
	var result := AABB(points[0],Vector3.ZERO)
	for point in points: result = result.expand(point)
	return result

func head_vertices(p) -> PackedInt32Array:
	var node := mesh_of(p); var skeleton := skeleton_of(p)
	var arrays := node.mesh.surface_get_arrays(0)
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var head_bind := -1
	for bind in node.skin.get_bind_count():
		var bone := node.skin.get_bind_bone(bind)
		if bone < 0: bone = skeleton.find_bone(node.skin.get_bind_name(bind))
		if skeleton.get_bone_name(bone) == "Head": head_bind = bind; break
	var result := PackedInt32Array()
	for i in bones.size()/4:
		var head_weight := 0.0
		for slot in 4:
			if bones[i*4+slot] == head_bind: head_weight += weights[i*4+slot]
		if head_weight > .98: result.append(i)
	return result

func run() -> void:
	check(PROFILE.BODY_KEYS == ["normal","magro","parrudo"] and BODIES.NAMES.size() == 3,"only three selectable body builds")
	for height in [1.2,1.55,1.78,2,2.3]: check(PROFILE.valid_height(height),"valid height: "+str(height))
	for height in [0,-1,1.19,2.31,INF,NAN,true,"1.80",null]: check(not PROFILE.valid_height(height),"invalid height rejected: "+str(height))
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/match_roster.json"))
	var record: Dictionary = document.jogadores[1].duplicate(true)
	record.tipo_corpo = "normal"; record.altura = 1.65
	check(is_equal_approx(PROFILE.from_dictionary(record).altura,1.65) and PROFILE.from_dictionary(record).tipo_corpo == 0,"short normal player accepted")
	record.tipo_corpo = "parrudo"; record.altura = 1.95
	check(is_equal_approx(PROFILE.from_dictionary(record).altura,1.95) and PROFILE.from_dictionary(record).tipo_corpo == 2,"tall stocky player accepted")
	for legacy in ["baixo_magro","baixo_parrudo",3,4]:
		record.tipo_corpo = legacy; record.erase("altura")
		var migrated := PROFILE.from_dictionary(record)
		check(migrated.tipo_corpo in [1,2] and is_equal_approx(migrated.altura,1.53),"old short build migrates: "+str(legacy))
		record.altura = 1.85
		check(is_equal_approx(PROFILE.from_dictionary(record).altura,1.85),"explicit height overrides legacy short default")
	record.tipo_corpo = "normal"; record.erase("altura")
	check(PROFILE.from_dictionary(record).altura == PROFILE.DEFAULT_HEIGHT,"old normal record receives default height")
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.hud.hide(); game.ball.freeze = true
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	for side in 2:
		var reference_head := Vector3.ZERO
		var original_mesh: Mesh = mesh_of(game.players[side*5]).mesh
		var shared_libraries: Dictionary = {}
		for meters in [1.20,1.55,1.78,2.00,2.30]:
			var depths: Array[float] = []
			for body in 3:
				var profile: Resource = game.players[side*5+1].profile.duplicate(true)
				profile.tipo_corpo = body; profile.altura = meters
				var p := PLAYER.new(); p.setup(game,side,1,Vector3(32,0,22),profile,game.team_definitions[side]); game.add_child(p)
				p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0; p.avatar.rotation = Vector3.ZERO
				var label: String = p.team_definition.modelo+"/"+BODIES.NAMES[body]+"/"+str(meters)
				var skeleton := skeleton_of(p); skeleton.reset_bone_poses()
				var points := sampled_vertices(p); var box := bounds(points)
				check(absf(box.size.y-meters) < .002 and box.position.y > -.01 and box.position.y < .03,"actual rest height and sole plane: "+label)
				check(mesh_of(p).mesh == original_mesh and p.avatar.scale == Vector3.ONE and skeleton.get_bone_count() == 65,"same mesh, unit object scale and skeleton: "+label)
				var head := PackedVector3Array()
				for index in head_vertices(p): head.append(points[index])
				var head_size := bounds(head).size
				if reference_head == Vector3.ZERO: reference_head = head_size
				check(head.size() > 5 and head_size.distance_to(reference_head) < .01,"head size stays stable across heights and builds: "+label)
				var library := p.animator.get_animation_library("football")
				if body == 0: shared_libraries[meters] = library
				check(library == shared_libraries[meters],"same-height builds share retargeted clips: "+label)
				var chest := PackedVector3Array()
				var original: PackedVector3Array = original_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				for i in original.size():
					if original[i].y > 1.10 and original[i].y < 1.35 and absf(original[i].x) < .16: chest.append(points[i])
				depths.append(bounds(chest).size.z)
				var safe := true
				for clip in POSES:
					p.animator.play(clip); p.animator.seek(.19,true); p.animator.pause()
					var pelvis := skeleton.get_bone_global_pose(skeleton.find_bone("pelvis")).origin
					for point in sampled_vertices(p): safe = safe and point.is_finite() and point.distance_to(pelvis) < meters*1.2
				check(safe,"eleven animation poses stay attached at all tested heights: "+label)
				p.queue_free()
			check(depths[1] < depths[0] and depths[0] < depths[2],"slim/normal/stocky volume ordering independent of height")
	print("PLAYER_HEIGHTS ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
