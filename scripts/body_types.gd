extends RefCounted
## Three builds and independent metric height, using only existing mesh morphs.
const NAMES := ["Normal", "Magro", "Parrudo"]
const RADII := [.30, .27, .36]
const SHORT_SCALE := .84
static var retargeted: Dictionary = {}
static var height_metrics: Dictionary = {}

static func morph_weights(body_type: int, height: float) -> Dictionary:
	# Short morphs encode bone shortening while preserving head size. Their
	# difference from the full-height morph also works continuously for tall bodies.
	var shortened := (1.0-height)/(1.0-SHORT_SCALE)
	if body_type == 0: return {"Magro":-SHORT_SCALE*shortened,"BaixoMagro":shortened}
	var build := "Magro" if body_type == 1 else "Parrudo"
	return {build:height-SHORT_SCALE*shortened,"Baixo"+build:shortened}

static func rest_vertices(node: MeshInstance3D, weights: Dictionary) -> PackedVector3Array:
	var mesh := node.mesh as ArrayMesh
	var base: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var vertices := base.duplicate()
	var shapes := mesh.surface_get_blend_shape_arrays(0)
	for shape in shapes.size():
		var weight: float = weights.get(mesh.get_blend_shape_name(shape),0.0)
		if is_zero_approx(weight): continue
		var positions: PackedVector3Array = shapes[shape][Mesh.ARRAY_VERTEX]
		for i in vertices.size():
			var delta := positions[i] if mesh.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_RELATIVE else positions[i]-base[i]
			vertices[i] += delta*weight
	return vertices

static func height_factor(model: Node3D, meters: float) -> float:
	var node: MeshInstance3D = model.find_children("*","MeshInstance3D",true,false)[0]
	var key := node.mesh.get_instance_id()
	if not height_metrics.has(key):
		# Builds preserve the head and soles, so one calibration serves all three.
		var full := rest_vertices(node,morph_weights(0,1.0))
		var short_points := rest_vertices(node,morph_weights(0,SHORT_SCALE))
		var full_min := INF; var full_max := -INF; var short_min := INF; var short_max := -INF
		for point in full: full_min = minf(full_min,point.y); full_max = maxf(full_max,point.y)
		for point in short_points: short_min = minf(short_min,point.y); short_max = maxf(short_max,point.y)
		var slope := ((full_max-full_min)-(short_max-short_min))/(1.0-SHORT_SCALE)
		height_metrics[key] = Vector2(slope,full_max-full_min-slope)
	var metric: Vector2 = height_metrics[key]
	return (meters-metric.y)/metric.x

static func apply_model(model: Node3D, body_type: int, meters := 1.78) -> float:
	var height := height_factor(model,meters)
	var weights := morph_weights(body_type,height)
	model.set_meta("body_type", NAMES[body_type])
	model.set_meta("height_meters",meters)
	for node: Skeleton3D in model.find_children("*","Skeleton3D",true,false):
		if is_equal_approx(height, 1.0): continue
		# Same hierarchy, names and 65 bones; adapt rest translations to the height.
		for bone in node.get_bone_count():
			var rest := node.get_bone_rest(bone)
			rest.origin *= height
			node.set_bone_rest(bone,rest)
			node.set_bone_pose_position(bone,node.get_bone_pose_position(bone)*height)
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for shape in mesh.mesh.get_blend_shape_count():
			mesh.set_blend_shape_value(shape,weights.get(mesh.mesh.get_blend_shape_name(shape),0.0))
		mesh.extra_cull_margin = .8
		if not is_equal_approx(height,1.0) and mesh.skin != null:
			# Per-instance inverse binds keep teammates of other heights unchanged.
			mesh.skin = mesh.skin.duplicate(true) as Skin
			for bind in mesh.skin.get_bind_count():
				var pose := mesh.skin.get_bind_pose(bind)
				pose.origin *= height
				mesh.skin.set_bind_pose(bind,pose)
	for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):
		for key in player.get_animation_library_list():
			var source := player.get_animation_library(key)
			if not is_equal_approx(height,1.0):
				player.remove_animation_library(key)
				player.add_animation_library(key,animation_library(source,height))
	return height

static func animation_library(source: AnimationLibrary, height: float) -> AnimationLibrary:
	if is_equal_approx(height,1.0): return source
	var key := str(source.get_instance_id())+"/"+str(height)
	if retargeted.has(key): return retargeted[key]
	var library := source.duplicate(true) as AnimationLibrary
	for label in library.get_animation_list():
		var animation := library.get_animation(label)
		for track in animation.get_track_count():
			if animation.track_get_type(track) != Animation.TYPE_POSITION_3D: continue
			for frame in animation.track_get_key_count(track):
				var position: Vector3 = animation.track_get_key_value(track,frame)
				animation.track_set_key_value(track,frame,position*height)
	retargeted[key] = library
	return library
