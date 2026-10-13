extends Node
## Opt-in component fixtures only; prepared facts never represent earned travel.
const STATE = preload("res://dialogue_state.gd")
const TRAVEL = preload("res://tests/chapter_travel_test.gd")
const PRESSURE = preload("res://tests/map02_pressure_test.gd")
const OWNER = preload("res://combat/map02_dynamic_encounters.gd")
var checks := {}
var router: Node
@export var ambusher_fixture := false

class DiagnosticAmbusherRouter extends DiagnosticDynamicRouter:
	func _ready() -> void:
		super()
		# Initialize the production bus routing without reading/writing preferences.
		state.apply_global_audio()
		# Opt-in prepared history, intercepted before any production persistence.
		state.meadow_dynamic_serial = 2
		state.meadow_dynamic_groups = 1
		for i in 2:
			var id := "ch02_dynamic_%d" % (i+1)
			var point := Vector3(-7,2,50+i*3)
			state.meadow_dynamic_instances[id] = {"chapter":"CH02","archetype":"ambusher","instance_id":id,"home":point,"position":point,"hp":36.0,"status":"active","xp":15,"loot":[],"revealed":false,"variant":i}
		world.restored_position = {"position":Vector3(-7,0,45),"map_id":state.MAP02,"yaw":PI}

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
	if ambusher_fixture:
		router = DiagnosticAmbusherRouter.new()
		router.name = "MeadowAmbusherDiagnostic"
		add_child(router)
	else:
		router = attach_diagnostic(self)

func _mcp_state() -> Dictionary:
	var failed := []
	for key in checks:
		if checks[key] != true: failed.append(key)
	return {"diagnostic_fixture":true,"prepared_history":true,"ambusher_fixture":ambusher_fixture,"check_count":checks.size(),"failed_checks":failed,"checks":checks,"router":router._mcp_state() if is_instance_valid(router) else null}

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
	# Optional prepared component facts; these roundtrips do not earn E03 travel.
	var fixed_rewards: Dictionary = state.reward_history.duplicate(true)
	var fixed_revealed: bool = state.e03_revealed
	for variant in [0,1]:
		for status in ["active","pending","collected"]:
			for revealed in ([false,true] if status == "active" else [true]):
				var ambusher := record(status,"ambusher")
				ambusher.xp = 15
				ambusher.revealed = revealed
				ambusher.variant = variant
				state.meadow_dynamic_serial = 1
				state.meadow_dynamic_groups = 1
				state.meadow_dynamic_remaining = 83.5
				state.meadow_dynamic_instances = {"ch02_dynamic_1":ambusher}
				var config := TRAVEL.history(state)
				var key := "ambusher_%d_%s_%s" % [variant,status,"revealed" if revealed else "concealed"]
				result[key+"_valid"] = state.config_unavailable_reason(config) == ""
				var wire := ConfigFile.new()
				result[key+"_serialization"] = wire.parse(config.encode_to_text()) == OK
				var reader := STATE.new()
				reader.restore_config(wire)
				result[key+"_restore"] = reader.meadow_dynamic_serial == 1 and reader.meadow_dynamic_groups == 1 and reader.meadow_dynamic_remaining == 83.5 and reader.meadow_dynamic_instances == state.meadow_dynamic_instances and reader.experience == state.experience
				result[key+"_fixed_identity_isolated"] = reader.e03_revealed == fixed_revealed and reader.reward_history == fixed_rewards and reader.ambush_remaining() == state.ambush_remaining()
				reader.free()
	var ambusher := record("active","ambusher")
	ambusher.xp = 15
	ambusher.revealed = false
	ambusher.variant = 0
	var ambusher_facts := {"ch02_dynamic_1":ambusher}
	var revealed_peer: Dictionary = ambusher.duplicate(true)
	revealed_peer.instance_id = "ch02_dynamic_2"
	revealed_peer.revealed = true
	revealed_peer.variant = 1
	state.meadow_dynamic_serial = 2
	state.meadow_dynamic_instances = {"ch02_dynamic_1":ambusher.duplicate(true),"ch02_dynamic_2":revealed_peer}
	var independent_config := TRAVEL.history(state)
	result.ambusher_independent_visibility_valid = state.config_unavailable_reason(independent_config) == ""
	var independent_reader := STATE.new()
	independent_reader.restore_config(independent_config)
	result.ambusher_independent_visibility_restore = independent_reader.meadow_dynamic_instances == state.meadow_dynamic_instances and not independent_reader.meadow_dynamic_instances.ch02_dynamic_1.revealed and independent_reader.meadow_dynamic_instances.ch02_dynamic_2.revealed and not independent_reader.e03_revealed
	independent_config.set_value("post_bow","e03_revealed",true)
	independent_reader.restore_config(independent_config)
	result.ambusher_fixed_reveal_does_not_reveal_instances = independent_reader.e03_revealed and not independent_reader.meadow_dynamic_instances.ch02_dynamic_1.revealed and independent_reader.meadow_dynamic_instances.ch02_dynamic_2.revealed
	independent_reader.free()
	state.meadow_dynamic_serial = 1
	state.meadow_dynamic_instances = ambusher_facts.duplicate(true)
	for key in ["revealed","variant"]:
		var bad: Dictionary = ambusher_facts.duplicate(true)
		bad.ch02_dynamic_1.erase(key)
		result["reject_ambusher_missing_"+key] = not STATE.valid_meadow_dynamic_facts(1,120,1,bad)
	var legacy_ambusher: Dictionary = ambusher_facts.duplicate(true)
	legacy_ambusher.ch02_dynamic_1.erase("revealed")
	legacy_ambusher.ch02_dynamic_1.erase("variant")
	result.reject_ambusher_legacy_shape = not STATE.valid_meadow_dynamic_facts(1,120,1,legacy_ambusher)
	var malformed := {"revealed_string":["revealed","false"],"revealed_integer":["revealed",0],"revealed_null":["revealed",null],"variant_string":["variant","0"],"variant_float":["variant",1.0],"variant_bool":["variant",true],"variant_negative":["variant",-1],"variant_above_range":["variant",2],"variant_null":["variant",null],"hp_above_cap":["hp",36.01],"xp_melee":["xp",10]}
	for key in malformed:
		var bad: Dictionary = ambusher_facts.duplicate(true)
		bad.ch02_dynamic_1[malformed[key][0]] = malformed[key][1]
		result["reject_ambusher_"+key] = not STATE.valid_meadow_dynamic_facts(1,120,1,bad)
	var full_health: Dictionary = ambusher_facts.duplicate(true)
	full_health.ch02_dynamic_1.hp = 36.0
	result.ambusher_full_health_valid = STATE.valid_meadow_dynamic_facts(1,120,1,full_health)
	for status in ["pending","collected"]:
		var bad: Dictionary = ambusher_facts.duplicate(true)
		bad.ch02_dynamic_1.status = status
		bad.ch02_dynamic_1.hp = 0.0
		result["reject_ambusher_concealed_"+status] = not STATE.valid_meadow_dynamic_facts(1,120,1,bad)
	var fixed_id: String = state.AMBUSH_IDS[0]
	var foreign_record: Dictionary = ambusher.duplicate(true)
	foreign_record.instance_id = fixed_id
	result.reject_ambusher_fixed_identity = not STATE.valid_meadow_dynamic_facts(1,120,1,{fixed_id:foreign_record})
	var xp_before: int = state.experience
	result.ambusher_cannot_settle_fixed_e03 = not state.settle_ambush(Vector3(-7,2,51),{},"ch02_dynamic_1") and state.experience == xp_before and state.reward_history == fixed_rewards and state.e03_revealed == fixed_revealed
	result.fixed_e03_cannot_collect_dynamic = not state.collect_meadow_reward(fixed_id) and state.experience == xp_before and state.reward_history == fixed_rewards
	# Initialize only this disposable fixture's bag; no node enters a live world.
	state.inventory._ready()
	var settled := record("pending","ambusher")
	settled.xp = 15
	settled.revealed = true
	settled.variant = 1
	settled.loot = []
	state.meadow_dynamic_instances = {"ch02_dynamic_1":settled}
	result.ambusher_reward_once = state.collect_meadow_reward("ch02_dynamic_1") and state.experience == xp_before+15 and state.meadow_dynamic_instances.ch02_dynamic_1.status == "collected"
	result.ambusher_reward_repeat = not state.collect_meadow_reward("ch02_dynamic_1") and state.experience == xp_before+15
	result.ambusher_reward_fixed_identity_isolated = state.reward_history == fixed_rewards and state.e03_revealed == fixed_revealed and state.ambush_remaining() == 2
	state.e03_revealed = true
	var dynamic_history: Dictionary = state.meadow_dynamic_instances.duplicate(true)
	result.fixed_e03_settlement_dynamic_identity_isolated = state.settle_ambush(Vector3(4,1,75),{},fixed_id) and state.experience == xp_before+25 and state.meadow_dynamic_instances == dynamic_history and state.ambush_remaining() == 1
	result.fixed_e03_repeat_dynamic_identity_isolated = not state.settle_ambush(Vector3(4,1,75),{},fixed_id) and state.experience == xp_before+25 and state.meadow_dynamic_instances == dynamic_history
	var settled_config := TRAVEL.history(state)
	result.ambusher_settlement_config_valid = state.config_unavailable_reason(settled_config) == ""
	var settled_reader := STATE.new()
	settled_reader.restore_config(settled_config)
	result.ambusher_settlement_restore_once = settled_reader.meadow_dynamic_instances == dynamic_history and settled_reader.reward_history == state.reward_history and settled_reader.experience == xp_before+25 and not settled_reader.collect_meadow_reward("ch02_dynamic_1") and not settled_reader.settle_ambush(Vector3(4,1,75),{},fixed_id) and settled_reader.experience == xp_before+25
	settled_reader.free()
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
