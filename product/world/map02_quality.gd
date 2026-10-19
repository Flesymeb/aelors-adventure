extends "res://environment_quality.gd"
## Keep authored terrain, textures, baked composition and atmosphere.
func configure(map: Node3D) -> void:
	village = map
	if state: state.preferences_changed.connect(apply_quality)
	apply_quality()
	var roadside := preload("res://world/map02_roadside.gd").new()
	roadside.name = "RoadsideFerns"
	village.add_child(roadside)
	roadside.populate.call_deferred(village.get_parent())
func set_dusk(value: bool) -> void:
	dusk = value
func apply_quality() -> void:
	var profile: String = state.graphics_quality if state else "high"
	enhanced = profile != "low"
	var high := profile == "high"
	var map_environment: Environment = village.get_node("WorldEnvironment").environment
	preload("res://world/render_quality.gd").apply(get_viewport(), map_environment, profile)
	# Clear gameplay visibility; preserve the authored sky and colour palette.
	map_environment.fog_enabled = false
	# The authored sky shader has very low radiance: with GI off, forest shade
	# had almost no indirect light. A restrained daylight fill keeps material
	# colour readable without altering camera exposure or lifting screen black.
	map_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	map_environment.ambient_light_color = Color(1.0,0.96,0.88)
	map_environment.ambient_light_energy = 0.30
	map_environment.ambient_light_sky_contribution = 0.35
	preload("res://world/render_quality.gd").lights(village, high, 55.0 if enhanced else 30.0)
	preload("res://world/render_quality.gd").materials(village)
	for mesh in village.get_node("Groundcover").find_children("*", "MultiMeshInstance3D", true, false):
		mesh.visibility_range_end = 120 if high else (65 if enhanced else 40)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if high else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
