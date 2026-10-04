extends SkeletonModifier3D

# Transfer model-space rotation changes, not raw local quaternions. The rigs
# have different rest axes and a different number of wrist/spine bones.
const BONE_MAP := {
	"pelvis": "hips", "spine_01": "spine", "spine_03": "chest", "Head": "head",
	"upperarm_l": "upperarm.l", "lowerarm_l": "lowerarm.l", "hand_l": "hand.l",
	"upperarm_r": "upperarm.r", "lowerarm_r": "lowerarm.r", "hand_r": "hand.r",
	"thigh_l": "upperleg.l", "calf_l": "lowerleg.l", "foot_l": "foot.l", "ball_l": "toes.l",
	"thigh_r": "upperleg.r", "calf_r": "lowerleg.r", "foot_r": "foot.r", "ball_r": "toes.r",
}

var source_skeleton: Skeleton3D
var source_player: AnimationPlayer
var mappings: Array[Dictionary] = []
var pose_weight := 0.0
var lower_body_weight := 0.0
var clip := "Ranged_Bow_Draw"
var clip_time := 0.7
var pitch := 0.0
var previous_clip := ""
var transition_time := 0.16
var transition_from: Dictionary = {}
var last_rotations: Dictionary = {}


func configure(source: Skeleton3D, animations: AnimationPlayer) -> void:
	source_skeleton = source
	source_player = animations
	var target := get_skeleton()
	for i in range(target.get_bone_count()):
		var name := target.get_bone_name(i)
		if not BONE_MAP.has(name):
			continue
		var source_index := source.find_bone(BONE_MAP[name])
		if source_index < 0:
			continue
		mappings.append({
			"target": i, "source": source_index,
			"source_rest_inverse": source.get_bone_global_rest(source_index).basis.orthonormalized().inverse(),
			"target_rest": target.get_bone_global_rest(i).basis.orthonormalized(),
			"lower": name == "pelvis" or name.begins_with("thigh_") or name.begins_with("calf_") or name.begins_with("foot_") or name.begins_with("ball_"),
		})


func _process_modification() -> void:
	if source_player == null or pose_weight < 0.001:
		previous_clip = ""
		last_rotations.clear()
		return
	if clip != previous_clip:
		transition_from = last_rotations.duplicate()
		transition_time = 0.0
		previous_clip = clip
	transition_time = minf(0.16, transition_time + get_process_delta_time())
	var blend := smoothstep(0.0, 0.16, transition_time)
	if source_player.current_animation != clip:
		source_player.play(clip)
		source_player.pause()
	source_player.seek(clip_time, true)
	source_skeleton.force_update_all_bone_transforms()
	var target := get_skeleton()
	for mapping in mappings:
		var weight := lower_body_weight if mapping.lower else pose_weight
		if weight < 0.001:
			continue
		var index: int = mapping.target
		var desired: Basis = source_skeleton.get_bone_global_pose(mapping.source).basis.orthonormalized() * mapping.source_rest_inverse * mapping.target_rest
		if not mapping.lower:
			desired = Basis(Vector3.RIGHT, pitch) * desired
		var desired_rotation := desired.get_rotation_quaternion()
		if transition_from.has(index) and blend < 1.0:
			desired_rotation = (transition_from[index] as Quaternion).slerp(desired_rotation, blend)
		last_rotations[index] = desired_rotation
		desired = Basis(desired_rotation)
		var parent := target.get_bone_parent(index)
		var parent_basis := target.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
		var rotation := (parent_basis.inverse() * desired).get_rotation_quaternion()
		target.set_bone_pose_rotation(index, target.get_bone_pose_rotation(index).slerp(rotation, weight))
