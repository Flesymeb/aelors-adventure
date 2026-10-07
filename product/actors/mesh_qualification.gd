extends RefCounted
## Preserve imported skin/shape/materials while repairing zero-area UV islands
## in product instances. Source assets remain immutable.
static func qualify_tree(node: Node) -> void:
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
			var uvs = PackedVector2Array()
			if arrays[Mesh.ARRAY_TEX_UV] != null: uvs = arrays[Mesh.ARRAY_TEX_UV]
			var repaired = false
			for triangle in range(0, uvs.size() - 2, 3):
				var area = (uvs[triangle + 1] - uvs[triangle]).cross(uvs[triangle + 2] - uvs[triangle])
				if absf(area) > 0.000000000001: continue
				# Tiny islands stay within the original palette texel, with valid
				# UV area for engine tangent generation and normal-map sampling.
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
			final_tool.commit(output)
			output.surface_set_material(output.get_surface_count() - 1, instance.mesh.surface_get_material(surface))
			changed = changed or repaired
		if changed: instance.mesh = output
