extends Node

const TERRAIN_SHADER := preload("res://terrain_detail.gdshader")
var village: Node3D
var world: WorldEnvironment
var sun: DirectionalLight3D
var lamps: Array[OmniLight3D] = []
var dusk := false
var enhanced := false
var terrain_surfaces := 0
var filtered_materials := 0
var environment: Environment
@export var developer_lamp_overlay := false

func configure(map: Node3D) -> void:
	village = map
	world = village.get_node("WorldEnvironment")
	sun = village.get_node("Directional Light/Light")
	# Copy the environment settings only. Deep-copying the original sky also
	# duplicates asynchronous NoiseTexture resources that we immediately replace.
	environment = world.environment.duplicate()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 0.9
	environment.fog_enabled = true
	environment.fog_density = 0.0025
	environment.fog_light_color = Color(0.57, 0.66, 0.76)
	world.environment = environment
	sun.directional_shadow_max_distance = 55.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.2
	_bind_materials()
	set_dusk(false)
	apply_quality()
	# Authored village fixtures remain. The optional demo overlay has no globe
	# collider and can cross the shipped shoulder camera at the opening route.
	# Retire it in player builds; opt in only for same-pose isolation research.
	if developer_lamp_overlay:
		_add_lamps.call_deferred()

func _bind_materials() -> void:
	var terrain := ShaderMaterial.new()
	terrain.shader = TERRAIN_SHADER
	terrain.set_shader_parameter("dirt_texture", load("res://Textures/Pobbles_Sand_Dirt.png"))
	terrain.set_shader_parameter("detail_noise", _noise_texture())
	var copies := {}
	for node in village.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if not mesh.mesh:
			continue
		for surface in range(mesh.mesh.get_surface_count()):
			if mesh.name.begins_with("EA03_Terrain"):
				mesh.set_surface_override_material(surface, terrain)
				terrain_surfaces += 1
				continue
			var original := mesh.get_active_material(surface) as StandardMaterial3D
			if not original:
				continue
			if not copies.has(original.get_instance_id()):
				var copy := original.duplicate() as StandardMaterial3D
				# Palette texels encode authored colours; never blur adjacent swatches.
				var palette := copy.albedo_texture and copy.albedo_texture.get_width() <= 64
				copy.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS if palette else BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				copies[original.get_instance_id()] = copy
				filtered_materials += 1
			mesh.set_surface_override_material(surface, copies[original.get_instance_id()])

func _noise_texture() -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.seed = 9813
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	var image := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in range(256):
		for x in range(256):
			var a := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var b := noise.get_noise_2d(x + 93, y + 67) * 0.5 + 0.5
			var c := noise.get_noise_2d(x + 43, y + 131) * 0.5 + 0.5
			image.set_pixel(x, y, Color(a, b, c))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

func set_dusk(value: bool) -> void:
	dusk = value
	var sky := environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = Color(0.08, 0.12, 0.22) if dusk else Color(0.18, 0.35, 0.57)
	sky.sky_horizon_color = Color(0.57, 0.31, 0.23) if dusk else Color(0.64, 0.74, 0.81)
	sky.ground_bottom_color = Color(0.12, 0.14, 0.19)
	sky.ground_horizon_color = sky.sky_horizon_color * 0.65
	environment.ambient_light_color = Color(0.43, 0.52, 0.72) if dusk else Color(0.65, 0.75, 0.86)
	environment.ambient_light_energy = 0.55 if dusk else 0.48
	environment.fog_light_color = Color(0.24, 0.29, 0.40) if dusk else Color(0.57, 0.66, 0.76)
	environment.fog_density = 0.006 if dusk else 0.0025
	sun.light_color = Color(1.0, 0.67, 0.38) if dusk else Color(1.0, 0.94, 0.84)
	sun.light_energy = 0.62 if dusk else 0.82
	for lamp in lamps:
		lamp.light_energy = 2.4 if dusk else 0.8

func toggle_quality() -> void:
	enhanced = not enhanced
	apply_quality()

func apply_quality() -> void:
	var viewport := get_viewport()
	viewport.msaa_3d = Viewport.MSAA_2X if enhanced else Viewport.MSAA_DISABLED
	# Current Godot 4.7 Compatibility supports SSAO and glow. Both stay optional
	# on software rendering, while core textures, lighting and fog always apply.
	environment.ssao_enabled = enhanced
	environment.ssao_radius = 0.65
	environment.ssao_intensity = 0.65
	environment.glow_enabled = enhanced
	environment.glow_intensity = 0.45
	for i in range(lamps.size()):
		lamps[i].shadow_enabled = enhanced and i == 0

func _add_lamps() -> void:
	await get_tree().physics_frame
	for xz in [Vector2(18, 18), Vector2(25, 22), Vector2(30, 16)]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(xz.x, 100, xz.y), Vector3(xz.x, -100, xz.y))
		var hit := village.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var post := StaticBody3D.new()
		post.name = "WarmLantern"
		post.add_to_group("opening_lamp_overlay")
		village.add_child(post)
		post.global_position = hit.position
		var pole := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.055
		cylinder.bottom_radius = 0.09
		cylinder.height = 2.1
		var metal := StandardMaterial3D.new()
		metal.albedo_color = Color(0.15, 0.11, 0.08)
		metal.roughness = 0.8
		cylinder.material = metal
		pole.mesh = cylinder
		pole.position.y = 1.05
		post.add_child(pole)
		var collider := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.09
		shape.height = 2.1
		collider.shape = shape
		collider.position.y = 1.05
		post.add_child(collider)
		var glass := MeshInstance3D.new()
		var globe := SphereMesh.new()
		globe.radius = 0.16
		globe.height = 0.32
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(1.0, 0.66, 0.25)
		glow.emission_enabled = true
		glow.emission = Color(1.0, 0.38, 0.08)
		glow.emission_energy_multiplier = 2.0
		globe.material = glow
		glass.mesh = globe
		glass.position.y = 2.15
		post.add_child(glass)
		var lamp := OmniLight3D.new()
		lamp.position.y = 2.15
		lamp.light_color = Color(1.0, 0.60, 0.26)
		lamp.omni_range = 7.0
		lamp.omni_attenuation = 1.5
		post.add_child(lamp)
		lamps.append(lamp)
	set_dusk(dusk)
	apply_quality()

func toggle_developer_lamps() -> void:
	developer_lamp_overlay = not developer_lamp_overlay
	var existing := get_tree().get_nodes_in_group("opening_lamp_overlay")
	if developer_lamp_overlay and existing.is_empty():
		_add_lamps.call_deferred()
	else:
		for post in existing:
			post.visible = developer_lamp_overlay
			post.collision_layer = 1 if developer_lamp_overlay else 0
			for child in post.get_children():
				if child is OmniLight3D:
					child.light_energy = (2.4 if dusk else 0.8) if developer_lamp_overlay else 0.0
