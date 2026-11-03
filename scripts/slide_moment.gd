extends RefCounted
## Real-time envelope; the world slows, but this clock keeps normal speed.
const SLOW_SECONDS := .75
const RETURN_SECONDS := .35
const ENTER_SECONDS := .14
const SLOW_SCALE := .30
const ZOOM_FOV := 30.0
const ORBIT_DEGREES := 14.0
const PITCH_DEGREES := 5.0
const ROLL_DEGREES := 1.8
var active := false
var age := 0.0
var origin := Vector3.ZERO
var direction := 1.0
var previous_time_scale := 1.0
var serial := 0

func begin(world: Vector3, side: float) -> bool:
	if active or Engine.time_scale <= 0: return false
	previous_time_scale = Engine.time_scale
	active = true; age = 0; origin = world; direction = side; serial += 1
	return true

func advance(real_delta: float, paused := false) -> void:
	if not active or paused: return
	age += maxf(real_delta,0)
	Engine.time_scale = previous_time_scale*(SLOW_SCALE if age < SLOW_SECONDS else 1.0)
	if age >= SLOW_SECONDS+RETURN_SECONDS:
		Engine.time_scale = previous_time_scale; active = false

func cancel() -> void:
	if active: Engine.time_scale = previous_time_scale
	active = false; age = 0

func weight() -> float:
	if not active: return 0
	if age < ENTER_SECONDS: return smoothstep(0,ENTER_SECONDS,age)
	if age <= SLOW_SECONDS: return 1
	return 1-smoothstep(SLOW_SECONDS,SLOW_SECONDS+RETURN_SECONDS,age)

func shake() -> Vector2:
	var strength := weight()*(.3+.7*exp(-age*6))
	return Vector2(sin(age*89)*.055,sin(age*71+.8)*.035)*strength
