extends SceneTree
var all_checks := {}
var details := {}
func _initialize() -> void: call_deferred("run_probe")
func collect(prefix: String, checks: Dictionary, excluded: Array = []) -> void:
    for key in checks:
        if typeof(checks[key]) == TYPE_BOOL and key not in excluded: all_checks[prefix + ":" + str(key)] = checks[key]
func finish() -> void:
    var failures: Array = []
    for key in all_checks:
        if all_checks[key] != true: failures.append(key)
    print("VEYNE_REGRESSION_RESULT=" + JSON.stringify({"checks":all_checks,"assertions":all_checks.size(),"failures":failures,"details":details,"scope":"Staged next-Developer source, prepared authored map and real player; not earned progression, independent QA or export acceptance"}))
    quit(0 if failures.is_empty() else 3)
func run_probe() -> void:
    var fixture = load("res://tests/map03_veyne_probe.gd")
    var test = load("res://tests/map03_veyne_test.gd")
    var router = fixture.VeyneRouter.new()
    router.warden_completed = true
    root.add_child(router)
    for i in range(1800):
        await process_frame
        if router.diagnostic_ready: break
    all_checks["authored_map_ready"] = router.diagnostic_ready
    if not router.diagnostic_ready:
        details["entry_error"] = router.entry_error
        finish()
        return
    var world = router.world
    var boss = world.veyne_encounter
    var actor = boss.actor
    collect("bindings", test.binding_checks(actor))
    world.ground_policy.place(world, world.player, Vector2(-4,-21))
    if boss.phase == "waiting": boss.begin_reveal()
    if boss.phase == "reveal": boss.finish_presentation()
    all_checks["battle_entered"] = boss.combat_allowed()
    var diagnostic_boundary_resets: Array = []
    var skills: Array = []
    var observed_damage := false
    var lowest_hp := 100.0
    var start: Vector3 = actor.global_position
    var movement := 0.0
    var camera_modes_stable := true
    var camera_pitch_stable := true
    var native_collision_retained := true
    var skill_camera_samples := 0
    var expected_look: Vector3 = world.player.arm.rotation
    var audio_events := {}
    for i in range(3000):
        await physics_frame
        if actor.attack_kind in ["charge","dive"]:
            skill_camera_samples += 1
            camera_modes_stable = camera_modes_stable and world.player.camera.current and not world.player.encounter_camera_active
            camera_pitch_stable = camera_pitch_stable and world.player.arm.rotation.is_equal_approx(expected_look)
            native_collision_retained = native_collision_retained and world.player.arm.collision_mask != 0 and world.player.arm.get_hit_length() <= world.player.arm.spring_length+0.01
        if not boss.ARENA.contains(Vector2(world.player.global_position.x,world.player.global_position.z)):
            diagnostic_boundary_resets.append(world.player.global_position)
            world.ground_policy.place(world,world.player,Vector2(-4,-26))
        if actor.attack_kind != "" and actor.attack_kind not in skills: skills.append(actor.attack_kind)
        movement = maxf(movement, start.distance_to(actor.global_position))
        lowest_hp = minf(lowest_hp, world.dialogue_state.health)
        if world.dialogue_state.health < 100: observed_damage = true
        # Prevent fixture death from hiding later AI decisions; never persist it.
        if world.dialogue_state.health < 30: world.dialogue_state.health = 100
        if skills.size() >= 5 and actor.phase == "recovery": break
    for skill in ["fire_breath","charge","dive","beam","melee"]: all_checks["ai_selected:" + skill] = skill in skills
    all_checks["ai_damaged_real_player"] = observed_damage
    all_checks["ai_moved_real_actor"] = movement > 1.0
    all_checks["camera_sampled_charge_and_dive"] = skill_camera_samples > 30
    all_checks["third_person_camera_stays_current"] = camera_modes_stable
    all_checks["no_automatic_overhead_or_orbit_jump"] = camera_pitch_stable
    all_checks["camera_collision_stays_enabled"] = native_collision_retained
    audio_events = boss.creature_audio.event_counts.duplicate()
    for event in ["fire_warning","fire_breath","charge_warning","charge","dive_warning","dive","beam_warning","beam","melee"]:
        all_checks["skill_audio_triggered:"+event] = int(audio_events.get(event,0)) > 0
    details["camera_and_audio"] = {"skill_camera_samples":skill_camera_samples,"expected_look":expected_look,"events":audio_events,"audio":boss.creature_audio.snapshot(),"vfx":boss.battle_vfx.snapshot()}
    details["ai"] = {"skills":skills,"lowest_player_hp":lowest_hp,"movement":movement,"attacks_started":actor.attacks_started,"casts":actor.casts_started,"melee":actor.melee_started,"navigation":actor.navigation_status,"diagnostic_boundary_resets":diagnostic_boundary_resets,"actor_position":actor.global_position,"player_position":world.player.global_position,"actor_state":actor._mcp_state(),"phase":boss.phase,"pause_owners":world.pause_owners,"player_locked":world.training.player_locked()}
    actor.interrupt_action()
    actor.set_physics_process(false)
    for scenario in ["charge_hit","charge_evade","charge_wall","fire_hit","fire_evade","fire_wall","dive_hit","dive_evade","interruption","initial_overlap"]:
        actor.character.play("Idle",1,true)
        await physics_frame
        await process_frame
        await physics_frame
        var result: Dictionary = await test.dragon_case(world, scenario)
        # These existing test fields are initialized for all scenarios, but only
        # flight scenarios exercise flight and only completion exercises recovery.
        var excluded: Array = []
        if not scenario.begins_with("dive"): excluded.append("flight_clip_advanced")
        if scenario in ["interruption","initial_overlap"]: excluded.append("recovery")
        details[scenario] = result
        collect(scenario, result, excluded)
        print("VEYNE_REGRESSION_CASE=" + JSON.stringify({"scenario":scenario,"result":result}))
    collect("beam", await test.beam_checks(world))
    boss.interrupt()
    actor.set_physics_process(true)
    for wait_frame in range(180):
        await physics_frame
        if actor.navigation_ready and not world.training.player_locked(): break
    world.ground_policy.place(world,world.player,Vector2(-4,-21))
    boss.begin_reveal()
    boss.finish_presentation()
    actor.set_physics_process(false)
    all_checks["phase_fixture_fresh_health"] = actor.health == 420 and boss.combat_allowed()
    collect("phase_and_retry", test.phase_checks(world))
    # Qualify actual second-phase rift damage in a fresh prepared fight.
    world.training.phase = "idle"
    world.training.hurt_time = 0
    world.training.protection = 0
    world.dialogue_state.health = 100
    world.ground_policy.place(world, world.player, Vector2(-4,-21))
    actor.set_physics_process(true)
    for wait_frame in range(180):
        await physics_frame
        if actor.navigation_ready and not world.training.player_locked(): break
    boss.begin_reveal()
    boss.finish_presentation()
    actor.set_physics_process(false)
    var source = load("res://combat/snaiel/damage_source.gd").new()
    source.entity = world.player
    source.can_damage = true
    source.damage_attributes.health = 210
    source.instance = 1002
    actor.receive_contact(source,actor.global_position + Vector3.UP)
    source.free()
    if boss.phase == "phase_transition": boss.finish_presentation()
    collect("rift", test.rift_checks(world))
    router.queue_free()
    await process_frame
    finish()
