extends RefCounted
## A physical cut, never a teleport or an automatic possession win.
const DURATION := .40
const SPEED := 7.2
const COOLDOWN := 1.15
const STAMINA_COST := .18
const OFF_BALANCE_SECONDS := .30
var cooldown := 0.0
var direction := Vector3.ZERO
var forward := Vector3.RIGHT
var origin := Vector3.ZERO
var side := 1.0
var defender
var beaten := false

func reset(actor) -> void:
	cooldown = 0; defender = null; beaten = false
	if actor.action == "dribble": actor.action = ""
	if actor.goalkeeper == null: actor.avatar.rotation.z = 0

func start(actor, input := Vector3.ZERO) -> bool:
	var game = actor.game
	if not game.live() or game.carrier != actor or actor.is_goalkeeper(): return false
	if cooldown > 0 or actor.cooldown > 0 or not actor.action.is_empty(): return false
	var technique: float = actor.attribute_scale(actor.tecnica,.85,1.12)
	var cost := STAMINA_COST/technique
	if actor.stun > 0 or actor.fall_time >= 0 or actor.stamina < cost: return false
	if not game.can_play_ball(actor) or game.ball.position.y > .65 or game.flat_distance(actor.position,game.ball.position) > 1.9: return false
	forward = actor.facing; forward.y = 0; forward = forward.normalized()
	var lateral := Vector3.UP.cross(forward)
	origin = actor.position; defender = null; beaten = false
	var nearest := 2.3
	for opponent in game.players:
		if opponent.team == actor.team or opponent.is_goalkeeper() or opponent.stun > 0 or opponent.fall_time >= 0: continue
		var offset: Vector3 = opponent.position-origin; offset.y = 0
		if offset.length() < .1 or offset.normalized().dot(forward) < .45: continue
		if opponent.facing.dot(-offset.normalized()) < .25: continue
		if offset.length() < nearest: nearest = offset.length(); defender = opponent
	var preference: float = input.dot(lateral)
	if absf(preference) < .15:
		# With no side requested, cut away from the closest marker.
		preference = -(defender.position-origin).dot(lateral) if is_instance_valid(defender) else 1.0
	side = -1.0 if preference < 0 else 1.0
	direction = (forward*.9+lateral*side).normalized()
	actor.action = "dribble"; actor.action_time = 0; actor.action_length = DURATION
	actor.stamina -= cost; cooldown = COOLDOWN/technique
	actor.cancel_charge(); actor.current_clip = ""; game.clear_reception()
	game.dust(actor.position)
	game.juice.impact("dribble",game.ball.global_position,.35)
	return true

func prepare(actor, delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	if actor.action == "dribble" and (not actor.game.live() or actor.game.carrier != actor or actor.stun > 0 or actor.fall_time >= 0):
		actor.action = ""; defender = null
		actor.avatar.rotation.z = 0

func finish(actor, delta: float) -> void:
	if actor.goalkeeper != null: return
	var active: bool = actor.action == "dribble"
	var lean := side*.17*sin(PI*clampf(actor.action_time/DURATION,0,1)) if active else 0.0
	actor.avatar.rotation.z = move_toward(actor.avatar.rotation.z,lean,4*delta)
	if not active or beaten or not is_instance_valid(defender): return
	if actor.game.carrier != actor or defender.stun > 0 or defender.fall_time >= 0: return
	var offset: Vector3 = actor.position-defender.position; offset.y = 0
	# Reward actually passing the marker's line, with lateral separation.
	var lateral := Vector3.UP.cross(forward)
	if offset.dot(forward) <= .05 or absf(offset.dot(lateral)) < .65 or offset.length() > 2.6: return
	if (actor.position-origin).dot(direction) < .65: return
	beaten = true
	defender.stun = OFF_BALANCE_SECONDS
	defender.cooldown = maxf(defender.cooldown,OFF_BALANCE_SECONDS+.1)
	defender.action = ""; defender.cancel_charge(); defender.velocity *= .25
	defender.current_clip = ""; defender._animate()
	actor.game.hud.push_reaction("dribble",defender.global_position,actor.team)
	actor.game.dust(defender.position)
