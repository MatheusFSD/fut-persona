extends SceneTree
func _initialize() -> void:
	var original: Animation = load("res://assets/animations/football.res").get_animation("Idle_Loop")
	for label in ["Kick_Medium","Kick_Strong"]:
		var clip: Animation = load("res://assets/animations/kicks.res").get_animation(label)
		for bone in ["root","pelvis","spine_02","thigh_l","thigh_r","foot_l"]:
			for type in [Animation.TYPE_ROTATION_3D,Animation.TYPE_POSITION_3D]:
				var path := NodePath("RioRig/Skeleton3D:"+bone)
				var a := original.find_track(path,type); var b := clip.find_track(path,type)
				if a < 0 or b < 0: continue
				if type == Animation.TYPE_ROTATION_3D: print(label," ",bone," quat idle=",original.rotation_track_interpolate(a,0)," new0=",clip.rotation_track_interpolate(b,0)," prep=",clip.rotation_track_interpolate(b,.13))
				else: print(label," ",bone," pos idle=",original.position_track_interpolate(a,0)," new0=",clip.position_track_interpolate(b,0)," prep=",clip.position_track_interpolate(b,.13))
	quit()
