extends StaticBody3D
## Stationary story actor. Ground and visibility are checked on authored collision.
var grounded := false
var interaction_available := false
var grounding_normal := Vector3.UP
var model_height := 0.0
var interaction_distance := 2.8
var skeleton: Skeleton3D
var idle_bases: Dictionary = {}
var idle_player: AnimationPlayer

func _ready() -> void:
	add_to_group("isha")
	_normalize_model()
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.30
	capsule.height = 1.72
	collision.shape = capsule
	collision.position.y = 0.86
	add_child(collision)
	_ground.call_deferred()

func _normalize_model() -> void:
	var model := $Model as Node3D
	var bounds := AABB()
	var first := true
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var local: AABB = (model.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		bounds = local if first else bounds.merge(local)
		first = false
	model_height = bounds.size.y
	if model_height > 0.01:
		var scale_factor := 1.72 / model_height
		model.scale *= scale_factor
		model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * scale_factor
	for node in model.find_children("*", "Skeleton3D", true, false):
		skeleton = node
		break
	if skeleton:
		_pose_idle()
		_build_idle_clip()
	# The source uses blended skin for opaque cloth/body; avoid see-through faces.
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material:
				var copy := material.duplicate() as StandardMaterial3D
				copy.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				mesh.set_surface_override_material(surface, copy)

func _pose_idle() -> void:
	# Work in measured skeleton-global axes, then convert through each actual
	# parent rest. Source arms extend along +/-X; +Y is up and +Z is forward.
	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		if "LeftArm_" in bone_name or "RightArm_" in bone_name:
			var parent := skeleton.get_bone_parent(i)
			var parent_basis := skeleton.get_bone_global_rest(parent).basis
			var rest_basis := skeleton.get_bone_global_rest(i).basis
			var angle := -1.28 if "LeftArm_" in bone_name else 1.28
			var desired := Basis(Vector3.FORWARD, -angle) * rest_basis
			skeleton.set_bone_pose_rotation(i, (parent_basis.inverse() * desired).get_rotation_quaternion())
		if "Spine1_" in bone_name or "Head_" in bone_name:
			idle_bases[i] = skeleton.get_bone_pose_rotation(i)

func _build_idle_clip() -> void:
	# Animate the complete source skin; never reconstruct live cloth geometry.
	idle_player = AnimationPlayer.new()
	idle_player.name = "IdleAnimation"
	add_child(idle_player)
	var clip := Animation.new()
	clip.length = 3.5
	clip.loop_mode = Animation.LOOP_LINEAR
	for i in idle_bases:
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath(str(get_path_to(skeleton)) + ":" + skeleton.get_bone_name(i)))
		var amplitude := 0.009 if "Spine1_" in skeleton.get_bone_name(i) else 0.012
		for frame in 9:
			var time := float(frame) / 8.0 * clip.length
			clip.rotation_track_insert_key(track, time, idle_bases[i] * Quaternion(Vector3.RIGHT, sin(float(frame) / 8.0 * TAU) * amplitude))
	var library := AnimationLibrary.new()
	library.add_animation("Isha_Idle", clip)
	idle_player.add_animation_library("", library)
	idle_player.play("Isha_Idle")

func _ground() -> void:
	var world := get_parent()
	if world.meadow_slice: return
	for attempt in 120:
		await get_tree().physics_frame
		if preload("res://forest_ground.gd").place(world, self, preload("res://forest_ground.gd").ISHA):
			grounded = true
			grounding_normal = world.village.get_node("Terrain3D").data.get_normal(global_position)
			break
	if not grounded: push_error("Isha has no safe forest ground at the selected approach")


func can_interact(player: CharacterBody3D) -> bool:
	interaction_available = false
	if not grounded or global_position.distance_to(player.global_position) > interaction_distance:
		return false
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3(0, 1.35, 0), global_position + Vector3(0, 1.2, 0), 1, [player.get_rid(), get_rid()])
	interaction_available = get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	return interaction_available

func _mcp_state() -> Dictionary:
	return {"grounded": grounded, "interaction_available": interaction_available, "distance_limit": interaction_distance, "source_height": model_height, "actor_height": 1.72, "ground_normal": grounding_normal, "model_path": "res://assets/dialogue/isha_actor.glb", "skeleton_bones": skeleton.get_bone_count() if skeleton else 0, "idle_clip": idle_player.current_animation if idle_player else "", "idle_position": idle_player.current_animation_position if idle_player else 0.0, "idle_kind": "native-body skin transfer; skeletal breathing"}
