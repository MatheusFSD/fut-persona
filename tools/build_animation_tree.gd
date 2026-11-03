extends SceneTree
## Rebuild the editable graph. Runtime parameters belong to each AnimationTree.
const CLIPS := {
	"ShotWeak": "custom/shot", "ShotMedium": "kicks/Kick_Medium",
	"ShotStrong": "kicks/Kick_Strong", "Pass": "custom/pass", "Tackle": "custom/tackle",
	"SlideStart": "football/Slide_Start", "SlideLoop": "football/Slide_Loop",
	"SlideExit": "football/Slide_Exit", "Stunned": "football/Jump_Land",
	"Fall": "football/Hit_Knockback", "GetUp": "football/LayToIdle", "Celebrate": "football/Yes",
	"KeeperReady": "keeper/Ready", "KeeperReach": "keeper/Reach", "KeeperDive": "keeper/Dive",
	"KeeperJump": "keeper/Jump", "KeeperCatch": "keeper/Catch", "KeeperRecover": "keeper/Recover", "KeeperThrow": "keeper/Throw", "KeeperLand": "keeper/Land"
}

func clip_node(clip: String, gait := false) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = clip
	if gait:
		# Equal timelines keep stride phase aligned without cyclic-sync processing.
		node.use_custom_timeline = true
		node.timeline_length = 1.0
		node.stretch_time_scale = true
		node.loop_mode = Animation.LOOP_LINEAR
	return node

func _initialize() -> void:
	var locomotion := AnimationNodeBlendSpace1D.new()
	locomotion.min_space = 0; locomotion.max_space = 7.4
	locomotion.value_label = "Velocidade (m/s)"
	locomotion.sync_mode = AnimationNodeBlendSpace1D.SYNC_MODE_INDEPENDENT
	locomotion.add_blend_point(clip_node("football/Idle_Loop",true),0,-1,"Idle")
	locomotion.add_blend_point(clip_node("football/Walk_Loop",true),1.5,-1,"Walk")
	locomotion.add_blend_point(clip_node("football/Jog_Fwd_Loop",true),4.5,-1,"Jog")
	locomotion.add_blend_point(clip_node("football/Sprint_Loop",true),7.4,-1,"Sprint")
	var states := AnimationNodeStateMachine.new()
	states.add_node("Locomotion",locomotion,Vector2(300,100))
	var index := 0
	for state in CLIPS:
		states.add_node(state,clip_node(CLIPS[state]),Vector2(550+(index%3)*250,100+(index/3)*110))
		index += 1
	var entry := AnimationNodeStateMachineTransition.new()
	entry.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	states.add_transition("Start","Locomotion",entry)
	var names: Array = ["Locomotion"]+CLIPS.keys()
	# Direct paths allow a foul, reset or celebration to interrupt any action.
	for target in names:
		var transition := AnimationNodeStateMachineTransition.new()
		transition.xfade_time = .035 if target in ["ShotMedium","ShotStrong"] else .10
		for source in names:
			if source != target: states.add_transition(source,target,transition)
	var graph := AnimationNodeBlendTree.new()
	graph.add_node("States",states,Vector2(0,100))
	graph.add_node("Rate",AnimationNodeTimeScale.new(),Vector2(240,100))
	graph.add_node("ContactSeek",AnimationNodeTimeSeek.new(),Vector2(470,100))
	graph.connect_node("Rate",0,"States")
	graph.connect_node("ContactSeek",0,"Rate")
	graph.connect_node("output",0,"ContactSeek")
	var result := ResourceSaver.save(graph,"res://assets/animations/player_tree.tres")
	print("BUILD_ANIMATION_TREE ",error_string(result))
	quit(result)
