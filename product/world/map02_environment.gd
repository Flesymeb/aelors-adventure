extends Node3D
## Collision follows the selected opaque terrain triangles, never a substitute floor.
var collision_ready := false
var terrain_meshes := 0
var obstacle_meshes := 0
func _ready() -> void:
	for mesh in get_node("Main Terrain").find_children("*", "MeshInstance3D", true, false):
		if mesh.name.begins_with("Plane"):
			mesh.create_trimesh_collision()
			for body in mesh.get_children():
				if body is StaticBody3D:
					body.collision_layer = 1
					body.collision_mask = 0
			terrain_meshes += 1
	# Bind nearby authored rocks and trunk surfaces at their exact transforms.
	# Leaves stay cutout visuals, not solid roofs. Distant scenery is unchanged.
	for decoration in get_node("Decorations-Forest").get_children():
		var point: Vector3 = decoration.position
		if point.x < -35 or point.x > 50 or point.z < -5 or point.z > 100: continue
		for mesh in decoration.find_children("*", "MeshInstance3D", true, false):
			if mesh.name.contains("LOD"): continue
			var solid := ArrayMesh.new()
			for surface in mesh.mesh.get_surface_count():
				var material: Material = mesh.get_active_material(surface)
				if material == null: continue
				if "rock_moss" in material.resource_path or "Tree bark" in material.resource_path:
					solid.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.mesh.surface_get_arrays(surface))
			if solid.get_surface_count() == 0: continue
			var body := StaticBody3D.new()
			body.name = "AuthoredObstacleCollision"
			body.collision_layer = 1
			body.collision_mask = 0
			var collision := CollisionShape3D.new()
			collision.shape = solid.create_trimesh_shape()
			body.add_child(collision)
			mesh.add_child(body)
			obstacle_meshes += 1
	collision_ready = terrain_meshes > 0
func _mcp_state() -> Dictionary:
	return {"collision_ready":collision_ready,"terrain_meshes":terrain_meshes,"obstacle_meshes":obstacle_meshes,"source":"Rytelier authored forest"}
