extends RefCounted
const STATE = preload("res://dialogue_state.gd")
const BRIDGE_TEST = preload("res://tests/bridge_actions_test.gd")
const ACTION = preload("res://combat/snaiel/ranged_action.gd")

class PickupTraining extends Node:
	var locked := false
	func player_locked() -> bool: return locked
	func commit() -> void: pass # Isolated adapter test never writes user saves.
	func tell(_message: String, _seconds := 3) -> void: pass

class PickupWorld extends Node3D:
	var player: CharacterBody3D
	var training: PickupTraining

class PickupEnemy extends CharacterBody3D:
	var stable_id := "channel_ranged"
	func reset_encounter() -> void: pass

class ObservationEnemy extends CharacterBody3D:
	var stable_id := "channel_ranged"
	var display_name := "fixture ranged guard"
	var health := 0.0
	var phase := "death"
	var engaged := false
	var navigation_ready := false
	func _mcp_state() -> Dictionary: return {"health":health,"phase":phase}

static func prepared() -> Node:
	var state: Node = BRIDGE_TEST.prepared()
	state.perform_bridge_action("light")
	state.perform_bridge_action("rescue")
	state.guard_briefing_acknowledged = true
	state.practice_hit = true
	state.practice_defense = true
	state.encounter_defeated = true
	state.trace_revealed = true
	state.experience = 40
	return state

static func run() -> Dictionary:
	var checks := {}
	for adapter in [preload("res://combat/bridge_encounter.gd"), preload("res://combat/channel_guard_encounter.gd")]:
		var unconfigured = adapter.new()
		var observed: Dictionary = unconfigured._mcp_state()
		checks["unconfigured_" + ("channel" if observed.has("ranged") else "bridge")] = not observed.ready and not observed.state_ready and observed.rewards == null and observed.enemies.is_empty()
		if observed.has("ranged"):
			checks.unconfigured_channel_details = observed.ranged == null and observed.cover_position == null and observed.complete == null and observed.missing_conditions == null
		unconfigured.free()
	var state := prepared()
	var starting: int = state.experience
	checks.unsettled_projection = state.guard_melee_a_reward_state == "unsettled" and state.guard_melee_a_xp == 0
	checks.distinct_ids = state.GUARD_IDS.size() == 3 and not state.GUARD_IDS.has("bridge_patrol_a")
	for id in state.GUARD_IDS:
		checks[id+"_settles"] = state.settle_guard(id,Vector3(133,11,142),{"id":"healing","quantity":1})
		checks[id+"_repeat"] = not state.settle_guard(id,Vector3.ZERO,{})
	checks.three_only = state.experience == starting+30 and state.reward_history.size() == 3 and state.guards_defeated()
	checks.farewell_required = state.passage_missing_conditions() == ["与伊莎确认离村"]
	var config: ConfigFile = BRIDGE_TEST.config_for(state)
	config.set_value("opening","experience",state.experience)
	checks.valid_history = state.config_unavailable_reason(config) == ""
	var restored := STATE.new()
	restored.restore_config(config)
	checks.restore_no_award = restored.guards_defeated() and restored.experience == state.experience and not restored.settle_guard("channel_ranged",Vector3.ZERO,{})
	checks.pending_pickup_retained = not restored.reward_history.channel_ranged.collected
	checks.pending_metadata_roundtrip = restored.reward_history.channel_ranged == state.reward_history.channel_ranged and restored.reward_history.keys() == state.reward_history.keys()
	checks.pending_projection = restored.guard_melee_a_reward_state == "pending" and restored.guard_melee_b_reward_state == "pending" and restored.guard_ranged_reward_state == "pending" and restored.guard_melee_a_xp == 10 and restored.guard_melee_b_xp == 10 and restored.guard_ranged_xp == 10
	checks.scalar_selector_shape = restored._mcp_state().guard_ranged_reward_state == "pending" and restored._mcp_state().guard_ranged_xp == 10
	# Isolated projection test; not a claim of ordinary pickup collection.
	var before_projection := restored.adventure_snapshot()
	var observed: String = restored.guard_ranged_reward_state
	checks.observation_read_only = observed == "pending" and restored.adventure_snapshot() == before_projection
	# Config roundtrip is diagnostic: neither an ordinary death nor Continue.
	# A collected record must retain its item/position and cannot award XP again.
	var collected := BRIDGE_TEST.config_for(state)
	collected.set_value("opening", "experience", state.experience)
	var collected_rewards: Dictionary = state.reward_history.duplicate(true)
	collected_rewards.channel_ranged.collected = true
	collected.set_value("post_bow", "reward_history", collected_rewards)
	var collected_state := STATE.new()
	collected_state.restore_config(collected)
	checks.collected_metadata_roundtrip = collected_state.reward_history.channel_ranged == collected_rewards.channel_ranged and collected_state.guard_ranged_reward_state == "collected"
	checks.collected_no_reaward = collected_state.experience == state.experience and not collected_state.settle_guard("channel_ranged", Vector3.ZERO, {})
	checks.roundtrip_source_unchanged = state.guard_ranged_reward_state == "pending" and state.experience == starting + 30
	collected_state.free()
	config.set_value("post_bow","guard_briefing_acknowledged",false)
	checks.reject_unearned = restored.config_unavailable_reason(config) != ""
	config.set_value("post_bow","guard_briefing_acknowledged",true)
	config.set_value("post_bow","bridge_resident_rescued",false)
	checks.reject_missing_bridge = restored.config_unavailable_reason(config) != ""
	var unearned := STATE.new()
	checks.no_unearned_reward = not unearned.settle_guard("channel_melee_a",Vector3.ZERO,{})
	unearned.free()
	restored.free()
	state.free()
	var action := ACTION.new()
	var board := SnaielBlackboard.new()
	action.blackboard = board
	var releases: Array[int] = []
	action.action_effect.connect(func(id): releases.append(id))
	checks.start = action.perform_action()
	action.tick(0.79,true)
	checks.anticipation_no_contact = releases.is_empty() and action.stage == "telegraph"
	action.tick(0.02,true)
	checks.one_release = releases == [1]
	action.tick(0.8,true)
	checks.recovery_no_repeat = releases == [1] and not action.perform_action()
	action.tick(0.4,true)
	checks.interval = action.perform_action()
	action.tick(0.3,true)
	action.interrupt_action()
	action.tick(1.5,true)
	checks.interruption_no_late_release = releases == [1]
	action.free()
	board.free()
	return checks

static func observation_lifecycle_checks(parent: Node) -> Dictionary:
	# Opt-in isolated lifetime fixture; no combat, progression or save mutation.
	var stage := Node3D.new()
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(stage)
	var state := prepared()
	stage.add_child(state)
	state.settle_guard("channel_ranged", Vector3(0,50,0), {"id":"healing","quantity":1})
	var encounter := preload("res://combat/channel_guard_encounter.gd").new()
	stage.add_child(encounter)
	encounter.state = state
	encounter.grounded = true
	for i in 3:
		var enemy := ObservationEnemy.new()
		stage.add_child(enemy)
		encounter.enemies.append(enemy)
	encounter.cover = MeshInstance3D.new()
	stage.add_child(encounter.cover)
	var before: Dictionary = state.reward_history.duplicate(true)
	var observed: Dictionary = encounter._mcp_state()
	var checks := {"configured_observation_shape":observed.ready and observed.state_ready and observed.enemies.size() == 3 and observed.enemies[2].id == "channel_ranged" and observed.ranged.health == 0.0 and observed.cover_position != null}
	checks.configured_observation_read_only = observed.rewards.channel_ranged == before.channel_ranged and state.reward_history == before and state.experience == 50
	state.queue_free()
	encounter.enemies[2].queue_free()
	encounter.cover.queue_free()
	observed = encounter._mcp_state()
	checks.queued_dependencies_unknown = not observed.ready and not observed.state_ready and observed.rewards == null and observed.enemies[2] == null and observed.ranged == null and observed.cover_position == null and observed.complete == null
	checks.queued_observation_preserves_pending = state.reward_history == before and state.guard_ranged_reward_state == "pending" and state.guard_ranged_xp == 10 and state.experience == 50
	encounter.queue_free()
	observed = encounter._mcp_state()
	checks.queued_encounter_not_ready = not observed.ready
	stage.free()
	return checks

static func pending_pickup_checks(parent: Node) -> Dictionary:
	# Explicitly invoked component fixture, not an earned death/Continue journey.
	# Exercise the inherited adapter and real GLoot insertion without touching
	# the live adventure, terrain, audio preferences or any save file.
	var state := prepared()
	state.settle_guard("channel_ranged", Vector3(0,50,0), {"id":"healing","quantity":1})
	var xp: int = state.experience
	var stage := PickupWorld.new()
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(stage)
	stage.player = CharacterBody3D.new()
	stage.add_child(stage.player)
	stage.player.position = Vector3(0,50,0)
	stage.training = PickupTraining.new()
	stage.add_child(stage.training)
	state.inventory = preload("res://inventory/product_inventory.gd").new()
	state.inventory.state = state
	stage.add_child(state.inventory)
	var encounter := preload("res://combat/bridge_encounter.gd").new()
	stage.add_child(encounter)
	encounter.world = stage
	encounter.state = state
	encounter.grounded = true
	var enemy := PickupEnemy.new()
	stage.add_child(enemy)
	encounter.enemies.append(enemy)
	encounter.restore_history()
	var checks := {"pending_sprite_restored": encounter.pickups.has("channel_ranged") and encounter.pickups.channel_ranged.visible}
	var point: Vector3 = encounter.pickups.channel_ranged.global_position
	# Repeat restoration is idempotent and uses the saved position/drop.
	encounter.restore_history()
	checks.pending_identity_position = encounter.pickups.size() == 1 and encounter.pickups.channel_ranged.global_position == point and state.experience == xp
	stage.training.locked = true
	encounter._physics_process(1.0)
	checks.locked_retains_pending = encounter.pickups.has("channel_ranged") and state.guard_ranged_reward_state == "pending"
	stage.training.locked = false
	state.inventory.accept("healing",9)
	encounter._physics_process(1.0)
	checks.failed_insertion_retains_pending = encounter.pickups.has("channel_ranged") and state.guard_ranged_reward_state == "pending" and state.experience == xp
	state.health = 50
	state.inventory.use_item("healing")
	encounter._physics_process(1.1)
	checks.collection_once = not encounter.pickups.has("channel_ranged") and state.guard_ranged_reward_state == "collected" and state.inventory.count("healing") == 9 and state.experience == xp
	encounter.restore_history()
	checks.collected_not_recreated = encounter.pickups.is_empty() and state.guard_ranged_xp == 10
	stage.free()
	state.free()
	return checks
