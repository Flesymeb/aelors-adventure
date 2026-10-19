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
var sky_elapsed := 0.0
var sky_clock := 0.0
var dome: Node
func configure(map: Node3D) -> void:
	village = map
	world = village.get_node("Sky3D")
	sun = world.get_node("SunLight")
	environment = world.environment
	# Clouds move slowly. Sampling their positions once per second avoids
	# invalidating the full radiance cube every physics tick. Keep the original
	# sky colours, clouds, lighting and immediate time-of-day setters intact.
	dome = world.get_node("SkyDome")
	dome.process_method = 2 # SkyDome.MANUAL
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
func _process(delta: float) -> void:
	if not is_instance_valid(dome) or get_tree().paused: return
	sky_elapsed += delta
	if sky_elapsed < 1.0: return
	sky_clock += sky_elapsed
	dome.process_tick(sky_elapsed)
	environment.sky.sky_material.set_shader_parameter("presentation_time", sky_clock)
	sky_elapsed = 0.0
func toggle_quality() -> void:
	if state:
		state.graphics_quality = "normal" if state.graphics_quality == "high" else "high"
	apply_quality()
func apply_quality() -> void:
	var profile: String = state.graphics_quality if state else "high"
	enhanced = profile != "low"
	var high := profile == "high"
	preload("res://world/render_quality.gd").apply(get_viewport(), environment, profile)
	# No full-scene fog veil: retain sky/clouds and precision, not haze.
	environment.fog_enabled = false
	world.set("fog_enabled", false) # Also disable Sky3D's separate fog overlay.
	preload("res://world/render_quality.gd").lights(village, high, 25.0 if enhanced else 20.0)
	village.get_node("Terrain3D").material.dual_scaling = high
	village.get_node("Terrain3D").material.set_shader_param("mipmap_bias", 0.0 if high else 1.0)
	village.get_node("Terrain3D").set("mesh_lods", 7 if enhanced else 5)
	preload("res://world/render_quality.gd").materials(village)
	for asset in village.get_node("Terrain3D").assets.mesh_list:
		var tall: bool = "pine" in asset.name or "maple" in asset.name
		asset.cast_shadows = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if high or tall else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		asset.lod0_range = (180.0 if tall else (100.0 if "bush" in asset.name else 65.0)) if high else ((96.0 if enhanced else 90.0) if tall else ((60.0 if enhanced else 35.0) if "bush" in asset.name else (40.0 if enhanced else 25.0)))
