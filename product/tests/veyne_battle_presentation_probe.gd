extends SceneTree
## Prepared rendered combat checks; no earned-route or independent QA claim.
var checks := {}
var details := {}

func _initialize() -> void:
	call_deferred("run_probe")

func frame(label: String) -> void:
	var directory := OS.get_environment("HOH_VALIDATION_OUT")
	if directory.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(label+".png"))

func run_probe() -> void:
	var fixture = load("res://tests/map03_veyne_probe.gd")
	var router: Node = fixture.VeyneRouter.new()
	router.warden_completed = true
	root.add_child(router)
	for index in 1500:
		await process_frame
		if router.diagnostic_ready: break
	checks.authored_map_ready = router.diagnostic_ready
	if not router.diagnostic_ready:
		print("VEYNE_BATTLE_PRESENTATION_RESULT="+JSON.stringify({"checks":checks,"failures":["authored_map_ready"]}))
		quit(3)
		return
	var world: Node3D = router.world
	var boss: Node = world.veyne_encounter
	world.ground_policy.place(world,world.player,Vector2(-4,-21))
	boss.begin_reveal()
	boss.finish_presentation()
	var expected: Vector3 = world.player.arm.rotation
	var stable := true
	var charge_seen := false
	var dive_seen := false
	var charge_saved := false
	var dive_saved := false
	var samples := 0
	for index in 1500:
		await physics_frame
		if world.dialogue_state.health < 35: world.dialogue_state.health = 100
		if not boss.ARENA.contains(Vector2(world.player.global_position.x,world.player.global_position.z)):
			world.ground_policy.place(world,world.player,Vector2(-4,-26))
		var action: Node = boss.actor.dragon_actions
		if action.kind in ["charge","dive"]:
			samples += 1
			stable = stable and world.player.arm.rotation.is_equal_approx(expected) and world.player.camera.current and not world.player.encounter_camera_active
		if action.kind == "charge" and action.stage == "active":
			charge_seen = true
			if not charge_saved:
				await frame("battle-third-person-charge")
				charge_saved = true
		if action.kind == "dive" and action.stage == "active":
			dive_seen = true
			if not dive_saved:
				await frame("battle-third-person-dive")
				dive_saved = true
		if charge_seen and dive_seen and action.kind == "": break
	checks.native_charge_and_dive_seen = charge_seen and dive_seen
	checks.third_person_stable_in_rendered_sequence = stable and samples > 30
	checks.dust_shader_bound = boss.battle_vfx.material.shader == load("res://assets/shaders/veyne_dust.gdshader")
	checks.live_dust_bounded = boss.battle_vfx.ambient.amount == 18 and boss.battle_vfx.bursts.size() == 4
	world._set_pause_owner("controls",true)
	await create_timer(0.15).timeout
	var held: float = boss.battle_vfx.effect_clock
	await create_timer(0.25).timeout
	checks.shader_clock_pauses = is_equal_approx(held,boss.battle_vfx.effect_clock)
	world._set_pause_owner("controls",false)
	world.dialogue_state.reduced_motion = true
	await create_timer(0.15).timeout
	checks.reduced_motion_hides_dust = not boss.battle_vfx.ambient.visible and not boss.battle_vfx.ambient.emitting
	world.dialogue_state.reduced_motion = false
	world.dialogue_state.graphics_quality = "low"
	await create_timer(0.15).timeout
	checks.low_quality_bounds_particles = boss.battle_vfx.ambient.amount == 6
	details = {"camera_samples":samples,"camera_rotation":expected,"vfx":boss.battle_vfx.snapshot(),"audio":boss.creature_audio.snapshot()}
	boss.interrupt()
	checks.reset_cleans_vfx = not boss.battle_vfx.was_battle and not boss.battle_vfx.ambient.visible
	checks.reset_cleans_audio = not boss.creature_audio.voice.playing and not boss.creature_audio.sustain.playing
	router.queue_free()
	await process_frame
	var failures: Array = []
	for key in checks:
		if not checks[key]: failures.append(key)
	print("VEYNE_BATTLE_PRESENTATION_RESULT="+JSON.stringify({"checks":checks,"details":details,"failures":failures,"assertions":checks.size(),"scope":"Prepared rendered native Boss fight, ordinary camera owner; not earned route or independent Tester acceptance"}))
	quit(0 if failures.is_empty() else 3)
