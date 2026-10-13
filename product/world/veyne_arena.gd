extends Node3D
## Adaptation of the licensed open-roof ruin. Imported triangles own support.
const CENTER := Vector2(-4,-26)
const HOME := Vector2(-4,-25)
const KEY := Vector2(-4,-33)
const MINIMUM := Vector2(-13,-36)
const MAXIMUM := Vector2(5,-17.2)

static func contains(point: Vector2) -> bool:
	return point.x > MINIMUM.x and point.x < MAXIMUM.x and point.y > MINIMUM.y and point.y < MAXIMUM.y

var geometry_bound := false

func bind_geometry() -> void:
	if geometry_bound: return
	geometry_bound = true
	var crypt: Node3D = get_parent().get_node("NativeCrypt")
	# Retire the superseded left chamber rather than layering floors/colliders.
	for mesh in crypt.find_children("*","MeshInstance3D",true,false):
		trim_crypt(mesh)
	for mesh in get_node("RitualRuin").find_children("*","MeshInstance3D",true,false):
		trim(mesh,true)
		if not mesh.mesh: continue
		for surface in mesh.mesh.get_surface_count():
			var material = mesh.mesh.surface_get_material(surface)
			if material is StandardMaterial3D:
				material = material.duplicate()
				material.albedo_color *= Color(0.45,0.48,0.38,1)
				material.roughness = 0.9
				mesh.set_surface_override_material(surface,material)
		bind_collision(mesh)
		mesh.set_meta("arena_collision_bound",true)
	bind_stone_route()
	for spot in [Vector3(-9,6,-22),Vector3(1,6,-30),Vector3(-4,9,-25)]:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0,0.69,0.36)
		lamp.light_energy = 2.5
		lamp.omni_range = 15
		add_child(lamp); lamp.global_position = spot

func bind_stone_route() -> void:
	# The ruin's generated moss surface has holes. Replace its inner ground
	# with the retained crypt's authored textured stone, not a primitive slab.
	var original: Node3D = preload("res://assets/maps/map03/crypt.glb").instantiate()
	var source_mesh: MeshInstance3D = original.find_child("Floor_005_Floor_Tiles_0",true,false)
	var transform := source_mesh.transform
	var parent := source_mesh.get_parent()
	while parent and parent != original:
		transform = parent.transform*transform; parent = parent.get_parent()
	var box: AABB = transform*source_mesh.mesh.get_aabb()
	for x in 4:
		for z in 4:
			add_stone(source_mesh,transform,box,Vector2(-16+x*6,-41.2+z*6),Vector2(6,6))
	for flight in 2:
		for mesh_name in ["Stairs_001_Wall_Tiles_0","Stairs_001_StairsArchTrimBrazier_0"]:
			var stair: MeshInstance3D = original.find_child(mesh_name,true,false)
			var stair_transform := stair.transform
			var ancestor := stair.get_parent()
			while ancestor and ancestor != original:
				stair_transform = ancestor.transform*stair_transform; ancestor = ancestor.get_parent()
			var reference: MeshInstance3D = original.find_child("Stairs_001_Wall_Tiles_0",true,false)
			var reference_transform := reference.transform
			ancestor = reference.get_parent()
			while ancestor and ancestor != original:
				reference_transform = ancestor.transform*reference_transform; ancestor = ancestor.get_parent()
			var stair_box: AABB = reference_transform*reference.mesh.get_aabb()
			var factor := Vector3(4/stair_box.size.x,1.45/stair_box.size.y,4/stair_box.size.z)
			var normalize := Transform3D(Basis.from_scale(factor),Vector3(-6,2+flight*1.45,-13.2-flight*4)-stair_box.position*factor)
			add_authored_mesh(stair,normalize*stair_transform)

	original.free()

func add_stone(source_mesh: MeshInstance3D, source_transform: Transform3D, box: AABB, corner: Vector2, size: Vector2) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "RitualStoneFloor"
	mesh.mesh = source_mesh.mesh
	add_child(mesh)
	var factor := Vector3(size.x/box.size.x,1,size.y/box.size.z)
	var normalize := Transform3D(Basis.from_scale(factor),Vector3(corner.x,4.9,corner.y)-box.position*factor)
	mesh.global_transform = normalize*source_transform
	bind_stone_collision(mesh)
	mesh.set_meta("arena_collision_bound",true)

func add_authored_mesh(source_mesh: MeshInstance3D, transform: Transform3D) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "RitualStoneStairs"
	mesh.mesh = source_mesh.mesh
	add_child(mesh)
	mesh.global_transform = transform
	bind_stone_collision(mesh)

func bind_stone_collision(mesh: MeshInstance3D) -> void:
	mesh.create_trimesh_collision()
	mesh.set_meta("arena_collision_bound",true)
	for body in mesh.get_children():
		if body is StaticBody3D:
			body.collision_layer = 1; body.collision_mask = 1; body.set_meta("tomb_floor",true)
			for shape in body.get_children():
				if shape is CollisionShape3D: shape.shape.backface_collision = true

func bind_collision(mesh: MeshInstance3D) -> void:
	var faces := PackedVector3Array()
	for surface in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for triangle in range(0,indices.size(),3):
			var a: Vector3 = mesh.global_transform*vertices[indices[triangle]]
			var b: Vector3 = mesh.global_transform*vertices[indices[triangle+1]]
			var c: Vector3 = mesh.global_transform*vertices[indices[triangle+2]]
			var middle := (a+b+c)/3
			# The merged source includes large decorative leaves. Keep structural
			# floor triangles and perimeter stone; leaves do not block walking.
			var floor_face: bool = maxf(a.y,maxf(b.y,c.y)) < 2.7
			var perimeter: bool = middle.x < -11 or middle.x > 3 or middle.z < -34 or middle.z > -11
			if not floor_face and not perimeter: continue
			for vertex in [vertices[indices[triangle]],vertices[indices[triangle+1]],vertices[indices[triangle+2]]]: faces.append(vertex)
	var body := StaticBody3D.new()
	body.collision_layer = 1; body.collision_mask = 1
	body.set_meta("tomb_floor",true)
	mesh.add_child(body)
	var shape := CollisionShape3D.new()
	var geometry := ConcavePolygonShape3D.new()
	geometry.set_faces(faces)
	geometry.backface_collision = true
	shape.shape = geometry
	body.add_child(shape)


func clip_polygon(polygon: Array, axis: int, cut: float, greater: bool) -> Array:
	var result: Array = []
	if polygon.is_empty(): return result
	var previous: Dictionary = polygon[-1]
	var was_inside: bool = previous.world[axis] >= cut if greater else previous.world[axis] <= cut
	for current in polygon:
		var inside: bool = current.world[axis] >= cut if greater else current.world[axis] <= cut
		if inside != was_inside:
			var fraction: float = (cut-previous.world[axis])/(current.world[axis]-previous.world[axis])
			var interpolated := {}
			for key in current: interpolated[key] = previous[key].lerp(current[key],fraction)
			result.append(interpolated)
		if inside: result.append(current)
		previous = current; was_inside = inside
	return result

func trim_crypt(node: MeshInstance3D) -> void:
	if not node.mesh: return
	var result := ArrayMesh.new()
	for surface in node.mesh.get_surface_count():
		var arrays := node.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for i in vertices.size(): indices.append(i)
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.set_material(node.mesh.surface_get_material(surface))
		var count := 0
		for triangle in range(0,indices.size(),3):
			var polygon: Array = []
			for corner in 3:
				var i := indices[triangle+corner]
				var data := {"p":vertices[i],"world":node.global_transform*vertices[i]}
				for key in [Mesh.ARRAY_NORMAL,Mesh.ARRAY_COLOR,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2]:
					if arrays[key] != null and not arrays[key].is_empty(): data[key] = arrays[key][i]
				polygon.append(data)
			var positive := clip_polygon(polygon,0,0,true)
			var negative := clip_polygon(clip_polygon(polygon,0,0,false),2,-9.2,true)
			for part in [positive,negative]:
				for i in range(1,part.size()-1):
					if (part[i].p-part[0].p).cross(part[i+1].p-part[0].p).length_squared()<0.000000000001: continue
					for vertex in [part[0],part[i],part[i+1]]:
						if vertex.has(Mesh.ARRAY_NORMAL): tool.set_normal(vertex[Mesh.ARRAY_NORMAL].normalized())
						if vertex.has(Mesh.ARRAY_COLOR): tool.set_color(vertex[Mesh.ARRAY_COLOR])
						if vertex.has(Mesh.ARRAY_TEX_UV): tool.set_uv(vertex[Mesh.ARRAY_TEX_UV])
						if vertex.has(Mesh.ARRAY_TEX_UV2): tool.set_uv2(vertex[Mesh.ARRAY_TEX_UV2])
						tool.add_vertex(vertex.p); count += 1
		if count > 0: tool.index(); tool.commit(result)
	node.mesh = result if result.get_surface_count() else null
	node.visible = node.mesh != null

func trim(node: MeshInstance3D, arena: bool) -> void:
	if not node.mesh: return
	var result := ArrayMesh.new()
	for surface in node.mesh.get_surface_count():
		var arrays: Array = node.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var old_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if old_indices.is_empty():
			for i in vertices.size(): old_indices.append(i)
		var indices := PackedInt32Array()
		for triangle in range(0,old_indices.size(),3):
			var rejected := 0
			for corner in 3:
				var point: Vector3 = node.global_transform*vertices[old_indices[triangle+corner]]
				# Keep Warden and LN02 geometry intact. The new ruin ends at the
				# chapter-side overlap; old left-room triangles beyond it retire.
				var inner_ground: bool = (point.x > -16 and point.x < 8 and point.z > -41.2 and point.z < -17.2 and point.y < 5.0) or Vector2(point.x+4,point.z+26).length() < 5.0
				var doorway: bool = point.x > -6.5 and point.x < -1.5 and point.z > -22 
				if (arena and ((point.x > 0 and point.z > -16) or inner_ground or doorway)) or (not arena and point.x < 0 and point.z < -9.2): rejected += 1
			if rejected == 3: continue
			for corner in 3: indices.append(old_indices[triangle+corner])
		if indices.is_empty(): continue
		var remap := {}
		var used: Array[int] = []
		for i in indices.size():
			var original := indices[i]
			if not remap.has(original): remap[original] = used.size(); used.append(original)
			indices[i] = remap[original]
		for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT,Mesh.ARRAY_COLOR,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2]:
			var old = arrays[channel]
			if old == null or old.is_empty(): continue
			var compact = old.slice(0,0)
			var components: int = old.size()/vertices.size()
			for original in used:
				for component in components: compact.append(old[original*components+component])
			arrays[channel] = compact
		arrays[Mesh.ARRAY_INDEX] = indices
		# glTF's compressed auxiliary channels are not used by these materials;
		# preserve ordinary UV/color/normal/tangent arrays in the rebuilt surface.
		for channel in [Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2,Mesh.ARRAY_CUSTOM3]: arrays[channel] = null
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		result.surface_set_material(result.get_surface_count()-1,node.mesh.surface_get_material(surface))
	node.mesh = result if result.get_surface_count() else null
	node.visible = node.mesh != null
