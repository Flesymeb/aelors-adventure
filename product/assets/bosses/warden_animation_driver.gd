extends "res://combat/snaiel/scripts/animations/character_animations.gd"
## Native Phons golem rig; no humanoid retargeting or Ranger socket assumptions.
const CLIPS := {"Idle":"Idle", "Walk":"Walk", "Punch":"Attack1", "HitReact":"Defence3", "Wave":"Attack3", "Reveal":"IdlePieces", "Death":"IdlePieces"}

func configure(model: Node3D) -> void:
	anim_player = model.find_child("AnimationPlayer",true,false)
	skeleton = model.find_child("Skeleton3D",true,false)
	# Keep the importer root and the native skin/rest/track paths together.
	var library := AnimationLibrary.new()
	var originals := {}
	for alias in CLIPS:
		var key: String = CLIPS[alias]
		if not anim_player.has_animation(key):
			push_error("Warden missing native clip: " + key)
			return
		originals[alias] = anim_player.get_animation(key)
	for alias in CLIPS:
		var clip: Animation = reversed_clip(originals[alias]) if alias == "Death" else originals[alias].duplicate()
		clip.loop_mode = Animation.LOOP_LINEAR if alias in ["Idle","Walk"] else Animation.LOOP_NONE
		if alias == "Walk": anchor_locomotion(clip)
		library.add_animation(alias,clip)
	# Private aliases leave the imported native library unchanged.
	anim_player.add_animation_library("warden",library)
	# The inherited durable defeated restore addresses the exact default key.
	anim_player.get_animation_library("").add_animation("Death",library.get_animation("Death"))
	anim_player.stop()
	anim_tree = AnimationTree.new()
	model.add_child(anim_tree)
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)
	anim_tree.root_node = NodePath("..")
	anim_tree.tree_root = BLEND_TREE.duplicate(true)
	var action: AnimationNodeStateMachine = anim_tree.tree_root.get_node("TimedAction").get_node("Action")
	for alias in ["Idle","Walk","Punch","HitReact","Death"]:
		action.get_node(alias).animation = "warden/" + alias
	anim_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	anim_tree.active = true
	playback = anim_tree.get("parameters/TimedAction/Action/playback")
	contact_socket = BoneAttachment3D.new()
	contact_socket.name = "NativeBoulderContact"
	contact_socket.bone_name = "Boulder.r_12"
	if skeleton.find_bone(contact_socket.bone_name) < 0:
		push_error("Warden missing native boulder bone")
		return
	skeleton.add_child(contact_socket)
	# 94 native vertices bound to Boulder.r_12 (>0.8 weight), transformed
	# by its inverse bind: bounds (-2.199605,-1.053862,-2.446226),
	# size (4.770992,4.430842,4.643605). Contact follows the stone mass,
	# not the proximal attachment bone at the edge of the rock.
	palm_offset = Vector3(0.185891,1.16156,-0.124424)
	idle_driver = preload("res://combat/snaiel/scripts/animations/subclasses/idle_animations.gd").new()
	movement_driver = preload("res://combat/snaiel/scripts/animations/subclasses/movement_animations.gd").new()
	hit_driver = preload("res://combat/snaiel/scripts/animations/subclasses/hit_and_death_animations.gd").new()
	for driver in [idle_driver,movement_driver,hit_driver]:
		driver.character = self
		add_child(driver)
	play("Idle",1,true)

static func anchor_locomotion(clip: Animation) -> void:
	# ROOT_4's parent joint has an identity rest in this native Y-up rig.
	# Preserve Y bob; physics owns horizontal X/Z travel.
	for track in clip.get_track_count():
		if clip.track_get_type(track) != Animation.TYPE_POSITION_3D or not str(clip.track_get_path(track)).ends_with(":ROOT_4"): continue
		var first: Vector3 = clip.track_get_key_value(track,0)
		for key in clip.track_get_key_count(track):
			var value: Vector3 = clip.track_get_key_value(track,key)
			value.x = first.x
			value.z = first.z
			clip.track_set_key_value(track,key,value)

static func reversed_clip(native: Animation) -> Animation:
	var result := Animation.new()
	result.length = native.length
	for index in native.get_track_count():
		var track := result.add_track(native.track_get_type(index))
		result.track_set_path(track,native.track_get_path(index))
		result.track_set_interpolation_type(track,native.track_get_interpolation_type(index))
		for key in native.track_get_key_count(index):
			result.track_insert_key(track,native.length-native.track_get_key_time(index,key),native.track_get_key_value(index,key))
	return result

func play(clip: String, speed: float = 1.0, restart := false) -> void:
	# Wave uses a native clip outside the five-state inherited blend tree.
	if clip == "Wave":
		anim_tree.active = false
		if active_clip != clip or restart:
			anim_player.speed_scale = 1.0
			anim_player.play("warden/Wave",-1,speed)
		else: anim_player.speed_scale = speed
		active_clip = clip
		return
	if not anim_tree.active:
		anim_player.stop()
		anim_player.speed_scale = 1.0
		anim_tree.active = true
	super(clip,speed,restart)
