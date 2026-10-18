extends RefCounted
## Opt-in memory-only prerequisite/persistence checks, never ordinary earning.
const STATE = preload("res://dialogue_state.gd")
const TOMB = preload("res://tests/map03_barrier_test.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")

static func run() -> Dictionary:
	var checks := {}
	var s: Node = TOMB.prepared()
	var xp: int = s.experience
	checks.no_ritual_substitute = s.acquire_ritual_record() and not s.close_veyne_node() and not s.sq02_completed
	checks.no_remote_collection = not s.acquire_deployment_record() and not s.interpret_deployment_record()
	s.current_map = s.MAP02
	checks.fixed_record_once = s.acquire_deployment_record() and not s.acquire_deployment_record()
	checks.no_meadow_interpretation = not s.interpret_deployment_record()
	s.current_map = s.GROUND.MAP_ID
	checks.mara_interpretation_once = s.interpret_deployment_record() and not s.interpret_deployment_record()
	checks.no_remote_node = not s.close_veyne_node()
	s.current_map = s.MAP03
	checks.ln02_still_required = not s.close_veyne_node() and not s.ln02_purified
	s.reveal_ln02(); s.cut_ln02_supply("north"); s.cut_ln02_supply("south"); s.purify_ln02()
	checks.investigation_not_closure = not s.veyne_node_closed and not s.veyne_defeated
	checks.explicit_closure_once = s.close_veyne_node() and not s.close_veyne_node()
	checks.no_reward_or_victory = s.experience == xp and not s.veyne_defeated and not s.veyne_release_key and s.rescue_released.is_empty()
	var c := HISTORY.history(s)
	checks.valid_closed_history = s.config_unavailable_reason(c) == ""
	var restored: Node = STATE.new()
	restored.restore_config(c)
	checks.restore_durable_closure = restored.sq02_completed and restored.veyne_node_closed and not restored.veyne_defeated
	var snapshot: Dictionary = restored.adventure_snapshot()
	restored.veyne_node_closed = false
	restored.restore_adventure(snapshot)
	checks.rollback_restores_closure = restored.veyne_node_closed
	c.set_value("post_bow","sq02_completed",false)
	checks.closure_without_intelligence_rejected = s.config_unavailable_reason(c) != ""
	c.set_value("post_bow","sq02_completed",true)
	c.set_value("post_bow","sq02_record_found",false)
	checks.interpretation_without_record_rejected = s.config_unavailable_reason(c) != ""
	for key in ["sq02_record_found","sq02_completed","veyne_node_closed"]: c.erase_section_key("post_bow",key)
	checks.legacy_history_accepted = s.config_unavailable_reason(c) == ""
	restored.restore_config(c)
	checks.legacy_defaults_no_suppression = not restored.sq02_completed and not restored.veyne_node_closed
	c.set_value("post_bow","sq02_record_found","true")
	checks.malformed_record_rejected = s.config_unavailable_reason(c) != ""
	s.sq02_completed = false
	s.veyne_node_closed = false
	checks.victory_still_independent = s.defeat_veyne()
	s.current_map = s.GROUND.MAP_ID
	checks.late_interpretation_records_only = s.interpret_deployment_record() and not s.veyne_node_closed and s.experience == xp and not s.veyne_release_key
	restored.free(); s.free()
	return checks
