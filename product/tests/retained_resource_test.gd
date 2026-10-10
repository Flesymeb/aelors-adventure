extends RefCounted
## Explicit native load probe. CACHE_MODE_IGNORE_DEEP avoids inherited cache success.
const ROOTS := ["res://world.tscn", "res://Prefabs/Town/Building/EA03_Town_House_Comp_01a_PRE.prefab.scn"]
const GRASS_OWNERS := ["res://Objects/EA03_Plant_Grass_02a.fbx", "res://Objects/EA03_Plant_Grass_02b.fbx"]
const GRASS_TEXTURE := "res://Textures/Grass_Texture.png"

static func run() -> Dictionary:
	var checks := {}
	var pending: Array = ROOTS.duplicate()
	pending.append_array(GRASS_OWNERS)
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
	for path in GRASS_OWNERS:
		var scene := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
		checks[path + "_loaded"] = scene != null
		var instance: Node = scene.instantiate() if scene else null
		checks[path + "_instantiated"] = instance != null
		var surfaces := 0
		var matching_textures := 0
		if instance:
			for node in instance.find_children("*", "MeshInstance3D", true, false):
				var mesh_node := node as MeshInstance3D
				if not mesh_node.mesh: continue
				for index in mesh_node.mesh.get_surface_count():
					surfaces += 1
					var material := mesh_node.get_active_material(index) as BaseMaterial3D
					var texture_path := ""
					if material and material.albedo_texture:
						texture_path = material.albedo_texture.resource_path
					if texture_path == GRASS_TEXTURE: matching_textures += 1
					grass_materials.append({"owner": path, "mesh": str(mesh_node.name),
						"surface": index, "albedo_texture": texture_path})
			instance.free()
		checks[path + "_original_texture_binding"] = surfaces > 0 and matching_textures == surfaces
	var texture := ResourceLoader.load(GRASS_TEXTURE, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Texture2D
	checks.retained_grass_png = texture != null and texture.get_size() == Vector2(480, 480)
	var card := ResourceLoader.load("res://Materials/EA_Grass_Card.tres", "ShaderMaterial", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as ShaderMaterial
	var card_texture: Texture2D = card.get_shader_parameter("albedo_texture") if card else null
	checks.authored_alpha_cutout_material = card_texture != null and card_texture.resource_path == GRASS_TEXTURE and is_equal_approx(float(card.get_shader_parameter("alpha_cutoff")), 0.45)
	# A current importer log is still required; resource loading alone cannot prove fresh import.
	return {"checks": checks, "resources_inspected": seen.size(), "missing": missing,
		"original_psd_present": FileAccess.file_exists("res://Objects/Grass_Texture.psd"),
		"fbx_import_owners": GRASS_OWNERS, "grass_materials": grass_materials}
