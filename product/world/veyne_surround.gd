extends Node3D
## Decorative authored masonry only. Existing arena owns collision/navigation.
var modules: Array[MeshInstance3D] = []
var sky_material: ShaderMaterial
var effect_time := 0.0
var clock_budget := 0.0
var state: Node

func bind(arena: Node3D) -> void:
	var environment_root := arena.get_parent()
	var environment_node: WorldEnvironment = environment_root.get_node("WorldEnvironment")
	environment_node.environment = preload("res://assets/bosses/veyne_night.tres").duplicate(true)
	sky_material = environment_node.environment.sky.sky_material
	var moon: DirectionalLight3D = environment_root.get_node_or_null("Moon")
	if moon:
		sky_material.set_shader_parameter("moon_direction",moon.global_basis.z.normalized())
	var world := environment_root.get_parent()
	state = world.get("dialogue_state")
	# The arena replaces WorldEnvironment after the chapter quality owner ran.
	# Reapply that owner now so the boss keeps fog, glow and the same tonemapper.
	if is_instance_valid(world.get("quality")): world.quality.apply_quality()
	var original: Node3D = preload("res://assets/maps/map03/crypt.glb").instantiate()
	var wall: MeshInstance3D = original.find_child("Wall_004_Wall_Tiles_0",true,false)
	var pillar: MeshInstance3D = original.find_child("Pillar_001_Pillar_Texture_0",true,false)
	var floor_mesh: MeshInstance3D = original.find_child("Floor_005_Floor_Tiles_0",true,false)
	# Four foundations enclose the raised courtyard; top stays below its floor.
	for data in [[Vector3(-16,-8.2,-41.2),Vector3(24,13,1.2)], [Vector3(-16,-8.2,-41.2),Vector3(1.2,13,24)], [Vector3(6.8,-8.2,-41.2),Vector3(1.2,13,24)], [Vector3(-16,-8.2,-18.4),Vector3(24,13,1.2)]]:
		add_module(arena,original,wall,data[0],data[1],"foundation")
	# Distant broken towers lie outside all retained travel/attack bounds.
	for data in [[Vector3(-28,-8.2,-49),Vector3(5,18,5)], [Vector3(18,-8.2,-51),Vector3(6,24,6)], [Vector3(-32,-8.2,-12),Vector3(5,14,5)], [Vector3(21,-8.2,-9),Vector3(4,17,4)]]:
		add_module(arena,original,pillar,data[0],data[1],"ruin")
	add_module(arena,original,floor_mesh,Vector3(-44,-8.5,-65),Vector3(80,0.25,80),"lower_court")
	original.free()

func add_module(arena: Node3D, original: Node3D, source: MeshInstance3D, corner: Vector3, dimensions: Vector3, variant: String) -> void:
	var source_pose: Transform3D = arena.source_transform(source,original)
	var bounds: AABB = source_pose*source.mesh.get_aabb()
	# The selected wall is a plane; rotate its authored horizontal span into
	# the desired facade before scaling. Zero thickness is not a volume.
	if variant == "foundation" and (bounds.size.x >= bounds.size.z) != (dimensions.x >= dimensions.z):
		source_pose = Transform3D(Basis(Vector3.UP,PI*0.5),Vector3.ZERO)*source_pose
		bounds = source_pose*source.mesh.get_aabb()
	var factor := Vector3.ONE
	var placement := corner
	var threshold := maxf(0.001,bounds.size.length()*0.0001)
	for axis in 3:
		if bounds.size[axis] > threshold:
			factor[axis] = dimensions[axis]/bounds.size[axis]
		else:
			# Retain planar/nearly planar thickness instead of dividing by it.
			placement[axis] += maxf(0.0,dimensions[axis]-bounds.size[axis])*0.5
	var mesh := MeshInstance3D.new()
	mesh.name = "OuterMasonry"+str(modules.size())
	mesh.mesh = source.mesh
	if variant == "foundation":
		for surface in mesh.mesh.get_surface_count():
			var material = source.get_active_material(surface)
			if material is BaseMaterial3D:
				var facade_material: BaseMaterial3D = material.duplicate()
				facade_material.cull_mode = BaseMaterial3D.CULL_DISABLED
				mesh.set_surface_override_material(surface,facade_material)
	mesh.set_meta("surround_variant",variant)
	mesh.set_meta("surround_corner",corner)
	mesh.set_meta("surround_extent",dimensions)
	add_child(mesh)
	mesh.global_transform = Transform3D(Basis.from_scale(factor),placement-bounds.position*factor)*source_pose
	modules.append(mesh)

func _process(delta: float) -> void:
	if not sky_material: return
	var reduced: bool = is_instance_valid(state) and state.get("reduced_motion") == true
	if not reduced: effect_time = fmod(effect_time+delta,3600.0)
	clock_budget += delta
	# Slow cloud clock, bounded radiance updates; inherits the world pause owner.
	if clock_budget < 0.25: return
	clock_budget = 0.0
	sky_material.set_shader_parameter("effect_time",effect_time)
	sky_material.set_shader_parameter("reduced_motion",reduced)
