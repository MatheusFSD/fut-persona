extends SceneTree
var game
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL "+label)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false); game.muted = true; game.ball.freeze = true
	for p in game.players: p.set_physics_process(false)
	var districts := get_nodes_in_group("rio_district")
	check(districts.size() == 1,"one procedural fictional Rio district")
	var district = districts[0]; district.set_process(false)
	check(district.find_children("*","CollisionObject3D",true,false).is_empty(),"all new scenery is visual and adds no gameplay collision")
	var meshes := district.find_children("*","MeshInstance3D",true,false)
	check(meshes.size() <= 22 and int(district.get_meta("triangles")) < 32000,"static city stays within 22 mesh batches / 32k triangles")
	var finite := true; var clear_pitch := true; var triangles := 0
	for node: MeshInstance3D in meshes:
		check(node.mesh is ArrayMesh and node.mesh.get_surface_count() == 1,"single native mesh surface: "+str(node.name))
		var arrays: Array = node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]; var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		triangles += indices.size()/3
		for vertex in vertices: finite = finite and vertex.is_finite()
		for i in range(0,indices.size(),3):
			var a: Vector3 = node.global_transform*vertices[indices[i]]; var b: Vector3 = node.global_transform*vertices[indices[i+1]]; var c: Vector3 = node.global_transform*vertices[indices[i+2]]
			var low := a.min(b).min(c); var high := a.max(b).max(c)
			if low.x < 27.3 and high.x > -27.3 and low.z < 16.7 and high.z > -16.7: clear_pitch = false
	check(finite,"all generated architecture and terrain vertices are finite")
	check(clear_pitch,"no new scenery triangles overlap field or cage footprint")
	check(triangles == int(district.get_meta("triangles")),"indexed native mesh triangle count matches construction budget")
	check(get_nodes_in_group("rio_landmark").size() == 4,"Paço, arch, fountain and ferry terminal are modeled")
	for group in ["rio_water","rio_ferry","rio_beach","rio_suburb","rio_promenade","rio_crowd","rio_islands","rio_sky"]:
		check(not get_nodes_in_group(group).is_empty(),"fictional city includes "+group)
	var ground: MeshInstance3D = get_nodes_in_group("rio_plaza")[0]
	check(ground.mesh.get_aabb().end.x < 58.3,"stone square stops at quay and cannot bury ferry/water")
	var ferry: MeshInstance3D = get_nodes_in_group("rio_ferry")[0]
	check(ferry.mesh.get_aabb().position.x > 58.3,"ferry hull sits over bay rather than paved ground")
	var lawn: MeshInstance3D = game.find_child("Gramado",true,false)
	check(lawn.mesh.size == Vector3(53,.06,32) and lawn.position == Vector3(0,-.025,0),"existing lawn size and transform preserved")
	check(lawn.material_override.albedo_texture.get_size() == Vector2(512,256),"original procedural lawn texture retained")
	check(game.find_child("Graminhas",true,false).multimesh.instance_count == 2600,"all original 2600 grass tufts retained")
	check(get_nodes_in_group("pitch_fence_mesh").size() == 4 and get_nodes_in_group("pitch_fence_body").size() == 4,"all four original cage panels and ball walls retained")
	check(get_nodes_in_group("pitch_fence_frame")[0].multimesh.instance_count == 58,"same original posts and rails retained")
	check(get_nodes_in_group("goal_net_visual").size() == 2 and get_nodes_in_group("goal_frame").size() == 6,"goal frames and animated goal nets retained")
	var sun: DirectionalLight3D = game.find_children("*","DirectionalLight3D",true,false)[0]
	var env: WorldEnvironment = game.find_children("*","WorldEnvironment",true,false)[0]
	check(is_equal_approx(sun.light_energy,.85) and is_equal_approx(env.environment.ambient_light_energy,.35),"sun and ambient energy remain unchanged for existing grass")
	var clock: float = district.sea_time
	game.phase = "playing"; district._process(.1)
	check(is_equal_approx(district.sea_time,clock+.1),"subtle bay shader clock advances with game time")
	game.phase = "paused"; district._process(1)
	check(is_equal_approx(district.sea_time,clock+.1),"pause freezes water uniforms")
	game.phase = "playing"; district._process(.03)
	check(is_equal_approx(district.sea_time,clock+.13) and is_equal_approx(district.water_material.get_shader_parameter("sea_time"),clock+.13),"slow motion can drive bay with scaled delta")
	game.queue_free(); await process_frame; await process_frame
	print("PRACA_XV ",checks-failures.size(),"/",checks," passed; triangles=",triangles," meshes=",meshes.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
