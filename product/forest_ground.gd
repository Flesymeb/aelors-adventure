extends RefCounted
## Shared spatial interface for the selected authored map, including legacy saves.
const MAP_ID := "forest-885de576-v1"
const SPAWN := Vector2(116.5, 97.25)
const ISHA := Vector2(116.5, 94.5)
# The dirt path beside the western timber house is the safe practice yard.
# The lower branch introduces the live challenge, beyond Hers' withdrawal stance.
const HERS := Vector2(110, 106)
const PRACTICE := Vector2(113, 105)
const ENCOUNTER := Vector2(116, 112)
const RONEN := Vector2(123, 103)
const BOW_TARGET := Vector2(123, 109)
const COVER := Vector2(125, 106)

static func in_bounds(xz: Vector2) -> bool:
	return xz.is_finite() and xz.x >= 2 and xz.y >= 2 and xz.x <= 253 and xz.y <= 253

static func restored_xz(position: Vector3, map_id: String) -> Vector2:
	# Old coordinates are not meaningful on this map. Keep every progress fact,
	# but relocate to CP01; never write or erase the source slot during reading.
	if map_id != MAP_ID or not position.is_finite(): return SPAWN
	var xz := Vector2(position.x, position.z)
	return xz if in_bounds(xz) else SPAWN

static func support(world: Node3D, xz: Vector2, excludes: Array[RID] = []) -> Dictionary:
	if not in_bounds(xz): return {}
	# Heightmap rays exactly on grid vertices can miss triangle seams.
	# Probe just inside a cell; retain real terrain collision as the authority.
	if absf(xz.x - roundf(xz.x)) < 0.001: xz.x += 0.013
	if absf(xz.y - roundf(xz.y)) < 0.001: xz.y += 0.017
	var terrain = world.village.get_node("Terrain3D")
	var height: float = terrain.data.get_height(Vector3(xz.x, 0, xz.y))
	if not is_finite(height): return {}
	var query := PhysicsRayQueryParameters3D.create(Vector3(xz.x, 80, xz.y), Vector3(xz.x, -80, xz.y), 1, excludes)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < 0.65: return {}
	var on_bridge := false
	var collider: Object = hit.collider
	if collider is Node:
		var ancestor: Node = collider
		while ancestor and ancestor != world.village:
			if ancestor.name in ["bridge", "bridge2"]: on_bridge = true; break
			ancestor = ancestor.get_parent()
	# Avoid riverbed reloads and accidental roof spawns.
	if not on_bridge and (height < 8.5 or absf(hit.position.y - height) > 1.3): return {}
	return hit

static func place(world: Node3D, body: Node3D, xz: Vector2) -> bool:
	var excludes: Array[RID] = []
	for actor in world.find_children("*", "CollisionObject3D", true, false):
		if not world.village.is_ancestor_of(actor): excludes.append(actor.get_rid())
	var hit := support(world, xz, excludes)
	if hit.is_empty(): return false
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	var volume := PhysicsShapeQueryParameters3D.new()
	volume.shape = shape
	volume.transform = Transform3D(Basis(), hit.position + Vector3(0, 0.98, 0))
	volume.collision_mask = 1
	volume.exclude = excludes
	if not world.get_world_3d().direct_space_state.intersect_shape(volume, 1).is_empty(): return false
	body.global_position = hit.position + Vector3.UP * 0.08
	if body is CharacterBody3D: body.velocity = Vector3.ZERO
	return true
