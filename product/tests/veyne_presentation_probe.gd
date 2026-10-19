extends SceneTree
## Opt-in prepared native lifecycle/visual checks. Never writes real saves.
var checks := {}
var details := {}
var capture: AudioEffectCapture

func _initialize() -> void:
	call_deferred("run_probe")

func frame(label: String) -> void:
	var directory := OS.get_environment("HOH_VALIDATION_OUT")
	if directory.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(label+".png"))

func peak() -> float:
	var count := capture.get_frames_available()
	if count == 0: return 0.0
	var result := 0.0
	for sample in capture.get_buffer(count): result = maxf(result,maxf(absf(sample.x),absf(sample.y)))
	return result

func fresh_router() -> Node:
	var fixture = load("res://tests/map03_veyne_probe.gd")
	var router: Node = fixture.VeyneRouter.new()
	router.warden_completed = true
	root.add_child(router)
	for index in 1200:
		await process_frame
		if router.diagnostic_ready: return router
	return router

func run_probe() -> void:
	capture = AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(0,capture)
	var fixture = load("res://tests/veyne_defeat_scene_test.gd")
	for scenario in ["natural","skip","reduced_motion"]:
		var router: Node = await fresh_router()
		checks[scenario+"_authored_ready"] = router.diagnostic_ready
		if not router.diagnostic_ready: break
		var world: Node3D = router.world
		if scenario == "reduced_motion": world.dialogue_state.reduced_motion = true
		var began: Dictionary = fixture.start_live_case(world)
		var boss: Node = world.veyne_encounter
		var scene: Node = boss.defeat_scene
		checks[scenario+"_durable_death_starts"] = began.get("ready",false)
		checks[scenario+"_one_commit"] = boss.victory_commits == 1
		checks[scenario+"_key_not_auto_granted"] = not world.dialogue_state.veyne_release_key
		if scenario == "reduced_motion":
			checks.reduced_motion_uses_live_fallback = not scene.movie_active and scene.presentation_status == "live_death"
			await create_timer(0.5).timeout
			checks.reduced_motion_has_death_voice = int(boss.creature_audio.event_counts.get("death",0)) == 1
			scene.finish()
		else:
			checks[scenario+"_movie_with_audio"] = scene.movie_active and scene.video.volume == 1.0 and scene.video.bus == "Effects"
			await create_timer(1.2).timeout
			checks[scenario+"_decoder_advances"] = scene.movie_position > 0.4
			capture.clear_buffer()
			await create_timer(0.4).timeout
			var movie_peak := peak()
			checks[scenario+"_native_audio_output"] = movie_peak > 0.00001 and movie_peak < 0.99
			details[scenario+"_audio_peak"] = movie_peak
			await frame(scenario+"-death-early")
			if scenario == "skip":
				scene.finish()
			else:
				world._set_pause_owner("controls",true)
				await create_timer(0.2).timeout
				var held: float = scene.movie_position
				capture.clear_buffer()
				await create_timer(0.4).timeout
				checks.menu_pauses_movie = absf(scene.movie_position-held) < 0.08
				checks.menu_pauses_movie_audio = peak() < 0.00001
				world._set_pause_owner("controls",false)
				await create_timer(3.0).timeout
				checks.resume_continues_same_movie = scene.movie_position > held+1.5
				await frame("natural-death-impact")
				for index in 900:
					await process_frame
					if not scene.active: break
				checks.natural_movie_completes = not scene.active
		checks[scenario+"_decoder_released"] = scene.video.stream == null and not scene.video.is_playing()
		checks[scenario+"_third_person_restored"] = world.player.camera.current and not world.pause_owners.has("veyne_presentation")
		checks[scenario+"_cannot_repeat_commit"] = not scene.begin() and boss.victory_commits == 1
		details[scenario] = scene._mcp_state()
		router.queue_free()
		await process_frame
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	var failures: Array = []
	for key in checks:
		if not checks[key]: failures.append(key)
	print("VEYNE_PRESENTATION_RESULT="+JSON.stringify({"checks":checks,"failures":failures,
		"assertions":checks.size(),"details":details,"scope":"Prepared native movie/death lifecycle and mixer output; not earned victory or independent Tester acceptance"}))
	quit(0 if failures.is_empty() else 3)
