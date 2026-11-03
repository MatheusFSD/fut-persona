extends "res://scripts/slide_moment.gd"
## Live stages: kick -> flight -> woodwork -> rebound/goal -> net -> smooth return.
const ENTER_SHOT_SECONDS := .22
const BACK_DISTANCE := 9.0
const CAMERA_HEIGHT := 4.8
const LOOK_AHEAD := 5.0
const SHOT_FOV := 48.0
const IMPACT_ENTER := .10
const MAX_FLIGHT_SECONDS := 6.0
var shot_direction := Vector3.RIGHT
var stage := "idle"
var stage_age := 0.0
var scored := false
var net_seen := false
var post_seen := false
var impact_origin := Vector3.ZERO
var stage_from := Transform3D.IDENTITY
var stage_fov := 43.0
var view := Transform3D.IDENTITY
var view_fov := 43.0
var flight_offset := Vector3.ZERO
var last_ball := Vector3.ZERO
var post_queued := false
var net_queued := false
var pending_post := Vector3.ZERO
var pending_net := Vector3.ZERO
var net_started := false

func begin_shot(world: Vector3, axis: Vector3, camera_view := Transform3D.IDENTITY, fov := 43.0) -> bool:
	axis.y = 0
	if axis.length_squared() < .001: return false
	if not begin(world,1): return false
	shot_direction = axis.normalized(); scored = false; net_seen = false; post_seen = false
	post_queued = false; net_queued = false; net_started = false
	view = camera_view; view_fov = fov; last_ball = world
	_enter("shot",world)
	return true

func weight() -> float:
	if not active: return 0
	if stage == "shot": return smoothstep(0,ENTER_SHOT_SECONDS,stage_age)
	if stage == "return": return 1-smoothstep(0,RETURN_SECONDS,stage_age)
	return 1

func _enter(next: String, point: Vector3) -> void:
	stage = next; stage_age = 0; impact_origin = point; stage_from = view; stage_fov = view_fov
	flight_offset = view.origin-point

func advance(real_delta: float, paused := false) -> void:
	if not active or paused: return
	age += maxf(real_delta,0); stage_age += maxf(real_delta,0)
	if post_queued and stage == "shot" and stage_age >= ENTER_SHOT_SECONDS:
		post_queued = false; _enter("post",pending_post)
	if net_queued and ((stage == "shot" and stage_age >= ENTER_SHOT_SECONDS) or (stage == "post" and stage_age >= .20) or stage not in ["shot","post"]):
		net_queued = false; net_started = true; _enter("net",pending_net)
	if stage_age >= SLOW_SECONDS:
		if stage == "shot": _enter("goal_wait" if scored else "flight",last_ball)
		elif stage == "post": _enter("goal_wait" if scored else "post_flight",last_ball)
		elif stage == "net": _enter("net_hold",last_ball)
	if stage == "return" and stage_age >= RETURN_SECONDS: cancel()
	elif age > MAX_FLIGHT_SECONDS and not scored and stage not in ["post","return"]: release()
	if active:
		var slow := stage in ["shot","post","net"] and stage_age < SLOW_SECONDS
		Engine.time_scale = previous_time_scale*(SLOW_SCALE if slow else 1.0)

func observe(ball: Vector3, velocity: Vector3, possessed: bool, phase: String) -> void:
	if not active or phase == "paused": return
	last_ball = ball
	if phase == "out":
		if stage != "post": release()
	elif not scored and stage in ["flight","post_flight"]:
		if possessed or velocity.length() < 1.2: release()
		elif stage == "post_flight" and absf(ball.x) < 23.6 and absf(ball.z) < 14: release()

func _start_if_idle(point: Vector3, camera_view: Transform3D, fov: float) -> void:
	if active: return
	begin(point,1); shot_direction = Vector3.RIGHT; post_seen = false; scored = false; net_seen = false
	post_queued = false; net_queued = false; net_started = false
	view = camera_view; view_fov = fov; last_ball = point

func post_impact(point: Vector3, camera_view: Transform3D, fov: float) -> bool:
	if scored or net_seen: return false
	if active and stage == "post" and stage_age < .15 and impact_origin.distance_to(point) < .6: return false
	_start_if_idle(point,camera_view,fov)
	if stage == "shot" and stage_age < ENTER_SHOT_SECONDS:
		post_seen = true; post_queued = true; pending_post = point
		return true
	view = camera_view; view_fov = fov; post_seen = true; _enter("post",point)
	return true

func goal_scored(ball: Vector3, camera_view: Transform3D, fov: float) -> void:
	_start_if_idle(ball,camera_view,fov)
	scored = true
	# An immediate post -> goal preserves the woodwork shot until actual net contact.
	if stage not in ["shot","post","net","net_hold"]:
		view = camera_view; view_fov = fov; _enter("goal_wait",ball)
		Engine.time_scale = previous_time_scale

func net_impact(point: Vector3, camera_view: Transform3D, fov: float) -> bool:
	if not active or not scored or net_seen: return false
	net_seen = true; pending_net = point
	if (stage == "shot" and stage_age < ENTER_SHOT_SECONDS) or (stage == "post" and stage_age < .20) or post_queued:
		net_queued = true; return true
	view = camera_view; view_fov = fov; net_started = true; _enter("net",point)
	return true

func release() -> void:
	if not active or stage == "return": return
	Engine.time_scale = previous_time_scale; _enter("return",last_ball)

func cancel() -> void:
	super.cancel(); stage = "idle"; stage_age = 0; scored = false; net_seen = false; post_seen = false
	post_queued = false; net_queued = false; net_started = false

func shake() -> Vector2:
	if not active or stage not in ["shot","post","net"]: return Vector2.ZERO
	var strength := exp(-stage_age*7)*(1-exp(-stage_age*45))
	return Vector2(sin(stage_age*89)*.040,sin(stage_age*71+.8)*.025)*strength

func _look(position: Vector3, target: Vector3, roll := 0.0) -> Transform3D:
	var basis := Basis.looking_at(target-position)
	return Transform3D(basis*Basis(Vector3.FORWARD,roll),position)

func frame(ball: Vector3, baseline: Transform3D, base_fov: float) -> Transform3D:
	if not active: return baseline
	last_ball = ball
	if stage == "shot":
		var behind := origin-shot_direction*BACK_DISTANCE+Vector3.UP*CAMERA_HEIGHT
		behind.x = clampf(behind.x,-26,26); behind.z = clampf(behind.z,-15.6,15.6)
		var target := origin.lerp(ball,.25)+shot_direction*LOOK_AHEAD+Vector3.UP*.8
		var blend := smoothstep(0,ENTER_SHOT_SECONDS,stage_age)
		view = stage_from.interpolate_with(_look(behind,target),blend)
		view_fov = lerpf(stage_fov,SHOT_FOV,blend)
	elif stage in ["flight","post_flight","goal_wait","net_hold"]:
		var position := ball+flight_offset
		var tilt := deg_to_rad(3.0) if post_seen or net_seen else 0.0
		var following := _look(position,ball+Vector3.UP*.25+shot_direction*.7,tilt)
		var moving_from := stage_from; moving_from.origin += ball-impact_origin
		view = moving_from.interpolate_with(following,smoothstep(0,.22,stage_age))
		view_fov = stage_fov
	elif stage in ["post","net"]:
		var approach := stage_from.origin-impact_origin; approach.y = 0
		if approach.length_squared() < .01: approach = -shot_direction
		var position := impact_origin+approach.normalized()*4.4+Vector3.UP*2.0
		var target := impact_origin.lerp(ball,.40)+Vector3.UP*.1
		var tilt := deg_to_rad(3.0)*(1 if shot_direction.x >= 0 else -1)
		var blend := smoothstep(0,IMPACT_ENTER,stage_age)
		view = stage_from.interpolate_with(_look(position,target,tilt),blend)
		view_fov = lerpf(stage_fov,35.0 if stage == "net" else 35.0,blend)
	elif stage == "return":
		var blend := smoothstep(0,RETURN_SECONDS,stage_age)
		view = stage_from.interpolate_with(baseline,blend); view_fov = lerpf(stage_fov,base_fov,blend)
	return view
