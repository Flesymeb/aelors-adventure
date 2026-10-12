extends RefCounted
## Explicit read-only native support probe. Never changes actor stances or saves.
const GROUND := preload("res://forest_ground.gd")
const BRIDGE := preload("res://combat/bridge_encounter.gd")

static func run(world: Node3D) -> Dictionary:
	var samples: Array[Dictionary] = []
	var checks := {}
	var excludes: Array[RID] = []
	for actor in world.find_children("*", "CollisionObject3D", true, false):
		if not world.village.is_ancestor_of(actor): excludes.append(actor.get_rid())
	for index in BRIDGE.ANCHORS.size():
		var xz: Vector2 = BRIDGE.ANCHORS[index] + Vector2(0.013, 0.017)
		var height: float = world.village.get_node("Terrain3D").data.get_height(Vector3(xz.x, 0, xz.y))
		var query := PhysicsRayQueryParameters3D.create(Vector3(xz.x, 80, xz.y), Vector3(xz.x, -80, xz.y), 1, excludes)
		var first := world.get_world_3d().direct_space_state.intersect_ray(query)
		var hit := GROUND.support(world, BRIDGE.ANCHORS[index], excludes)
		var sample := {"anchor": [xz.x, xz.y], "height": height, "ray_hit": not first.is_empty(), "support": not hit.is_empty(), "standing_clear": false}
		if not first.is_empty():
			sample.ray_height = first.position.y
			sample.ray_normal_y = first.normal.y
			sample.collider = str(first.collider.get_path()) if first.collider is Node else str(first.collider)
		if not hit.is_empty():
			sample.support_height = hit.position.y
			sample.support_normal_y = hit.normal.y
			var shape := CapsuleShape3D.new()
			shape.radius = 0.38
			shape.height = 1.8
			var volume := PhysicsShapeQueryParameters3D.new()
			volume.shape = shape
			volume.transform = Transform3D(Basis(), hit.position + Vector3(0, 0.98, 0))
			volume.collision_mask = 1
			volume.exclude = excludes
			var blocked := world.get_world_3d().direct_space_state.intersect_shape(volume, 8)
			sample.standing_clear = blocked.is_empty()
			sample.standing_rejections = blocked.map(func(contact): return str(contact.collider))
		checks["anchor_%d_safe" % index] = sample.support and sample.standing_clear
		samples.append(sample)
	checks.arch_roof_discriminated = samples[1].get("ray_height", 0) > samples[1].height + 1.3 and samples[1].get("support_height", INF) <= samples[1].height + 1.3
	checks.out_of_bounds_rejected = GROUND.support(world, Vector2(-1, 137), excludes).is_empty()
	checks.nonfinite_rejected = GROUND.support(world, Vector2(NAN, 137), excludes).is_empty()
	return {"checks": checks, "samples": samples}

static func pillar_probe(world: Node3D, include_prior_recipe: bool = false) -> Dictionary:
	# Explicit diagnostic only. The recipe view is labeled and never positions
	# the actor, changes eligibility, advances time or commits a save.
	var pillar: Node3D = world.chapter_pillar
	var player: CharacterBody3D = world.player
	if not is_instance_valid(pillar) or not is_instance_valid(player) or not pillar.grounded:
		return {"available": false, "reason": "grounded pillar/player unavailable"}
	var camera := player.get_node_or_null("CameraArm/Camera") as Camera3D
	if camera == null:
		return {"available": false, "reason": "shipped camera unavailable"}
	var excluded: Array[RID] = []
	for actor in world.find_children("*", "CollisionObject3D", true, false):
		if not world.village.is_ancestor_of(actor): excluded.append(actor.get_rid())
	var support: Dictionary = world.ground_policy.support(world, pillar.anchor, excluded)
	var subjects: Array[Dictionary] = []
	var nearby: Array[Dictionary] = []
	var tall_instance_count := 0
	var unmarked_visible_count := 0
	var excluded_instances: Array[Dictionary] = []
	var terrain: Node3D = world.village.get_node("Terrain3D")
	for child in terrain.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := child as MultiMeshInstance3D
		if mmi.multimesh == null or mmi.multimesh.mesh == null: continue
		var mesh: Mesh = mmi.multimesh.mesh
		if mesh.get_aabb().size.y <= 4.0: continue
		var asset := "unknown"
		for candidate in terrain.assets.mesh_list:
			if "_M%d_" % candidate.id in mmi.name:
				asset = candidate.name
				break
		if not ("pine" in asset or "maple" in asset): continue
		var visible_count: int = mmi.multimesh.visible_instance_count
		var count: int = mmi.multimesh.instance_count if visible_count < 0 else mini(visible_count, mmi.multimesh.instance_count)
		tall_instance_count += mmi.multimesh.instance_count
		if not mmi.has_meta("departure_sightline_excluded"): unmarked_visible_count += count
		for index in mmi.multimesh.instance_count:
			var transform: Transform3D = mmi.global_transform * mmi.multimesh.get_instance_transform(index)
			if Vector2(transform.origin.x, transform.origin.z).distance_to(pillar.anchor) > 12.0: continue
			var instance_visible: bool = mmi.is_visible_in_tree() and index < count
			var identity := {"node_path": str(mmi.get_path()), "kind": "terrain_tree", "asset": asset, "instance_index": index, "transform": _transform_values(transform), "mesh_path": mesh.resource_path, "visible": instance_visible, "excluded": mmi.has_meta("departure_sightline_excluded")}
			nearby.append(identity)
			if identity.excluded: excluded_instances.append(identity)
			if not instance_visible: continue
			subjects.append({"identity": identity, "mesh": mesh, "transform": transform, "material_override": mmi.material_override})
	for stone in pillar.stones:
		if not is_instance_valid(stone) or not stone is MeshInstance3D or not stone.is_visible_in_tree(): continue
		var identity := {"node_path": str(stone.get_path()), "kind": "pillar_stone", "asset": stone.scene_file_path, "instance_index": null, "transform": _transform_values(stone.global_transform), "mesh_path": stone.mesh.resource_path}
		subjects.append({"identity": identity, "mesh": stone.mesh, "transform": stone.global_transform, "material_override": stone.material_override})
	var views: Array[Dictionary] = [{"label": "actual_shipped_camera", "camera": camera.global_position, "player_target": player.global_position + Vector3(0, 1.45, 0)}]
	if include_prior_recipe:
		views.append({"label": "prior_recipe_diagnostic_only", "camera": Vector3(133, 13.305, 153.424), "player_target": Vector3(133, 12.2, 149.7)})
	var observations: Array[Dictionary] = []
	for view in views:
		var targets := {"player": view.player_target, "passage_light": pillar.flow.global_position}
		for target_name in targets:
			var from: Vector3 = view.camera
			var to: Vector3 = targets[target_name]
			var rays: Array[Dictionary] = []
			for mask in [1, 3]:
				var query := PhysicsRayQueryParameters3D.create(from, to, mask, [player.get_rid()])
				var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
				var ray := {"mask": mask, "hit": not hit.is_empty()}
				if not hit.is_empty():
					ray.position = _vector_values(hit.position)
					ray.collider = str(hit.collider.get_path()) if hit.collider is Node else str(hit.collider)
					ray.collision_layer = hit.collider.collision_layer if hit.collider is CollisionObject3D else null
				rays.append(ray)
			var intersections: Array[Dictionary] = []
			for subject in subjects:
				var intersection := _nearest_mesh_intersection(from, to, subject)
				if not intersection.is_empty(): intersections.append(intersection)
			intersections.sort_custom(func(a: Dictionary, b: Dictionary): return a.distance < b.distance)
			observations.append({"view": view.label, "target": target_name, "from": _vector_values(from), "to": _vector_values(to), "physics_rays": rays, "mesh_intersections": intersections})
	var arm := player.get_node("CameraArm") as SpringArm3D
	var recipe_clear: Variant = null
	if include_prior_recipe:
		recipe_clear = true
		for observation in observations:
			if observation.view == "prior_recipe_diagnostic_only" and not observation.mesh_intersections.is_empty(): recipe_clear = false
	var exclusion_exact := false
	if excluded_instances.size() == 1:
		var excluded_instance: Dictionary = excluded_instances[0]
		var origin: Array = excluded_instance.transform.origin
		exclusion_exact = excluded_instance.asset == "maple_2" and not excluded_instance.visible and Vector3(origin[0], origin[1], origin[2]).distance_to(Vector3(137.4184, 11.56699, 154.4324)) < 0.01
	return {"available": true, "read_only": true, "pillar_path": str(pillar.get_path()), "pillar_anchor": [pillar.anchor.x, pillar.anchor.y], "pillar_position": _vector_values(pillar.global_position), "support_position": _vector_values(support.position) if not support.is_empty() else null, "anchor_support_matches": not support.is_empty() and pillar.global_position.distance_to(support.position) < 0.001, "camera_position": _vector_values(camera.global_position), "camera_requested_length": arm.spring_length, "camera_hit_length": arm.get_hit_length(), "nearby_tall_instances": nearby, "tall_instance_count": tall_instance_count, "unmarked_visible_instance_count": unmarked_visible_count, "excluded_instance_count": excluded_instances.size(), "exclusion_matches_exact_singleton": exclusion_exact, "prior_recipe_mesh_sightline_clear": recipe_clear, "observations": observations}

static func _nearest_mesh_intersection(from: Vector3, to: Vector3, subject: Dictionary) -> Dictionary:
	var mesh: Mesh = subject.mesh
	var transform: Transform3D = subject.transform
	var best := {}
	var best_distance := INF
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		if arrays.is_empty(): continue
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var count: int = indices.size() if not indices.is_empty() else vertices.size()
		for triangle in range(0, count - 2, 3):
			var a: Vector3 = transform * vertices[indices[triangle] if not indices.is_empty() else triangle]
			var b: Vector3 = transform * vertices[indices[triangle + 1] if not indices.is_empty() else triangle + 1]
			var c: Vector3 = transform * vertices[indices[triangle + 2] if not indices.is_empty() else triangle + 2]
			var hit: Variant = Geometry3D.segment_intersects_triangle(from, to, a, b, c)
			if hit == null: continue
			var distance: float = from.distance_to(hit)
			if distance >= best_distance: continue
			best_distance = distance
			var material: Material = subject.material_override if subject.material_override != null else mesh.surface_get_material(surface)
			var material_path: String = material.resource_path if material != null else ""
			var material_name: String = material.resource_name if material != null else ""
			var description := (material_path + " " + material_name).to_lower()
			var family := "bark" if "bark" in description else ("leaves" if "leaf" in description or "leaves" in description else "unknown")
			best = {"subject": subject.identity, "surface": surface, "material_path": material_path, "material_name": material_name, "material_family": family, "distance": distance, "position": _vector_values(hit)}
	return best

static func _vector_values(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func _transform_values(value: Transform3D) -> Dictionary:
	return {"origin": _vector_values(value.origin), "basis_x": _vector_values(value.basis.x), "basis_y": _vector_values(value.basis.y), "basis_z": _vector_values(value.basis.z)}
