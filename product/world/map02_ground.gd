extends RefCounted
## Rytelier triangle collision and occupied-volume queries; no Terrain3D dependency.
const MAP02_ID := "meadow-entry-v1"
const ENTRY := Vector2(3, 25)
const ROADBLOCK := Vector2(3, 43)
const ROADBLOCK_ANCHORS := [ROADBLOCK, Vector2(5, 43)]
const PRESSURE_ANCHORS := [Vector2(8, 61), Vector2(10, 64)]
const PRESSURE_COVER := Vector2(8, 58)
const PRESSURE_APPROACH := Vector2(8, 53)
const PRESSURE_FLANK := [Vector2(4, 57), Vector2(4, 61)]
const RETURN := Vector2(-3, 25)
const ROUTE_RECORD := Vector2(6, 66)
const RECORD_APPROACH := Vector2(4, 65)

static func in_bounds(xz: Vector2) -> bool:
	return xz.is_finite() and xz.x >= -1100 and xz.x <= 700 and xz.y >= -1300 and xz.y <= 500

static func entry_xz(position: Vector3, map_id: String) -> Vector2:
	# Old MAP02 reused village coordinates. Recover at CP02 without altering facts.
	if map_id != MAP02_ID or not position.is_finite(): return ENTRY
	var xz := Vector2(position.x, position.z)
	return xz if xz.x >= -20 and xz.x <= 35 and xz.y >= 10 and xz.y <= 85 else ENTRY

static func support(world: Node3D, xz: Vector2, excludes: Array = []) -> Dictionary:
	if not in_bounds(xz): return {}
	var exclusions: Array[RID] = []
	exclusions.assign(excludes)
	var player = world.get("player")
	if is_instance_valid(player) and player is CollisionObject3D and not exclusions.has(player.get_rid()): exclusions.append(player.get_rid())
	var ray := PhysicsRayQueryParameters3D.create(Vector3(xz.x, 220, xz.y), Vector3(xz.x, -60, xz.y), 1, exclusions)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.normal.y < 0.65: return {}
	# Only the actual opaque terrain may support route anchors. A rock/tree roof
	# is never mistaken for the intended bank below it.
	var terrain: Node = world.village.get_node("Main Terrain")
	if not terrain.is_ancestor_of(hit.collider): return {}
	return hit

static func place(world: Node3D, body: Node3D, xz: Vector2) -> bool:
	var excludes: Array = []
	for actor in world.find_children("*", "CollisionObject3D", true, false):
		if not world.village.is_ancestor_of(actor): excludes.append(actor.get_rid())
	var hit := support(world, xz, excludes)
	if hit.is_empty(): return false
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	var volume := PhysicsShapeQueryParameters3D.new()
	volume.shape = shape
	volume.transform.origin = hit.position + Vector3.UP * 0.98
	volume.collision_mask = 1
	volume.exclude = excludes
	if not world.get_world_3d().direct_space_state.intersect_shape(volume, 1).is_empty(): return false
	body.global_position = hit.position + Vector3.UP * 0.08
	if body is CharacterBody3D: body.velocity = Vector3.ZERO
	return true
