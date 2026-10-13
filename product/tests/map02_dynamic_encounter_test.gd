extends Node
## Opt-in component fixtures only; prepared facts never represent earned travel.
const STATE = preload("res://dialogue_state.gd")
const TRAVEL = preload("res://tests/chapter_travel_test.gd")
const PRESSURE = preload("res://tests/map02_pressure_test.gd")
const OWNER = preload("res://combat/map02_dynamic_encounters.gd")
var checks := {}
var router: Node

class DiagnosticDynamicRouter extends PRESSURE.DiagnosticPressureRouter:
	func _ready() -> void:
		super()
		# Every save request is intercepted by the inherited DiagnosticState.
		for id in state.PRESSURE_IDS: state.settle_pressure(Vector3(8,0,61), {}, id)
		state.acquire_mf01()
		state.meadow_dynamic_remaining = 0
		world.restored_position = {"position":Vector3(-15,0,45),"map_id":state.MAP02,"yaw":PI}

func _ready() -> void:
	checks = run()
	router = attach_diagnostic(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture":true,"prepared_history":true,"checks":checks,"router":router._mcp_state() if is_instance_valid(router) else null}

static func attach_diagnostic(parent: Node) -> Node:
	var fixture := DiagnosticDynamicRouter.new()
	fixture.name = "MeadowDynamicDiagnostic"
	parent.add_child(fixture)
	return fixture

static func prepared() -> Node:
	var state := PRESSURE.prepared()
	for id in state.PRESSURE_IDS: state.settle_pressure(Vector3(8,0,61), {}, id)
	state.acquire_mf01()
	return state

static func record(status: String, archetype := "melee", index := 1) -> Dictionary:
	return {"chapter":"CH02","archetype":archetype,"instance_id":"ch02_dynamic_%d" % index,"home":Vector3(-7,2,50+index),"position":Vector3(-7,2,50+index),"hp":17.0 if status == "active" else 0.0,"status":status,"xp":15 if archetype == "ranged" else 10,"loot":[] if status == "active" else [{"id":"healing","count":1}]}

static func run() -> Dictionary:
	var result := {}
	var state := prepared()
	var legacy := TRAVEL.history(state)
	for key in ["meadow_dynamic_serial","meadow_dynamic_remaining","meadow_dynamic_groups","meadow_dynamic_instances"]: legacy.erase_section_key("post_bow",key)
	result.legacy_valid = state.config_unavailable_reason(legacy) == ""
	state.restore_config(legacy)
	result.legacy_restore = state.meadow_dynamic_serial == 0 and state.meadow_dynamic_groups == 0 and state.meadow_dynamic_remaining == 120 and state.meadow_dynamic_instances.is_empty()
	for status in ["active","pending","collected"]:
		state.meadow_dynamic_serial = 2
		state.meadow_dynamic_groups = 1
		state.meadow_dynamic_remaining = 83.5
		state.meadow_dynamic_instances = {"ch02_dynamic_1":record(status),"ch02_dynamic_2":record(status,"ranged",2)}
		var config := TRAVEL.history(state)
		result[status+"_valid"] = state.config_unavailable_reason(config) == ""
		var reader := STATE.new()
		reader.restore_config(config)
		result[status+"_restore"] = reader.meadow_dynamic_serial == 2 and reader.meadow_dynamic_groups == 1 and reader.meadow_dynamic_remaining == 83.5 and reader.meadow_dynamic_instances == state.meadow_dynamic_instances and reader.experience == state.experience
		reader.free()
	var facts := {"ch02_dynamic_1":record("active"),"ch02_dynamic_2":record("active","ranged",2)}
	result.chapter_identity = STATE.valid_meadow_dynamic_facts(2,120,1,facts)
	result.reject_revisit_nonfinite = not STATE.valid_meadow_dynamic_facts(2,INF,1,facts)
	result.reject_group_cap = not STATE.valid_meadow_dynamic_facts(2,120,3,facts)
	result.reject_serial_reuse = not STATE.valid_meadow_dynamic_facts(1,120,1,facts)
	result.reject_missing_groups = not STATE.valid_meadow_dynamic_facts(2,120,0,facts)
	for key in ["chapter","archetype","instance_id","home","position","hp","xp","loot","status"]:
		var bad: Dictionary = facts.duplicate(true)
		bad.ch02_dynamic_2[key] = {"chapter":"CH01","archetype":"mage","instance_id":"ch02_dynamic_1","home":Vector3(3,2,25),"position":Vector3.INF,"hp":37.0,"xp":10,"loot":[{"id":"sword","count":1}],"status":"defeated"}[key]
		result["reject_"+key] = not STATE.valid_meadow_dynamic_facts(2,120,1,bad)
	var pending := {"ch02_dynamic_1":record("pending")}
	pending.ch02_dynamic_1.hp = 1.0
	result.reject_pending_hp = not STATE.valid_meadow_dynamic_facts(1,120,1,pending)
	result.ch01_unchanged = STATE.valid_dynamic_facts(7,83.5,{"ch01_dynamic_7":preload("res://tests/dynamic_encounter_test.gd").record("pending")})
	result.melee_scene_load = load("res://combat/Map02DynamicMelee.tscn") is PackedScene
	result.ranged_scene_load = load("res://combat/Map02DynamicRanged.tscn") is PackedScene
	var archer: CharacterBody3D = preload("res://combat/map02_dynamic_ranged_adapter.gd").new()
	archer.action = preload("res://combat/snaiel/ranged_action.gd").new()
	result.ranged_idle_save = archer.can_save()
	archer.engaged = true
	result.ranged_engaged_blocks_save = not archer.can_save()
	archer.engaged = false
	archer.phase = "telegraph"
	result.ranged_windup_blocks_save = not archer.can_save()
	archer.phase = "idle"
	archer.action.executing_action = true
	result.ranged_timeline_blocks_save = not archer.can_save()
	archer.action.free()
	archer.free()
	state.free()
	return result

static func qualification_checks(world: Node3D) -> Dictionary:
	if not world.dialogue_state is TRAVEL.DiagnosticState: return {"isolated_state":false}
	var encounter: Node = world.dynamic_encounters
	var result := {"isolated_state":true,"ready":encounter.initialized,"eligibility":encounter.spawn_reason()}
	var excluded: Array[RID] = [world.player.get_rid()]
	for index in OWNER.ANCHORS.size():
		var anchor: Vector2 = OWNER.ANCHORS[index]
		result["anchor_%d_support" % index] = not encounter.support_point(anchor,excluded).is_empty()
		result["anchor_%d_corridor" % index] = encounter.return_corridor(anchor,excluded)
		result["anchor_%d_protected" % index] = encounter.protected_xz(anchor)
	result.cp02_protected = encounter.protected_xz(OWNER.GROUND.ENTRY)
	result.mf01_protected = encounter.protected_xz(OWNER.GROUND.ROUTE_RECORD)
	result.e03_protected = encounter.protected_xz(OWNER.GROUND.AMBUSH_ANCHORS[0])
	result.e04_protected = encounter.protected_xz(OWNER.GROUND.LINE_ANCHORS[0])
	result.ln01_protected = encounter.protected_xz(OWNER.GROUND.LN01_EXIT)
	return result

static func settlement_checks(world: Node3D) -> Dictionary:
	# Uses actual admitted actors; no unsafe forced materialization.
	var state: Node = world.dialogue_state
	if not state is TRAVEL.DiagnosticState: return {"isolated_state":false}
	var owner: Node = world.dynamic_encounters
	if owner.registry().size() != 2: return {"ready":false,"isolated_state":true,"eligibility":owner.spawn_reason(),"placement":owner.last_placement}
	var result := {"ready":true,"isolated_state":true}
	var before: int = state.experience
	var total := 0
	var identities := []
	for enemy in owner.enemies:
		identities.append(enemy.archetype)
		enemy.health_component.decrement_health(enemy.health)
		var first: Dictionary = state.meadow_dynamic_instances[enemy.stable_id].duplicate(true)
		result[enemy.stable_id+"_pending"] = first.status == "pending" and first.hp == 0 and owner.pickups.has(enemy.stable_id) and state.experience == before
		owner.settle_defeat(enemy)
		result[enemy.stable_id+"_repeat_death"] = state.meadow_dynamic_instances[enemy.stable_id] == first and state.experience == before
		total += int(first.xp)
	result.mixed_group = "melee" in identities and "ranged" in identities
	var bag: Dictionary = state.inventory.snapshot()
	for id in ["healing","lifeflame"]:
		var maximum := 9 if id == "healing" else 5
		var missing: int = maximum-state.inventory.count(id)
		if missing > 0: state.inventory.accept(id,missing)
	var id: String = owner.enemies[0].stable_id
	var drop: Array = state.meadow_dynamic_instances[id].loot
	# Retained weighted table always returns one real item; retain honest failure
	# if a future table intentionally returns no drop instead of inventing one.
	result.full_bag_retains = not drop.is_empty() and not owner.collect(id) and state.experience == before and state.meadow_dynamic_instances[id].status == "pending" and owner.pickups.has(id)
	state.bag_history = bag
	state.inventory.restore()
	for enemy in owner.enemies:
		var collected: bool = owner.collect(enemy.stable_id)
		result[enemy.stable_id+"_collected"] = collected and state.meadow_dynamic_instances[enemy.stable_id].status == "collected" and not owner.pickups.has(enemy.stable_id)
		var xp: int = state.experience
		result[enemy.stable_id+"_repeat_collect"] = not owner.collect(enemy.stable_id) and state.experience == xp
	result.experience_once = state.experience == before+total
	var config := TRAVEL.history(state)
	result.collected_config_valid = state.config_unavailable_reason(config) == ""
	var reader := STATE.new()
	reader.restore_config(config)
	result.collected_restore = reader.meadow_dynamic_instances == state.meadow_dynamic_instances and reader.experience == state.experience and reader.meadow_dynamic_groups == 1
	reader.free()
	return result
