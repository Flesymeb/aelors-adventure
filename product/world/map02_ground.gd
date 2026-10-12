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
const AMBUSH_APPROACH := Vector2(3, 70)
const AMBUSH_ROUTE_START := Vector2(3, 65)
const AMBUSH_FLANK := Vector2(3, 74)
const AMBUSH_ANCHORS := [Vector2(4, 75), Vector2(7, 76)]
const LINE_APPROACH := Vector2(5, 88)
const LINE_COVER := Vector2(6.244, 96.483)
const LINE_COVER_PATH := "Decorations-Forest/@rock_moss_set_01_rock06@28709"
const LINE_FLANK := [Vector2(3, 92), Vector2(3, 96)]
const LINE_ANCHORS := [Vector2(4, 95), Vector2(9, 95), Vector2(9, 100)]
const LINE_RECORD := Vector2(13, 100)
const LINE_RECORD_APPROACH := Vector2(11, 101)
const LINE_SUPPLY := Vector2(2, 100)
const LINE_SUPPLY_APPROACH := Vector2(4, 100)
const LN01_CLUE := Vector2(6, 103)
const LN01_SUPPLY := Vector2(3, 107)
const LN01_LOCATION := Vector2(9, 107)
const LN01_PASSAGE := Vector2(6, 111)
const LN01_EXIT := Vector2(6, 116)

static func in_bounds(xz: Vector2) -> bool:
	return xz.is_finite() and xz.x >= -1100 and xz.x <= 700 and xz.y >= -1300 and xz.y <= 500

static func entry_xz(position: Vector3, map_id: String) -> Vector2:
	# Old MAP02 reused village coordinates. Recover at CP02 without altering facts.
	if map_id != MAP02_ID or not position.is_finite(): return ENTRY
	var xz := Vector2(position.x, position.z)
	return xz if xz.x >= -20 and xz.x <= 35 and xz.y >= 10 and xz.y <= 119 else ENTRY

static func support(world: Node3D, xz: Vector2, excludes: Array = []) -> Dictionary:
	if not in_bounds(xz): return {}
	var exclusions: Array[RID] = []
	exclusions.assign(excludes)
	var player = world.get("player")
	if is_instance_valid(player) and player is CollisionObject3D and not exclusions.has(player.get_rid()): exclusions.append(player.get_rid())
	# Select terrain support directly. Authored canopy/trunk collision remains
	# active for movement and standing volume, but cannot masquerade as ground.
	var terrain: Node = world.village.get_node("Main Terrain")
	if not world.village.has_meta("terrain_support_exclusions"):
		var authored_exclusions: Array[RID] = []
		for body in world.village.find_children("*", "CollisionObject3D", true, false):
			if not terrain.is_ancestor_of(body): authored_exclusions.append(body.get_rid())
		world.village.set_meta("terrain_support_exclusions", authored_exclusions)
	for rid in world.village.get_meta("terrain_support_exclusions"):
		if not exclusions.has(rid): exclusions.append(rid)
	# A ray exactly on a native triangle seam can miss both faces. Bounded
	# neighboring rays recover the same authored surface plane, never a floor.
	for offset in [Vector2.ZERO, Vector2(0.015,0.011), Vector2(-0.013,-0.017)]:
		var p: Vector2 = xz + offset
		var ray := PhysicsRayQueryParameters3D.create(Vector3(p.x, 220, p.y), Vector3(p.x, -60, p.y), 1, exclusions)
		var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or hit.normal.y < 0.65 or not terrain.is_ancestor_of(hit.collider): continue
		var n: Vector3 = hit.normal
		var y: float = hit.position.y + (n.x * offset.x + n.z * offset.y) / n.y
		hit.position = Vector3(xz.x, y, xz.y)
		return hit
	return {}

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
