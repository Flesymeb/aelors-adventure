extends RefCounted
## Explicit native load probe. CACHE_MODE_IGNORE_DEEP avoids inherited cache success.
const ROOTS := ["res://world.tscn", "res://Prefabs/Town/Building/EA03_Town_House_Comp_01a_PRE.prefab.scn"]

static func run() -> Dictionary:
	var checks := {}
	var pending: Array = ROOTS.duplicate()
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
			elif target.get_extension() in ["tscn", "tres", "scn", "res", "material", "mesh", "gltf", "glb"]:
				pending.append(target)
	checks.native_dependency_edges = missing.is_empty() and pending.is_empty()
	for path in ROOTS:
		var scene := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
		checks[path + "_loaded"] = scene != null
		var instance: Node = scene.instantiate() if scene else null
		checks[path + "_instantiated"] = instance != null
		if instance: instance.free()
	var texture := load("res://Textures/Grass_Texture.png") as Texture2D
	checks.retained_grass_png = texture != null and texture.get_size() == Vector2(480, 480)
	# Keep the unresolved import defect explicit; scene loading is a separate gate.
	return {"checks": checks, "resources_inspected": seen.size(), "missing": missing,
		"original_psd_present": FileAccess.file_exists("res://Objects/Grass_Texture.psd"),
		"fbx_import_owners": ["res://Objects/EA03_Plant_Grass_02a.fbx", "res://Objects/EA03_Plant_Grass_02b.fbx"]}
