extends RefCounted
## Contact freeze on top of any cinematic slow motion. Cinematics write through
## set_world_scale() and read world_scale(), so they never save the frozen speed.
const FREEZE_SCALE := .05
const COOLDOWN := .18
const MIN_SECONDS := .04 # Weak shots and standing tackles stay fluid.
# Seconds at full strength, counted in real time from the contact.
const SECONDS := {"shot":.06,"power":.09,"post":.09,"save":.08,"tackle":.08,"net":.09}
static var freeze := 1.0
static var clean_scale := 1.0
static var remaining := 0.0
static var cooldown := 0.0

static func hit(kind: String, strength := 1.0) -> bool:
	if not SECONDS.has(kind) or cooldown > 0: return false
	var seconds: float = SECONDS[kind]*clampf(strength,0,1)
	if seconds < MIN_SECONDS: return false
	remaining = seconds; cooldown = COOLDOWN
	return true

static func world_scale() -> float:
	return clean_scale if freeze < 1 else Engine.time_scale

static func set_world_scale(value: float) -> void:
	clean_scale = value; Engine.time_scale = value*freeze

# Only runs from juice._process: changing the scale during a physics step would
# make that frame's delta/time_scale report twenty times the real time.
static func advance(real_delta: float, paused := false) -> void:
	if paused: clear(); return
	cooldown = maxf(0,cooldown-real_delta)
	if remaining <= 0: return
	remaining = maxf(0,remaining-real_delta)
	if remaining > 0 and freeze == 1:
		clean_scale = Engine.time_scale; freeze = FREEZE_SCALE
		Engine.time_scale = clean_scale*freeze
	elif remaining <= 0 and freeze < 1:
		freeze = 1; Engine.time_scale = clean_scale

static func clear() -> void:
	if freeze < 1: Engine.time_scale = clean_scale
	freeze = 1; remaining = 0; cooldown = 0
