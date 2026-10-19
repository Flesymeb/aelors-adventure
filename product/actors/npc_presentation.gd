extends Node3D
## Presentation-only extraction of the selected village rig and calibrated mounts.
## No InputMap, player input, camera, traversal, projectile or save ownership.
@export var appearance: Resource
@export var model_scene: PackedScene
@export var assembled_head := false
const MODEL_PATH = "res://Characters/QuaterniusRanger/Male_Ranger.gltf"
const ANIMATION_PATH = "res://Characters/QuaterniusAnimations/UAL1_Standard.glb"
const SWORD_ANIMATION_PATH = "res://Characters/QuaterniusAnimations/UAL2_Standard.glb"
const BOW_ANIMATION_PATH = "res://Characters/KayKitAnimations/Rig_Medium_CombatRanged.glb"
const SWORD_PATH = "res://Weapons/Sword_Bronze.gltf"
const BOW_PATH = "res://Weapons/Bow_Golden.obj"
const HEAD_ASSEMBLY = preload("res://ranger_head_assembly.gd")
const BOW_POSE_SCRIPT = preload("res://bow_pose_modifier.gd")
const BOW_VISUAL_SCRIPT = preload("res://bow_visual.gd")
const BOW_IDLE_BASIS = Vector3(-0.556121, -0.448697, 3.117197)
var visual: Node3D
var character_model: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var current_animation = ""
var head_components: Array[MeshInstance3D] = []
var sword_attachment: BoneAttachment3D
var bow_attachment: BoneAttachment3D
var back_attachment: BoneAttachment3D
var sword_holder: Node3D
var bow_holder: Node3D
var sword_back_holder: Node3D
var bow_back_holder: Node3D
var bow_visual: Node3D
var bow_pose: SkeletonModifier3D
var bow_ik: TwoBoneIK3D
var bow_draw_target: Node3D
var bow_elbow_target: Node3D
var bow_frame = Transform3D.IDENTITY
var weapon_mode = "unarmed"
var owns_sword = false
var owns_bow = false
var aim_requested = false
var aim_blend = 0.0
var bow_state = "idle"
var bow_charge = 0.0
var bow_clock = 0.0
var release_charge = 0.0

func configure_equipment(sword: bool, bow: bool, mode: String) -> void:
	owns_sword = sword
	owns_bow = bow
	weapon_mode = mode

func _ready() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	character_model = (model_scene if model_scene else load(MODEL_PATH)).instantiate()
	visual.add_child(character_model)
	skeleton = character_model.get_node("Armature/Skeleton3D")
	var hood := character_model.find_child("Male_Ranger_Head_Hood", true, false) as MeshInstance3D
	if hood: head_components.append(hood)
	if assembled_head:
		for mesh in character_model.find_children("BaseHead_*", "MeshInstance3D", true, false): head_components.append(mesh)
	else:
		head_components.append_array(HEAD_ASSEMBLY.assemble(skeleton))
	var source = load(ANIMATION_PATH).instantiate()
	animation_player = source.get_node("AnimationPlayer")
	animation_player.owner = null
	source.remove_child(animation_player)
	character_model.add_child(animation_player)
	source.free()
	# Sword_Idle in the imported library is a one-shot: it used to finish after
	# 1.67 seconds and leave the village guard frozen indefinitely. Keep these
	# edits actor-local; Aelor and combat animations retain their source clips.
	var idle_library: AnimationLibrary = animation_player.get_animation_library("").duplicate()
	for idle_name in ["Idle","Sword_Idle","Idle_Talking"]:
		if not idle_library.has_animation(idle_name): continue
		var idle_clip: Animation = idle_library.get_animation(idle_name).duplicate(true)
		idle_clip.loop_mode = Animation.LOOP_LINEAR
		idle_library.remove_animation(idle_name)
		idle_library.add_animation(idle_name,idle_clip)
	animation_player.remove_animation_library("")
	animation_player.add_animation_library("",idle_library)
	var extra = load(SWORD_ANIMATION_PATH).instantiate()
	animation_player.add_animation_library("sword", extra.get_node("AnimationPlayer").get_animation_library("").duplicate(true))
	extra.free()
	_attach_weapons()
	_setup_archery()
	_apply_appearance()
	preload("res://actors/mesh_qualification.gd").qualify_tree(visual)
	_play_animation("Sword_Idle" if weapon_mode == "sword" else "Idle")
	# A restored conversation can pause before this rig's first process tick.
	# Evaluate the requested pose now without advancing its animation clock.
	animation_player.advance(0)

func _apply_appearance() -> void:
	if not appearance: return
	for mesh in character_model.find_children("*", "MeshInstance3D", true, false):
		if String(mesh.name) in appearance.hidden_parts: mesh.hide()
		for surface in mesh.mesh.get_surface_count():
			var source = mesh.get_active_material(surface) as StandardMaterial3D
			if source:
				var material = source.duplicate() as StandardMaterial3D
				if "Pauldron" in String(mesh.name) and appearance.armored:
					material.albedo_color = appearance.metal_color
					material.albedo_texture = null
					material.metallic = 0.7
					material.roughness = 0.5
				elif "BaseHead" not in String(mesh.name):
					material.albedo_color = appearance.cloth_color
				mesh.set_surface_override_material(surface, material)
	if appearance.armored:
		# Reuse the authored armor mesh, mirrored across the rig. No primitive armor.
		var shoulder = character_model.find_child("Male_Ranger_Acc_Pauldron", true, false) as MeshInstance3D
		if shoulder:
			var other = shoulder.duplicate() as MeshInstance3D
			other.name = "GuardSecondPauldron"
			shoulder.get_parent().add_child(other)
			other.scale.x = -1
			other.visible = true
			other.set_surface_override_material(0, shoulder.get_active_material(0).duplicate())
	if appearance.quiver:
		var bundle = Node3D.new()
		bundle.name = "HunterArrowBundle"
		back_attachment.add_child(bundle)
		bundle.position = Vector3(-0.22, 0.1, -0.15)
		bundle.rotation.z = -0.25
		for i in 5:
			var arrow = MeshInstance3D.new()
			arrow.mesh = load("res://Weapons/Arrow.obj")
			arrow.scale = Vector3.ONE * 0.24
			# The authored arrow runs along +Z; rotate its shaft up the back.
			arrow.rotation.x = -PI / 2
			arrow.position = Vector3(i * 0.025, 0, 0)
			bundle.add_child(arrow)

func _set_weapon_visibility() -> void:
	if sword_holder: sword_holder.visible = owns_sword and weapon_mode == "sword"
	if bow_holder: bow_holder.visible = owns_bow and weapon_mode == "bow"
	if sword_back_holder: sword_back_holder.visible = owns_sword and weapon_mode != "sword"
	if bow_back_holder: bow_back_holder.visible = owns_bow and weapon_mode != "bow"

func reset_archery() -> void:
	aim_requested = false
	aim_blend = 0
	bow_state = "idle"
	bow_charge = 0
	bow_clock = 0
	_update_archery(0)

func _update_archery(delta: float) -> void:
	aim_blend = lerpf(aim_blend, 1.0 if aim_requested else 0.0, 1.0 - exp(-4.5 * delta))
	if bow_state == "draw":
		bow_charge = minf(1, bow_charge + delta)
		if bow_charge >= 1:
			bow_state = "hold"
			bow_clock = 0
	elif bow_state in ["hold", "release"]:
		bow_clock += delta
	if bow_pose:
		bow_pose.pose_weight = aim_blend
		bow_pose.lower_body_weight = aim_blend
		bow_pose.pitch = 0
		bow_pose.clip = "Ranged_Bow_Release" if bow_state == "release" else ("Ranged_Bow_Aiming_Idle" if bow_state == "hold" else "Ranged_Bow_Draw")
		bow_pose.clip_time = minf(1.32, 0.06 + bow_clock * 2.5) if bow_state == "release" else (fmod(bow_clock, 1.833) if bow_state == "hold" else 0.7 + bow_charge * 0.63)
		bow_ik.influence = 0 if bow_state == "release" else aim_blend

func _mcp_state() -> Dictionary:
	return {"presentation_only": true, "appearance": appearance.resource_path if appearance else "", "head_components": head_components.size(), "animation": animation_player.current_animation, "animation_position": animation_player.current_animation_position, "bow_state": bow_state, "bow_clip": bow_pose.clip if bow_pose else "", "bow_clip_time": bow_pose.clip_time if bow_pose else 0, "sword_in_hand": sword_holder.visible, "bow_in_hand": bow_holder.visible}

func _attach_weapons() -> void:
	if skeleton == null:
		return
	sword_attachment = BoneAttachment3D.new()
	sword_attachment.bone_name = "hand_r"
	skeleton.add_child(sword_attachment)
	sword_holder = Node3D.new()
	sword_holder.visible = false
	sword_attachment.add_child(sword_holder)
	# The hand bone starts at the wrist; the palm is about 6.5 cm along its Y axis.
	sword_holder.position.y = 0.065
	sword_holder.basis = Basis.from_euler(Vector3(0.496039, -0.808365, -2.084909))
	if ResourceLoader.exists(SWORD_PATH):
		var sword := (load(SWORD_PATH) as PackedScene).instantiate() as Node3D
		sword.position.y = 0.05  # The center of the handle is at source Y = -0.05.
		sword_holder.add_child(sword)

	bow_attachment = BoneAttachment3D.new()
	bow_attachment.bone_name = "hand_l"
	skeleton.add_child(bow_attachment)
	bow_holder = Node3D.new()
	bow_holder.visible = false
	bow_attachment.add_child(bow_holder)
	bow_holder.position.y = 0.065
	# Source +X points from bow limbs to string. Turn the string toward the
	# archer (local -Z) and the limbs toward the target (local +Z).
	bow_holder.basis = Basis.from_euler(Vector3(-0.556121, -0.448697, 3.117197)) * Basis(Vector3.UP, 0.85)
	if ResourceLoader.exists(BOW_PATH):
		bow_visual = Node3D.new()
		bow_visual.set_script(BOW_VISUAL_SCRIPT)
		bow_holder.add_child(bow_visual)

	back_attachment = BoneAttachment3D.new()
	back_attachment.bone_name = "spine_02"
	skeleton.add_child(back_attachment)
	sword_back_holder = Node3D.new()
	sword_back_holder.visible = false
	back_attachment.add_child(sword_back_holder)
	# The sword mesh extends from its grip along local +Y. Keep the grip above
	# the shoulder and point the blade diagonally down across the back.
	sword_back_holder.position = Vector3(0.12, 0.47, -0.25)
	sword_back_holder.basis = Basis.from_euler(Vector3(0.0681, 0.2316, -0.5581)) * Basis(Vector3.RIGHT, PI)
	if ResourceLoader.exists(SWORD_PATH):
		var stowed_sword := (load(SWORD_PATH) as PackedScene).instantiate() as Node3D
		stowed_sword.position.y = 0.05
		sword_back_holder.add_child(stowed_sword)

	bow_back_holder = Node3D.new()
	bow_back_holder.visible = false
	back_attachment.add_child(bow_back_holder)
	bow_back_holder.position = Vector3(0.0356, 0.1348, -0.1307)
	bow_back_holder.basis = Basis.from_euler(Vector3(-0.0318, 0.2324, 0.4920))
	if ResourceLoader.exists(BOW_PATH):
		var stowed_bow := MeshInstance3D.new()
		stowed_bow.mesh = load(BOW_PATH) as Mesh
		stowed_bow.scale = Vector3.ONE * 0.21
		stowed_bow.position.x = -0.0063
		bow_back_holder.add_child(stowed_bow)
	_set_weapon_visibility()

func _setup_archery() -> void:
	if skeleton == null or not ResourceLoader.exists(BOW_ANIMATION_PATH):
		push_warning("Bow aiming requires KayKit Rig_Medium_CombatRanged.glb; see README.")
		return
	var source := (load(BOW_ANIMATION_PATH) as PackedScene).instantiate() as Node3D
	source.name = "BowAnimationSource"
	source.visible = false
	add_child(source)
	bow_pose = SkeletonModifier3D.new()
	bow_pose.set_script(BOW_POSE_SCRIPT)
	skeleton.add_child(bow_pose)
	bow_pose.configure(source.find_child("Skeleton3D", true, false), source.get_node("AnimationPlayer"))
	bow_draw_target = Node3D.new()
	bow_draw_target.name = "BowDrawTarget"
	visual.add_child(bow_draw_target)
	bow_elbow_target = Node3D.new()
	bow_elbow_target.name = "BowElbowTarget"
	visual.add_child(bow_elbow_target)
	bow_ik = TwoBoneIK3D.new()
	skeleton.add_child(bow_ik)
	bow_ik.set_setting_count(1)
	bow_ik.set_root_bone_name(0, "upperarm_r")
	bow_ik.set_middle_bone_name(0, "lowerarm_r")
	bow_ik.set_end_bone_name(0, "hand_r")
	bow_ik.set_extend_end_bone(0, true)
	bow_ik.set_end_bone_direction(0, SkeletonModifier3D.BONE_DIRECTION_PLUS_Y)
	bow_ik.set_end_bone_length(0, 0.065)
	bow_ik.set_target_node(0, bow_ik.get_path_to(bow_draw_target))
	bow_ik.set_pole_node(0, bow_ik.get_path_to(bow_elbow_target))
	bow_ik.set_pole_direction(0, SkeletonModifier3D.SECONDARY_DIRECTION_PLUS_X)
	bow_ik.influence = 0.0
	bow_pose.modification_processed.connect(_prepare_bow_targets)
	skeleton.skeleton_updated.connect(_update_bow_visual)

func _play_animation(name: String, speed: float = 1.0) -> void:
	if animation_player == null or current_animation == name:
		return
	if animation_player.has_animation(name):
		animation_player.play(name, 0.16, speed)
		current_animation = name

func _update_bow_visual() -> void:
	if bow_visual == null:
		return
	var nock := bow_holder.to_local(bow_draw_target.global_position) if aim_blend > 0.001 else Vector3(0.2105, 0, 0)
	bow_visual.set_draw(aim_requested and bow_state != "release", nock, Vector3(-1, 0, 0))

func _prepare_bow_targets() -> void:
	var left := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("hand_l"))
	var forward := visual.global_basis.z.normalized()
	var up := visual.global_basis.y.normalized()
	var desired := Basis(-forward, up, (-forward).cross(up).normalized())
	var idle := Basis.from_euler(BOW_IDLE_BASIS) * Basis(Vector3.UP, 0.85)
	bow_holder.basis = Basis(idle.get_rotation_quaternion().slerp((left.basis.inverse() * desired).orthonormalized().get_rotation_quaternion(), aim_blend))
	bow_frame = left * bow_holder.transform
	var draw_amount: float = bow_charge
	if bow_state == "release":
		draw_amount = release_charge * exp(-bow_clock * 35.0)
	bow_draw_target.global_position = bow_frame * Vector3(0.2105 + draw_amount * 0.36, 0, 0)
	var elbow := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("lowerarm_r"))
	bow_elbow_target.global_position = elbow.origin + visual.global_basis.x * -0.2
