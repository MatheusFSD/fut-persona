extends SceneTree
var game
var fx
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); push_error("FAIL "+label)

func reset(at := Vector3(.75,.4,0)) -> void:
	game.juice.reset_presentation(); game._drop_carrier(); game.clear_reception()
	game.phase = "playing"; game.released_by = null; game.release_guard = 0; game.kick_lock = 0
	game.recent_shot_time = 0; game.ball_speed_before_step = 0
	game.ball.freeze = true; game.ball.position = at
	game.ball.linear_velocity = Vector3.ZERO; game.ball.angular_velocity = Vector3.ZERO
	game.controlled = game.players[4]; game.controlled.position = Vector3(at.x-.75,.05,at.z)
	game.ball.freeze = false
	fx.reset()

func tick(count := 1) -> void:
	for i in count: await physics_frame; fx._physics_process(1.0/60)

func world_shape() -> Basis:
	# Visual over body: removes the rolling and leaves only the deformation.
	var body: Basis = game.ball.global_transform.basis.orthonormalized()
	return game.ball_visual.global_transform.basis*body.inverse()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.juice.shot_cinematic_enabled = false; game.juice.hit_stop_enabled = false
	game.set_physics_process(false); game.muted = true; game.hud.hide()
	for p in game.players: p.set_physics_process(false); p.collision_layer = 0; p.collision_mask = 0
	fx = game.juice.ball_fx; fx.set_physics_process(false)
	var collider: CollisionShape3D = game.ball.get_child(0)
	var radius: float = collider.shape.radius

	reset(); await tick(3)
	check(not fx.deformed and game.ball_visual.transform == Transform3D.IDENTITY,"ball at rest keeps its original shape")

	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",1); await tick(3)
	check(fx.squash > .05 and fx.deformed,"real kick squashes the visual")
	check(absf(fx.squash_axis.x) > .9,"squash follows the direction of the hit")
	var shape: Basis = world_shape()
	check(shape*fx.squash_axis != fx.squash_axis,"deformation is on the rendered mesh")
	check(absf(shape.determinant()-1) < .02,"deformation preserves the ball volume")
	check(game.ball.global_transform.basis.orthonormalized().is_equal_approx(game.ball.global_transform.basis),"rigid body keeps a clean transform")
	check(collider.transform == Transform3D.IDENTITY and collider.shape.radius == radius,"collision sphere is untouched")
	var speed: float = game.ball.linear_velocity.length()
	check(fx.find_children("*","CollisionObject3D",true,false).is_empty(),"effect adds no physics bodies")
	await tick(12)
	check(fx.stretch > .03,"fast flight stretches the ball")
	var along: float = (world_shape()*game.ball.linear_velocity.normalized()).length()
	var across: Vector3 = game.ball.linear_velocity.normalized().cross(Vector3.UP).normalized()
	check(along > (world_shape()*across).length(),"stretch lies along the velocity")
	check(speed > fx.STRETCH_MIN_SPEED,"shot used in the test is above the stretch speed")

	reset(); game.ball.linear_velocity = Vector3(fx.STRETCH_MIN_SPEED-2,0,0); await tick(2); await tick(4)
	check(fx.stretch == 0,"slow ball does not stretch")
	reset(); game.ball.linear_velocity = Vector3(25,0,0); await tick(1); await tick(40)
	fx.squash = 0; fx.squash_speed = 0; game.take_possession(game.players[2]); fx.stretch = 0; await tick(2)
	check(fx.stretch == 0,"ball at someone's feet does not stretch")

	# Stored spring energy must die out quickly once there are no more hits.
	reset(); fx.squash = fx.SQUASH_MAX; fx.squash_axis = Vector3.UP
	game.ball.freeze = true; var settle := 0
	while (fx.deformed or settle == 0) and settle < 60: fx._physics_process(1.0/60); settle += 1
	check(settle < 40 and not fx.deformed and game.ball_visual.transform == Transform3D.IDENTITY,"squash settles in about half a second")
	var lowest := 0.0
	reset(); fx.squash = fx.SQUASH_MAX; fx.squash_axis = Vector3.UP; game.ball.freeze = true
	for i in 30:
		fx._physics_process(1.0/60); lowest = minf(lowest,fx.squash)
	check(lowest < 0 and lowest > -fx.SQUASH_MAX,"squash rebounds once, without exploding")
	fx.squash = fx.SQUASH_MAX; fx.squash_speed = 0
	fx._physics_process(.5)
	check(absf(fx.squash) < 1,"long frames keep the spring stable")

	reset(Vector3(3,3.2,3)); game.ball.linear_velocity = Vector3.ZERO
	var bounced := false; var up := 0.0
	for i in 90:
		await tick()
		if fx.squash > .02 and fx.squash_axis.y > .8 and game.ball.linear_velocity.y > 0:
			bounced = true; up = fx.squash_axis.y; break
	check(bounced and up > .8,"floor bounce squashes vertically")
	var bottom: float = game.ball_visual.global_position.y-game.BALL_RADIUS*(1-fx.squash)
	check(bottom < game.ball.global_position.y-game.BALL_RADIUS+.02,"squashed ball stays on the surface it hit")

	# A soft nudge is not a hit.
	reset(); await tick(1); game.ball.linear_velocity = Vector3(fx.SQUASH_MIN_KICK*.5,0,0); await tick(2)
	check(fx.squash == 0,"small velocity changes do not squash")
	# Dribbling forces nudge a carried ball all the time.
	reset(); game.take_possession(game.players[2]); fx.reset(); await tick(1)
	game.ball.linear_velocity += Vector3(fx.SQUASH_MIN_KICK_CARRIED*.7,0,0); await tick(1)
	check(fx.squash <= 0,"dribbling nudges do not squash a carried ball")
	await tick(1); fx.squash = 0; fx.squash_speed = 0
	game.ball.linear_velocity += Vector3(fx.SQUASH_MIN_KICK_CARRIED*1.5,0,0); await tick(1)
	check(fx.squash > 0,"a real hit still squashes a carried ball")
	# Repositioning with a frozen ball is not a hit either.
	reset(); await tick(1); game.ball.linear_velocity = Vector3(20,0,0); await tick(1); fx.squash = 0; fx.squash_speed = 0
	game.ball.freeze = true; game.ball.position = Vector3(-9,.4,4); game.ball.linear_velocity = Vector3.ZERO; await tick(2)
	game.ball.freeze = false; await tick(1)
	check(fx.squash == 0,"frozen reposition does not squash")

	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",1); await tick(3)
	var held: float = fx.squash; var at: Transform3D = game.ball_visual.transform
	game.toggle_pause(); fx._physics_process(.5)
	check(fx.squash == held and game.ball_visual.transform == at,"pause holds the deformation")
	game.toggle_pause(); var before: float = fx.squash_speed; await tick(1)
	check(fx.squash < held+.0001 or fx.squash_speed != before,"resume continues the same deformation")
	reset(); await tick(1); game.ball.linear_velocity = Vector3(20,0,0); await tick(2); fx.squash = 0; fx.squash_speed = 0
	game.toggle_pause(); await tick(3); game.toggle_pause(); await tick(2)
	check(fx.squash == 0,"pausing a fast ball is not a hit when it resumes")
	# Set pieces kick the same physics tick the ball is released.
	reset(); game.ball.freeze = true; await tick(1); game.ball.freeze = false
	game.strike(game.controlled,Vector3(24,0,0),"shot",1); await tick(3)
	check(fx.squash > .05,"kick right after a frozen ball still squashes")

	var ball_at: Vector3 = game.ball.position; var velocity: Vector3 = game.ball.linear_velocity
	game.ball.freeze = true; fx.squash = .2; fx._physics_process(.01)
	check(game.ball.position == ball_at and game.ball.linear_velocity == velocity,"deformation cannot move the ball or alter its velocity")
	game.ball.freeze = false

	reset(); game.strike(game.controlled,Vector3(24,0,0),"shot",1); await tick(3)
	game.begin_restart(0,Vector3(6,.05,0),"FALTA • BOLA PARADA",false)
	check(not fx.deformed and game.ball_visual.transform == Transform3D.IDENTITY,"set piece restores the original shape")
	game.phase = "playing"; game.ball.freeze = false; fx.squash = .2; fx._physics_process(1.0/60); game.selection_menu()
	check(not fx.deformed and game.ball_visual.transform == Transform3D.IDENTITY,"leaving the match restores the original shape")
	print("BALL_SQUASH ",checks-failures.size(),"/",checks," passed; failures=",failures)
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
