extends SceneTree
## Prepared in-memory history on the real authored map. Never writes user saves.
const RANGED = preload("res://combat/map02_ranged_adapter.gd")
const RUSH = preload("res://combat/map02_ambusher_adapter.gd")
var checks := {}
var details := {}
func _initialize() -> void: call_deferred("run_probe")
func finish() -> void:
	var failures := []
	for key in checks:
		if not checks[key]: failures.append(key)
	print("ROUTE_RECOVERY_RESULT=" + JSON.stringify({"checks":checks,"assertions":checks.size(),"failures":failures,"details":details,"scope":"Developer prepared native source checks; not independent QA or exported EXE acceptance"}))
	quit(0 if failures.is_empty() else 3)
func run_probe() -> void:
	var fixture = load("res://tests/map02_line_defense_test.gd")
	var history = load("res://tests/chapter_travel_test.gd")
	var router = fixture.attach_diagnostic(root)
	for i in 2400:
		await process_frame
		if router.diagnostic_ready: break
	checks.authored_map_ready = router.diagnostic_ready
	if not router.diagnostic_ready:
		details.entry_error = router.entry_error
		finish()
		return
	var world = router.world
	var state = world.dialogue_state
	var line = world.line_encounter
	for i in 90: await physics_frame
	var patrols = world.route_patrols
	checks.route_nine_added = patrols.grounded and patrols.enemies.size() == 9
	var fixed_count: int = world.bridge_encounter.enemies.size() + world.pressure_encounter.enemies.size() + world.ambush_encounter.enemies.size() + line.enemies.size()
	checks.route_population_doubled = fixed_count == 9 and fixed_count + patrols.enemies.size() >= fixed_count * 2
	checks.route_three_archetypes = patrols.enemies.filter(func(e): return e is RANGED).size() == 3 and patrols.enemies.filter(func(e): return e is RUSH).size() == 3
	checks.route_unique_persistent_ids = patrols.enemies.map(func(e): return e.stable_id) == state.ROUTE_PATROL_IDS
	checks.route_supported = patrols.enemies.all(func(e): return not world.ground_policy.support(world, Vector2(e.home.x,e.home.z)).is_empty())
	checks.route_navigation_ready = patrols.enemies.all(func(e): return e.navigation_ready)
	details.patrols = patrols.enemies.map(func(e): return {"id":e.stable_id,"home":e.home,"nav":e.navigation_ready})
	# A historically broken save contains genuine E03 kills but a cleared flag.
	state.e03_revealed = false
	var legacy = history.history(state)
	checks.legacy_completed_e03_loadable = state.config_unavailable_reason(legacy) == ""
	state.restore_config(legacy)
	checks.legacy_completed_e03_repaired = state.e03_revealed and state.ambush_defeated()
	var rewards: Dictionary = state.reward_history.duplicate(true)
	var xp: int = state.experience
	for attempt in 2:
		state.lives = 5
		world.training.settle_death()
		world.training.recover_at_checkpoint()
		for i in 90: await physics_frame
		checks["recovery_pending_cleared_%d" % attempt] = not state.recovery_pending and state.health == 100
		checks["e03_fact_retained_%d" % attempt] = state.e03_revealed and state.ambush_defeated()
		checks["e04_reappears_%d" % attempt] = line.enemies.all(func(e): return e.visible and e.health > 0 and e.hitbox.enabled and e.collision_layer == 2)
		checks["no_reward_replay_%d" % attempt] = rewards == state.reward_history and xp == state.experience
		checks["checkpoint_safe_%d" % attempt] = Vector2(world.player.global_position.x,world.player.global_position.z).distance_to(world.checkpoint_xz()) < 0.2
	# Isolate one real AI owner to measure repeated ordinary attack events.
	for owner in [world.bridge_encounter,world.pressure_encounter,world.ambush_encounter,patrols]:
		owner.process_mode = Node.PROCESS_MODE_DISABLED
	for e in line.enemies: e.process_mode = Node.PROCESS_MODE_DISABLED
	var melee = line.enemies[0]
	melee.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.training.protection = 0
	world.ground_policy.place(world,world.player,Vector2(melee.home.x,melee.home.z - 0.9))
	var first_instance: int = melee.source.instance
	var damaged := false
	for i in 840:
		await physics_frame
		if state.health < 100: damaged = true
		if state.health < 40: state.health = 100
	checks.melee_repeats_after_recovery = melee.source.instance >= first_instance + 4
	checks.melee_real_contact_damage = damaged
	details.melee = {"attacks":melee.source.instance-first_instance,"phase":melee.phase,"navigation":melee.navigation_state()}
	melee.process_mode = Node.PROCESS_MODE_DISABLED
	var ranged = line.enemies[2]
	ranged.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.ground_policy.place(world,world.player,Vector2(ranged.home.x,ranged.home.z - 3.5))
	var shots: int = ranged.shots_fired
	for i in 900:
		await physics_frame
		if state.health < 40: state.health = 100
	checks.ranged_repeats_in_close_combat = ranged.shots_fired >= shots + 3
	details.ranged = {"shots":ranged.shots_fired-shots,"phase":ranged.phase,"position":ranged.global_position}
	# Genuine partial defeat survives another recovery, without duplicating XP.
	ranged.process_mode = Node.PROCESS_MODE_DISABLED
	melee.health_component.decrement_health(melee.health)
	var partial_rewards: Dictionary = state.reward_history.duplicate(true)
	var partial_xp: int = state.experience
	state.lives = 5
	world.training.settle_death()
	world.training.recover_at_checkpoint()
	for i in 10: await physics_frame
	checks.partial_dead_stays_dead = melee.health == 0 and not melee.visible
	checks.partial_survivors_present = line.enemies[1].health > 0 and line.enemies[1].visible and ranged.health > 0 and ranged.visible
	checks.partial_no_duplicate_reward = state.reward_history == partial_rewards and state.experience == partial_xp
	checks.remaining_gate_matches_survivors = state.line_remaining() == 2 and not state.line_defeated()
	# Newly added route patrols use the same persistent once-only reward schema.
	world.training.phase = "idle"
	world.training.protection = 0
	var patrol = patrols.enemies[0]
	world.ground_policy.place(world,world.player,Vector2(patrol.home.x,patrol.home.z-1))
	var route_xp: int = state.experience
	var line_remaining: int = state.line_remaining()
	patrol.health_component.decrement_health(patrol.health)
	checks.route_reward_settles_once = state.reward_history.has(patrol.stable_id) and state.experience == route_xp + 10
	patrols.settle_defeat(patrol)
	checks.route_duplicate_reward_rejected = state.experience == route_xp + 10
	patrols.restore_history()
	checks.route_defeat_persists = patrol.health == 0 and not patrol.visible and patrols.enemies[1].health > 0
	checks.route_not_a_story_gate = state.line_remaining() == line_remaining
	checks.route_reward_history_loads = state.config_unavailable_reason(history.history(state)) == ""
	var recovery_checks: Dictionary = load("res://tests/map02_ambush_test.gd").recovery_checks(world)
	for key in recovery_checks: checks["ambush_recovery:" + str(key)] = recovery_checks[key]
	# Existing independent state checks continue to guard story prerequisites.
	for test_path in ["map02_line_state_test.gd","map02_roadblock_test.gd","map02_ambush_test.gd"]:
		var test = load("res://tests/" + test_path)
		var result: Dictionary = test.run()
		for key in result:
			checks[test_path + ":" + str(key)] = result[key]
	root.remove_child(router)
	router.queue_free()
	for i in 3: await process_frame
	finish()
