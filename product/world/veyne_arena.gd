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
	bind_stone_route()
	var surround := preload("res://world/veyne_surround.tscn").instantiate()
	add_child(surround)
	surround.bind(self)
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

	bind_stone_perimeter(original)
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

func source_transform(mesh: MeshInstance3D, root: Node3D) -> Transform3D:
	var transform := mesh.transform
	var parent := mesh.get_parent()
	while parent and parent != root:
		transform = parent.transform*transform
		parent = parent.get_parent()
	return transform

func bind_stone_perimeter(original: Node3D) -> void:
	var wall: MeshInstance3D = original.find_child("Wall_004_Wall_Tiles_0",true,false)
	var pillar: MeshInstance3D = original.find_child("Pillar_001_Pillar_Texture_0",true,false)
	var wall_transform := source_transform(wall,original)
	var pillar_transform := source_transform(pillar,original)
	# Retained textured architectural modules surround the supported stone route.
	# All stand outside legal attack/travel bounds, leaving the stair opening.
	for i in 4:
		add_perimeter_module(wall,wall_transform,Vector3(-16+i*6,4.9,-41.2),Vector2(6,4.8),0.0)
		add_perimeter_module(wall,wall_transform,Vector3(-16,4.9,-17.2-i*6),Vector2(6,4.8),PI/2)
		add_perimeter_module(wall,wall_transform,Vector3(8,4.9,-41.2+i*6),Vector2(6,4.8),-PI/2)
	for segment in [Vector2(-16,9.5),Vector2(-1.5,9.5)]:
		add_perimeter_module(wall,wall_transform,Vector3(segment.x+segment.y,4.9,-17.2),Vector2(segment.y,4.8),PI)
	var positions: Array[Vector3] = []
	for i in 5:
		positions.append(Vector3(-16+i*6,4.9,-41.2))
	for i in range(1,5):
		positions.append(Vector3(-16,4.9,-41.2+i*6))
		positions.append(Vector3(8,4.9,-41.2+i*6))
	positions.append(Vector3(-6.5,4.9,-17.2))
	positions.append(Vector3(-1.5,4.9,-17.2))
	var box: AABB = pillar_transform*pillar.mesh.get_aabb()
	for position in positions:
		var factor := Vector3(3,4.8/box.size.y,3)
		var offset := Vector3(box.get_center().x,box.position.y,box.get_center().z)
		add_authored_mesh(pillar,Transform3D(Basis.from_scale(factor),position-offset*factor)*pillar_transform)

func add_perimeter_module(source: MeshInstance3D, transform: Transform3D, corner: Vector3, size: Vector2, yaw: float) -> void:
	var box: AABB = transform*source.mesh.get_aabb()
	var factor := Vector3(size.x/box.size.x,size.y/box.size.y,1)
	var orientation := Basis(Vector3.UP,yaw)
	var normalize := Transform3D(orientation*Basis.from_scale(factor),corner-orientation*(box.position*factor))
	add_authored_mesh(source,normalize*transform)
	var mesh := get_child(get_child_count()-1) as MeshInstance3D
	mesh.name = "RitualStoneWall"
	for surface in mesh.mesh.get_surface_count():
		var material = mesh.mesh.surface_get_material(surface)
		if material is StandardMaterial3D:
			material = material.duplicate()
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.roughness = 0.9
			mesh.set_surface_override_material(surface,material)
