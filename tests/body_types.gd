extends SceneTree
const BODIES = preload("res://scripts/body_types.gd")
const POSES := ["football/Idle_Loop","football/Walk_Loop","football/Jog_Fwd_Loop","football/Sprint_Loop","custom/shot","custom/pass","custom/tackle","football/Slide_Start","football/Slide_Loop","football/Slide_Exit","football/Yes"]
var game
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("PASS ",label)
	else: failures.append(label); push_error("FAIL "+label)

func skeleton_of(p) -> Skeleton3D:
	return p.avatar.find_children("*","Skeleton3D",true,false)[0]

func mesh_of(p) -> MeshInstance3D:
	return p.avatar.find_children("*","MeshInstance3D",true,false)[0]

func sampled_vertices(p) -> PackedVector3Array:
	var node := mesh_of(p)
	var mesh := node.mesh as ArrayMesh
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX].duplicate()
	var original := vertices.duplicate()
	var shapes := mesh.surface_get_blend_shape_arrays(0)
	for shape in shapes.size():
		var weight := node.get_blend_shape_value(shape)
		if is_zero_approx(weight): continue
		var positions: PackedVector3Array = shapes[shape][Mesh.ARRAY_VERTEX]
		for i in vertices.size():
			vertices[i] += (positions[i] if mesh.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_RELATIVE else positions[i]-original[i])*weight
	var skeleton := skeleton_of(p)
	skeleton.force_update_all_bone_transforms()
	var bind_transforms: Array[Transform3D] = []
	for bind in node.skin.get_bind_count():
		var bone := node.skin.get_bind_bone(bind)
		if bone < 0: bone = skeleton.find_bone(node.skin.get_bind_name(bind))
		bind_transforms.append(skeleton.get_bone_global_pose(bone)*node.skin.get_bind_pose(bind))
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var result := PackedVector3Array(); result.resize(vertices.size())
	for vertex in vertices.size():
		var point := Vector3.ZERO
		for slot in 4:
			var at := vertex*4+slot
			if weights[at] > 0: point += (bind_transforms[bones[at]]*vertices[vertex])*weights[at]
		result[vertex] = point
	return result

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.hud.hide(); game.ball.freeze = true
	for p in game.players:
		p.set_physics_process(false); p.avatar.rotation = Vector3.ZERO
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/body_types_manifest.json"))
	for team in 2:
		var types: Array = []
		for p in game.players:
			if p.team == team: types.append(p.body_type)
		check(types == [0,1,2,1,2],"three builds independent of height in team "+str(team))
		var key := "hero" if team == 0 else "enemy_a"
		var original: Dictionary = manifest[key].invariants
		check(original.values().all(func(value): return value == true),"original vertices, indices, UVs, skin weights and bones preserved: "+key)
	for p in game.players:
		var label: String = p.team_definition.nome+"/"+BODIES.NAMES[p.body_type]+"/"+str(p.profile.altura)
		var base = game.players[p.team*5]
		var ratio: float = p.body_height/base.body_height
		var skeleton := skeleton_of(p); var base_skeleton := skeleton_of(base)
		var node := mesh_of(p); var base_mesh := mesh_of(base)
		check(p.avatar.scale.is_equal_approx(Vector3.ONE) and node.scale.is_equal_approx(Vector3.ONE),"vertex deformation uses no object scale: "+label)
		check(node.mesh.surface_get_array_len(0) == int(manifest["hero" if p.team == 0 else "enemy_a"].vertices) and node.mesh.surface_get_array_index_len(0)/3 == int(manifest["hero" if p.team == 0 else "enemy_a"].triangles),"same vertex and triangle count: "+label)
		skeleton.reset_bone_poses()
		var rest_points := sampled_vertices(p)
		var floor_y := INF; var top_y := -INF
		for point in rest_points: floor_y = minf(floor_y,point.y); top_y = maxf(top_y,point.y)
		check(node.mesh.get_blend_shape_count() == 4 and absf(top_y-floor_y-p.profile.altura) < .002,"rest mesh matches declared metric height using existing morphs: "+label)
		var rig_ok: bool = skeleton.get_bone_count() == 65 and node.skin.get_bind_count() == base_mesh.skin.get_bind_count()
		for bone in skeleton.get_bone_count():
			rig_ok = rig_ok and skeleton.get_bone_name(bone) == base_skeleton.get_bone_name(bone) and skeleton.get_bone_parent(bone) == base_skeleton.get_bone_parent(bone)
			var rest := skeleton.get_bone_rest(bone); var base_rest := base_skeleton.get_bone_rest(bone)
			rig_ok = rig_ok and rest.basis.is_equal_approx(base_rest.basis) and rest.origin.distance_to(base_rest.origin*ratio) < .0001
		for bind in node.skin.get_bind_count():
			rig_ok = rig_ok and node.skin.get_bind_pose(bind).origin.distance_to(base_mesh.skin.get_bind_pose(bind).origin*ratio) < .0001
		check(rig_ok,"same skeleton, joint orientations and matching inverse binds: "+label)
		var animation_ok := true
		var geometry_ok := true
		for clip in POSES:
			for actor in [base,p]:
				actor.animator.play(clip); actor.animator.seek(minf(.19,actor.animator.current_animation_length*.4),true); actor.animator.pause()
			skeleton.force_update_all_bone_transforms(); base_skeleton.force_update_all_bone_transforms()
			for bone in skeleton.get_bone_count():
				var transform := skeleton.get_bone_global_pose(bone); var reference := base_skeleton.get_bone_global_pose(bone)
				animation_ok = animation_ok and transform.origin.distance_to(reference.origin*ratio) < .001 and transform.basis.is_equal_approx(reference.basis)
			var points := sampled_vertices(p)
			var pelvis := skeleton.get_bone_global_pose(skeleton.find_bone("pelvis")).origin
			for point in points: geometry_ok = geometry_ok and point.is_finite() and point.distance_to(pelvis) < p.profile.altura
		check(animation_ok,"retargeted positions and original rotations across eleven football poses: "+label)
		check(geometry_ok,"skinned vertices remain finite and close to the rig across all poses: "+label)
		p.animator.play("football/Idle_Loop"); p.animator.seek(.25,true); p.animator.pause()
		var standing := sampled_vertices(p)
		var minimum := INF; var maximum := -INF
		for point in standing: minimum = minf(minimum,point.y); maximum = maxf(maximum,point.y)
		print("BODY_BOUNDS ",label," floor=",minimum," top=",maximum)
		check(minimum > -.06 and minimum < .1 and absf((maximum-minimum)-p.profile.altura) < .1,"feet contact and standing height: "+label)
		var capsule: CapsuleShape3D = p.get_child(0).shape
		check(is_equal_approx(capsule.height,p.profile.altura*.94) and p.number_label.position.y > maximum,"existing collider and number follow body dimensions: "+label)
	print("BODY_TYPES ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
