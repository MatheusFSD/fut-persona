extends AnimationTree
## AnimationPlayer owns the shared clips; only this tree drives live poses.
const STATES := {
	"custom/shot": "ShotWeak", "kicks/Kick_Medium": "ShotMedium",
	"kicks/Kick_Strong": "ShotStrong", "custom/pass": "Pass", "custom/tackle": "Tackle",
	"football/Slide_Start": "SlideStart", "football/Slide_Loop": "SlideLoop",
	"football/Slide_Exit": "SlideExit", "football/Jump_Land": "Stunned",
	"football/Hit_Knockback": "Fall", "football/LayToIdle": "GetUp", "football/Yes": "Celebrate",
	"keeper/Ready": "KeeperReady", "keeper/Reach": "KeeperReach", "keeper/Dive": "KeeperDive",
	"keeper/Jump": "KeeperJump", "keeper/Catch": "KeeperCatch", "keeper/Recover": "KeeperRecover", "keeper/Throw": "KeeperThrow", "keeper/Land": "KeeperLand"
}
var playback: AnimationNodeStateMachinePlayback
var rate := 1.0
var contact_pose := false
var gait_speeds := PackedFloat64Array()
var gait_lengths := PackedFloat64Array()

func setup(player: AnimationPlayer) -> void:
	active = false
	anim_player = get_path_to(player)
	root_node = get_path_to(player.get_node(player.root_node))
	callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var space: AnimationNodeBlendSpace1D = tree_root.get_node("States").get_node("Locomotion")
	for point in space.get_blend_point_count():
		var clip: AnimationNodeAnimation = space.get_blend_point_node(point)
		gait_speeds.append(space.get_blend_point_position(point))
		gait_lengths.append(player.get_animation(clip.animation).length)
	player.stop()
	active = true
	playback = get("parameters/States/playback")
	reset()

func reset() -> void:
	contact_pose = false; rate = _gait_rate(0.0)
	set("parameters/Rate/scale",rate)
	set("parameters/ContactSeek/seek_request",-1.0)
	set("parameters/States/Locomotion/blend_position",0.0)
	playback.start("Locomotion")
	advance(0)

func select(state: String, speed_scale := 1.0, restart := false) -> void:
	rate = speed_scale
	set("parameters/Rate/scale",rate)
	if playback.get_current_node() != state:
		playback.travel(state)
		advance(0)
	elif restart:
		playback.start(state)
		advance(0)

func play_clip(clip: String, speed_scale := 1.0, restart := false) -> void:
	if clip == "football/Idle_Loop":
		locomotion(0.0)
	else:
		select(STATES[clip],speed_scale,restart)

func locomotion(speed: float) -> void:
	set("parameters/States/Locomotion/blend_position",clampf(speed,0.0,7.4))
	select("Locomotion",_gait_rate(speed))

func _gait_rate(speed: float) -> float:
	# The four clips share a one-second timeline. Restore their natural cadence
	# with one shared rate so changing blend weights never desynchronizes feet.
	for point in range(1,gait_speeds.size()):
		if speed <= gait_speeds[point]:
			var weight := clampf(inverse_lerp(gait_speeds[point-1],gait_speeds[point],speed),0.0,1.0)
			return 1.0/lerpf(gait_lengths[point-1],gait_lengths[point],weight)
	return 1.0/gait_lengths[-1]

func seek_contact(seconds: float) -> void:
	# Apply the actual contact pose before the physical impulse, once per kick.
	set("parameters/ContactSeek/seek_request",seconds)
	advance(0)
	contact_pose = true

func tick(delta: float, paused: bool) -> void:
	set("parameters/Rate/scale",0.0 if paused else rate)
	if not paused and not contact_pose: advance(delta)
	contact_pose = false
