extends Node
## Keep the selected authored sky, ground materials and foliage intact.
var village: Node3D
var world: WorldEnvironment
var sun: DirectionalLight3D
var environment: Environment
var dusk := false
var enhanced := true
var state: Node
var developer_lamp_overlay := false
func configure(map: Node3D) -> void:
	village = map
	world = village.get_node("Sky3D")
	sun = world.get_node("SunLight")
	environment = world.environment
	# Authored forest ambience belongs to the same effects mix as world cues.
	# Preserve stream/lifecycle settings and any explicitly authored bus.
	for player_type in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for source in village.find_children("*", player_type, true, false):
			if source.bus == &"Master": source.bus = &"Effects"
	if state:
		state.preferences_changed.connect(apply_quality)
	apply_quality()
func set_dusk(value: bool) -> void:
	dusk = value
	world.set("current_time", 18.0 if dusk else 11.07)
func toggle_quality() -> void:
	enhanced = not enhanced
	apply_quality()
func apply_quality() -> void:
	if state: enhanced = state.graphics_quality == "normal"
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	get_viewport().scaling_3d_scale = 1.0 if enhanced else 0.7
	sun.directional_shadow_max_distance = 45.0 if enhanced else 25.0
	environment.ssao_enabled = false
	environment.ssil_enabled = false
	environment.sdfgi_enabled = false
	environment.volumetric_fog_enabled = false
	village.get_node("Terrain3D").set("mesh_lods", 7 if enhanced else 5)

	# Keep authored transforms/density and long tree silhouettes; restrict the
	# cost of small foliage and avoid casting thousands of grass shadows.
	for asset in village.get_node("Terrain3D").assets.mesh_list:
		var tall: bool = "pine" in asset.name or "maple" in asset.name
		asset.cast_shadows = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if tall else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		asset.lod0_range = (128.0 if enhanced else 90.0) if tall else ((60.0 if enhanced else 35.0) if "bush" in asset.name else (40.0 if enhanced else 25.0))
