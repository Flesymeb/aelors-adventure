extends RefCounted
## Explicit native load probe. CACHE_MODE_IGNORE_DEEP avoids inherited cache success.
const ROOTS := ["res://world.tscn", "res://Prefabs/Town/Building/EA03_Town_House_Comp_01a_PRE.prefab.scn"]
const GRASS_OWNERS := ["res://Objects/EA03_Plant_Grass_02a.fbx", "res://Objects/EA03_Plant_Grass_02b.fbx"]
const GRASS_TEXTURE := "res://Textures/Grass_Texture.png"
const AMBUSH_MEDIA := ["res://assets/ambush/ambusher_a.gltf", "res://assets/ambush/ambusher_b.gltf"]
const AMBUSH_CLIPS := ["Idle", "Walk", "Punch", "HitReact", "Death"]

static func run() -> Dictionary:
	var checks := {}
	var pending: Array = ROOTS.duplicate()
	pending.append_array(GRASS_OWNERS)
	pending.append_array(AMBUSH_MEDIA)
	var seen := {}
	var missing: Array[Dictionary] = []
	while not pending.is_empty() and seen.size() < 300:
		var path: String = pending.pop_back()
		if seen.has(path): continue
		seen[path] = true
		for dependency in ResourceLoader.get_dependencies(path):
			var target: String = dependency.split("::")[-1]
			if target == "res://" or not ResourceLoader.exists(target):
				missing.append({"owner": path, "dependency": target})
			elif target.get_extension() in ["tscn", "tres", "scn", "res", "material", "mesh", "gltf", "glb", "fbx"]:
				pending.append(target)
	checks.native_dependency_edges = missing.is_empty() and pending.is_empty()
	for path in ROOTS:
		var scene := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
		checks[path + "_loaded"] = scene != null
		var instance: Node = scene.instantiate() if scene else null
		checks[path + "_instantiated"] = instance != null
		if instance: instance.free()
	var grass_materials: Array[Dictionary] = []
	var grass_geometry: Array[Dictionary] = []
	var grass_imports: Array[Dictionary] = []
	for path in GRASS_OWNERS:
		grass_imports.append(_import_facts(path))
		var scene := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
		checks[path + "_loaded"] = scene != null
		var instance: Node = scene.instantiate() if scene else null
		checks[path + "_instantiated"] = instance != null
		var surfaces := 0
		var matching_textures := 0
		var vertices := 0
		if instance:
			for node in instance.find_children("*", "MeshInstance3D", true, false):
				var mesh_node := node as MeshInstance3D
				if not mesh_node.mesh: continue
				for index in mesh_node.mesh.get_surface_count():
					surfaces += 1
					var geometry := _geometry_facts(path, mesh_node, index)
					vertices += int(geometry.vertices)
					grass_geometry.append(geometry)
					var material := mesh_node.get_active_material(index) as BaseMaterial3D
					var texture_path := ""
					if material and material.albedo_texture:
						texture_path = material.albedo_texture.resource_path
					if texture_path == GRASS_TEXTURE: matching_textures += 1
					grass_materials.append({"owner": path, "mesh": str(mesh_node.name),
						"surface": index, "albedo_texture": texture_path,
						"imported": _material_facts(mesh_node.mesh.surface_get_material(index)),
						"surface_override": _material_facts(mesh_node.get_surface_override_material(index)),
						"node_override": _material_facts(mesh_node.material_override),
						"active": _material_facts(mesh_node.get_active_material(index))})
			instance.free()
		checks[path + "_original_texture_binding"] = surfaces > 0 and matching_textures == surfaces
		checks[path + "_geometry_present"] = surfaces > 0 and vertices > 0
	var texture := ResourceLoader.load(GRASS_TEXTURE, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Texture2D
	checks.retained_grass_png = texture != null and texture.get_size() == Vector2(480, 480)
	var card := ResourceLoader.load("res://Materials/EA_Grass_Card.tres", "ShaderMaterial", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as ShaderMaterial
	var card_texture: Texture2D = card.get_shader_parameter("albedo_texture") if card else null
	checks.authored_alpha_cutout_material = card_texture != null and card_texture.resource_path == GRASS_TEXTURE and is_equal_approx(float(card.get_shader_parameter("alpha_cutoff")), 0.45)
	var ambush_bindings: Array[Dictionary] = []
	for path in AMBUSH_MEDIA:
		var facts := _ambush_binding_facts(path)
		ambush_bindings.append(facts)
		checks[path + "_loaded"] = facts.loaded
		checks[path + "_instantiated"] = facts.instantiated
		checks[path + "_retained_rig"] = facts.bone_count > 0 and facts.contact_bone_present and facts.palm_bone_present and facts.skinned_meshes > 0
		checks[path + "_retained_clips"] = facts.missing_clips.is_empty()
		checks[path + "_retained_materials"] = facts.surfaces > 0 and facts.textured_surfaces == facts.surfaces
	# Ignoring loaded-resource caches does not remove the native imported scene cache.
	# Host cold import and Tester material correspondence are separate qualification gates.
	return {"checks": checks, "resources_inspected": seen.size(), "missing": missing,
		"original_psd_present": FileAccess.file_exists("res://Objects/Grass_Texture.psd"),
		"fbx_import_owners": GRASS_OWNERS, "grass_materials": grass_materials,
		"grass_geometry": grass_geometry, "grass_imports": grass_imports,
		"ambush_bindings": ambush_bindings,
		"grass_texture": _texture_facts(texture),
		"qualification": {"probe": "opt_in_resource_load", "cache_mode": "CACHE_MODE_IGNORE_DEEP",
			"native_import_cache_bypassed": false, "cold_import_observed": false}}

static func _ambush_binding_facts(path: String) -> Dictionary:
	# Opt-in structural observation only. Never configure the gameplay adapter,
	# reveal an actor or claim playback/source authentication from this load.
	var scene := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
	var instance: Node = scene.instantiate() if scene else null
	var facts := {"owner": path, "loaded": scene != null, "instantiated": instance != null,
		"bone_count": 0, "contact_bone_present": false, "palm_bone_present": false,
		"skinned_meshes": 0, "surfaces": 0, "textured_surfaces": 0,
		"catalog": [], "missing_clips": AMBUSH_CLIPS.duplicate(), "clips": [], "materials": []}
	if not instance: return facts
	var skeleton := instance.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton:
		facts.bone_count = skeleton.get_bone_count()
		facts.contact_bone_present = skeleton.find_bone("LowerArm.R") >= 0
		facts.palm_bone_present = skeleton.find_bone("Middle1.R") >= 0
	var player := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player:
		facts.catalog = Array(player.get_animation_list())
		for name in AMBUSH_CLIPS:
			if not player.has_animation(name): continue
			var clip := player.get_animation(name)
			facts.clips.append({"name": name, "resource": clip.resource_path,
				"length": clip.length, "track_count": clip.get_track_count()})
			if clip.length > 0 and clip.get_track_count() > 0: facts.missing_clips.erase(name)
	for node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if not mesh_node.mesh: continue
		if mesh_node.skin and mesh_node.get_node_or_null(mesh_node.skeleton) == skeleton: facts.skinned_meshes += 1
		for surface in mesh_node.mesh.get_surface_count():
			facts.surfaces += 1
			var material := mesh_node.get_active_material(surface) as BaseMaterial3D
			if material and material.albedo_texture: facts.textured_surfaces += 1
			facts.materials.append({"mesh": str(mesh_node.name), "surface": surface,
				"active": _material_facts(material)})
	instance.free()
	return facts

static func _import_facts(owner: String) -> Dictionary:
	var recipe := ConfigFile.new()
	var result := recipe.load(owner + ".import")
	var facts := {"owner": owner, "recipe": owner + ".import", "load_error": result,
		"source_exists": FileAccess.file_exists(owner)}
	if result != OK: return facts
	facts.importer = recipe.get_value("remap", "importer", "")
	facts.source_file = recipe.get_value("deps", "source_file", "")
	facts.root_scale = recipe.get_value("params", "nodes/root_scale", null)
	facts.generate_lods = recipe.get_value("params", "meshes/generate_lods", null)
	facts.materials_extract = recipe.get_value("params", "materials/extract", null)
	facts.import_script = recipe.get_value("params", "import_script/path", "")
	facts.material_subresources = recipe.get_value("params", "_subresources", {})
	return facts

static func _texture_facts(texture: Texture2D) -> Dictionary:
	if not texture: return {"present": false}
	var facts := {"present": true, "class": texture.get_class(), "path": texture.resource_path,
		"size": [texture.get_width(), texture.get_height()]}
	var image := texture.get_image()
	if image:
		facts.image_format = image.get_format()
		facts.image_is_compressed = image.is_compressed()
		facts.image_alpha_mode = null if image.is_compressed() else image.detect_alpha()
		facts.image_has_mipmaps = image.has_mipmaps()
	return facts

static func _material_facts(material: Material) -> Dictionary:
	if not material: return {"present": false}
	var facts := {"present": true, "class": material.get_class(), "path": material.resource_path,
		"name": material.resource_name}
	if material is BaseMaterial3D:
		var base := material as BaseMaterial3D
		facts.albedo_color = [base.albedo_color.r, base.albedo_color.g, base.albedo_color.b, base.albedo_color.a]
		facts.albedo_texture = _texture_facts(base.albedo_texture)
		facts.transparency = base.transparency
		facts.alpha_scissor_threshold = base.alpha_scissor_threshold
		facts.cull_mode = base.cull_mode
		facts.shading_mode = base.shading_mode
		facts.vertex_color_use_as_albedo = base.vertex_color_use_as_albedo
		facts.metallic = base.metallic
		facts.roughness = base.roughness
		facts.normal_enabled = base.normal_enabled
		facts.normal_texture = _texture_facts(base.normal_texture)
	return facts

static func _geometry_facts(owner: String, node: MeshInstance3D, surface: int) -> Dictionary:
	var arrays := node.mesh.surface_get_arrays(surface)
	var bounds := node.mesh.get_aabb()
	var counts := {}
	var channels := {"vertices": Mesh.ARRAY_VERTEX, "normals": Mesh.ARRAY_NORMAL,
		"uv": Mesh.ARRAY_TEX_UV, "uv2": Mesh.ARRAY_TEX_UV2, "indices": Mesh.ARRAY_INDEX}
	for channel in channels:
		var data = arrays[channels[channel]]
		counts[channel] = data.size() if data != null else 0
	counts.merge({"owner": owner, "mesh": str(node.name), "mesh_path": node.mesh.resource_path,
		"surface": surface, "surface_count": node.mesh.get_surface_count(),
		"primitive": node.mesh.surface_get_primitive_type(surface),
		"aabb_position": [bounds.position.x, bounds.position.y, bounds.position.z],
		"aabb_size": [bounds.size.x, bounds.size.y, bounds.size.z],
		"position": [node.position.x, node.position.y, node.position.z],
		"rotation": [node.rotation.x, node.rotation.y, node.rotation.z],
		"scale": [node.scale.x, node.scale.y, node.scale.z]})
	return counts
