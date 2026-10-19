extends Node3D
## Seeded visual-only fern clusters, grounded on the actual authored triangles.
## The central route, encounter navigation, cover and collision are untouched.
var instance_count := 0
func populate(world: Node3D) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var source: Mesh
	for candidate in world.village.get_node("Groundcover").find_children("*", "MultiMeshInstance3D",true,false):
		if candidate.name.begins_with("fern_02") and candidate.multimesh:
			source = candidate.multimesh.mesh
			break
	if source == null: return
	var random := RandomNumberGenerator.new()
	random.seed = 20261019
	var transforms: Array[Transform3D] = []
	for z in [29.0,40.0,55.0,70.0,88.0,104.0,113.0]:
		for side in [-1.0,1.0]:
			var x := -5.0 if side < 0.0 else 17.0
			for i in 9:
				var anchor := Vector2(x+random.randf_range(-1.5,1.5),z+random.randf_range(-2.0,2.0))
				var hit: Dictionary = world.ground_policy.support(world,anchor)
				if hit.is_empty() or hit.normal.y < 0.85: continue
				var scale_factor := random.randf_range(1.1,1.9)
				var pose := Basis(Vector3.UP,random.randf_range(-PI,PI)).scaled(Vector3.ONE*scale_factor)
				transforms.append(Transform3D(pose,hit.position+Vector3.UP*0.015))
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = source
	instances.instance_count = transforms.size()
	for i in transforms.size(): instances.set_instance_transform(i,transforms[i])
	var batch := MultiMeshInstance3D.new()
	batch.name = "GroundedFernClusters"
	batch.multimesh = instances
	batch.visibility_range_end = 90.0
	batch.visibility_range_end_margin = 15.0
	batch.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(batch)
	instance_count = transforms.size()
