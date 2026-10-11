extends RefCounted
## Explicit, save-intercepted fixtures only. None is referenced by normal boot.
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const AMBUSH = preload("res://tests/map02_ambush_test.gd")
const ROADBLOCK = preload("res://tests/map02_roadblock_test.gd")

static func prepared() -> Node:
	var state: Node = AMBUSH.prepared()
	state.e03_revealed = true
	for id in state.AMBUSH_IDS: state.settle_ambush(Vector3(4,1,75), {}, id)
	return state

class DiagnosticLineRouter extends ROADBLOCK.DiagnosticMeadowRouter:
	var smoke_spawn := Vector2(5,88)
	func _ready() -> void:
		super()
		for id in state.E01_IDS: state.settle_roadblock(Vector3(3,1,43), {}, id)
		for id in state.PRESSURE_IDS: state.settle_pressure(Vector3(6,1,66), {}, id)
		state.acquire_mf01()
		state.e03_revealed = true
		for id in state.AMBUSH_IDS: state.settle_ambush(Vector3(4,1,75), {}, id)
		state.arrows = 12
		state.skills = {"lightning":1}
		state.selected_equipment = "sword"
		world.restored_position = {"position":Vector3(smoke_spawn.x,0,smoke_spawn.y), "map_id":state.MAP02, "yaw":PI}

static func attach_diagnostic(parent: Node, spawn := Vector2(5,88)) -> Node:
	var router := DiagnosticLineRouter.new()
	router.smoke_spawn = spawn
	router.name = "E04Diagnostic"
	parent.add_child(router)
	return router

static func run() -> Dictionary:
	var checks := {}
	var scene: PackedScene = load("res://combat/Map02LineDefense.tscn")
	var owner: Node = scene.instantiate() if scene else null
	checks.separate_owner = owner != null and owner.get_script() == preload("res://combat/map02_line_defense.gd")
	checks.pre_ground_save_rejected = owner != null and not owner.can_save()
	if owner: owner.free()
	var model: Node = preload("res://assets/training/Orc.gltf").instantiate()
	var animator: AnimationPlayer = model.get_node("AnimationPlayer")
	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	checks.complete_melee_rig = skeleton.find_bone("LowerArm.R") >= 0 and skeleton.find_bone("Middle1.R") >= 0
	for clip in ["Idle", "Walk", "Punch", "HitReact", "Death"]:
		checks["melee_" + clip] = animator.has_animation(clip) and animator.get_animation(clip).length > 0
	model.free()
	checks.ranged_dependency_load = load("res://assets/guards/ranged_guard.glb") is PackedScene and load("res://Characters/KayKitAnimations/Rig_Medium_CombatRanged.glb") is PackedScene and load("res://actors/npc_presentation.tscn") is PackedScene
	checks.e02_owner_retained = load("res://combat/Map02Pressure.tscn") is PackedScene
	return checks

static func lifecycle_checks(world: Node3D) -> Dictionary:
	if not world.dialogue_state is HISTORY.DiagnosticState: return {"isolated_state":false}
	var state: Node = world.dialogue_state
	var owner: Node = world.line_encounter
	if not owner.grounded or owner.enemies.size() != 3: return {"ready":false}
	var ranged: CharacterBody3D = owner.enemies[2]
	if ranged.health != 36 or state.LINE_IDS.any(func(id): return state.reward_history.has(id)):
		return {"fresh_fixture_required":false}
	var checks := {"isolated_state":true, "three_real_actors":owner.enemies.size() == 3}
	checks.identities = owner.enemies.map(func(actor): return actor.stable_id) == state.LINE_IDS
	checks.no_e02_identity = owner.enemies.all(func(actor): return actor.stable_id not in state.PRESSURE_IDS)
	checks.actual_authored_cover = is_instance_valid(owner.cover) and world.village.is_ancestor_of(owner.cover)
	owner.interrupt()
	checks.idle_save = owner.can_save()
	checks.registry_all_three = owner.registry().size() == 3
	checks.element_eligibility_all_three = owner.enemies.all(func(actor): return world.element_abilities.eligible_target(actor))
	owner.enemies[0].phase = "telegraph"
	owner.enemies[1].phase = "attack"
	checks.two_slots_bound = not owner.attack_slot_available(ranged) and owner.attack_slot_available(owner.enemies[0])
	owner.interrupt()
	checks.draw_starts = ranged.action.perform_action() and ranged.phase == "telegraph" and not owner.can_save()
	owner.interrupt()
	checks.draw_cancel = not ranged.action.executing_action and ranged.projectiles.is_empty() and ranged.phase == "idle" and owner.can_save()
	var hp: float = ranged.health
	var src: SnaielDamageSource = world.element_abilities.source(22)
	world.element_abilities.settle(ranged, src, ranged.global_position + Vector3.UP, "lightning")
	checks.nonlethal_lightning = ranged.health == hp - 22 and ranged.phase == "hurt" and ranged.presentation.current_animation == "Hit_Chest" and not ranged.action.executing_action and not owner.can_save()
	world.element_abilities.settle(ranged, src, ranged.global_position + Vector3.UP, "lightning")
	checks.one_loss_per_source = ranged.health == hp - 22
	src.free()
	# Manual ticks are confined to this opted-in component fixture. Ordinary
	# timed hurt/recovery remains an independent player-route observation.
	ranged._physics_process(0.41)
	checks.hurt_recovers = ranged.hurt_remaining == 0 and ranged.phase == "idle" and ranged.presentation.current_animation == "Idle"
	ranged.action.tick(2.1, false)
	checks.ranged_control_returns = ranged.action.can_perform_action and ranged.action.perform_action() and ranged.phase == "telegraph"
	owner.interrupt()
	checks.hurt_cancel_idle = ranged.hurt_remaining == 0 and ranged.phase == "idle" and owner.can_save()
	var xp: int = state.experience
	ranged.health_component.decrement_health(ranged.health)
	checks.ranged_defeat = ranged.phase == "death" and ranged.health == 0 and state.reward_history.has(state.LINE_IDS[2]) and state.experience == xp + 10
	var before: Dictionary = state.reward_history.duplicate(true)
	owner.restore_history()
	checks.partial_restore = state.line_remaining() == 2 and owner.enemies[0].health > 0 and owner.enemies[1].health > 0 and ranged.health == 0 and state.reward_history == before and state.experience == xp + 10
	checks.pending_preserved = before[state.LINE_IDS[2]].collected or owner.pickups.has(state.LINE_IDS[2])
	checks.defeated_excluded = owner.registry().size() == 2 and not world.element_abilities.eligible_target(ranged)
	owner.interrupt()
	checks.restore_clears_arrows = ranged.projectiles.is_empty() and not ranged.action.executing_action
	return checks

static func ranged_contact_checks(parent: Node) -> Dictionary:
	# Adjacent E02 remains the same real ranged adapter and reaction pipeline.
	return preload("res://tests/ranged_lightning_contact_test.gd").lightning_contact_checks(parent, preload("res://combat/map02_ranged_adapter.gd"))
