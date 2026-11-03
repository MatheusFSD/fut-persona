extends SceneTree
func _initialize() -> void:
	var document := GLTFDocument.new(); var state := GLTFState.new()
	var error := document.append_from_file(ProjectSettings.globalize_path("res://tools/source/kicks_authored.glb"),state)
	if error != OK: push_error("Cannot load Blender kick export"); quit(1); return
	var scene := document.generate_scene(state)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/kick_animation_manifest.json"))
	var players := scene.find_children("*","AnimationPlayer",true,false)
	var library := AnimationLibrary.new()
	for player: AnimationPlayer in players:
		for clip in player.get_animation_list():
			print("BLENDER_CLIP ",clip," length=",player.get_animation(clip).length)
			if clip not in ["Kick_Medium","Kick_Strong","Idle_Loop"]: continue
			var animation := player.get_animation(clip).duplicate(true) as Animation
			animation.loop_mode = Animation.LOOP_NONE
			for info: Dictionary in manifest.clips:
				if info.name == clip: animation.set_meta("contact_seconds",float(info.contact))
			for i in range(animation.get_track_count()-1,-1,-1):
				var path := animation.track_get_path(i)
				# Blender also exports object/armature transforms. These must never
				# be redirected onto Godot's Skeleton3D node itself.
				if path.get_subname_count() != 1:
					animation.remove_track(i); continue
				var bone := String(path.get_subname(0))
				if bone == "root":
					animation.remove_track(i); continue # CharacterBody3D owns the unchanged root basis.
				animation.track_set_path(i,NodePath("RioRig/Skeleton3D:"+bone))
			library.add_animation(clip,animation)
	if not library.has_animation("Kick_Strong") or not library.has_animation("Kick_Medium"):
		push_error("Missing Blender actions"); scene.free(); quit(1); return
	# Baseline comparison checks the round trip did not rotate the original joint bases.
	if library.has_animation("Idle_Loop"):
		var a := library.get_animation("Idle_Loop")
		var b: Animation = load("res://assets/animations/football.res").get_animation("Idle_Loop")
		var max_angle := 0.0; var max_shift := 0.0
		for i in a.get_track_count():
			var track := b.find_track(a.track_get_path(i),a.track_get_type(i))
			if track < 0: continue
			if a.track_get_type(i) == Animation.TYPE_ROTATION_3D:
				max_angle = maxf(max_angle,a.rotation_track_interpolate(i,0).angle_to(b.rotation_track_interpolate(track,0)))
			elif a.track_get_type(i) == Animation.TYPE_POSITION_3D:
				max_shift = maxf(max_shift,a.position_track_interpolate(i,0).distance_to(b.position_track_interpolate(track,0)))
		print("ROUNDTRIP idle max_angle=",max_angle," shift=",max_shift)
		library.remove_animation("Idle_Loop")
	var result := ResourceSaver.save(library,"res://assets/animations/kicks.res")
	print("KICKS_EXTRACTED ",library.get_animation_list()," result=",result)
	scene.free(); quit(0 if result == OK else 1)
