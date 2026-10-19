extends SceneTree
## Production checkpoint transaction on the authored village. Saves intercepted;
## this fixture does not establish ordinary acquisition, death or disk restart.
const HISTORY = preload("res://tests/chapter_travel_test.gd")

func _initialize() -> void:
	call_deferred("run_probe")

func run_probe() -> void:
	var result: Dictionary = await run(root)
	print("CHECKPOINT_RECOVERY_RESULT=" + JSON.stringify(result))
	quit(0 if result.failures.is_empty() else 3)

static func run(holder: Node) -> Dictionary:
	var checks := {}
	var tree: SceneTree = holder.get_tree()
	var router: Node = HISTORY.attach_diagnostic(holder)
	for frame in 2400:
		await tree.process_frame
		if router.diagnostic_ready: break
	checks.authored_world_ready = router.diagnostic_ready
	if router.diagnostic_ready:
		var world: Node = router.world
		var state: Node = world.dialogue_state
		world._set_pause_owner("recovery_contract", true)
		var rewards: Dictionary = state.reward_history.duplicate(true)
		var before_lives: int = state.lives
		state.arrows = 10
		world.training.parry_cooldown = 0.5
		world.element_abilities.cooldowns = {"fire":6.0,"lightning":8.0}
		world.training.settle_death()
		world.training.settle_death()
		checks.one_life_deducted = state.lives == before_lives - 1
		world.training.recover_at_checkpoint()
		checks.full_health_and_ammunition = state.health == 100 and state.arrows == 12
		checks.no_second_deduction = state.lives == before_lives - 1
		checks.recovery_cleared = not state.recovery_pending and world.training.phase == "idle"
		checks.cooldowns_available = world.training.parry_cooldown == 0 and world.element_abilities.cooldowns.fire == 0 and world.element_abilities.cooldowns.lightning == 0
		checks.projectiles_cleared = world.bow_training.active_shots.is_empty() and world.element_abilities.projectiles.is_empty()
		checks.no_reward_replay = state.reward_history == rewards
		var committed: Dictionary = state.diagnostic_commits.back()
		checks.refill_precedes_commit = committed.arrows == 12 and committed.health == 100 and committed.lives == before_lives - 1 and not committed.recovery_pending
		var restored: Node = preload("res://dialogue_state.gd").new()
		restored.restore_config(HISTORY.history(state))
		checks.serialized_recovery_roundtrip = restored.arrows == 12 and restored.health == 100 and restored.lives == before_lives - 1 and not restored.recovery_pending
		restored.free()
		state.bow_owned = false
		state.arrows = 0
		state.selected_equipment = "unarmed"
		world.training.settle_death()
		world.training.recover_at_checkpoint()
		checks.unowned_bow_stays_unowned = not state.bow_owned and state.arrows == 0 and not world.player.owns_bow
		checks.unowned_commit_stays_empty = state.diagnostic_commits.back().arrows == 0
	holder.remove_child(router)
	router.queue_free()
	tree.paused = false
	for frame in 3: await tree.process_frame
	var failures := []
	for key in checks:
		if not checks[key]: failures.append(key)
	return {"checks":checks,"failures":failures,"assertions":checks.size(),"scope":"isolated production recovery; no ordinary earned history or disk restart proof"}
