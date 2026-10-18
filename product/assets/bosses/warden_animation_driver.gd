extends "res://combat/snaiel/scripts/animations/character_animations.gd"
## Native Phons golem rig; no humanoid retargeting or Ranger socket assumptions.
const CLIPS := {"Idle":"Idle", "Walk":"Walk", "Punch":"Attack1", "HitReact":"Defence3", "Wave":"Attack3", "Reveal":"IdlePieces", "Death":"IdlePieces"}
var presentation_clip := ""
var presentation_position := 0.0
var prior_callback := AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS

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
	var native_library: AnimationLibrary = anim_player.get_animation_library("")
	if native_library.has_animation("Death"): native_library.remove_animation("Death")
	native_library.add_animation("Death",library.get_animation("Death"))
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
	if presentation_clip != "": end_presentation(false)
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

func begin_presentation(clip: String) -> void:
	# The existing native player is the sole pose owner. Only this clip is
	# sampled while encounter AI, contact and physics remain world-paused.
	if presentation_clip != "": end_presentation(false)
	prior_callback = anim_player.callback_mode_process
	anim_tree.active = false
	anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	anim_player.speed_scale = 1.0
	presentation_clip = "warden/"+clip
	presentation_position = 0.0
	active_clip = clip
	anim_player.play(presentation_clip)
	anim_player.seek(0.0,true)
	anim_player.pause()

func advance_presentation(delta: float) -> void:
	if presentation_clip == "": return
	presentation_position = minf(presentation_position+delta,anim_player.get_animation(presentation_clip).length)
	anim_player.seek(presentation_position,true)

func end_presentation(hold_final: bool) -> void:
	if presentation_clip == "": return
	if hold_final:
		presentation_position = anim_player.get_animation(presentation_clip).length
		anim_player.seek(presentation_position,true)
		anim_player.pause()
	else: anim_player.stop()
	anim_player.callback_mode_process = prior_callback
	presentation_clip = ""
	if not hold_final:
		anim_tree.active = true
		active_clip = ""
		super.play("Idle",1.0,true)

func presentation_bounds(model_root: Node3D) -> AABB:
	# Include the scattered pieces and the assembled pose before choosing a
	# camera. A capsule/rest-mesh box cannot describe this native assembly rig.
	var clip: Animation = anim_player.get_animation(presentation_clip)
	var bounds := AABB()
	for fraction in [0.0,0.5,1.0]:
		anim_player.seek(clip.length*fraction,true)
		var posed := posed_world_bounds(model_root)
		bounds = posed if fraction == 0.0 else bounds.merge(posed)
	anim_player.seek(presentation_position,true)
	return bounds

func posed_world_bounds(model_root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	skeleton.force_update_all_bone_transforms()
	for mesh in model_root.find_children("*","MeshInstance3D",true,false):
		if not mesh.skin or not mesh.mesh: continue
		var transforms: Array[Transform3D] = []
		for bind in mesh.skin.get_bind_count():
			var bone: int = mesh.skin.get_bind_bone(bind)
			if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(bind))
			transforms.append(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind))
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences: int = weights.size()/vertices.size()
			for vertex in vertices.size():
				var point := Vector3.ZERO
				for influence in influences:
					var i := vertex*influences+influence
					if weights[i] > 0: point += (transforms[bones[i]]*vertices[vertex])*weights[i]
				point = skeleton.global_transform*point
				box = AABB(point,Vector3.ZERO) if first else box.expand(point)
				first = false
	return box

func _mcp_state() -> Dictionary:
	var result := super()
	result["presentation_clip"] = presentation_clip
	result["presentation_position"] = presentation_position
	return result
