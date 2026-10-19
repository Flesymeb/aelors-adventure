extends SceneTree
var checks := {}
var details := {}
func _initialize() -> void: call_deferred("run_probe")
func run_probe() -> void:
	var router = load("res://tests/map02_line_defense_test.gd").DiagnosticLineRouter.new()
	root.add_child(router)
	for i in 1800:
		await process_frame
		if router.diagnostic_ready: break
	checks.authored_map_ready = router.diagnostic_ready
	if router.diagnostic_ready:
		var world = router.world
		var combat = world.training
		var player = world.player
		var spin = combat.whirlwind
		for i in 90: await physics_frame
		for owner in [world.bridge_encounter,world.pressure_encounter,world.ambush_encounter,world.route_patrols,world.line_encounter]:
			owner.set_physics_process(false)
			for actor in owner.enemies: actor.set_physics_process(false)
		var enemy = world.line_encounter.enemies[0]
		world.ground_policy.place(world,player,Vector2(enemy.home.x,enemy.home.z-1.0))
		for i in 15: await physics_frame
		var state = world.dialogue_state
		state.sword_owned = false
		state.practice_hit = false
		state.practice_defense = false
		checks.no_sword_no_skill = not spin.unlocked() and not spin.request()
		state.sword_owned = true
		world.gameplay_hud._process(0)
		checks.sword_acquisition_alone_does_not_unlock = not spin.unlocked() and not spin.request() and spin.cooldown == 0
		checks.icon_hidden_until_learned = not world.gameplay_hud.whirlwind_icon.visible
		state.practice_hit = true
		checks.attack_drill_alone_does_not_unlock = not spin.unlocked() and not spin.request()
		state.practice_defense = true
		world.gameplay_hud._process(0)
		checks.lesson_unlocks_skill_and_icon = spin.unlocked() and world.gameplay_hud.whirlwind_icon.visible
		var incoming := SnaielDamageSource.new()
		incoming.entity = enemy
		incoming.can_damage = true
		incoming.damage_attributes.health = 7.0
		incoming.set_meta("ranged_contact",true)
		incoming.set_meta("attack_origin",enemy.global_position)
		incoming.set_meta("attack_direction",enemy.global_position.direction_to(player.global_position))
		world.add_child(incoming)
		state.health = 100
		var phase_hits := {}
		var hp: float = enemy.health
		var occurrence: int = combat.sword_source.instance
		checks.request_accepted = spin.request()
		var yaw: float = spin.start_yaw
		checks.retrigger_rejected = not spin.request()
		var max_turn := 0.0
		var saw_trail := false
		var saw_ring := false
		for i in 150:
			await physics_frame
			max_turn = maxf(max_turn,player.visual.rotation.y-yaw)
			if spin.active and combat.phase in ["anticipation","contact","recovery"] and not phase_hits.has(combat.phase):
				var stage: String = combat.phase
				var before_health: float = state.health
				incoming.instance += 1
				incoming.set_meta("heavy_impact",stage == "contact")
				var hit: Dictionary = combat.player_hitbox.contact(incoming,player.global_position+Vector3.UP)
				checks[stage+"_hit_deducts_hp"] = hit.get("hp_loss",0) == 7 and state.health == before_health-7
				checks[stage+"_hit_preserves_skill"] = spin.active and combat.phase == stage and combat.hurt_time == 0 and not combat.heavy_impact.active() and hit.get("whirlwind_super_armor",false)
				var hp_after: float = state.health
				checks[stage+"_duplicate_contact_rejected"] = combat.player_hitbox.contact(incoming,player.global_position+Vector3.UP).is_empty() and state.health == hp_after
				phase_hits[stage] = true
			saw_trail = saw_trail or combat.sword_presentation.emphasis_active
			saw_ring = saw_ring or spin.ring.visible
		checks.armour_covers_all_three_stages = phase_hits.size() == 3 and state.health == 79
		checks.two_complete_turns = max_turn >= TAU * 2 - 0.02
		checks.exactly_two_contact_occurrences = combat.sword_source.instance == occurrence + 2
		details.enemy = {"nav":enemy.navigation_ready,"enabled":enemy.enabled_policy.call(),"last_contact":enemy.hitbox.last_result,"registry":world.line_encounter.registry().size()}
		checks.real_damage_with_bound = enemy.health < hp and hp - enemy.health <= 36.01
		checks.blade_trail_and_ring = saw_trail and saw_ring
		checks.cleanup = not spin.active and not spin.ring.visible and not combat.sword_source.can_damage and combat.phase == "idle"
		checks.cooldown_blocks_spam = spin.cooldown > 0 and not spin.request()
		details.first_spin = {"yaw_radians":max_turn,"damage":hp-enemy.health,"occurrences":combat.sword_source.instance-occurrence}
		incoming.instance += 1
		incoming.set_meta("heavy_impact",false)
		var ordinary: Dictionary = combat.player_hitbox.contact(incoming,player.global_position+Vector3.UP)
		checks.normal_hurt_returns_after_skill = ordinary.get("hp_loss",0) == 7 and combat.hurt_time > 0 and not ordinary.get("whirlwind_super_armor",false)
		for i in 35: await physics_frame
		spin.cooldown = 0
		checks.second_attempt_starts = spin.request()
		for i in 20: await physics_frame
		var instance_before: int = combat.sword_source.instance
		combat.interrupt("hurt")
		checks.direct_hurt_cannot_cancel = spin.active and combat.sword_source.instance == instance_before
		combat.interrupt("heavy_hurt")
		checks.direct_heavy_hurt_cannot_cancel = spin.active and not combat.heavy_impact.active()
		var lives_before: int = state.lives
		state.health = 5
		incoming.instance += 1
		incoming.set_meta("heavy_impact",true)
		var lethal: Dictionary = combat.player_hitbox.contact(incoming,player.global_position+Vector3.UP)
		checks.lethal_hit_still_settles = lethal.get("hp_loss",0) == 5 and state.health == 0 and state.lives == lives_before-1
		checks.death_cleans_spin = not spin.active and not spin.ring.visible and not combat.sword_source.can_damage and combat.phase == "death"
		checks.lesson_unlock_survives_death = spin.unlocked()
		combat.interrupt("recovery")
		checks.recovery_resets_cooldown = spin.cooldown == 0
		incoming.queue_free()
		var fixture = load("res://tests/chapter_travel_test.gd")
		var snapshot = fixture.history(world.dialogue_state)
		checks.no_persistent_skill_flags_required = world.dialogue_state.config_unavailable_reason(snapshot) == ""
	root.remove_child(router)
	router.queue_free()
	for i in 3: await process_frame
	var failures := []
	for key in checks:
		if not checks[key]: failures.append(key)
	print("WHIRLWIND_RESULT=" + JSON.stringify({"checks":checks,"assertions":checks.size(),"failures":failures,"details":details,"scope":"Developer native prepared map; actual rig rotation and existing contact owner; not independent QA"}))
	quit(0 if failures.is_empty() else 3)
