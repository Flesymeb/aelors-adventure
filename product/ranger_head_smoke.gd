extends SceneTree
## Executable geometry/attachment checks; optional three near-view captures.
## Run only through the owner's single Godot session, after asset import.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var player := (load("res://Player.tscn") as PackedScene).instantiate() as CharacterBody3D
	stage.add_child(player)
	player.set_physics_process(false)
	if player.animation_player:
		player.animation_player.stop()
	if player.bow_pose:
		player.bow_pose.active = false
	if player.bow_ik:
		player.bow_ik.active = false
	check(player.head_components.size() == 5, "Must have hood, actual head, eyes, eyebrows and one fitted hair mesh")
	var added_vertices := 0
	var base_components: Array[MeshInstance3D] = []
	var hair_components: Array[MeshInstance3D] = []
	for component in player.head_components:
		if component == player.head_mesh:
			continue
		base_components.append(component)
		if str(component.name).begins_with("AelorHair_"):
			hair_components.append(component)
		check(component.get_parent() is BoneAttachment3D, "Each face component must follow a bone attachment")
		for surface in range(component.mesh.get_surface_count()):
			var arrays: Array = component.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			added_vertices += vertices.size()
			check(not vertices.is_empty(), "Face component must contain real triangle geometry")
			check(component.mesh.surface_get_material(surface) != null, "Keep original skin/eye/brow materials")
			check(arrays[Mesh.ARRAY_BONES] == null or arrays[Mesh.ARRAY_BONES].is_empty(), "Rigid extraction must not leave source skin indices")
	check(added_vertices > 3000, "Must extract substantive face geometry, not a placeholder")
	check(hair_components.size() == 1, "Hair must attach exactly once through the existing head group")
	var repeated: Array[MeshInstance3D] = player.HEAD_ASSEMBLY.assemble(player.skeleton, true)
	check(repeated.size() == 4, "Repeated assembly must reuse the same base head and hair components")
	for component in repeated:
		check(component in base_components, "Repeated assembly must not duplicate head attachments")
	if base_components.size() != 4 or hair_components.size() != 1:
		quit(1)
		return
	var head: int = player.skeleton.find_bone("Head")
	player.skeleton.reset_bone_poses()
	await process_frame
	await process_frame
	var probe_points: Array[Vector3] = []
	for component in base_components:
		var vertex: Vector3 = component.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][0]
		probe_points.append(component.global_transform * vertex)
	player.skeleton.set_bone_pose_rotation(head, Quaternion(Vector3.UP, 0.6))
	await process_frame
	await process_frame
	for index in range(base_components.size()):
		var component := base_components[index]
		var vertex: Vector3 = component.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][0]
		var actual: Vector3 = component.global_transform * vertex
		var expected: Vector3 = player.skeleton.global_transform * player.skeleton.get_bone_global_pose(head) * vertex
		check(actual.distance_to(expected) < 0.0001, "Face/eyes/brows/hair must follow the same actual Head pose")
		check(actual.distance_to(probe_points[index]) > 0.001, "Head rotation must really move component geometry")
	player.skeleton.reset_bone_poses()
	for blend in [0.0, 1.0, 0.0]:
		player.perspective_blend = blend
		player._update_head_visibility()
		for component in player.head_components:
			var expected_shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if blend == 1.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			check(component.cast_shadow == expected_shadow, "All head geometry must hide/restore together while retaining shadows")
	# Authored source head ends at ~1.81m. Whole-body extraction would fail this.
	var rest: Transform3D = player.skeleton.get_bone_global_rest(head)
	for component in base_components:
		for surface in range(component.mesh.get_surface_count()):
			var vertices: PackedVector3Array = component.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				check((rest * vertex).y > 1.55, "Extraction must not add torso, legs or feet beneath clothing")
	var hair := hair_components[0]
	var hair_bounds := AABB()
	var hair_vertex_count := 0
	for surface in range(hair.mesh.get_surface_count()):
		var vertices: PackedVector3Array = hair.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			var authored := rest * vertex
			hair_bounds = AABB(authored, Vector3.ZERO) if hair_vertex_count == 0 else hair_bounds.expand(authored)
			hair_vertex_count += 1
		var material := hair.mesh.surface_get_material(surface) as StandardMaterial3D
		check(material != null and material.albedo_texture != null and material.normal_texture != null, "Hair keeps actual source base-color and normal textures")
		if material != null:
			check(material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "Volumetric source hair remains opaque")
			check(material.albedo_color == player.HEAD_ASSEMBLY.AELOR_HAIR_COLOR, "Aelor hair uses the restrained chestnut identity tint")
			check(material.resource_local_to_scene, "Aelor tint must use a private material")
	for component in base_components:
		if str(component.name) == "BaseHead_Eyebrows":
			var material := component.mesh.surface_get_material(0) as StandardMaterial3D
			check(material != null and material.albedo_color == player.HEAD_ASSEMBLY.AELOR_HAIR_COLOR, "Aelor eyebrows match the hair tint")
			check(material != null and material.resource_local_to_scene, "Eyebrow tint must not mutate the shared source material")
	check(hair_vertex_count >= 700, "Hair must contain substantive authored geometry")
	check(hair_bounds.position.y > 1.63 and hair_bounds.end.y < 1.86, "Hair sits around the existing head, within the hood height")
	check(hair_bounds.size.x < 0.20 and hair_bounds.size.z < 0.21, "Hair remains compact inside the hood silhouette")
	var capture_directory := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--head-capture-directory="):
			capture_directory = argument.trim_prefix("--head-capture-directory=")
	if capture_directory.is_absolute_path() and DisplayServer.get_name() != "headless":
		await capture_views(stage, player, capture_directory)
	print(JSON.stringify({"head_smoke_failures": failures, "extracted_triangle_vertices": added_vertices, "face_components": base_components.size() - hair_components.size(), "hair_components": hair_components.size(), "hair_vertices": hair_vertex_count, "rendered_views": "optional; inspect captures separately"}))
	quit(0 if failures.is_empty() else 1)


func capture_views(stage: Node3D, player: CharacterBody3D, output: String) -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	stage.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.15, 0.18, 0.22)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.6
	stage.add_child(environment)
	var camera := Camera3D.new()
	camera.near = 0.025
	camera.fov = 40
	stage.add_child(camera)
	camera.make_current()
	check(not output.begins_with(ProjectSettings.globalize_path("res://")), "Head captures must stay outside product source")
	if output.begins_with(ProjectSettings.globalize_path("res://")):
		return
	DirAccess.make_dir_recursive_absolute(output)
	var head: int = player.skeleton.find_bone("Head")
	for label in ["front", "side", "three_quarter", "head_rotated", "first_person", "third_person_restored"]:
		player.skeleton.reset_bone_poses()
		if label == "head_rotated":
			player.skeleton.set_bone_pose_rotation(head, Quaternion(Vector3.UP, 0.6))
		player.perspective_blend = 1.0 if label == "first_person" else 0.0
		player._update_head_visibility()
		camera.position = Vector3(0, 1.7, -0.9) if label == "front" else Vector3(0.6, 1.7, -0.75)
		if label == "side":
			camera.position = Vector3(0.8, 1.7, 0)
		if label == "first_person":
			camera.position = Vector3(0, 1.68, 0.02)
			camera.look_at(camera.position + Vector3(0, 0, -1))
		else:
			camera.look_at(Vector3(0, 1.69, 0))
		await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(output + "/" + label + ".png")
		check(error == OK, "Near-view capture must save")
