extends RefCounted
## Extract only Head-weighted geometry from the local base character.
## Rigid Head binding deliberately omits independent neck/face deformation.

const BASE_PATH := "res://Characters/QuaterniusBase/Superhero_Male_FullBody.gltf"


static func assemble(target: Skeleton3D) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if target == null or target.find_bone("Head") < 0 or not ResourceLoader.exists(BASE_PATH):
		push_error("Ranger head assembly needs the base character and target Head bone")
		return result
	var source := (load(BASE_PATH) as PackedScene).instantiate()
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(source, meshes)
	var attachment := BoneAttachment3D.new()
	attachment.name = "BaseHeadAttachment"
	attachment.bone_name = "Head"
	target.add_child(attachment)
	for mesh in meshes:
		var source_skeleton := mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
		if source_skeleton == null or mesh.skin == null:
			continue
		var head_bone := source_skeleton.find_bone("Head")
		if head_bone < 0:
			continue
		var head_bind := -1
		for index in range(mesh.skin.get_bind_count()):
			if mesh.skin.get_bind_name(index) == &"Head" or (mesh.skin.get_bind_name(index) == &"" and mesh.skin.get_bind_bone(index) == head_bone):
				head_bind = index
				break
		if head_bind < 0:
			continue
		# Skin inverse bind maps source mesh vertices into source Head-local space.
		# BoneAttachment supplies the target Head pose; other body binds are unused.
		var extracted := _extract_head(mesh, head_bind, mesh.skin.get_bind_pose(head_bind))
		if extracted.get_surface_count() == 0:
			continue
		var component := MeshInstance3D.new()
		component.name = "BaseHead_" + str(mesh.name)
		component.mesh = extracted
		attachment.add_child(component)
		result.append(component)
	source.free()
	if result.is_empty():
		attachment.queue_free()
		push_error("Base character returned no Head-weighted face geometry")
	return result


static func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, result)


static func _extract_head(source: MeshInstance3D, head_bind: int, inverse_bind: Transform3D) -> ArrayMesh:
	var extracted := ArrayMesh.new()
	for surface in range(source.mesh.get_surface_count()):
		if source.mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays := source.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if vertices.is_empty() or bones.is_empty() or weights.size() != bones.size():
			continue
		var influences: int = bones.size() / vertices.size()
		var selected := PackedByteArray()
		selected.resize(vertices.size())
		for vertex in range(vertices.size()):
			var head_weight := 0.0
			for influence in range(influences):
				var index := vertex * influences + influence
				if bones[index] == head_bind:
					head_weight += weights[index]
			selected[vertex] = 1 if head_weight >= 0.5 else 0
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for vertex in range(vertices.size()):
				indices.append(vertex)
		var output: Array = []
		output.resize(Mesh.ARRAY_MAX)
		var positions := PackedVector3Array()
		var normals := PackedVector3Array()
		var uvs := PackedVector2Array()
		var tangents := PackedFloat32Array()
		var normal_basis := inverse_bind.basis.inverse().transposed()
		var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var source_uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var source_tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT] if arrays[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
		for triangle in range(0, indices.size() - 2, 3):
			if not (selected[indices[triangle]] and selected[indices[triangle + 1]] and selected[indices[triangle + 2]]):
				continue
			for corner in range(3):
				var index := indices[triangle + corner]
				positions.append(inverse_bind * vertices[index])
				if not source_normals.is_empty():
					normals.append((normal_basis * source_normals[index]).normalized())
				if not source_uvs.is_empty():
					uvs.append(source_uvs[index])
				if not source_tangents.is_empty():
					var tangent := (inverse_bind.basis * Vector3(source_tangents[index * 4], source_tangents[index * 4 + 1], source_tangents[index * 4 + 2])).normalized()
					tangents.append_array(PackedFloat32Array([tangent.x, tangent.y, tangent.z, source_tangents[index * 4 + 3]]))
		if positions.is_empty():
			continue
		output[Mesh.ARRAY_VERTEX] = positions
		if not normals.is_empty():
			output[Mesh.ARRAY_NORMAL] = normals
		if not uvs.is_empty():
			output[Mesh.ARRAY_TEX_UV] = uvs
		if not tangents.is_empty():
			output[Mesh.ARRAY_TANGENT] = tangents
		extracted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, output)
		extracted.surface_set_material(extracted.get_surface_count() - 1, source.get_active_material(surface))
	return extracted
