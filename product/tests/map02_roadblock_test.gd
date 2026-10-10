extends RefCounted
## Opt-in fixtures intercept saves; never entered through normal startup.
const TRAVEL = preload("res://tests/chapter_travel_test.gd")
const STATE = preload("res://dialogue_state.gd")

class IsolatedState extends "res://dialogue_state.gd":
	var commit_samples: Array[Dictionary] = []
	func save_progress(position: Vector3, yaw: float, slot := 0) -> Error:
		commit_samples.append({"map_id":current_map,"position":position,"yaw":yaw,"slot":slot,"xp":experience,"lives":lives,"rewards":reward_history.duplicate(true)})
		return OK
	func load_progress(_slot := 0) -> Dictionary:
		return {}

class DiagnosticMeadowRouter extends TRAVEL.DiagnosticRouter:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		state = TRAVEL.DiagnosticState.new()
		state.name = "DiagnosticState"
		var prepared := TRAVEL.earned()
		prepared.departure_confirmed = true
		prepared.commit_arrival(prepared.MAP02)
		add_child(state)
		state.restore_config(TRAVEL.history(prepared))
		prepared.free()
		audio = preload("res://ui/menu_audio.gd").new()
		audio.state = state
		add_child(audio)
		world = preload("res://world/map02_entry.tscn").instantiate()
		world.name = "DiagnosticMeadow"
		world.dialogue_state = state
		world.entry_router = self
		world.restored_position = {"position":Vector3(3,0,25),"map_id":state.MAP02,"yaw":PI}
		world.entry_ready.connect(func(): player_ready = true)
		world.entry_failed.connect(func(message): entry_error = message)
		route = "diagnostic_initializing"
		add_child(world)
		world._set_pause_owner("entry", true)
		get_tree().paused = false

static func attach_diagnostic(parent: Node) -> Node:
	# Component/runtime smoke only, never evidence of legitimately earned travel.
	var router := DiagnosticMeadowRouter.new()
	router.name = "E01Diagnostic"
	parent.add_child(router)
	return router

static func run() -> Dictionary:
	var checks := {}
	var ground = preload("res://world/map02_ground.gd")
	checks.obsolete_map02_position_recovers_cp02 = ground.entry_xz(Vector3(133,11,146), ground.MAP02_ID) == ground.ENTRY
	checks.map02_position_preserved = ground.entry_xz(Vector3(4,2,61), ground.MAP02_ID) == Vector2(4,61)
	checks.other_map_recovers_cp02 = ground.entry_xz(Vector3(4,2,61), "forest-885de576-v1") == ground.ENTRY
	var state := TRAVEL.earned()
	state.departure_confirmed = true
	state.commit_arrival(state.MAP02)
	var xp: int = state.experience
	checks.identities = state.E01_IDS.size() == 2 and state.E01_IDS[0] == "map02_e01" and state.E01_IDS[0] != state.E01_IDS[1]
	checks.initial_group = not state.roadblock_defeated() and state.roadblock_remaining() == 2
	checks.reject_unknown = not state.settle_roadblock(Vector3.ZERO, {}, "unknown") and state.experience == xp
	checks.once = state.settle_roadblock(Vector3(133,11,146), {"id":"healing","quantity":1}) and state.experience == xp + 10
	checks.repeat = not state.settle_roadblock(Vector3.ZERO, {}) and state.experience == xp + 10
	checks.partial = not state.roadblock_defeated() and state.roadblock_remaining() == 1 and not state.objective().contains("E02")
	var c := TRAVEL.history(state)
	checks.legacy_valid = state.config_unavailable_reason(c) == ""
	var restored := STATE.new()
	restored.restore_config(c)
	checks.legacy_preserved = restored.reward_history.size() == state.GUARD_IDS.size() + 1 and not restored.reward_history.has("map02_e01_b") and not restored.roadblock_defeated()
	checks.pending = not restored.reward_history.map02_e01.collected and restored.experience == xp + 10
	checks.reload_no_award = not restored.settle_roadblock(Vector3.ZERO,{}) and restored.experience == xp + 10
	checks.second_once = restored.settle_roadblock(Vector3(135,11,146), {"id":"lifeflame","quantity":1}, "map02_e01_b") and restored.experience == xp + 20
	checks.group = restored.roadblock_defeated() and restored.roadblock_remaining() == 0 and restored.objective().contains("E02")
	checks.second_repeat = not restored.settle_roadblock(Vector3.ZERO,{},"map02_e01_b") and restored.experience == xp + 20
	restored.reward_history.map02_e01.collected = true
	var completed := TRAVEL.history(restored)
	checks.completed_valid = restored.config_unavailable_reason(completed) == ""
	restored.restore_config(completed)
	checks.collected_restored = restored.reward_history.map02_e01.collected and not restored.reward_history.map02_e01_b.collected and restored.reward_history.size() == state.GUARD_IDS.size() + 2
	checks.objective_restored = restored.roadblock_defeated() and restored.objective().contains("E02") and restored.experience == xp + 20
	# Recovery keeps committed kills, pending drops and the group objective.
	restored.health = 0
	restored.lives -= 1
	restored.recovery_pending = true
	var recovering := TRAVEL.history(restored)
	checks.recovery_valid = restored.config_unavailable_reason(recovering) == ""
	restored.restore_config(recovering)
	checks.recovery_history = restored.recovery_pending and restored.roadblock_defeated() and restored.experience == xp + 20 and not restored.reward_history.map02_e01_b.collected
	# Either actor can be defeated first; B alone never invents the legacy outcome.
	var reverse := TRAVEL.earned()
	reverse.departure_confirmed = true
	reverse.commit_arrival(reverse.MAP02)
	var reverse_xp: int = reverse.experience
	checks.b_first = reverse.settle_roadblock(Vector3(135,11,146), {}, "map02_e01_b") and not reverse.roadblock_defeated() and not reverse.reward_history.has("map02_e01")
	var b_only := TRAVEL.history(reverse)
	checks.b_only_valid = reverse.config_unavailable_reason(b_only) == ""
	reverse.restore_config(b_only)
	checks.b_only_restored = reverse.roadblock_remaining() == 1 and not reverse.roadblock_defeated() and reverse.experience == reverse_xp + 10
	checks.reverse_complete = reverse.settle_roadblock(Vector3(133,11,146), {}) and reverse.roadblock_defeated() and reverse.experience == reverse_xp + 20
	var invalid := TRAVEL.history(reverse)
	invalid.set_value("post_bow", "cp02_claimed", false)
	checks.b_requires_cp02 = reverse.config_unavailable_reason(invalid) != ""
	reverse.free()
	restored.free()
	state.free()
	return checks

static func settlement_checks(world: Node3D) -> Dictionary:
	# Refuse a live state: only the opt-in fixture intercepts every save call.
	var state: Node = world.dialogue_state
	if not state is TRAVEL.DiagnosticState: return {"isolated_state": false}
	var checks := {"isolated_state": true}
	var encounter: Node = world.bridge_encounter
	if not encounter.grounded or encounter.enemies.size() != 2: return {"ready": false}
	var a: CharacterBody3D = encounter.enemies[0]
	var b: CharacterBody3D = encounter.enemies[1]
	var xp: int = state.experience
	var serial: int = world.training.feedback.cue_serial
	a.health_component.decrement_health(a.health)
	# AnimationTree applies a requested state on its next physics update.
	# This synchronous check covers the event; playback is sampled after stepping.
	checks.first_dead_event = a.health == 0 and a.phase == "death" and a.character.active_clip == "Death" and state.experience == xp + 10
	checks.partial_boundary = not state.roadblock_defeated() and state.roadblock_remaining() == 1 and b.health > 0
	checks.first_reward_cue = world.training.feedback.cue_serial == serial + 1
	encounter.settle_defeat(a)
	checks.duplicate_event_ignored = state.experience == xp + 10 and world.training.feedback.cue_serial == serial + 1
	var first_record: Dictionary = state.reward_history[a.stable_id].duplicate(true)
	encounter.restore_history()
	checks.partial_restore = a.health == 0 and not a.visible and a.collision_layer == 0 and b.health == 42 and b.visible and b.collision_layer == 2
	checks.first_pending_restored = state.reward_history[a.stable_id] == first_record and (first_record.collected or encounter.pickups.has(a.stable_id))
	b.health_component.decrement_health(b.health)
	checks.second_dead_event = b.health == 0 and b.phase == "death" and b.character.active_clip == "Death" and state.experience == xp + 20
	checks.complete_boundary = state.roadblock_defeated() and state.objective().contains("E02")
	var rewards: Dictionary = state.reward_history.duplicate(true)
	var lives: int = state.lives
	world.training.settle_death()
	checks.death_history = state.lives == lives - 1 and state.recovery_pending and state.reward_history == rewards
	world.training.recover_at_checkpoint()
	checks.recovered_checkpoint = not state.recovery_pending and state.health == 100 and Vector2(world.player.global_position.x,world.player.global_position.z).distance_to(world.checkpoint_xz()) < 0.1
	checks.recovery_no_reaward = state.experience == xp + 20 and state.reward_history == rewards and state.objective().contains("E02")
	checks.recovery_visibility = not a.visible and not b.visible and a.health == 0 and b.health == 0 and encounter.death_remaining.is_empty()
	for id in state.E01_IDS:
		checks[id + "_pending_preserved"] = state.reward_history[id].collected or encounter.pickups.has(id)
	checks.transients_cleared = world.training.feedback.cues.is_empty() and world.training.feedback.sparks.is_empty() and world.training.feedback.sounds.is_empty()
	return checks
