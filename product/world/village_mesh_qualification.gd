extends RefCounted
## Instance-only repair for the retained house's three imported palette meshes.
## Source meshes, material resources, transforms and collision remain untouched.
const SUBJECTS := ["EA03_Village_HouseModule_Porch_01d", "EA03_Town_Ill_Roof_01a", "EA03_Village_Hut_Ceiling_01e"]
const UV_AREA_EPSILON := 1e-12
const MAX_COLOR_ERROR := 2.0 / 255.0
static var _qualified: Dictionary = {}

static func qualify_tree(house: Node) -> void:
	for instance in house.find_children("*", "MeshInstance3D", true, false):
		if not _selected(str(house.get_path_to(instance))) or not instance.mesh is ArrayMesh: continue
		var source: ArrayMesh = instance.mesh
		if not _qualified.has(source): _qualified[source] = qualify_mesh(source)
		instance.mesh = _qualified[source]

static func _selected(path: String) -> bool:
	for subject in SUBJECTS:
		if subject in path: return true
	return false

static func qualify_mesh(source: ArrayMesh) -> ArrayMesh:
	# These retained rigid meshes have one triangle surface, no blend shapes or
	# custom channels. Refuse unknown layouts rather than discard their data.
	if source.get_surface_count() != 1 or source.get_blend_shape_count() != 0: return source
	if source.surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES: return source
	var material := source.surface_get_material(0) as StandardMaterial3D
	if material == null or material.albedo_texture == null: return source
	if material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS: return source
	var image := material.albedo_texture.get_image()
	if image == null: return source
	if image.is_compressed() and image.decompress() != OK: return source
	var mipmaps := mip_images(image)
	var arrays := expanded_arrays(source)
	if arrays.is_empty() or arrays[Mesh.ARRAY_TEX_UV] == null: return source
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var changed := false
	for triangle in range(0, uvs.size() - 2, 3):
		if absf((uvs[triangle + 1] - uvs[triangle]).cross(uvs[triangle + 2] - uvs[triangle])) >= UV_AREA_EPSILON: continue
		if not _valid_position_triangle(arrays, triangle): continue
		var repaired := repaired_triangle(PackedVector2Array([uvs[triangle], uvs[triangle + 1], uvs[triangle + 2]]), mipmaps)
		# A failed correspondence check leaves the source triangle visible and
		# measurable; it never hides a defect or changes validation coverage.
		if repaired.is_empty(): continue
		for corner in 3: uvs[triangle + corner] = repaired[corner]
		changed = true
	if not changed: return source
	var lods := remapped_lods(source, arrays)
	if not lods.valid: return source
	if not lods.indices.is_empty():
		# Godot requires an indexed base surface before it accepts LOD buffers.
		# Identity indices retain the expanded independent UV corners verbatim.
		var indices := PackedInt32Array()
		indices.resize(uvs.size())
		for corner in indices.size(): indices[corner] = corner
		arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	# SurfaceTool generates only tangents. Preserve native vertex/normal/color
	# arrays directly rather than roundtripping them through its vertex format.
	arrays[Mesh.ARRAY_TANGENT] = null
	var temporary := ArrayMesh.new()
	temporary.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var tool := SurfaceTool.new()
	tool.create_from(temporary, 0)
	tool.generate_tangents()
	arrays[Mesh.ARRAY_TANGENT] = tool.commit().surface_get_arrays(0)[Mesh.ARRAY_TANGENT]
	var output := ArrayMesh.new()
	output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], lods.indices)
	output.surface_set_material(0, material)
	output.surface_set_name(0, source.surface_get_name(0))
	output.custom_aabb = source.custom_aabb
	output.shadow_mesh = source.shadow_mesh
	return output

static func remapped_lods(source: ArrayMesh, expanded: Array) -> Dictionary:
	var original := source.surface_get_arrays(0)
	var vertices: PackedVector3Array = original[Mesh.ARRAY_VERTEX]
	var source_indices: PackedInt32Array = original[Mesh.ARRAY_INDEX] if original[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var representatives := PackedInt32Array()
	representatives.resize(vertices.size())
	representatives.fill(-1)
	var preferred := PackedByteArray()
	preferred.resize(vertices.size())
	var source_uvs: PackedVector2Array = expanded[Mesh.ARRAY_TEX_UV]
	var count: int = source_indices.size() if not source_indices.is_empty() else vertices.size()
	for corner in count:
		var vertex: int = source_indices[corner] if not source_indices.is_empty() else corner
		var triangle: int = corner - corner % 3
		var unchanged := absf((source_uvs[triangle + 1] - source_uvs[triangle]).cross(source_uvs[triangle + 2] - source_uvs[triangle])) >= UV_AREA_EPSILON or not _valid_position_triangle(expanded, triangle)
		if representatives[vertex] == -1 or (unchanged and preferred[vertex] == 0):
			representatives[vertex] = corner
			preferred[vertex] = 1 if unchanged else 0
	var result := {}
	for lod in RenderingServer.mesh_get_surface(source.get_rid(), 0).get("lods", []):
		var bytes: PackedByteArray = lod.index_data
		var stride := 2 if vertices.size() <= 65536 else 4
		var indices := PackedInt32Array()
		indices.resize(bytes.size() / stride)
		for index in indices.size():
			var source_vertex: int = bytes.decode_u16(index * stride) if stride == 2 else bytes.decode_u32(index * stride)
			if source_vertex >= representatives.size() or representatives[source_vertex] < 0: return {"valid": false, "indices": {}}
			indices[index] = representatives[source_vertex]
		result[float(lod.edge_length)] = indices
	return {"valid": true, "indices": result}

static func expanded_arrays(mesh: ArrayMesh) -> Array:
	var original := mesh.surface_get_arrays(0)
	for channel in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS]:
		if original[channel] != null and not original[channel].is_empty(): return []
	var indices: PackedInt32Array = original[Mesh.ARRAY_INDEX] if original[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty(): return original.duplicate(true)
	var expanded: Array = []
	expanded.resize(Mesh.ARRAY_MAX)
	for channel in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
		if original[channel] == null: continue
		var values: Variant = original[channel].duplicate()
		var stride := 4 if channel == Mesh.ARRAY_TANGENT else 1
		values.resize(indices.size() * stride)
		for corner in indices.size():
			for component in stride: values[corner * stride + component] = original[channel][indices[corner] * stride + component]
		expanded[channel] = values
	return expanded

static func repaired_triangle(before: PackedVector2Array, mipmaps: Array) -> PackedVector2Array:
	var image: Image = mipmaps[0]
	var texel := Vector2(1.0 / image.get_width(), 1.0 / image.get_height())
	var center := (before[0] + before[1] + before[2]) / 3.0
	var contour := _color_contour(center, texel, mipmaps)
	var first := 0
	var second := 1
	var longest := 0.0
	for pair in [Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 0)]:
		var length_squared := before[pair.x].distance_squared_to(before[pair.y])
		if length_squared > longest:
			longest = length_squared
			first = pair.x
			second = pair.y
	if longest > 1e-10:
		# Keep the authored trim's longest edge and its complete color variation.
		# Widen the authored strip in texel units, preserving its full length.
		var edge := before[second] - before[first]
		var perpendicular := Vector2(-edge.y, edge.x).normalized()
		for width in [0.25, -0.25, 0.5, -0.5, 0.125, -0.125, 0.0625, -0.0625]:
			var after := before.duplicate()
			after[3 - first - second] += perpendicular * texel * width
			if absf((after[1] - after[0]).cross(after[2] - after[0])) >= UV_AREA_EPSILON and palette_corresponds(before, after, mipmaps): return after
		# Where the UV line crosses a steep palette boundary, opening directly
		# perpendicular needlessly changes its color. Follow the least-varying
		# local color contour instead, still retaining both authored edge corners.
		for direction in [contour, contour.rotated(PI * 0.125), contour.rotated(-PI * 0.125)]:
			for width in [0.25, -0.25, 0.125, -0.125, 0.0625, -0.0625]:
				var after := before.duplicate()
				after[3 - first - second] += direction * texel * width
				if absf((after[1] - after[0]).cross(after[2] - after[0])) >= UV_AREA_EPSILON and palette_corresponds(before, after, mipmaps): return after
	# Nearly point-mapped palette faces get a footprint centered on the source
	# color. Even the smallest 1/16-texel square is millions of times the UV-area
	# threshold at this 32px atlas size; no existing texture variation is erased.
	for footprint in [0.6, 0.3, 0.15, 0.0625]:
		for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
			var after := PackedVector2Array([center + Vector2(-1.0, -1.0).rotated(angle) * texel * footprint / 3.0, center + Vector2(2.0, -1.0).rotated(angle) * texel * footprint / 3.0, center + Vector2(-1.0, 2.0).rotated(angle) * texel * footprint / 3.0])
			if palette_corresponds(before, after, mipmaps): return after
	# Point-mapped faces near atlas borders require an anisotropic footprint:
	# extend along the measured color contour, keeping the cross-gradient width
	# small. This expands their original point mapping rather than discarding
	# any existing valid texture variation or changing the filtering/material.
	var across := Vector2(-contour.y, contour.x)
	for length in [0.6, 0.3, 0.15, 0.0625]:
		for width in [0.03125, 0.015625, 0.0078125]:
			var first_edge: Vector2 = contour * texel * length
			var second_edge: Vector2 = across * texel * width
			var origin: Vector2 = center - (first_edge + second_edge) / 3.0
			var after := PackedVector2Array([origin, origin + first_edge, origin + second_edge])
			if palette_corresponds(before, after, mipmaps): return after
	return PackedVector2Array()

static func _color_contour(center: Vector2, texel: Vector2, mipmaps: Array) -> Vector2:
	var xx := 0.0
	var xy := 0.0
	var yy := 0.0
	for image in mipmaps:
		var horizontal := _palette_color(center + Vector2(texel.x * 0.01, 0), image) - _palette_color(center - Vector2(texel.x * 0.01, 0), image)
		var vertical := _palette_color(center + Vector2(0, texel.y * 0.01), image) - _palette_color(center - Vector2(0, texel.y * 0.01), image)
		for pair in [Vector2(horizontal.r, vertical.r), Vector2(horizontal.g, vertical.g), Vector2(horizontal.b, vertical.b)]:
			xx += pair.x * pair.x
			xy += pair.x * pair.y
			yy += pair.y * pair.y
	var angle := 0.5 * atan2(2.0 * xy, xx - yy) + PI * 0.5
	return Vector2(cos(angle), sin(angle))

static func _valid_position_triangle(arrays: Array, triangle: int) -> bool:
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if normals.size() != points.size(): return false
	for corner in 3:
		if not points[triangle + corner].is_finite() or not normals[triangle + corner].is_finite(): return false
	var cross := (points[triangle + 1] - points[triangle]).cross(points[triangle + 2] - points[triangle])
	var normal := normals[triangle] + normals[triangle + 1] + normals[triangle + 2]
	return cross.length() >= 1e-12 and normal.length_squared() >= 0.01 and absf(cross.normalized().dot(normal.normalized())) > 0.1

static func mip_images(image: Image) -> Array:
	var result := []
	var bytes := image.get_data()
	var levels := image.get_mipmap_count() + 1
	for level in range(levels):
		var offset := image.get_mipmap_offset(level)
		var end := image.get_mipmap_offset(level + 1) if level + 1 < levels else bytes.size()
		result.append(Image.create_from_data(maxi(1, image.get_width() >> level), maxi(1, image.get_height() >> level), false, image.get_format(), bytes.slice(offset, end)))
	return result

static func palette_corresponds(before: PackedVector2Array, after: PackedVector2Array, mipmaps: Array) -> bool:
	return palette_error(before, after, mipmaps) <= MAX_COLOR_ERROR

static func palette_error(before: PackedVector2Array, after: PackedVector2Array, mipmaps: Array) -> float:
	# Keep the actual linear+mipmap material. Compare bilinear sRGB texture
	# samples at every stored mip level, including authored palette gradients.
	var maximum := 0.0
	for a in range(17):
		for b in range(17 - a):
			var weights := Vector3(a / 16.0, b / 16.0, (16 - a - b) / 16.0)
			var source_uv := before[0] * weights.x + before[1] * weights.y + before[2] * weights.z
			var repaired_uv := after[0] * weights.x + after[1] * weights.y + after[2] * weights.z
			for image in mipmaps:
				var original := _palette_color(source_uv, image)
				var repaired := _palette_color(repaired_uv, image)
				maximum = maxf(maximum, maxf(absf(original.r - repaired.r), maxf(absf(original.g - repaired.g), absf(original.b - repaired.b))))
				if maximum > MAX_COLOR_ERROR: return maximum
	return maximum

static func _palette_color(uv: Vector2, image: Image) -> Color:
	var pixel := uv * Vector2(image.get_width(), image.get_height()) - Vector2(0.5, 0.5)
	var x := int(floorf(pixel.x))
	var y := int(floorf(pixel.y))
	var fraction := pixel - Vector2(x, y)
	var left := clampi(x, 0, image.get_width() - 1)
	var right := clampi(x + 1, 0, image.get_width() - 1)
	var top := clampi(y, 0, image.get_height() - 1)
	var bottom := clampi(y + 1, 0, image.get_height() - 1)
	var first := image.get_pixel(left, top).srgb_to_linear().lerp(image.get_pixel(right, top).srgb_to_linear(), fraction.x)
	var second := image.get_pixel(left, bottom).srgb_to_linear().lerp(image.get_pixel(right, bottom).srgb_to_linear(), fraction.x)
	return first.lerp(second, fraction.y).linear_to_srgb()
