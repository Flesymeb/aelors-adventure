extends RefCounted
## Support comes exclusively from imported floor triangles, never a substitute slab.
const MAP03_ID := "tomb-entry-v1"
const ENTRY := Vector2(0, 5)
const SPAWN := ENTRY
const RECORD := Vector2(4, -3)
const RETURN := Vector2(-4, 5)
const NORTH := Vector2(-4, -4)
const SOUTH := Vector2(-4, 0)
const DEVICE := Vector2(1.5, -5)
const OPEN_ROUTE := [Vector2(4,-5), Vector2(4,-6), Vector2(4,-8.7), Vector2(4,-11)]
const WARDEN_APPROACH := Vector2(4,-9)
const RECORD_APPROACH := Vector2(2.5, -3)
const ROUTE := [ENTRY, Vector2(0,0), Vector2(2.5,-3), Vector2(-2.5,-3), Vector2(-4,3), RETURN]

static func in_bounds(xz: Vector2) -> bool:
	return xz.is_finite() and absf(xz.x) < 6.8 and xz.y > -15.3 and xz.y < 7.3

static func entry_xz(position: Vector3, map_id: String) -> Vector2:
	var xz := Vector2(position.x,position.z)
	return xz if map_id == MAP03_ID and position.is_finite() and in_bounds(xz) else ENTRY

static func support(world: Node3D, xz: Vector2, excludes: Array = []) -> Dictionary:
	if not in_bounds(xz): return {}
	var exclusions: Array[RID] = []
	exclusions.assign(excludes)
	if is_instance_valid(world.player): exclusions.append(world.player.get_rid())
	var ray := PhysicsRayQueryParameters3D.create(Vector3(xz.x,20,xz.y), Vector3(xz.x,-5,xz.y), 1, exclusions)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.normal.y < 0.65 or not hit.collider.has_meta("tomb_floor"): return {}
	return hit

static func place(world: Node3D, body: Node3D, xz: Vector2) -> bool:
	var excludes: Array[RID] = []
	for actor in world.find_children("*", "CollisionObject3D", true, false):
		if not world.village.is_ancestor_of(actor): excludes.append(actor.get_rid())
	var hit := support(world,xz,excludes)
	if hit.is_empty(): return false
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = hit.position + Vector3.UP * 1.0
	query.collision_mask = 1
	query.exclude = excludes
	if not world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return false
	body.global_position = hit.position + Vector3.UP * 0.08
	if body is CharacterBody3D: body.velocity = Vector3.ZERO
	return true

static func route_clear(world: Node3D, xz: Vector2) -> bool:
	var exclusions: Array[RID] = []
	for actor in world.find_children("*", "CollisionObject3D", true, false):
		if not world.village.is_ancestor_of(actor): exclusions.append(actor.get_rid())
	var hit := support(world,xz,exclusions)
	if hit.is_empty(): return false
	# Survey standing clearance above a native tread, including the qualified
	# step rise. This is a probe, never collision or replacement ground.
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = hit.position + Vector3.UP * 1.65
	query.collision_mask = 1
	query.exclude = exclusions
	return world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
