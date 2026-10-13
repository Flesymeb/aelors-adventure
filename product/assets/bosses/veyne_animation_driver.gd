extends "res://combat/snaiel/scripts/animations/character_animations.gd"
## European Dragon native rig. Physics owns travel; supplemental creature clips
## are authored against this skeleton, without humanoid retargeting.
const NATIVE_CLIPS := {
 "Idle": "Idle Stand", "Walk": "Walk", "Run": "Run", "Flight": "Fly",
 "Punch": "Claw", "HitReact": "Hurt", "Death": "Death",
 "Cast": "Breath", "Reveal": "Reveal", "Takeoff": "Takeoff",
 "Dive": "Dive", "Land": "Landing", "Charge": "Run"
}
var casting_socket: BoneAttachment3D

func configure(model: Node3D) -> void:
	anim_player = model.find_child("AnimationPlayer", true, false)
	skeleton = model.find_child("Skeleton3D", true, false)
	if not anim_player or not skeleton:
		push_error("Veyne native animation player/skeleton missing")
		return
	author_creature_clips()
	var library := AnimationLibrary.new()
	for alias in NATIVE_CLIPS:
		var native_key: String = NATIVE_CLIPS[alias]
		if not anim_player.has_animation(native_key):
			push_error("Veyne missing imported native clip: " + native_key)
			return
		var clip: Animation = anim_player.get_animation(native_key).duplicate()
		clip.loop_mode = Animation.LOOP_LINEAR if alias in ["Idle", "Walk", "Run", "Flight", "Charge"] else Animation.LOOP_NONE
		anchor_horizontal_root(clip)
		library.add_animation(alias, clip)
	anim_player.add_animation_library("veyne", library)
	# The inherited defeated-save restore addresses Death in the default library.
	var native_library: AnimationLibrary = anim_player.get_animation_library("")
	if native_library.has_animation("Death"): native_library.remove_animation("Death")
	native_library.add_animation("Death", library.get_animation("Death"))
	anim_player.stop()
	anim_tree = AnimationTree.new()
	model.add_child(anim_tree)
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)
	anim_tree.root_node = NodePath("..")
	anim_tree.tree_root = BLEND_TREE.duplicate(true)
	var action: AnimationNodeStateMachine = anim_tree.tree_root.get_node("TimedAction").get_node("Action")
	for alias in ["Idle", "Walk", "Punch", "HitReact", "Death"]:
		action.get_node(alias).animation = "veyne/" + alias
	anim_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	anim_tree.active = true
	playback = anim_tree.get("parameters/TimedAction/Action/playback")
	contact_socket = BoneAttachment3D.new()
	contact_socket.name = "DragonRightClaw"
	contact_socket.bone_name = "DEF-Finger_2.R_073"
	skeleton.add_child(contact_socket)
	palm_offset = Vector3.ZERO
	casting_socket = BoneAttachment3D.new()
	casting_socket.name = "DragonMouth"
	casting_socket.bone_name = "DEF-Teeth_Top_013"
	skeleton.add_child(casting_socket)
	idle_driver = preload("res://combat/snaiel/scripts/animations/subclasses/idle_animations.gd").new()
	movement_driver = preload("res://combat/snaiel/scripts/animations/subclasses/movement_animations.gd").new()
	hit_driver = preload("res://combat/snaiel/scripts/animations/subclasses/hit_and_death_animations.gd").new()
	for driver in [idle_driver, movement_driver, hit_driver]:
		driver.character = self
		add_child(driver)
	play("Idle", 1.0, true)

func author_creature_clips() -> void:
	var native: AnimationLibrary = anim_player.get_animation_library("")
	# Duplicate neutral tracks so every transient restores all other bones.
	# Each keyed delta is composed in this bone's native local Rest convention.
	var recipes := {
	 "Reveal": [1.8, {"DEF-neck.002_010":Vector3(0.25,0,0),"DEF-Wing_Base.L_081":Vector3(0,0,-0.35),"DEF-Wing_Base.R_097":Vector3(0,0,0.35)}],
	 "Breath": [2.6, {"DEF-Teeth_Bottom_016":Vector3(0.5,0,0),"DEF-neck.003_011":Vector3(-0.35,0,0),"DEF-neck.004_012":Vector3(-0.2,0,0)}],
	 "Claw": [1.8, {"DEF-upper_arm.R_061":Vector3(0.15,0,0.8),"DEF-forearm.R_063":Vector3(-0.8,0,0),"DEF-neck.002_010":Vector3(0,0.2,0)}],
	 "Hurt": [0.5, {"DEF-Spine.003_05":Vector3(0.1,0,0.2),"DEF-neck_08":Vector3(0.2,0,0)}],
	 "Death": [2.4, {"DEF-Spine_02":Vector3(0.1,0,1.2),"DEF-neck_08":Vector3(0.5,0,0),"DEF-upper_arm.L_040":Vector3(-0.7,0,0),"DEF-upper_arm.R_061":Vector3(-0.7,0,0)}],
	 "Takeoff": [0.9, {"DEF-Wing_Base.L_081":Vector3(0,0,-0.9),"DEF-Wing_Base.R_097":Vector3(0,0,0.9),"DEF-thigh.L_0112":Vector3(-0.4,0,0),"DEF-thigh.R_0132":Vector3(-0.4,0,0)}],
	 "Dive": [0.7, {"DEF-Wing_Base.L_081":Vector3(0,0,0.35),"DEF-Wing_Base.R_097":Vector3(0,0,-0.35),"DEF-neck_08":Vector3(-0.3,0,0)}],
	 "Landing": [1.8, {"DEF-thigh.L_0112":Vector3(0.5,0,0),"DEF-thigh.R_0132":Vector3(0.5,0,0),"DEF-Wing_Base.L_081":Vector3(0,0,-0.6),"DEF-Wing_Base.R_097":Vector3(0,0,0.6)}]
	}
	for key in recipes:
		var base: Animation = anim_player.get_animation("Idle Stand")
		var clip: Animation = base.duplicate()
		clip.length = recipes[key][0]
		clip.loop_mode = Animation.LOOP_NONE
		# Freeze neutral sample; no Idle loop competes with the authored action.
		for track in clip.get_track_count():
			if clip.track_get_key_count(track) == 0: continue
			var value = clip.track_get_key_value(track,0)
			while clip.track_get_key_count(track) > 0: clip.track_remove_key(track,0)
			clip.track_insert_key(track,0,value)
		for bone_name in recipes[key][1]:
			var bone := skeleton.find_bone(bone_name)
			if bone < 0: push_error("Dragon required bone missing: "+bone_name); continue
			var path := NodePath(str(anim_player.get_node(anim_player.root_node).get_path_to(skeleton))+":"+bone_name)
			var track := clip.find_track(path,Animation.TYPE_ROTATION_3D)
			if track < 0: track = clip.add_track(Animation.TYPE_ROTATION_3D); clip.track_set_path(track,path)
			var rest: Quaternion = clip.track_get_key_value(track,0) if clip.track_get_key_count(track) > 0 else skeleton.get_bone_pose_rotation(bone)
			var delta_pose := Quaternion.from_euler(recipes[key][1][bone_name])
			clip.rotation_track_insert_key(track,0,rest)
			clip.rotation_track_insert_key(track,clip.length*0.35,rest*delta_pose)
			clip.rotation_track_insert_key(track,clip.length*0.75,rest*delta_pose)
			clip.rotation_track_insert_key(track,clip.length,rest*delta_pose if key == "Death" else rest)
		native.add_animation(key,clip)

static func anchor_horizontal_root(clip: Animation) -> void:
	for track in clip.get_track_count():
		if clip.track_get_type(track) != Animation.TYPE_POSITION_3D: continue
		var bone_name := str(clip.track_get_path(track)).get_slice(":",1)
		if bone_name not in ["_rootJoint","DEF-Spine_02"] or clip.track_get_key_count(track) == 0: continue
		var first: Vector3 = clip.track_get_key_value(track,0)
		for key in clip.track_get_key_count(track):
			var value: Vector3 = clip.track_get_key_value(track,key)
			value.x = first.x; value.z = first.z
			clip.track_set_key_value(track,key,value)

func play(clip: String, speed: float = 1.0, restart := false) -> void:
	if clip in ["Cast", "Reveal", "Run", "Flight", "Takeoff", "Dive", "Land", "Charge"]:
		anim_tree.active = false
		if active_clip != clip or restart:
			anim_player.speed_scale = 1.0
			anim_player.play("veyne/" + clip, 0.08, speed)
		else:
			anim_player.speed_scale = speed
		active_clip = clip
		return
	if not anim_tree.active:
		anim_player.stop()
		anim_player.speed_scale = 1.0
		anim_tree.active = true
	super(clip, speed, restart)

func set_speed(speed: float) -> void:
	if anim_tree.active:
		super(speed)
	else:
		anim_player.speed_scale = speed

func get_state_bindings() -> Dictionary:
	return NATIVE_CLIPS.duplicate()

func casting_position() -> Vector3:
	return casting_socket.global_position if is_instance_valid(casting_socket) else fist_position()

func posed_bounds(model_root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	skeleton.force_update_all_bone_transforms()
	for mesh in model_root.find_children("*","MeshInstance3D",true,false):
		if not mesh.skin: continue
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
				point = model_root.global_transform.affine_inverse()*skeleton.global_transform*point
				box = AABB(point,Vector3.ZERO) if first else box.expand(point)
				first = false
	return box

func _mcp_state() -> Dictionary:
	var result := super()
	result["native_states"] = NATIVE_CLIPS.duplicate()
	result["native_visual_forward"] = "+Z"
	result["native_mouth_bone"] = "DEF-Teeth_Top_013"
	result["casting_position"] = casting_position()
	return result
