extends RefCounted
## Opt-in native binding equivalence checks; never run at product startup.
const FIELDS := {
	"Gradient": ["offsets", "colors"],
	"FastNoiseLite": ["noise_type", "frequency", "cellular_jitter", "cellular_return_type", "domain_warp_enabled", "domain_warp_type", "domain_warp_amplitude", "domain_warp_fractal_type", "domain_warp_fractal_lacunarity", "domain_warp_fractal_gain"],
	"NoiseTexture2D": ["noise", "color_ramp", "seamless"],
	"Terrain3DMaterial": ["_shader_parameters", "world_background", "auto_shader", "dual_scaling"],
	"Terrain3DMeshAsset": ["name", "id", "scene_file", "density", "last_lod", "last_shadow_lod", "lod0_range"],
	"Terrain3DTextureAsset": ["name", "id", "albedo_color", "albedo_texture", "normal_texture", "uv_scale", "detiling_rotation", "detiling_shift"],
	"Terrain3DAssets": ["mesh_list", "texture_list"]
}

static func signature(value: Variant) -> Variant:
	if value is Resource:
		var kind: String = value.get_class()
		if not FIELDS.has(kind):
			return {"class": kind, "path": value.resource_path}
		var fields := {}
		for field in FIELDS[kind]:
			fields[field] = signature(value.get(field))
		return {"class": kind, "fields": fields}
	if value is Dictionary:
		var result := {}
		for key in value:
			result[str(key)] = signature(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(signature(item))
		return result
	return var_to_str(value)

static func terrain_signature(world: Node3D) -> Dictionary:
	var terrain := world.get_node("Terrain3D")
	return {"material": signature(terrain.get("material")), "assets": signature(terrain.get("assets"))}

static func checks(source: PackedScene, binding: Script) -> Dictionary:
	var original: Node3D = source.instantiate()
	var restored: Node3D = binding.instantiate(source)
	var terrain := original.get_node("Terrain3D")
	var rebuilt: Dictionary = binding.authored_resources()
	var result := {
		"authored_material_equivalent": signature(terrain.get("material")) == signature(rebuilt["Terrain3DMaterial_tlwt5"]),
		"authored_assets_equivalent": signature(terrain.get("assets")) == signature(rebuilt["Terrain3DAssets_dwbse"]),
		"valid_source_unchanged": terrain_signature(original) == terrain_signature(restored),
		"source_material_identity_retained": terrain.get("material") == restored.get_node("Terrain3D").get("material"),
		"source_assets_identity_retained": terrain.get("assets") == restored.get_node("Terrain3D").get("assets")
	}
	original.free()
	restored.free()
	return result
