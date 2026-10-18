extends RefCounted
## Preserve imported skin/shape/materials while repairing zero-area UV islands
## in product instances. Source assets remain immutable.
static func qualify_tree(node: Node, preserve_linear_uvs := false) -> void:
	for instance in node.find_children("*", "MeshInstance3D", true, false):
		if not instance.mesh is ArrayMesh: continue
		var output = ArrayMesh.new()
		var changed = false
		for surface in instance.mesh.get_surface_count():
			if instance.mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES: continue
			var tool = SurfaceTool.new()
			tool.create_from(instance.mesh, surface)
			tool.deindex()
			var flat = tool.commit()
			var arrays = flat.surface_get_arrays(0)
			if preserve_linear_uvs:
				arrays = _sword_arrays(instance.mesh, surface)
			var uvs = PackedVector2Array()
			if arrays[Mesh.ARRAY_TEX_UV] != null: uvs = arrays[Mesh.ARRAY_TEX_UV]
			var repaired = false
			for triangle in range(0, uvs.size() - 2, 3):
				var area = (uvs[triangle + 1] - uvs[triangle]).cross(uvs[triangle + 2] - uvs[triangle])
				if absf(area) > 0.000000000001: continue
				if preserve_linear_uvs:
					_open_linear_uv(uvs, triangle)
				else:
					# Retain the existing palette-island treatment for other actors.
					var center = (uvs[triangle] + uvs[triangle + 1] + uvs[triangle + 2]) / 3
					uvs[triangle] = center
					uvs[triangle + 1] = center + Vector2(0.0002, 0)
					uvs[triangle + 2] = center + Vector2(0, 0.0002)
				repaired = true
			arrays[Mesh.ARRAY_TEX_UV] = uvs if not uvs.is_empty() else null
			arrays[Mesh.ARRAY_TANGENT] = null
			var temporary = ArrayMesh.new()
			temporary.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var final_tool = SurfaceTool.new()
			final_tool.create_from(temporary, 0)
			if not uvs.is_empty(): final_tool.generate_tangents()
			if preserve_linear_uvs:
				# Tangent generation must not roundtrip the authored normals/colors
				# through SurfaceTool's vertex conversion a second time.
				arrays[Mesh.ARRAY_TANGENT] = final_tool.commit().surface_get_arrays(0)[Mesh.ARRAY_TANGENT]
				output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			else:
				final_tool.commit(output)
			output.surface_set_material(output.get_surface_count() - 1, instance.mesh.surface_get_material(surface))
			changed = changed or repaired
		if changed: instance.mesh = output


static func _sword_arrays(mesh: ArrayMesh, surface: int) -> Array:
	# Expand indices directly, retaining the imported position/normal/color
	# values. The sword is rigid and has no skin or custom attribute channels.
	var original := mesh.surface_get_arrays(surface)
	if original[Mesh.ARRAY_INDEX] == null: return original.duplicate(true)
	var indices: PackedInt32Array = original[Mesh.ARRAY_INDEX]
	if indices.is_empty(): return original.duplicate(true)
	var expanded: Array = []
	expanded.resize(Mesh.ARRAY_MAX)
	for channel in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
		if original[channel] == null: continue
		var values: Variant = original[channel].duplicate()
		var stride := 4 if channel == Mesh.ARRAY_TANGENT else 1
		values.resize(indices.size() * stride)
		for corner in indices.size():
			for component in stride:
				values[corner * stride + component] = original[channel][indices[corner] * stride + component]
		expanded[channel] = values
	return expanded


static func _open_linear_uv(uvs: PackedVector2Array, triangle: int) -> void:
	# Sword grip bevels were authored as zero-width trim strips. Keep the
	# longest edge and its texture variation, opening only the third corner.
	# Work on deindexed corners so adjacent, already-valid UVs stay unchanged.
	var first := 0
	var second := 1
	var longest := 0.0
	for pair in [Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 0)]:
		var length_squared := uvs[triangle + pair.x].distance_squared_to(uvs[triangle + pair.y])
		if length_squared > longest:
			longest = length_squared
			first = pair.x
			second = pair.y
	if longest > 0.000000000001:
		var edge := uvs[triangle + second] - uvs[triangle + first]
		var perpendicular := Vector2(-edge.y, edge.x).normalized()
		uvs[triangle + 3 - first - second] += perpendicular * 0.0002
	else:
		# Four point-mapped grip triangles have no trim direction to retain.
		uvs[triangle + 1] += Vector2(0.0002, 0)
		uvs[triangle + 2] += Vector2(0, 0.0002)
