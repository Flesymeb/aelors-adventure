extends RefCounted
## Opt-in disposable logic and inventory fixtures, never live player histories.
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const AMBUSH = preload("res://tests/map02_ambush_test.gd")

static func prepared() -> Node:
	var state: Node = AMBUSH.prepared()
	state.e03_revealed = true
	for id in state.AMBUSH_IDS: state.settle_ambush(Vector3(5,1,76), {}, id)
	return state

static func run() -> Dictionary:
	var checks := {}
	var locked: Node = AMBUSH.prepared()
	checks.e03_gate = not locked.line_defense_available() and not locked.settle_line(Vector3.ZERO,{},locked.LINE_IDS[0]) and not locked.acquire_mf02()
	locked.free()
	var state: Node = prepared()
	var xp: int = state.experience
	checks.unique_ids = state.LINE_IDS.size() == 3 and state.LINE_IDS.all(func(id): return id not in state.PRESSURE_IDS)
	checks.ready = state.line_defense_available() and state.line_remaining() == 3 and state.tracked_quest == "line"
	checks.no_premature_claims = not state.acquire_mf02() and state.claim_line_supply().is_empty()
	checks.bad_id = not state.settle_line(Vector3.ZERO,{},"unknown")
	checks.bad_position = not state.settle_line(Vector3.INF,{},state.LINE_IDS[0])
	checks.bad_drop = not state.settle_line(Vector3.ZERO,{"id":"healing","quantity":2},state.LINE_IDS[0])
	checks.reverse_first = state.settle_line(Vector3(9,1,92),{"id":"healing","quantity":1},state.LINE_IDS[2]) and state.line_remaining() == 2
	checks.once = not state.settle_line(Vector3.ZERO,{},state.LINE_IDS[2]) and state.experience == xp + 10
	var partial: ConfigFile = HISTORY.history(state)
	checks.partial_valid = state.config_unavailable_reason(partial) == ""
	var wire := ConfigFile.new()
	checks.serialized = wire.parse(partial.encode_to_text()) == OK
	var restored := preload("res://dialogue_state.gd").new()
	restored.restore_config(wire)
	checks.pending_restore = restored.line_remaining() == 2 and not restored.reward_history[restored.LINE_IDS[2]].collected and not restored.mf02_acquired
	checks.finish = restored.settle_line(Vector3(5,1,87),{},restored.LINE_IDS[0]) and restored.settle_line(Vector3(11,1,88),{},restored.LINE_IDS[1]) and restored.line_defeated() and restored.experience == xp + 30
	checks.mf02_once = restored.acquire_mf02() and not restored.acquire_mf02() and restored.tracked_quest == "line_record" and restored.mf01_acquired
	var settled: ConfigFile = HISTORY.history(restored)
	checks.complete_valid = restored.config_unavailable_reason(settled) == ""
	restored.restore_config(settled)
	checks.mf02_restore = restored.mf02_acquired and restored.mf02_information().contains("结界") and restored.quest_entries().any(func(row): return row.id == "line_record" and row.complete)
	var invalid: ConfigFile = HISTORY.history(restored)
	invalid.set_value("post_bow","e03_revealed",false)
	checks.impossible_rejected = restored.config_unavailable_reason(invalid) != ""
	invalid = HISTORY.history(state)
	invalid.set_value("post_bow","mf02_acquired",true)
	checks.partial_mf02_rejected = state.config_unavailable_reason(invalid) != ""
	invalid = HISTORY.history(state)
	invalid.set_value("post_bow","line_supply_claimed",true)
	checks.partial_supply_rejected = state.config_unavailable_reason(invalid) != ""
	invalid = HISTORY.history(state)
	invalid.set_value("post_bow","mf02_acquired","true")
	checks.wrong_type_rejected = state.config_unavailable_reason(invalid) != ""
	var legacy_source: Node = prepared()
	var legacy: ConfigFile = HISTORY.history(legacy_source)
	legacy_source.free()
	for key in ["mf02_acquired","line_supply_claimed"]: legacy.erase_section_key("post_bow",key)
	checks.legacy_valid = state.config_unavailable_reason(legacy) == ""
	restored.restore_config(legacy)
	checks.legacy_defaults = not restored.mf02_acquired and not restored.line_supply_claimed and restored.line_remaining() == 3
	for node in [state,restored]: node.free()
	return checks

static func supply_checks(parent: Node) -> Dictionary:
	var source: Node = prepared()
	var state := HISTORY.DiagnosticState.new()
	parent.add_child(state)
	state.restore_config(HISTORY.history(source))
	source.free()
	var checks := {"isolated":state.inventory.bag != null}
	checks.premature = state.claim_line_supply().is_empty() and not state.line_supply_claimed
	for id in state.LINE_IDS: state.settle_line(Vector3(9,1,92),{},id)
	state.health = 100
	checks.capacity_pending = state.line_supply_available() and state.claim_line_supply().is_empty() and not state.line_supply_claimed
	state.health = 85
	var gain: Dictionary = state.claim_line_supply()
	checks.clamped = gain.get("health",0) == 15 and state.health == 100 and state.line_supply_claimed
	checks.separate = not state.mf02_acquired and not state.pressure_supply_claimed
	checks.once = state.claim_line_supply().is_empty()
	var config: ConfigFile = HISTORY.history(state)
	checks.valid = state.config_unavailable_reason(config) == ""
	state.restore_config(config)
	checks.restored = state.line_supply_claimed and state.claim_line_supply().is_empty()
	state.free()
	return checks
