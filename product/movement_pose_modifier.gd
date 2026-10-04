extends "res://bow_pose_modifier.gd"

# The crawl/dodge rig is smaller than Ranger. Transfer vertical hip displacement
# relative to rest, scaled by hip height; gameplay owns horizontal displacement.
var root_height_scale := 1.0
var root_blend := 0.0
var breathing_weight := 0.0
var breath_blend := 0.0
var breath_clock := 0.0

func configure(source: Skeleton3D, animations: AnimationPlayer) -> void:
	super.configure(source, animations)
	var target := get_skeleton()
	root_height_scale = target.get_bone_global_rest(target.find_bone("pelvis")).origin.y / maxf(0.01, source.get_bone_global_rest(source.find_bone("hips")).origin.y)

func _process_modification() -> void:
	super._process_modification()
	breath_clock += get_process_delta_time()
	breath_blend = lerpf(breath_blend, breathing_weight, 1.0 - exp(-8.0 * get_process_delta_time()))
	if breath_blend > 0.001:
		var chest := get_skeleton().find_bone("spine_03")
		var amount := sin(breath_clock * TAU / 4.2) * 0.005 * breath_blend
		var scale := get_skeleton().get_bone_pose_scale(chest)
		get_skeleton().set_bone_pose_scale(chest, scale * Vector3(1.0 + amount, 1.0 + amount * 0.4, 1.0 + amount))
	root_blend = lerpf(root_blend, pose_weight, 1.0 - exp(-18.0 * get_process_delta_time()))
	if source_skeleton == null or root_blend < 0.001:
		return
	var source_index := source_skeleton.find_bone("hips")
	var delta_y := (source_skeleton.get_bone_global_pose(source_index).origin.y - source_skeleton.get_bone_global_rest(source_index).origin.y) * root_height_scale
	var target := get_skeleton()
	var index := target.find_bone("pelvis")
	var parent := target.get_bone_parent(index)
	var parent_basis := target.get_bone_global_rest(parent).basis if parent >= 0 else Basis.IDENTITY
	var desired := target.get_bone_rest(index).origin + parent_basis.inverse() * Vector3(0, delta_y, 0)
	target.set_bone_pose_position(index, target.get_bone_pose_position(index).lerp(desired, root_blend))

	if clip == "Crawling":
		# Retaining Ranger's bone lengths can leave the smaller source rig's
		# contact points above the floor. Ground the support joints after retarget.
		var support := INF
		for bone in ["hand_l", "hand_r", "calf_l", "calf_r", "foot_l", "foot_r"]:
			support = minf(support, target.get_bone_global_pose(target.find_bone(bone)).origin.y)
		var correction: Vector3 = parent_basis.inverse() * Vector3(0, 0.055 - support, 0)
		target.set_bone_pose_position(index, target.get_bone_pose_position(index) + correction * root_blend)
