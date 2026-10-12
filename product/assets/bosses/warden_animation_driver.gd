extends "res://combat/snaiel/scripts/animations/character_animations.gd"
## Snaiel animation recipient API on the retained, complete medieval Ranger.
## Aliases are built from actual imported Godot keys, not raw GLB labels.
const CLIPS := {"Idle":"Sword_Idle","Walk":"Walk","Punch":"sword/Sword_Regular_C","HitReact":"Hit_Chest","Death":"Death01","Wave":"Interact"}
func configure(model: Node3D) -> void:
	anim_player = model.animation_player
	skeleton = model.skeleton
	var library: AnimationLibrary = anim_player.get_animation_library("")
	for alias in CLIPS:
		var key: String = CLIPS[alias]
		if not anim_player.has_animation(key): push_error("Warden missing imported clip: " + key); continue
		var clip: Animation = anim_player.get_animation(key).duplicate()
		clip.loop_mode = Animation.LOOP_LINEAR if alias in ["Idle","Walk"] else Animation.LOOP_NONE
		if library.has_animation(alias): library.remove_animation(alias)
		library.add_animation(alias,clip)
	anim_player.stop()
	anim_tree = AnimationTree.new()
	model.character_model.add_child(anim_tree)
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)
	anim_tree.root_node = NodePath("..")
	anim_tree.tree_root = BLEND_TREE.duplicate(true)
	anim_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	anim_tree.active = true
	playback = anim_tree.get("parameters/TimedAction/Action/playback")
	contact_socket = model.sword_attachment
	palm_offset = Vector3(0,0.065,0)
	idle_driver = preload("res://combat/snaiel/scripts/animations/subclasses/idle_animations.gd").new()
	movement_driver = preload("res://combat/snaiel/scripts/animations/subclasses/movement_animations.gd").new()
	hit_driver = preload("res://combat/snaiel/scripts/animations/subclasses/hit_and_death_animations.gd").new()
	for driver in [idle_driver,movement_driver,hit_driver]:
		driver.character = self
		add_child(driver)
	play("Idle",1,true)
