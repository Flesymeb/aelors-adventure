extends RefCounted
## Opt-in retained-house array diagnostic. Never runs at shipped startup.
const HOUSE := "res://Prefabs/Town/Building/EA03_Town_House_Comp_01a_PRE.prefab.scn"
const SUBJECTS := ["EA03_Village_HouseModule_Porch_01d", "EA03_Town_Ill_Roof_01a", "EA03_Village_Hut_Ceiling_01e"]
const QUALIFICATION := preload("res://world/village_mesh_qualification.gd")

static func run() -> Dictionary:
	var source := (load(HOUSE) as PackedScene).instantiate()
	var first := (load(HOUSE) as PackedScene).instantiate()
	var repeated := (load(HOUSE) as PackedScene).instantiate()
	var collision_before := _collisions(first)
	QUALIFICATION.qualify_tree(first)
	QUALIFICATION.qualify_tree(repeated)
	var checks := {"collision_nodes_and_shapes_unchanged": collision_before == _collisions(first)}
	var rows := {}
	for node in source.find_children("*", "MeshInstance3D", true, false):
		var path := source.get_path_to(node)
		if not QUALIFICATION._selected(str(path)) or not node.mesh is ArrayMesh: continue
		var original: ArrayMesh = node.mesh
		var instance: MeshInstance3D = first.get_node(path)
		var repair: ArrayMesh = instance.mesh
		var arrays := QUALIFICATION.expanded_arrays(original)
		var result := QUALIFICATION.expanded_arrays(repair)
		var control := ArrayMesh.new()
		control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var encoded := QUALIFICATION.expanded_arrays(control)
		var before := surface_summary(original, 0)
		var after := surface_summary(repair, 0)
		var prefix := str(path) + ":"
		checks[prefix + "source_defect_reproduced"] = before.degenerate > 0
		checks[prefix + "uv_nondegenerate"] = after.degenerate == 0
		checks[prefix + "geometry_colors_uv2_unchanged"] = arrays[Mesh.ARRAY_VERTEX] == result[Mesh.ARRAY_VERTEX] and arrays[Mesh.ARRAY_COLOR] == result[Mesh.ARRAY_COLOR] and arrays[Mesh.ARRAY_TEX_UV2] == result[Mesh.ARRAY_TEX_UV2]
		checks[prefix + "normals_match_unchanged_native_encode"] = encoded[Mesh.ARRAY_NORMAL] == result[Mesh.ARRAY_NORMAL]
		checks[prefix + "valid_uvs_unchanged"] = _valid_uvs_unchanged(arrays, result)
		checks[prefix + "material_instance_visibility_transform_unchanged"] = original.surface_get_material(0) == repair.surface_get_material(0) and instance.visible == node.visible and instance.transform == node.transform
		checks[prefix + "finite_normals_tangents"] = _finite_directions(result)
		var color_error := _palette_error(original, arrays, result)
		checks[prefix + "filtered_palette_correspondence"] = color_error <= QUALIFICATION.MAX_COLOR_ERROR
		checks[prefix + "source_resource_unchanged"] = surface_summary(original, 0).degenerate == before.degenerate
		checks[prefix + "repeated_instance_uses_same_qualified_mesh"] = repeated.get_node(path).mesh == repair
		checks[prefix + "native_lod_geometry_normals_distances_unchanged"] = _lod_corresponds(original, repair)
		rows[str(path)] = {"before": before, "after": after, "max_filtered_srgb_component_error": color_error, "allowed_filtered_srgb_component_error": QUALIFICATION.MAX_COLOR_ERROR}
	# Qualification is a one-time assembly operation, idempotent on already
	# qualified data and unable to change adjacent unselected house meshes.
	var meshes_before := _meshes(first)
	QUALIFICATION.qualify_tree(first)
	checks["qualification_idempotent"] = meshes_before == _meshes(first)
	for node in source.find_children("*", "MeshInstance3D", true, false):
		var path := source.get_path_to(node)
		if not QUALIFICATION._selected(str(path)): checks[str(path) + ":unselected_source_unchanged"] = first.get_node(path).mesh == node.mesh
	source.free()
	first.free()
	repeated.free()
	return {"checks": checks, "surfaces": rows, "scope": "Native imported array, texture sampler and repeated instance construction only. Matched player-camera shading, ordinary collision traversal and reload remain independent runtime checks."}

static func _lod_corresponds(source: ArrayMesh, repair: ArrayMesh) -> bool:
	var original := source.surface_get_arrays(0)
	var repaired := repair.surface_get_arrays(0)
	var control := ArrayMesh.new()
	control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, original)
	var encoded := control.surface_get_arrays(0)
	var source_points: PackedVector3Array = original[Mesh.ARRAY_VERTEX]
	var source_normals: PackedVector3Array = encoded[Mesh.ARRAY_NORMAL]
	var points: PackedVector3Array = repaired[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = repaired[Mesh.ARRAY_NORMAL]
	var source_lods: Array = RenderingServer.mesh_get_surface(source.get_rid(), 0).get("lods", [])
	var repair_lods: Array = RenderingServer.mesh_get_surface(repair.get_rid(), 0).get("lods", [])
	if source_lods.size() != repair_lods.size(): return false
	for level in source_lods.size():
		if source_lods[level].edge_length != repair_lods[level].edge_length: return false
		var before := _lod_indices(source_points.size(), source_lods[level].index_data)
		var after := _lod_indices(points.size(), repair_lods[level].index_data)
		if before.size() != after.size(): return false
		for index in before.size():
			if source_points[before[index]] != points[after[index]] or source_normals[before[index]] != normals[after[index]]: return false
	return true

static func _lod_indices(vertex_count: int, bytes: PackedByteArray) -> PackedInt32Array:
	var stride := 2 if vertex_count <= 65536 else 4
	var indices := PackedInt32Array()
	indices.resize(bytes.size() / stride)
	for index in indices.size(): indices[index] = bytes.decode_u16(index * stride) if stride == 2 else bytes.decode_u32(index * stride)
	return indices

static func lod_diagnostics() -> Dictionary:
	var house := (load(HOUSE) as PackedScene).instantiate()
	var rows := {}
	for node in house.find_children("*", "MeshInstance3D", true, false):
		var path := str(house.get_path_to(node))
		if not QUALIFICATION._selected(path): continue
		var source: ArrayMesh = node.mesh
		var repair: ArrayMesh = QUALIFICATION.qualify_mesh(source)
		var original := source.surface_get_arrays(0)
		var result := repair.surface_get_arrays(0)
		var control := ArrayMesh.new()
		control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, original)
		var encoded := control.surface_get_arrays(0)
		var source_lods: Array = RenderingServer.mesh_get_surface(source.get_rid(), 0).get("lods", [])
		var repair_lods: Array = RenderingServer.mesh_get_surface(repair.get_rid(), 0).get("lods", [])
		var levels := []
		for level in mini(source_lods.size(), repair_lods.size()):
			var before := _lod_indices(original[Mesh.ARRAY_VERTEX].size(), source_lods[level].index_data)
			var after := _lod_indices(result[Mesh.ARRAY_VERTEX].size(), repair_lods[level].index_data)
			var point_error := 0.0
			var normal_error := 0.0
			var mismatch := {}
			for index in mini(before.size(), after.size()):
				var position_error: float = original[Mesh.ARRAY_VERTEX][before[index]].distance_to(result[Mesh.ARRAY_VERTEX][after[index]])
				var direction_error: float = encoded[Mesh.ARRAY_NORMAL][before[index]].distance_to(result[Mesh.ARRAY_NORMAL][after[index]])
				point_error = maxf(point_error, position_error)
				normal_error = maxf(normal_error, direction_error)
				if mismatch.is_empty() and (position_error > 0 or direction_error > 0): mismatch = {"corner": index, "source_index": before[index], "repair_index": after[index], "source_position": original[Mesh.ARRAY_VERTEX][before[index]], "repair_position": result[Mesh.ARRAY_VERTEX][after[index]], "source_normal_control": encoded[Mesh.ARRAY_NORMAL][before[index]], "repair_normal": result[Mesh.ARRAY_NORMAL][after[index]]}
			levels.append({"source_edge_length": source_lods[level].edge_length, "repair_edge_length": repair_lods[level].edge_length, "source_indices": before.size(), "repair_indices": after.size(), "max_point_error": point_error, "max_normal_error": normal_error, "first_mismatch": mismatch})
		rows[path] = {"source_levels": source_lods.size(), "repair_levels": repair_lods.size(), "levels": levels}
	house.free()
	return rows

static func _meshes(root: Node) -> Array:
	var result := []
	for node in root.find_children("*", "MeshInstance3D", true, false): result.append(node.mesh)
	return result

static func _collisions(root: Node) -> Array:
	var result := []
	for node in root.find_children("*", "CollisionShape3D", true, false): result.append([root.get_path_to(node), node.shape, node.transform, node.disabled])
	return result

static func _finite_directions(arrays: Array) -> bool:
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
	if tangents.size() != normals.size() * 4: return false
	for normal in normals:
		if not normal.is_finite() or normal.length_squared() < 0.5: return false
	for index in range(0, tangents.size(), 4):
		var tangent := Vector3(tangents[index], tangents[index + 1], tangents[index + 2])
		if not tangent.is_finite() or tangent.length_squared() < 0.5 or not is_finite(tangents[index + 3]): return false
	return true

static func _valid_uvs_unchanged(before: Array, after: Array) -> bool:
	var source: PackedVector2Array = before[Mesh.ARRAY_TEX_UV]
	var result: PackedVector2Array = after[Mesh.ARRAY_TEX_UV]
	if source.size() != result.size(): return false
	for triangle in range(0, source.size() - 2, 3):
		if absf((source[triangle + 1] - source[triangle]).cross(source[triangle + 2] - source[triangle])) < QUALIFICATION.UV_AREA_EPSILON and QUALIFICATION._valid_position_triangle(before, triangle): continue
		for corner in 3:
			if source[triangle + corner] != result[triangle + corner]: return false
	return true

static func _palette_error(mesh: ArrayMesh, before: Array, after: Array) -> float:
	var material: StandardMaterial3D = mesh.surface_get_material(0)
	var image := material.albedo_texture.get_image()
	if image.is_compressed() and image.decompress() != OK: return INF
	var mipmaps := QUALIFICATION.mip_images(image)
	var source: PackedVector2Array = before[Mesh.ARRAY_TEX_UV]
	var result: PackedVector2Array = after[Mesh.ARRAY_TEX_UV]
	var maximum := 0.0
	for triangle in range(0, source.size() - 2, 3):
		if source[triangle] == result[triangle] and source[triangle + 1] == result[triangle + 1] and source[triangle + 2] == result[triangle + 2]: continue
		maximum = maxf(maximum, QUALIFICATION.palette_error(PackedVector2Array([source[triangle], source[triangle + 1], source[triangle + 2]]), PackedVector2Array([result[triangle], result[triangle + 1], result[triangle + 2]]), mipmaps))
	return maximum

static func baseline() -> Dictionary:
	var house := (load(HOUSE) as PackedScene).instantiate()
	var rows := {}
	for node in house.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = node.mesh
		if mesh == null: continue
		for subject in SUBJECTS:
			if subject in str(house.get_path_to(node)):
				rows[str(house.get_path_to(node))] = surface_summary(mesh, 0)
	house.free()
	return rows

static func guards() -> Dictionary:
	var house := (load(HOUSE) as PackedScene).instantiate()
	var rows := {}
	for node in house.find_children("*", "MeshInstance3D", true, false):
		var path := str(house.get_path_to(node))
		if not QUALIFICATION._selected(path): continue
		var mesh: ArrayMesh = node.mesh
		var material: StandardMaterial3D = mesh.surface_get_material(0)
		var image := material.albedo_texture.get_image()
		var compressed := image.is_compressed()
		var decompress_result := image.decompress() if compressed else OK
		rows[path] = {"surfaces": mesh.get_surface_count(), "blend_shapes": mesh.get_blend_shape_count(), "primitive": mesh.surface_get_primitive_type(0), "triangles_enum": Mesh.PRIMITIVE_TRIANGLES, "material_class": material.get_class(), "filter": material.texture_filter, "nearest_enum": BaseMaterial3D.TEXTURE_FILTER_NEAREST, "texture_size": Vector2i(image.get_width(), image.get_height()), "image_compressed": compressed, "decompress_error": decompress_result, "expanded_array_size": QUALIFICATION.expanded_arrays(mesh).size()}
	house.free()
	return rows

static func surface_summary(mesh: Mesh, surface: int) -> Dictionary:
	var arrays := mesh.surface_get_arrays(surface)
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var count := indices.size() if not indices.is_empty() else points.size()
	var expanded := QUALIFICATION.expanded_arrays(mesh as ArrayMesh)
	var bad := 0
	var linear := 0
	var collapsed := 0
	var samples := []
	for triangle in range(0, count - 2, 3):
		var a := indices[triangle] if not indices.is_empty() else triangle
		var b := indices[triangle + 1] if not indices.is_empty() else triangle + 1
		var c := indices[triangle + 2] if not indices.is_empty() else triangle + 2
		if absf((uv[b] - uv[a]).cross(uv[c] - uv[a])) >= QUALIFICATION.UV_AREA_EPSILON: continue
		if not QUALIFICATION._valid_position_triangle(expanded, triangle): continue
		bad += 1
		var edge := maxf(uv[a].distance_squared_to(uv[b]), maxf(uv[b].distance_squared_to(uv[c]), uv[c].distance_squared_to(uv[a])))
		if edge > 1e-12: linear += 1
		else: collapsed += 1
		if samples.size() < 4: samples.append({"triangle": triangle / 3, "uv": [uv[a], uv[b], uv[c]], "position": [points[a], points[b], points[c]]})
	return {"triangles": count / 3, "degenerate": bad, "linear": linear, "collapsed": collapsed, "samples": samples, "material": str(mesh.surface_get_material(surface).resource_path)}
