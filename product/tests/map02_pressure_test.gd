extends RefCounted
## Explicit disposable fixtures only. No test behavior enters normal startup.
const STATE = preload("res://dialogue_state.gd")
const TRAVEL = preload("res://tests/chapter_travel_test.gd")
const ROADBLOCK = preload("res://tests/map02_roadblock_test.gd")

class DiagnosticPressureRouter extends ROADBLOCK.DiagnosticMeadowRouter:
	func _ready() -> void:
		super()
		# The parent fixture already intercepts persistence. This prepared history
		# is supplemental component support, never proof of ordinary earned travel.
		for id in state.E01_IDS: state.settle_roadblock(Vector3(133,11,146), {}, id)
		world.restored_position = {"position":Vector3(128,11,151), "map_id":state.MAP02, "yaw":PI}

static func attach_diagnostic(parent: Node) -> Node:
	var router := DiagnosticPressureRouter.new()
	router.name = "E02Diagnostic"
	parent.add_child(router)
	return router

static func prepared() -> Node:
	var state := TRAVEL.earned()
	state.departure_confirmed = true
	state.commit_arrival(state.MAP02)
	for id in state.E01_IDS: state.settle_roadblock(Vector3(133,11,146), {}, id)
	return state

static func run() -> Dictionary:
	var checks := {}
	var state := prepared()
	var xp: int = state.experience
	var pressure_scene: PackedScene = load("res://combat/Map02Pressure.tscn")
	var pressure: Node = pressure_scene.instantiate() if pressure_scene else null
	checks.production_pressure_load = pressure != null and pressure.get_script() == preload("res://combat/map02_pressure.gd")
	checks.production_map_load = load("res://world/map02_entry.tscn") is PackedScene
	checks.production_ranged_load = load("res://combat/ChannelRangedGuard.tscn") is PackedScene and load("res://combat/map02_ranged_adapter.gd") is GDScript
	if pressure: pressure.free()
	checks.identities = state.PRESSURE_IDS == ["map02_e02_melee", "map02_e02_ranged"]
	checks.initial_group = not state.pressure_defeated() and state.pressure_remaining() == 2
	checks.legacy_valid = state.config_unavailable_reason(TRAVEL.history(state)) == ""
	checks.reject_unknown = not state.settle_pressure(Vector3.ZERO, {}, "unknown") and state.experience == xp
	checks.first_once = state.settle_pressure(Vector3(133,11,157), {"id":"healing", "quantity":1}, "map02_e02_melee") and state.experience == xp + 10
	checks.first_repeat = not state.settle_pressure(Vector3.ZERO, {}, "map02_e02_melee") and state.experience == xp + 10
	checks.partial = not state.pressure_defeated() and state.pressure_remaining() == 1
	var partial := TRAVEL.history(state)
	checks.partial_valid = state.config_unavailable_reason(partial) == ""
	var missing_cp := TRAVEL.history(state)
	missing_cp.set_value("post_bow", "cp02_claimed", false)
	checks.reject_missing_cp = state.config_unavailable_reason(missing_cp) != ""
	var premature_supply := TRAVEL.history(state)
	premature_supply.set_value("post_bow", "pressure_supply_claimed", true)
	checks.reject_premature_victory_supply = state.config_unavailable_reason(premature_supply) != ""
	var restored := STATE.new()
	restored.restore_config(partial)
	checks.partial_restore = restored.pressure_remaining() == 1 and not restored.pressure_defeated() and restored.experience == xp + 10
	checks.pending_preserved = not restored.reward_history.map02_e02_melee.collected and restored.reward_history.map02_e02_melee.drop.id == "healing"
	checks.restore_no_award = not restored.settle_pressure(Vector3.ZERO, {}, "map02_e02_melee") and restored.experience == xp + 10
	checks.second_once = restored.settle_pressure(Vector3(137,11,160), {"id":"lifeflame", "quantity":1}, "map02_e02_ranged") and restored.experience == xp + 20
	checks.complete = restored.pressure_defeated() and restored.pressure_remaining() == 0
	checks.second_repeat = not restored.settle_pressure(Vector3.ZERO, {}, "map02_e02_ranged") and restored.experience == xp + 20
	restored.reward_history.map02_e02_melee.collected = true
	var completed := TRAVEL.history(restored)
	checks.complete_valid = restored.config_unavailable_reason(completed) == ""
	restored.restore_config(completed)
	checks.completed_restore = restored.pressure_defeated() and restored.reward_history.map02_e02_melee.collected and not restored.reward_history.map02_e02_ranged.collected and restored.experience == xp + 20
	var unknown_identity := TRAVEL.history(restored)
	var unknown_rewards: Dictionary = restored.reward_history.duplicate(true)
	unknown_rewards["map02_e02_unknown"] = unknown_rewards[restored.PRESSURE_IDS[0]].duplicate(true)
	unknown_identity.set_value("post_bow", "reward_history", unknown_rewards)
	checks.reject_unknown_reward_identity = restored.config_unavailable_reason(unknown_identity) != ""
	var wrong_branch := TRAVEL.history(restored)
	wrong_branch.set_value("post_bow", "meadow_branch_supply_claimed", true)
	checks.reject_light_first_branch_claim = restored.config_unavailable_reason(wrong_branch) != ""
	var aggregate := TRAVEL.history(restored)
	aggregate.set_value("post_bow", "dynamic_serial", 1)
	aggregate.set_value("post_bow", "dynamic_instances", {"ch01_dynamic_1":{"status":"collected", "xp":10, "hp":0.0, "home":Vector3(126,11,122), "position":Vector3(126,11,122)}})
	var required_xp: int = restored.reward_history.size() * 10 + 10
	aggregate.set_value("opening", "experience", required_xp)
	checks.fixed_dynamic_sum_valid = restored.config_unavailable_reason(aggregate) == ""
	aggregate.set_value("opening", "experience", required_xp - 1)
	checks.reject_fixed_dynamic_xp_shortfall = restored.config_unavailable_reason(aggregate) != ""
	var invalid := TRAVEL.history(restored)
	var unearned_rewards: Dictionary = restored.reward_history.duplicate(true)
	for id in restored.E01_IDS: unearned_rewards.erase(id)
	invalid.set_value("post_bow", "reward_history", unearned_rewards)
	checks.no_unearned_e02 = restored.config_unavailable_reason(invalid) != ""
	var reverse := prepared()
	checks.ranged_first = reverse.settle_pressure(Vector3(137,11,160), {}, "map02_e02_ranged") and not reverse.pressure_defeated() and not reverse.reward_history.has("map02_e02_melee")
	var reverse_history := TRAVEL.history(reverse)
	checks.reverse_valid = reverse.config_unavailable_reason(reverse_history) == ""
	reverse.restore_config(reverse_history)
	checks.reverse_restore = reverse.pressure_remaining() == 1 and reverse.experience == xp + 10
	checks.reverse_complete = reverse.settle_pressure(Vector3(133,11,157), {}, "map02_e02_melee") and reverse.pressure_defeated() and reverse.experience == xp + 20
	var unearned := TRAVEL.earned()
	unearned.departure_confirmed = true
	unearned.commit_arrival(unearned.MAP02)
	checks.e01_gate = not unearned.settle_pressure(Vector3.ZERO, {}, "map02_e02_melee")
	var legacy := TRAVEL.history(unearned)
	for key in ["pressure_supply_claimed", "meadow_branch_supply_claimed"]: legacy.erase_section_key("post_bow", key)
	var legacy_restored := STATE.new()
	legacy_restored.restore_config(legacy)
	checks.legacy_e02_default = legacy_restored.pressure_remaining() == 2 and not legacy_restored.pressure_defeated()
	checks.legacy_supply_defaults = not legacy_restored.pressure_supply_claimed and not legacy_restored.meadow_branch_supply_claimed
	legacy_restored.free()
	unearned.free()
	reverse.free()
	restored.free()
	state.free()
	return checks

static func supply_checks(parent: Node) -> Dictionary:
	# A live GLoot bag in disposable state exercises capacities and restores;
	# DiagnosticState prevents preferences or user-save reads/writes.
	var source := prepared()
	source.bridge_first_action = "rescue"
	source.bridge_later_supply_due = true
	source.bridge_supply_claimed = false
	var state := TRAVEL.DiagnosticState.new()
	parent.add_child(state)
	state.restore_config(TRAVEL.history(source))
	source.free()
	var checks := {"isolated_inventory":state.inventory.bag != null}
	var xp: int = state.experience
	state.health = 100
	state.arrows = 12
	checks.branch_capacity_pending = state.meadow_branch_supply_available() and state.claim_meadow_branch_supply().is_empty() and not state.meadow_branch_supply_claimed
	state.health = 85
	state.arrows = 11
	var branch: Dictionary = state.claim_meadow_branch_supply()
	checks.branch_clamped = branch.get("health",0) == 15 and branch.get("arrows",0) == 1 and state.health == 100 and state.arrows == 12
	checks.branch_once = state.meadow_branch_supply_claimed and state.bridge_later_supply_due and state.claim_meadow_branch_supply().is_empty() and not state.pressure_supply_claimed
	for id in state.PRESSURE_IDS: state.settle_pressure(Vector3(133,11,157), {}, id)
	checks.victory_capacity_pending = state.pressure_supply_available() and state.claim_pressure_supply().is_empty() and not state.pressure_supply_claimed
	state.health = 75
	var victory: Dictionary = state.claim_pressure_supply()
	checks.victory_twenty = victory.get("health",0) == 20 and state.health == 95 and state.pressure_supply_claimed
	checks.victory_once = state.claim_pressure_supply().is_empty() and state.experience == xp + 20
	var settled: ConfigFile = TRAVEL.history(state)
	checks.supply_history_valid = state.config_unavailable_reason(settled) == ""
	state.restore_config(settled)
	checks.supply_restore = state.meadow_branch_supply_claimed and state.pressure_supply_claimed and state.claim_pressure_supply().is_empty() and state.claim_meadow_branch_supply().is_empty() and state.health == 95
	state.free()
	var light := prepared()
	checks.light_first_preserved = not light.meadow_branch_supply_available() and light.claim_meadow_branch_supply().is_empty()
	light.free()
	return checks

static func lifecycle_checks(world: Node3D) -> Dictionary:
	var state: Node = world.dialogue_state
	if not state is TRAVEL.DiagnosticState: return {"isolated_state":false}
	var encounter: Node = world.pressure_encounter
	if not encounter.grounded or encounter.enemies.size() != 2: return {"ready":false}
	var melee: CharacterBody3D = encounter.enemies[0]
	var ranged: CharacterBody3D = encounter.enemies[1]
	var checks := {"isolated_state":true}
	checks.authored_cover = encounter.cover.mesh != null and encounter.cover_body.collision_layer == 1 and encounter.cover_body.get_child(0).shape is ConvexPolygonShape3D
	encounter.interrupt()
	checks.ranged_safe_idle = ranged.can_save()
	ranged.action.perform_action()
	checks.draw_blocks_save = not ranged.can_save() and not encounter.can_save() and ranged.phase == "telegraph"
	encounter.interrupt()
	checks.draw_interrupted = ranged.phase == "idle" and not ranged.action.executing_action and not ranged.blackboard.get_value("perform_action",false)
	var xp: int = state.experience
	var cue: int = world.training.feedback.cue_serial
	ranged.health_component.decrement_health(ranged.health)
	checks.ranged_defeat = ranged.health == 0 and ranged.phase == "death" and state.experience == xp + 10 and world.training.feedback.cue_serial == cue + 1
	checks.partial = not state.pressure_defeated() and melee.health > 0
	encounter.settle_defeat(ranged)
	checks.repeat_ignored = state.experience == xp + 10 and world.training.feedback.cue_serial == cue + 1
	encounter.restore_history()
	checks.partial_restore = not ranged.visible and ranged.collision_layer == 0 and ranged.health == 0 and melee.health == 42 and melee.visible
	checks.pending_restore = state.reward_history.map02_e02_ranged.collected or encounter.pickups.has("map02_e02_ranged")
	melee.health_component.decrement_health(melee.health)
	checks.complete = state.pressure_defeated() and state.experience == xp + 20
	var histories: Dictionary = state.reward_history.duplicate(true)
	world.training.settle_death()
	world.training.recover_at_checkpoint()
	checks.recovery = not state.recovery_pending and state.health == 100 and state.reward_history == histories and state.experience == xp + 20
	checks.clean_restore = not melee.visible and not ranged.visible and ranged.projectiles.is_empty() and not ranged.action.executing_action and encounter.death_remaining.is_empty()
	return checks
