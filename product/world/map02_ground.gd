extends "res://forest_ground.gd"
## Separate map identity on the retained authored forest terrain.
const MAP02_ID := "meadow-entry-v1"
const ENTRY := Vector2(135, 133)
const ROADBLOCK := Vector2(133, 146)
const RETURN := Vector2(127, 133)

static func entry_xz(position: Vector3, map_id: String) -> Vector2:
	if map_id != MAP02_ID or not position.is_finite(): return ENTRY
	var xz := Vector2(position.x, position.z)
	return xz if in_bounds(xz) else ENTRY
