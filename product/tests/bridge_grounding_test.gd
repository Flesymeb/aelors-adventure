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
