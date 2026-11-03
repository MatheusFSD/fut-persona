extends RefCounted
## Original poses on the existing rig; no new mesh, bone or external asset.
static var libraries: Dictionary = {}

static func curve(time: float, points: Array[Vector2]) -> float:
	for i in range(1,points.size()):
		if time <= points[i].x:
			return lerpf(points[i-1].y,points[i].y,smoothstep(points[i-1].x,points[i].x,time))
	return points[-1].y

static func rotations(name: String, time: float) -> Dictionary:
	var knee := .40
	var lean := .12
	var trail := 0.0
	match name:
		"Ready", "Catch": knee += sin(time/1.4*TAU)*.025
		"Jump":
			knee = curve(time,[Vector2(0,.65),Vector2(.12,.12),Vector2(.30,.7),Vector2(.50,.25),Vector2(.7,.5)])
			lean = curve(time,[Vector2(0,.17),Vector2(.15,-.04),Vector2(.45,.04),Vector2(.7,.15)])
		"Dive":
			knee = curve(time,[Vector2(0,.55),Vector2(.12,.12),Vector2(.32,.32),Vector2(.7,.55)])
			trail = curve(time,[Vector2(0,0),Vector2(.16,.15),Vector2(.34,.48),Vector2(.7,.3)])
			lean = .10
		"Land":
			knee = curve(time,[Vector2(0,.4),Vector2(.12,1.1),Vector2(.36,.85)])
			lean = curve(time,[Vector2(0,.12),Vector2(.12,.32),Vector2(.36,.23)])
		"Recover":
			knee = curve(time,[Vector2(0,.85),Vector2(.2,.9),Vector2(.6,.4)])
			lean = curve(time,[Vector2(0,.25),Vector2(.25,.3),Vector2(.6,.12)])
		"Throw": lean = curve(time,[Vector2(0,.08),Vector2(.12,-.10),Vector2(.26,.22),Vector2(.6,.12)])
	return {
		"thigh_l":Vector3(-knee*.5,0,-.025),"thigh_r":Vector3(-knee*.5-trail*.5,0,.025),
		"calf_l":Vector3(knee,0,0),"calf_r":Vector3(knee+trail,0,0),
		"foot_l":Vector3(-knee*.5,0,0),"foot_r":Vector3(-(knee+trail)*.5,0,0),
		"spine_02":Vector3(lean,0,0),
		"upperarm_l":Vector3(.05,0,-.85),"upperarm_r":Vector3(.05,0,.85),
		"lowerarm_l":Vector3(.12,0,-.45),"lowerarm_r":Vector3(.12,0,.45)
	}

static func library(source: Animation, height: float) -> AnimationLibrary:
	if libraries.has(height): return libraries[height]
	var result := AnimationLibrary.new()
	for name in ["Ready","Reach","Dive","Jump","Catch","Land","Recover","Throw"]:
		var animation := Animation.new()
		animation.length = 1.4 if name in ["Ready","Catch"] else .36 if name == "Land" else .6 if name in ["Throw","Recover"] else .7
		animation.loop_mode = Animation.LOOP_LINEAR if name in ["Ready","Catch"] else Animation.LOOP_NONE
		for i in source.get_track_count():
			var type := source.track_get_type(i)
			if type not in [Animation.TYPE_ROTATION_3D,Animation.TYPE_POSITION_3D,Animation.TYPE_SCALE_3D]: continue
			var track := animation.add_track(type); var path := source.track_get_path(i)
			animation.track_set_path(track,path)
			var value: Variant
			if type == Animation.TYPE_ROTATION_3D:
				value = source.rotation_track_interpolate(i,0)
				var bone := String(path).get_slice(":",1)
				var times: Array[float] = [0.0,.08,.12,.18,.26,.30,.36,.45,.50,.60,.70,1.0,1.4]
				for time in times:
					if time > animation.length: continue
					var offsets := rotations(name,time)
					animation.track_insert_key(track,time,value*Quaternion.from_euler(offsets.get(bone,Vector3.ZERO)))
				continue
			elif type == Animation.TYPE_POSITION_3D:
				value = source.position_track_interpolate(i,0)
			else: value = source.scale_track_interpolate(i,0)
			animation.track_insert_key(track,0,value); animation.track_insert_key(track,animation.length,value)
		result.add_animation(name,animation)
	libraries[height] = result
	return result
