extends RefCounted
## Opt-in in-memory persistence tests. No ordinary saves or natural-unlock claims.
const STATE = preload("res://dialogue_state.gd")
const BRIDGE = preload("res://tests/bridge_actions_test.gd")

static func record(status: String) -> Dictionary:
	return {"home":Vector3(126.013,10.62271,122.017), "position":Vector3(126.4,10.62271,122.8), "hp":17.0 if status == "active" else 0.0, "status":status, "xp":10}

static func run() -> Dictionary:
	var checks := {}
	var s := BRIDGE.prepared()
	s.experience = 40
	var legacy := BRIDGE.config_for(s)
	for key in ["dynamic_serial","dynamic_remaining","dynamic_instances"]: legacy.erase_section_key("post_bow",key)
	checks.legacy_valid = s.config_unavailable_reason(legacy) == ""
	s.restore_config(legacy)
	checks.legacy_restore = s.dynamic_instances.is_empty() and s.dynamic_serial == 0 and s.dynamic_remaining == 120 and s.sword_owned and s.element_practice_complete
	for status in ["active", "pending", "collected"]:
		s.dynamic_serial = 7
		s.dynamic_remaining = 83.5
		s.dynamic_instances = {"ch01_dynamic_7":record(status)}
		var c := BRIDGE.config_for(s)
		checks[status+"_valid"] = s.config_unavailable_reason(c) == ""
		var reader := STATE.new()
		reader.restore_config(c)
		checks[status+"_restore"] = reader.dynamic_serial == 7 and reader.dynamic_remaining == 83.5 and reader.dynamic_instances == s.dynamic_instances and reader.experience == 40
		var before: int = reader.experience
		var awarded: bool = reader.collect_dynamic_xp("ch01_dynamic_7")
		checks[status+"_collection"] = awarded == (status == "pending") and reader.experience == before + (10 if status == "pending" else 0)
		checks[status+"_repeat"] = not reader.collect_dynamic_xp("ch01_dynamic_7") and reader.experience == before + (10 if status == "pending" else 0)
		reader.free()
	s.dynamic_instances = {"ch01_dynamic_7":record("pending")}
	var corrupted := BRIDGE.config_for(s)
	corrupted.set_value("post_bow","dynamic_remaining",INF)
	checks.reject_nonfinite = s.config_unavailable_reason(corrupted) != ""
	corrupted.set_value("post_bow","dynamic_remaining",83.5)
	corrupted.set_value("post_bow","dynamic_serial",6)
	checks.reject_identity_reuse = s.config_unavailable_reason(corrupted) != ""
	corrupted.set_value("post_bow","dynamic_serial",7)
	corrupted.set_value("post_bow","element_practice_complete",false)
	checks.reject_unearned = s.config_unavailable_reason(corrupted) != ""
	for key in ["hp","position","home","xp","status"]:
		var bad := record("pending")
		bad[key] = {"hp":3.0,"position":Vector3.INF,"home":Vector3.ZERO,"xp":11,"status":"defeated"}[key]
		checks["reject_"+key] = not STATE.valid_dynamic_facts(7,83.5,{"ch01_dynamic_7":bad})
	var too_healthy := record("active")
	too_healthy.hp = 43.0
	checks.reject_hp_cap = not STATE.valid_dynamic_facts(7,120,{"ch01_dynamic_7":too_healthy})
	var crowded := {}
	for i in range(1,4): crowded["ch01_dynamic_%d" % i] = record("active")
	checks.reject_density = not STATE.valid_dynamic_facts(3,120,crowded)
	s.free()
	return checks
