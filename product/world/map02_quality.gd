extends "res://environment_quality.gd"
## Keep authored terrain, textures, baked composition and atmosphere.
func configure(map: Node3D) -> void:
	village = map
	if state: state.preferences_changed.connect(apply_quality)
	apply_quality()
func set_dusk(value: bool) -> void:
	dusk = value
func apply_quality() -> void:
	var normal: bool = state == null or state.graphics_quality == "normal"
	enhanced = normal
	get_viewport().scaling_3d_scale = 1.0 if normal else 0.7
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	var environment: Environment = village.get_node("WorldEnvironment").environment
	environment.sdfgi_enabled = false
	environment.volumetric_fog_enabled = false
	var sun: DirectionalLight3D = village.get_node("DirectionalLight3D")
	sun.directional_shadow_max_distance = 55 if normal else 30
	# Chunked MultiMeshes retain all baked instances; cull distant small plants.
	for mesh in village.get_node("Groundcover").find_children("*", "MultiMeshInstance3D", true, false):
		mesh.visibility_range_end = 65 if normal else 40
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
