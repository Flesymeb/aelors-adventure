extends SceneTree
var checks := {}
var chapter := "meadow"
func _initialize() -> void: call_deferred("run_probe")
func run_probe() -> void:
	var args := OS.get_cmdline_user_args()
	if "village" in args: chapter = "village"
	if "tomb" in args: chapter = "tomb"
	var router
	if chapter == "village": router = load("res://tests/chapter_travel_test.gd").DiagnosticRouter.new()
	elif chapter == "tomb": router = load("res://tests/map03_veyne_probe.gd").VeyneRouter.new()
	else: router = load("res://tests/map02_line_defense_test.gd").DiagnosticLineRouter.new()
	root.add_child(router)
	for i in 1800:
		await process_frame
		if router.diagnostic_ready: break
	print("QUALITY_PROGRESS=map_ready:" + str(router.diagnostic_ready))
	checks.authored_map_ready = router.diagnostic_ready
	if router.diagnostic_ready:
		var world = router.world
		checks.default_high = world.dialogue_state.graphics_quality == "high"
		world.quality.apply_quality()
		checks.native_resolution = root.scaling_3d_scale == 1.0
		checks.msaa_8x = root.msaa_3d == Viewport.MSAA_8X
		checks.anisotropy_16x = root.anisotropic_filtering_level == Viewport.ANISOTROPY_16X
		var environment: Environment = world.quality.environment if chapter == "village" else world.village.get_node("WorldEnvironment").environment
		var forward := RenderingServer.get_current_rendering_method() == "forward_plus"
		checks.no_added_screen_space_darkening = not environment.ssao_enabled and not environment.ssil_enabled
		checks.no_added_global_fog_veil = not environment.ssr_enabled and not environment.volumetric_fog_enabled
		if chapter != "tomb":
			checks.ordinary_fog_disabled = not environment.fog_enabled
		checks.authored_tonemapper_preserved = environment.tonemap_mode == (Environment.TONE_MAPPER_ACES if chapter == "village" else Environment.TONE_MAPPER_FILMIC)
		checks.project_forward_plus = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus"
		checks.full_resolution_occlusion = not ProjectSettings.get_setting("rendering/environment/ssao/half_size")
		checks.directional_shadow_8k = ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size") == 8192
		var hud = world.gameplay_hud
		for scale in [1.0,1.5,2.0]:
			world.dialogue_state.text_scale = scale
			for i in 4: await process_frame
			print("QUALITY_PROGRESS=text_scale:" + str(scale))
			checks["tracker_fits_" + str(scale)] = hud.tracker.get_global_rect().end.x <= root.get_visible_rect().size.x + 1 and hud.tracker.get_global_rect().end.y < root.get_visible_rect().size.y - 50
		if chapter == "village":
			world.dialogue_state.guard_briefing_acknowledged = true
			world.dialogue_state.departure_confirmed = false
			world.dialogue_state.tracked_quest = "bow"
			var return_action: String = hud.short_action("旧的弓练习")
			checks.explicit_return_to_isha = return_action.contains("返回村庄广场寻找伊莎") and return_action == world.dialogue_state.objective()
			world.dialogue_state.departure_confirmed = true
			var depart_action: String = hud.short_action("旧的弓练习")
			checks.explicit_departure_after_confirmation = depart_action.contains("请前往蓝色洞口") and not depart_action.contains("返回伊莎")
			hud._process(0)
			checks.completed_old_quest_does_not_hide_current_action = hud.tracker.visible
			checks.passage_shader_bound = world.chapter_pillar.ring_material.shader == load("res://assets/shaders/passage_ring.gdshader")
			checks.passage_audio_bound = world.chapter_pillar.ambient_voice.stream != null
		var plain := "救援请求 · 请返回村庄广场寻找伊莎，之后前往蓝色洞口 [E]"
		var markup = load("res://ui/quest_markup.gd").format_text(plain)
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		root.add_child(label)
		label.text = markup
		checks.keyword_plain_text_preserved = label.get_parsed_text() == plain
		checks.keyword_bold_and_colors = "[b][color=#ffaaa0]伊莎" in markup and "[b][color=#a9e3ae]救援请求" in markup and "[b][color=#a6dcff]蓝色洞口" in markup
		label.queue_free()
		world.dialogue_state.text_scale = 1.0
		if "capture" in args:
			for i in 8: await process_frame
			await RenderingServer.frame_post_draw
			var output := OS.get_environment("HOH_VALIDATION_OUT")
			root.get_texture().get_image().save_png(output + "/high-quality-" + chapter + ".png")
	root.remove_child(router)
	router.queue_free()
	for i in 3: await process_frame
	var failures := []
	for key in checks:
		if not checks[key]: failures.append(key)
	print("HIGH_QUALITY_RESULT=" + JSON.stringify({"chapter":chapter,"checks":checks,"assertions":checks.size(),"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"scope":"Developer source profile/rendering checks; target GPU frame rate and release export remain separate acceptance"}))
	quit(0 if failures.is_empty() else 3)
