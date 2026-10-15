extends Node
## Disposable geometry/lifecycle check; never attached to the shipped entry.
var observations: Dictionary = {}

func _ready() -> void:
	observations = run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture": true, "observations": observations}

static func run(holder: Node) -> Dictionary:
	var blade := Node3D.new()
	holder.add_child(blade)
	var trail := preload("res://combat/cats/mesh_streak.gd").new()
	trail.origin_node = blade
	holder.add_child(trail)
	trail.set_emitting(true)
	trail.sample(0.0)
	blade.position.x = 0.15
	trail.sample(0.016)
	var points_follow_blade: bool = trail.mesh_array.size() == 2 and trail.mesh_array.back().top.is_equal_approx(blade.to_global(trail.streak_top))
	var mesh_follows_blade: bool = trail.mesh != null and trail.mesh.get_surface_count() == 1
	var count: int = trail.mesh_array.size()
	trail.sample(0.0)
	var frozen_pose_no_duplicates: bool = trail.mesh_array.size() == count
	trail.set_emitting(false)
	trail.sample(0.12)
	var recovery_expires: bool = trail.mesh == null and trail.mesh_array.is_empty()
	trail.set_emitting(true)
	trail.sample(0.0)
	blade.position.x += 0.1
	trail.sample(0.016)
	trail.clear_streak()
	trail.sample(0.0)
	var interruption_clears: bool = not trail.emitting and trail.mesh == null and trail.mesh_array.is_empty()
	trail.set_emitting(true)
	for index in 40:
		blade.position.x += 0.02
		trail.sample(0.001)
	var bounded_edges: bool = trail.mesh_array.size() <= trail.maximum_edges
	blade.position.x += 10.0
	trail.sample(0.001)
	var teleport_no_bridge: bool = trail.mesh_array.size() == 1 and trail.mesh == null
	var result := {"checks": {"world_blade_endpoints": points_follow_blade, "ribbon_mesh": mesh_follows_blade,
		"frozen_pose_no_duplicates": frozen_pose_no_duplicates, "recovery_expires": recovery_expires,
		"interruption_clears": interruption_clears, "bounded_edges": bounded_edges, "teleport_no_bridge": teleport_no_bridge},
		"scope": "geometry and lifecycle only; ordinary clips, contact identity, low-quality appearance and normal-speed readability require native observation"}
	trail.free()
	blade.free()
	return result
