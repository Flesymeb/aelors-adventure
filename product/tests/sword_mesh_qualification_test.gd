extends Node
## Opt-in imported-mesh/mount diagnostic; never started by the shipped entry.
const PLAYER = preload("res://player_controller.gd")
const QUALIFICATION = preload("res://actors/mesh_qualification.gd")
var observations: Dictionary = {}

func _ready() -> void:
	observations = run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture": true, "observations": observations}

static func run(_holder: Node) -> Dictionary:
	var source := (load(PLAYER.SWORD_PATH) as PackedScene).instantiate()
	var original := _mesh(source)
	var source_arrays := _expanded(original)
	var source_bad := _degenerate_uvs(source_arrays)
	# Native ArrayMesh creation octahedrally encodes normals. An unchanged
	# rebuild is the exact control for that encode, independent of UV repair.
	var encoding_control := ArrayMesh.new()
	encoding_control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, original.surface_get_arrays(0))
	var control_arrays := _expanded(encoding_control)
	# Exercise both production instantiation paths without entering the actor's
	# tree or running gameplay, inventory grants, input or save initialization.
	var player := PLAYER.new()
	player.skeleton = Skeleton3D.new()
	player.add_child(player.skeleton)
	player._attach_weapons()
	var hand := _mesh(player.sword_holder)
	var back := _mesh(player.sword_back_holder)
	var hand_arrays := _expanded(hand)
	var back_arrays := _expanded(back)
	var points := PackedVector2Array([Vector2(0.1, 0.2), Vector2(0.7, 0.2), Vector2(0.4, 0.2)])
	QUALIFICATION._open_linear_uv(points, 0)
	var line_kept := points[0] == Vector2(0.1, 0.2) and points[1] == Vector2(0.7, 0.2)
	var line_opened := absf((points[1] - points[0]).cross(points[2] - points[0])) >= 1e-12
	player.configure_equipment(true, false, "sword")
	var hand_only: bool = player.sword_holder.visible and not player.sword_back_holder.visible
	player.configure_equipment(true, false, "unarmed")
	var back_only: bool = not player.sword_holder.visible and player.sword_back_holder.visible
	player.configure_equipment(false, false, "unarmed")
	var unearned_hidden: bool = not player.sword_holder.visible and not player.sword_back_holder.visible
	var result := {"checks": {
		"source_defect_reproduced": source_bad > 0,
		"hand_uvs_nondegenerate": _degenerate_uvs(hand_arrays) == 0,
		"back_uvs_nondegenerate": _degenerate_uvs(back_arrays) == 0,
		"authored_geometry_colors": _same_shape(source_arrays, hand_arrays) and _same_shape(source_arrays, back_arrays),
		"normals_match_unchanged_native_encode": hand_arrays[Mesh.ARRAY_NORMAL] == control_arrays[Mesh.ARRAY_NORMAL] and back_arrays[Mesh.ARRAY_NORMAL] == control_arrays[Mesh.ARRAY_NORMAL],
		"unchanged_trim_material": hand.surface_get_material(0) == original.surface_get_material(0) and back.surface_get_material(0) == original.surface_get_material(0),
		"valid_uvs_unchanged": _valid_uvs_unchanged(source_arrays, hand_arrays) and _valid_uvs_unchanged(source_arrays, back_arrays),
		"linear_trim_edge_retained": line_kept and line_opened,
		"finite_tangents": _finite_tangents(hand_arrays) and _finite_tangents(back_arrays),
		"source_resource_unchanged": _degenerate_uvs(_expanded(original)) == source_bad,
		"separate_single_mounts": hand != back and player.sword_holder.get_child_count() == 1 and player.sword_back_holder.get_child_count() == 1,
		"ownership_visibility": hand_only and back_only and unearned_hidden},
		"source_degenerate_triangles": source_bad,
		"normal_reencode_max_error": _normal_error(source_arrays, control_arrays),
		"normal_repair_max_error": _normal_error(source_arrays, hand_arrays),
		"scope": "Imported arrays and production mount construction only; ordinary earned equip, stow, moving attacks and rendered trim/normal shading remain independent native checks."}
	source.free()
	player.free()
	return result

static func _mesh(root: Node) -> ArrayMesh:
	return root.find_children("*", "MeshInstance3D", true, false)[0].mesh as ArrayMesh

static func _expanded(mesh: ArrayMesh) -> Array:
	# Observation must not re-encode normals through a second mesh creation.
	return QUALIFICATION._sword_arrays(mesh, 0)

static func _degenerate_uvs(arrays: Array) -> int:
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var count := 0
	for index in range(0, uvs.size() - 2, 3):
		if absf((uvs[index + 1] - uvs[index]).cross(uvs[index + 2] - uvs[index])) < 1e-12:
			count += 1
	return count

static func _same_shape(first: Array, second: Array) -> bool:
	return first[Mesh.ARRAY_VERTEX] == second[Mesh.ARRAY_VERTEX] and first[Mesh.ARRAY_COLOR] == second[Mesh.ARRAY_COLOR]

static func _normal_error(first: Array, second: Array) -> float:
	var before: PackedVector3Array = first[Mesh.ARRAY_NORMAL]
	var after: PackedVector3Array = second[Mesh.ARRAY_NORMAL]
	if before.size() != after.size(): return INF
	var maximum := 0.0
	for index in before.size(): maximum = maxf(maximum, before[index].distance_to(after[index]))
	return maximum

static func _valid_uvs_unchanged(first: Array, second: Array) -> bool:
	var before: PackedVector2Array = first[Mesh.ARRAY_TEX_UV]
	var after: PackedVector2Array = second[Mesh.ARRAY_TEX_UV]
	if before.size() != after.size(): return false
	for index in range(0, before.size() - 2, 3):
		if absf((before[index + 1] - before[index]).cross(before[index + 2] - before[index])) < 1e-12: continue
		for corner in 3:
			if before[index + corner] != after[index + corner]: return false
	return true

static func _finite_tangents(arrays: Array) -> bool:
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if tangents.size() != vertices.size() * 4: return false
	for index in range(0, tangents.size(), 4):
		var tangent := Vector3(tangents[index], tangents[index + 1], tangents[index + 2])
		if not tangent.is_finite() or tangent.length_squared() < 0.5 or not is_finite(tangents[index + 3]): return false
	return true
