extends StaticBody3D
## Stationary story actor. Ground and visibility are checked on authored collision.
var grounded := false
var interaction_available := false
var grounding_normal := Vector3.UP
var model_height := 0.0
var interaction_distance := 2.8
var skeleton: Skeleton3D
var idle_clock := 0.0
var idle_bases: Dictionary = {}

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
		_bind_source_clothes()
		_pose_idle()
	# The source uses blended skin for opaque cloth/body; avoid see-through faces.
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material:
				var copy := material.duplicate() as StandardMaterial3D
				copy.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				mesh.set_surface_override_material(surface, copy)

func _bind_source_clothes() -> void:
	# This source's dress is rigid beside the skinned body. Bind its measured
	# sleeve region to the existing arm joints so cloth follows the lowered pose.
	var dress := $Model.find_child("Object_13", true, false) as MeshInstance3D
	if not dress:
		return
	var left := -1
	var right := -1
	var spine := -1
	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		if "LeftArm_" in bone_name: left = i
		if "RightArm_" in bone_name: right = i
		if "Spine2_" in bone_name: spine = i
	if left < 0 or right < 0 or spine < 0:
		push_error("Isha source dress binding joints are missing")
		return
	var skin := Skin.new()
	for i in skeleton.get_bone_count():
		skin.add_bind(i, skeleton.get_bone_global_rest(i).affine_inverse())
	var transform_to_rig := skeleton.global_transform.affine_inverse() * dress.global_transform
	var bound_mesh := ArrayMesh.new()
	for surface in dress.mesh.get_surface_count():
		var arrays := dress.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		bones.resize(vertices.size() * 4)
		weights.resize(vertices.size() * 4)
		for v in vertices.size():
			vertices[v] = transform_to_rig * vertices[v]
			if v < normals.size(): normals[v] = (transform_to_rig.basis.inverse().transposed() * normals[v]).normalized()
			if tangents.size() >= v * 4 + 4:
				var tangent := (transform_to_rig.basis * Vector3(tangents[v * 4], tangents[v * 4 + 1], tangents[v * 4 + 2])).normalized()
				tangents[v * 4] = tangent.x
				tangents[v * 4 + 1] = tangent.y
				tangents[v * 4 + 2] = tangent.z
			var sleeve := clampf((absf(vertices[v].x) - 9.0) / 9.0, 0.0, 1.0) if vertices[v].y > 111.0 else 0.0
			bones[v * 4] = left if vertices[v].x > 0 else right
			bones[v * 4 + 1] = spine
			weights[v * 4] = sleeve
			weights[v * 4 + 1] = 1.0 - sleeve
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TANGENT] = tangents
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		bound_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		bound_mesh.surface_set_material(surface, dress.mesh.surface_get_material(surface))
	dress.reparent(skeleton)
	dress.transform = Transform3D.IDENTITY
	dress.mesh = bound_mesh
	dress.skin = skin
	dress.skeleton = NodePath("..")

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

func _process(delta: float) -> void:
	if not skeleton:
		return
	idle_clock += delta
	for i in idle_bases:
		var amplitude := 0.012 if "Spine1_" in skeleton.get_bone_name(i) else 0.018
		skeleton.set_bone_pose_rotation(i, idle_bases[i] * Quaternion(Vector3.RIGHT, sin(idle_clock * 1.8) * amplitude))

func _ground() -> void:
	await get_tree().physics_frame
	var from := Vector3(global_position.x, 100, global_position.z)
	var to := Vector3(global_position.x, -100, global_position.z)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.normal.y > 0.75:
		global_position = hit.position + Vector3(0, 0.015, 0)
		grounding_normal = hit.normal
		grounded = true
	else:
		push_error("Isha has no safe authored ground at the selected approach")
		visible = false

func can_interact(player: CharacterBody3D) -> bool:
	interaction_available = false
	if not grounded or global_position.distance_to(player.global_position) > interaction_distance:
		return false
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3(0, 1.35, 0), global_position + Vector3(0, 1.2, 0), 1, [player.get_rid(), get_rid()])
	interaction_available = get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	return interaction_available

func _mcp_state() -> Dictionary:
	return {"grounded": grounded, "interaction_available": interaction_available, "distance_limit": interaction_distance, "source_height": model_height, "actor_height": 1.72, "ground_normal": grounding_normal, "model_path": "res://assets/dialogue/woman_comparison.glb", "skeleton_bones": skeleton.get_bone_count() if skeleton else 0, "idle_clock": idle_clock, "idle_kind": "source-rest-aware skeletal breathing; stationary NPC"}
