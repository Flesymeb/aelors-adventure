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

static func live_ambush_checks(encounter: Node) -> Dictionary:
	# Opt-in inspection of an existing fixture or ordinary encounter. This never
	# attaches/configures an actor, advances a frame, plays a clip or writes state.
	var checks := {}
	var actors: Array[Dictionary] = []
	if not is_instance_valid(encounter) or not encounter.is_inside_tree() or not encounter.is_node_ready():
		return {"available": false, "reason": "encounter_absent_or_unready", "checks": checks, "actors": actors}
	var enemies: Variant = encounter.get("enemies")
	if not enemies is Array:
		return {"available": false, "reason": "encounter_enemies_unavailable", "checks": checks, "actors": actors}
	checks.two_existing_actors = enemies.size() == AMBUSH_MEDIA.size()
	var all_available: bool = bool(checks.two_existing_actors)
	for index in AMBUSH_MEDIA.size():
		var path: String = AMBUSH_MEDIA[index]
		var actor: Node = enemies[index] if index < enemies.size() and enemies[index] is Node else null
		var facts := {"owner": path, "available": false, "reason": "actor_absent_or_unready"}
		if not is_instance_valid(actor) or not actor is CharacterBody3D or not actor.is_inside_tree() or not actor.is_node_ready() or not actor.has_method("_binding_observation"):
			all_available = false
			actors.append(facts)
			continue
		# Detached native structure is a comparison reference, never live adoption
		# evidence. It is loaded before the consecutive observer-purity boundary.
		var detached := _ambush_binding_facts(path)
		var before := _ambush_read_snapshot(encounter, actor)
		var observed: Dictionary = actor.call("_binding_observation")
		var repeated: Dictionary = actor.call("_binding_observation")
		var after := _ambush_read_snapshot(encounter, actor)
		facts.merge({"available": bool(observed.get("binding_ready", false)),
			"reason": "" if observed.get("binding_ready", false) else "live_binding_unready",
			"actor_path": str(actor.get_path()), "observer": observed, "detached": detached}, true)
		checks[path + "_observer_repeated"] = observed == repeated
		checks[path + "_observer_read_only"] = before == after
		if not facts.available:
			all_available = false
			actors.append(facts)
			continue
		var model: Node3D = actor.get("model")
		var character: Node = actor.get("character")
		var animator: AnimationPlayer = actor.get("animator")
		var source: Node3D = actor.get("source")
		var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
		var socket: BoneAttachment3D = character.get("contact_socket")
		var tree: AnimationTree = character.get("anim_tree")
		var skinned_meshes := 0
		var skin_binds: Variant = null
		var skin_rig_path: Variant = null
		var all_skins_use_rig := true
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			if mesh.skin == null: continue
			skinned_meshes += 1
			var mesh_rig: Node = mesh.get_node_or_null(mesh.skeleton)
			all_skins_use_rig = all_skins_use_rig and mesh_rig == skeleton
			if skin_binds == null:
				skin_binds = mesh.skin.get_bind_count()
				skin_rig_path = str(mesh_rig.get_path()) if mesh_rig else null
		var animation_root: Node = animator.get_node_or_null(animator.root_node)
		var live_clips_present := true
		for clip in AMBUSH_CLIPS:
			live_clips_present = live_clips_present and animator.has_animation(clip)
		checks[path + "_model_correspondence"] = observed.model_resource == path and model.scene_file_path == path and observed.model_path == str(model.get_path())
		checks[path + "_rig_correspondence"] = skeleton != null and character.get("skeleton") == skeleton and observed.skeleton_path == str(skeleton.get_path()) and observed.bone_count == skeleton.get_bone_count() and observed.bone_count == detached.bone_count
		checks[path + "_skin_correspondence"] = all_skins_use_rig and skinned_meshes > 0 and skinned_meshes == detached.skinned_meshes and observed.skinned_mesh_count == skinned_meshes and observed.skin_bind_count == skin_binds and observed.skin_skeleton_path == skin_rig_path
		checks[path + "_driver_correspondence"] = animator == character.get("anim_player") and animator == model.find_child("AnimationPlayer", true, false) and observed.animation_player_path == str(animator.get_path()) and animation_root == model and observed.animation_root_path == str(model.get_path()) and observed.animation_driver_resource == character.get_script().resource_path and tree.get_node_or_null(tree.anim_player) == animator and tree.get_node_or_null(tree.root_node) == model and observed.animation_tree_active == tree.active
		checks[path + "_clip_correspondence"] = live_clips_present and observed.active_clip == character.call("current_clip") and observed.active_clip_position == character.call("current_position") and detached.missing_clips.is_empty() and animator.has_animation(str(observed.active_clip))
		checks[path + "_contact_correspondence"] = socket.get_parent() == skeleton and source.get_parent() == socket and observed.contact_attached and observed.contact_source_path == str(source.get_path()) and observed.contact_socket_path == str(socket.get_path()) and observed.contact_bone == socket.bone_name and observed.contact_bone_index == skeleton.find_bone(socket.bone_name) and socket.bone_name == "LowerArm.R" and detached.contact_bone_present and detached.palm_bone_present
		actors.append(facts)
	return {"available": all_available, "checks": checks, "actors": actors,
		"qualification": "read_only_existing_instances_diagnostic; ordinary_earning_and_rendered_binding_unverified"}

static func _ambush_read_snapshot(encounter: Node, actor: Node) -> Dictionary:
	var state: Object = encounter.get("state")
	var character: Node = actor.get("character")
	var animator: AnimationPlayer = actor.get("animator")
	var source: Node3D = actor.get("source")
	return {"reward_history": state.get("reward_history").duplicate(true) if state else null,
		"mf01_acquired": state.get("mf01_acquired") if state else null,
		"e03_revealed": state.get("e03_revealed") if state else null,
		"recognition_remaining": encounter.get("recognition_remaining"),
		"health": actor.get("health"), "phase": actor.get("phase"),
		"transform": (actor as Node3D).global_transform,
		"velocity": actor.get("velocity"),
		"clip": character.call("current_clip") if is_instance_valid(character) else null,
		"clip_position": character.call("current_position") if is_instance_valid(character) else null,
		"assigned_animation": animator.assigned_animation if is_instance_valid(animator) else null,
		"playing": animator.is_playing() if is_instance_valid(animator) else null,
		"attack_instance": source.get("instance") if is_instance_valid(source) else null,
		"damage_window": source.get("can_damage") if is_instance_valid(source) else null}

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
