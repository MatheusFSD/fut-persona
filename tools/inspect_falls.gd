extends SceneTree
func _initialize() -> void:
	for file in ["UAL1_Standard.glb","UAL2_Standard.glb"]:
		var doc := GLTFDocument.new(); var state := GLTFState.new()
		doc.append_from_file(ProjectSettings.globalize_path("res://tools/source/"+file),state)
		var scene := doc.generate_scene(state)
		var player: AnimationPlayer = scene.find_children("*","AnimationPlayer",true,false)[0]
		for clip in ["Death01","Hit_Knockback","LayToIdle"]:
			if not player.has_animation(clip): continue
			var anim := player.get_animation(clip)
			print(file," ",clip," length=",anim.length)
			for t in anim.get_track_count():
				if anim.track_get_type(t) == Animation.TYPE_POSITION_3D and String(anim.track_get_path(t)).ends_with(":pelvis"):
					for time in [0.0,anim.length*.25,anim.length*.5,anim.length*.75,anim.length]: print("  pelvis ",time," ",anim.position_track_interpolate(t,time))
		scene.free()
	quit()
