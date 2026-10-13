extends "res://combat/snaiel/scripts/animations/character_animations.gd"
## E02-only recipient adapter. Combat, movement, interruption and reward owners
## remain Snaiel/product-owned. The distinct tunic uses the same named humanoid
## hierarchy, but its own Rest transforms. Original UAL clips are never edited.
const UAL = preload("res://Characters/QuaterniusAnimations/UAL1_Standard.glb")
const CLIPS = {"Idle":"Idle", "Walk":"Walk", "Punch":"Punch_Cross", "HitReact":"Hit_Chest", "Death":"Death01"}

func configure(model: Node3D) -> void:
	var target: Skeleton3D = model.find_child("Skeleton3D", true, false)
	var source: Node3D = UAL.instantiate()
	var source_skeleton: Skeleton3D = source.find_child("Skeleton3D", true, false)
	var source_player: AnimationPlayer = source.get_node("AnimationPlayer")
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	model.add_child(player)
	var library := AnimationLibrary.new()
	for state in CLIPS:
		library.add_animation(state, _retarget(source_player.get_animation(CLIPS[state]), source_skeleton, target))
	player.add_animation_library("", library)
	source.free()
	# Retain CharacterAnimations' recipients, blend tree, physics playback and
	# current-position interface. The tunic has a real articulated wrist.
	anim_player = player
	skeleton = target
	for key in ["Idle", "Walk"]: library.get_animation(key).loop_mode = Animation.LOOP_LINEAR
	anim_tree = AnimationTree.new()
	model.add_child(anim_tree)
	anim_tree.anim_player = anim_tree.get_path_to(player)
	anim_tree.root_node = NodePath("..")
	anim_tree.tree_root = BLEND_TREE.duplicate(true)
	anim_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	anim_tree.active = true
	playback = anim_tree.get("parameters/TimedAction/Action/playback")
	contact_socket = BoneAttachment3D.new()
	contact_socket.name = "RightFistSocket"
	contact_socket.bone_name = "hand_r"
	target.add_child(contact_socket)
	palm_offset = Vector3(0, 0.065, 0)
	idle_driver = preload("res://combat/snaiel/scripts/animations/subclasses/idle_animations.gd").new()
	movement_driver = preload("res://combat/snaiel/scripts/animations/subclasses/movement_animations.gd").new()
	hit_driver = preload("res://combat/snaiel/scripts/animations/subclasses/hit_and_death_animations.gd").new()
	for driver in [idle_driver, movement_driver, hit_driver]:
		driver.character = self
		add_child(driver)
	play("Idle")

func _retarget(original: Animation, source: Skeleton3D, target: Skeleton3D) -> Animation:
	# Model-space rest deltas, as in the selected village's pose adapter.
	# Bake at the imported 30 Hz cadence into private tracks. Target bone lengths
	# stay intact; only vertical pelvis motion survives. Physics owns all travel.
	var clip := Animation.new()
	clip.length = original.length
	var rotations := {}
	var pelvis_track := -1
	for track in original.get_track_count():
		var path := original.track_get_path(track)
		if path.get_subname_count() != 1: continue
		var bone := String(path.get_subname(0))
		if original.track_get_type(track) == Animation.TYPE_ROTATION_3D: rotations[bone] = track
		if bone == "pelvis" and original.track_get_type(track) == Animation.TYPE_POSITION_3D: pelvis_track = track
	var tracks: Array[int] = []
	for index in target.get_bone_count():
		var name := target.get_bone_name(index)
		assert(source.find_bone(name) >= 0, "E02 UAL rig has a missing bone")
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath("Armature/Skeleton3D:" + name))
		tracks.append(track)
	var vertical := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(vertical, NodePath("Armature/Skeleton3D:pelvis"))
	var source_pelvis := source.find_bone("pelvis")
	var target_pelvis := target.find_bone("pelvis")
	var source_frame: Basis = source.get_parent().basis * source.basis
	var target_frame: Basis = target.get_parent().basis * target.basis
	var source_height: float = (source_frame * source.get_bone_global_rest(source_pelvis).origin).y
	var target_height: float = (target_frame * target.get_bone_global_rest(target_pelvis).origin).y
	var steps := ceili(clip.length * 30)
	for sample in range(steps + 1):
		var time := minf(float(sample) / 30.0, clip.length)
		var source_global: Array[Basis] = []
		for index in source.get_bone_count():
			var name := source.get_bone_name(index)
			var local := source.get_bone_rest(index).basis
			if rotations.has(name): local = Basis(original.rotation_track_interpolate(rotations[name], time))
			var parent := source.get_bone_parent(index)
			source_global.append(source_global[parent] * local if parent >= 0 else local)
		var target_global: Array[Basis] = []
		for index in target.get_bone_count():
			var source_index := source.find_bone(target.get_bone_name(index))
			var desired := source_global[source_index] * source.get_bone_global_rest(source_index).basis.inverse() * target.get_bone_global_rest(index).basis
			var parent := target.get_bone_parent(index)
			var local := target_global[parent].inverse() * desired if parent >= 0 else desired
			target_global.append(desired)
			clip.rotation_track_insert_key(tracks[index], time, local.orthonormalized().get_rotation_quaternion())
		var position := target.get_bone_rest(target_pelvis).origin
		if pelvis_track >= 0:
			var delta: Vector3 = source_frame * (original.position_track_interpolate(pelvis_track, time) - source.get_bone_rest(source_pelvis).origin)
			position += target_frame.inverse() * Vector3.UP * delta.y * (target_height / source_height)
		clip.position_track_insert_key(vertical, time, position)
	return clip
