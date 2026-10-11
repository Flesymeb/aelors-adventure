extends RefCounted
## Opt-in disposable state/world fixtures. All file persistence is intercepted.
## These checks supplement ordinary play and do not prove earned progression.
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const PRESSURE = preload("res://tests/map02_pressure_test.gd")
const ROADBLOCK = preload("res://tests/map02_roadblock_test.gd")

static func prepared() -> Node:
	var state: Node = PRESSURE.prepared()
	for id in state.PRESSURE_IDS: state.settle_pressure(Vector3(6,1,66), {}, id)
	state.acquire_mf01()
	return state

class DiagnosticAmbushRouter extends ROADBLOCK.DiagnosticMeadowRouter:
	func _ready() -> void:
		super()
		for id in state.E01_IDS: state.settle_roadblock(Vector3(3,1,43), {}, id)
		for id in state.PRESSURE_IDS: state.settle_pressure(Vector3(6,1,66), {}, id)
		state.acquire_mf01()
		world.restored_position = {"position":Vector3(3,0,70),"map_id":state.MAP02,"yaw":PI}

static func attach_diagnostic(parent: Node) -> Node:
	var router := DiagnosticAmbushRouter.new()
	router.name = "E03Diagnostic"
	parent.add_child(router)
	return router

static func run() -> Dictionary:
	var checks := {}
	var state: Node = prepared()
	var xp: int = state.experience
	var legacy := HISTORY.history(state)
	legacy.erase_section_key("post_bow", "e03_revealed")
	checks.legacy_valid = state.config_unavailable_reason(legacy) == ""
	var restored := preload("res://dialogue_state.gd").new()
	restored.restore_config(legacy)
	checks.legacy_concealed = not restored.e03_revealed and restored.ambush_remaining() == 2
	checks.concealed_no_settlement = not restored.settle_ambush(Vector3(4,1,75),{},restored.AMBUSH_IDS[0]) and restored.experience == xp
	restored.e03_revealed = true
	checks.unknown_rejected = not restored.settle_ambush(Vector3.ZERO,{},"unknown")
	checks.first_once = restored.settle_ambush(Vector3(4,1,75),{"id":"healing","quantity":1},restored.AMBUSH_IDS[0]) and restored.experience == xp + 10
	checks.repeat_ignored = not restored.settle_ambush(Vector3.ZERO,{},restored.AMBUSH_IDS[0]) and restored.experience == xp + 10
	checks.partial = restored.ambush_remaining() == 1 and not restored.ambush_defeated()
	var config := HISTORY.history(restored)
	checks.partial_valid = restored.config_unavailable_reason(config) == ""
	var wire := ConfigFile.new()
	checks.serialization = wire.parse(config.encode_to_text()) == OK
	restored.restore_config(wire)
	checks.pending_and_visibility_restored = restored.e03_revealed and not restored.reward_history.map02_e03_a.collected and restored.reward_history.map02_e03_a.drop.id == "healing" and restored.experience == xp + 10
	checks.second_once = restored.settle_ambush(Vector3(7,1,76),{},restored.AMBUSH_IDS[1]) and restored.ambush_defeated() and restored.experience == xp + 20
	checks.second_repeat = not restored.settle_ambush(Vector3.ZERO,{},restored.AMBUSH_IDS[1]) and restored.experience == xp + 20
	restored.health = 0
	restored.lives -= 1
	restored.recovery_pending = true
	checks.recovery_config_valid = restored.config_unavailable_reason(HISTORY.history(restored)) == ""
	var invalid := HISTORY.history(restored)
	invalid.set_value("post_bow", "mf01_acquired", false)
	checks.unearned_rejected = restored.config_unavailable_reason(invalid) != ""
	invalid = HISTORY.history(state)
	invalid.set_value("post_bow", "e03_revealed", "true")
	checks.wrong_type_rejected = state.config_unavailable_reason(invalid) != ""
	var reverse: Node = prepared()
	reverse.e03_revealed = true
	checks.reverse_order = reverse.settle_ambush(Vector3(7,1,76),{},reverse.AMBUSH_IDS[1]) and not reverse.reward_history.has(reverse.AMBUSH_IDS[0]) and reverse.ambush_remaining() == 1
	checks.reverse_valid = reverse.config_unavailable_reason(HISTORY.history(reverse)) == ""
	for path in ["res://assets/ambush/ambusher_a.gltf", "res://assets/ambush/ambusher_b.gltf"]:
		var actor: Node = load(path).instantiate()
		var animator: AnimationPlayer = actor.get_node("AnimationPlayer")
		var skeleton: Skeleton3D = actor.find_child("Skeleton3D",true,false)
		checks[path + "_rig"] = skeleton.find_bone("LowerArm.R") >= 0 and skeleton.find_bone("Middle1.R") >= 0
		for clip in ["Idle","Walk","Punch","HitReact","Death"]: checks[path + "_" + clip] = animator.has_animation(clip) and animator.get_animation(clip).length > 0
		actor.free()
	for node in [state,restored,reverse]: node.free()
	return checks

static func concealment_checks(world: Node3D) -> Dictionary:
	if not world.dialogue_state is HISTORY.DiagnosticState: return {"isolated":false}
	var encounter: Node = world.ambush_encounter
	if not encounter.grounded: return {"ready":false}
	var checks := {"isolated":true}
	var actor: CharacterBody3D = encounter.enemies[0]
	var hp: float = actor.health
	var source: SnaielDamageSource = world.element_abilities.source(22)
	actor.receive_contact(source,actor.global_position)
	checks.concealed_no_damage = actor.health == hp and not actor.hitbox.enabled and actor.collision_layer == 0
	checks.concealed_no_targets = encounter.registry().is_empty() and not world.element_abilities.eligible_target(actor)
	checks.concealed_no_pressure = not actor.engaged and not actor.source.can_damage and not encounter.combat_allowed()
	source.free()
	return checks

static func recovery_checks(world: Node3D) -> Dictionary:
	if not world.dialogue_state is HISTORY.DiagnosticState: return {"isolated":false}
	var state: Node = world.dialogue_state
	var encounter: Node = world.ambush_encounter
	var before: Dictionary = state.reward_history.duplicate(true)
	var xp: int = state.experience
	state.health = 0
	state.recovery_pending = true
	world.training.recover_at_checkpoint()
	return {"recovered":not state.recovery_pending and state.health == 100,
		"checkpoint":Vector2(world.player.global_position.x,world.player.global_position.z).distance_to(world.checkpoint_xz()) < 0.1,
		"facts_preserved":state.reward_history == before and state.experience == xp,
		"retry_concealed":not state.e03_revealed and encounter.registry().is_empty(),
		"pending_preserved":state.AMBUSH_IDS.all(func(id): return not before.has(id) or before[id].collected or encounter.pickups.has(id)),
		"motion_cleared":encounter.enemies.all(func(actor): return not actor.melee.attacking and not actor.source.can_damage)}
