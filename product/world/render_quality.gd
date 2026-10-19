extends RefCounted
## Shared desktop profile. Quality is an explicit preference, never inferred
## from the developer machine's renderer, frame rate or headless test mode.
static func apply(viewport: Viewport, environment: Environment, profile: String) -> void:
	var high := profile == "high"
	var low := profile == "low"
	viewport.scaling_3d_scale = 0.7 if low else 1.0
	viewport.msaa_3d = Viewport.MSAA_8X if high else Viewport.MSAA_DISABLED
	viewport.use_taa = false # Keep fast combat and dust edges free of temporal trails.
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.anisotropic_filtering_level = Viewport.ANISOTROPY_16X if high else Viewport.ANISOTROPY_4X
	viewport.mesh_lod_threshold = 0.5 if high else 1.0
	if environment == null: return
	# Preserve each chapter's original exposure, sky, colour curve and glow.
	# Raising precision must not silently add a grey veil or darken all shade.
	# These effects were disabled by the original runtime quality owners.
	environment.ssao_enabled = false
	environment.ssil_enabled = false
	environment.ssr_enabled = false
	environment.volumetric_fog_enabled = false
	environment.sdfgi_enabled = false

static func lights(root: Node, high: bool, distance: float) -> void:
	for light in root.find_children("*", "DirectionalLight3D", true, false):
		light.directional_shadow_max_distance = distance
		if high:
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			light.directional_shadow_blend_splits = true
			light.light_angular_distance = 0.35

static func materials(root: Node) -> void:
	# Retain real albedo/normal/roughness maps and each material's PBR response.
	# Mipmapped anisotropy adds ground detail at oblique third-person angles.
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null: continue
		for surface in mesh.mesh.get_surface_count():
			var material: Material = mesh.get_active_material(surface)
			if material is BaseMaterial3D:
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
