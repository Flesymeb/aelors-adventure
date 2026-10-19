extends SceneTree
func _initialize() -> void: call_deferred("run_probe")
func solid(color: Color) -> Image:
	var result := Image.create(8,8,false,Image.FORMAT_RGBA8)
	result.fill(color)
	return result
func array_texture(images: Array[Image]) -> Texture2DArray:
	var result := Texture2DArray.new()
	result.create_from_images(images)
	return result
func run_probe() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.01,0.01,0.01)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.2
	scene.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,30,0)
	scene.add_child(sun)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.5
	camera.position = Vector3(0,5,0)
	camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	camera.current = true
	var albedo: Array[Image] = []
	var orm: Array[Image] = []
	var normal: Array[Image] = []
	for layer in 8:
		albedo.append(solid(Color(0.55,0.55,0.55)))
		orm.append(solid(Color(1,0.85,0,0.5)))
		normal.append(solid(Color(0.5,0.5,1) if layer == 1 else Color(0.95,0.15,0.4)))
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/maps/map02/Shaders/Blend8 splat.gdshader")
	material.set_shader_parameter("splatMap_0",ImageTexture.create_from_image(solid(Color(1,0,0,0))))
	material.set_shader_parameter("splatMap_1",ImageTexture.create_from_image(solid(Color(0,0,0,0))))
	material.set_shader_parameter("textures_albedo",array_texture(albedo))
	material.set_shader_parameter("textures_ormh",array_texture(orm))
	material.set_shader_parameter("textures_normal",array_texture(normal))
	material.set_shader_parameter("normal_scale",1.0)
	material.set_shader_parameter("uv1_scale",Vector2.ONE)
	for side in [-1,1]:
		var plane := MeshInstance3D.new()
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(1.8,1.8)
		plane.mesh = mesh
		plane.position.x = side * 1.1
		if side == -1:
			plane.material_override = material
		else:
			var reference := StandardMaterial3D.new()
			reference.albedo_color = Color(0.55,0.55,0.55)
			reference.roughness = 0.85
			plane.material_override = reference
		scene.add_child(plane)
	for i in 15: await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var width := picture.get_width()
	var height := picture.get_height()
	var left := picture.get_pixel(int(width*0.255),int(height*0.5))
	var right := picture.get_pixel(int(width*0.745),int(height*0.5))
	var difference := absf(left.r-right.r)+absf(left.g-right.g)+absf(left.b-right.b)
	var checks := {"selected_layer_matches_flat_pbr_reference":difference < 0.12,"both_planes_rendered":left.r > 0.1 and right.r > 0.1,"native_forward_plus":RenderingServer.get_current_rendering_method() == "forward_plus"}
	var out := OS.get_environment("HOH_VALIDATION_OUT")
	if out != "": picture.save_png(out+"/terrain-material-reference.png")
	var failures := []
	for key in checks:
		if not checks[key]: failures.append(key)
	print("TERRAIN_MATERIAL_RESULT="+JSON.stringify({"checks":checks,"assertions":checks.size(),"failures":failures,"rgb_difference":difference,"left":left,"right":right,"scope":"Actual eight-layer terrain shader versus independent flat PBR reference with deliberately different unused-layer normals; not full-map aesthetic acceptance"}))
	quit(0 if failures.is_empty() else 3)
