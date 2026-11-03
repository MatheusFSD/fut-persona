extends SceneTree
## Uses the Unreal-Godot files extracted from BOTH original zip archives.
const PICKS := {
	"UAL1_Standard.glb": ["Idle_Loop", "Walk_Loop", "Jog_Fwd_Loop", "Sprint_Loop", "Death01", "Jump_Land"],
	"UAL2_Standard.glb": ["Slide_Start", "Slide_Loop", "Slide_Exit", "Shield_Dash", "Hit_Knockback", "LayToIdle", "Yes"]
}

func _initialize() -> void:
	var library := AnimationLibrary.new()
	for file in PICKS:
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_file(ProjectSettings.globalize_path("res://tools/source/" + file), state)
		if error != OK:
			push_error("Cannot read " + file); quit(1); return
		var scene := document.generate_scene(state)
		var player: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
		for clip: String in PICKS[file]:
			var animation := player.get_animation(clip).duplicate(true) as Animation
			animation.loop_mode = Animation.LOOP_LINEAR if clip.ends_with("_Loop") else Animation.LOOP_NONE
			for i in animation.get_track_count():
				var bone := String(animation.track_get_path(i)).get_slice(":", 1)
				animation.track_set_path(i, NodePath("RioRig/Skeleton3D:" + bone))
				# CharacterBody3D owns movement. Keep authored pelvis bob, remove root motion.
				if bone == "root" and animation.track_get_type(i) == Animation.TYPE_POSITION_3D:
					for k in animation.track_get_key_count(i):
						animation.track_set_key_value(i, k, Vector3.ZERO)
			library.add_animation(clip, animation)
		scene.free()
	var result := ResourceSaver.save(library, "res://assets/animations/football.res")
	print("FOOTBALL_ANIMATIONS ", library.get_animation_list(), " result=", result)
	quit(0 if result == OK else 1)
