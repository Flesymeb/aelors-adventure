extends RefCounted
## Opt-in synthetic state/settlement regression; never a natural-play proof.
const STATE = preload("res://dialogue_state.gd")
const INVENTORY = preload("res://inventory/product_inventory.gd")

static func prepared() -> Node:
	var s := STATE.new()
	s.q01_accepted = true
	s.sword_owned = true
	s.remnant_collected = true
	s.bow_owned = true
	s.bow_training_complete = true
	s.lamp_owned = true
	s.trace_investigated = true
	s.skills = {"fire":1}
	s.element_practice_complete = true
	s.inventory = INVENTORY.new()
	s.inventory.state = s
	s.add_child(s.inventory)
	return s

static func config_for(s: Node) -> ConfigFile:
	var c := ConfigFile.new()
	c.set_value("opening", "position", Vector3(116,10,97))
	c.set_value("opening", "map_id", "forest-885de576-v1")
	c.set_value("opening", "node", s.logical_node)
	c.set_value("opening", "accepted", s.q01_accepted)
	c.set_value("opening", "experience", 40)
	c.set_value("opening", "conversation", s.conversation_active)
	for key in s.TRAINING_KEYS: c.set_value("training",key,s.get(key))
	for key in s.POST_DEFAULTS: c.set_value("post_bow",key,s.get(key))
	return c

static func run() -> Dictionary:
	var checks := {}
	checks.legacy_defaults = STATE.valid_bridge_facts({})
	for order in ["rescue", "light"]:
		var s := prepared()
		s.health = 80
		s.arrows = 10
		checks[order + "_first"] = s.perform_bridge_action(order) and s.bridge_first_action == order and not s.bridge_briefing_acknowledged
		checks[order + "_repeat"] = not s.perform_bridge_action(order)
		var partial := config_for(s)
		checks[order + "_partial_valid"] = s.config_unavailable_reason(partial) == ""
		var grant: Dictionary = s.claim_bridge_supply()
		checks[order + "_timing"] = (grant == {"health":20.0,"arrows":2} and s.health == 100 and s.arrows == 12) if order == "light" else (grant.is_empty() and s.health == 80 and s.arrows == 10 and s.bridge_later_supply_due)
		checks[order + "_second"] = s.perform_bridge_action("light" if order == "rescue" else "rescue") and s.bridge_resident_rescued and s.bridge_lamp_lit and s.bridge_first_action == order
		checks[order + "_claim_repeat"] = s.claim_bridge_supply().is_empty()
		var c := config_for(s)
		checks[order + "_complete_valid"] = s.config_unavailable_reason(c) == ""
		var restored := STATE.new()
		restored.restore_config(partial)
		checks[order + "_partial_restore"] = restored.bridge_first_action == order and restored.bridge_resident_rescued == (order == "rescue") and restored.bridge_lamp_lit == (order == "light") and not restored.bridge_supply_claimed and restored.health == 80
		restored.restore_config(c)
		checks[order + "_restore_no_grant"] = restored.health == s.health and restored.arrows == s.arrows and restored.bridge_supply_claimed == s.bridge_supply_claimed and restored.bridge_first_action == order
		restored.free()
		s.free()
	for facts in [
		{"bridge_first_action":"rescue"},
		{"bridge_resident_rescued":true},
		{"bridge_supply_claimed":true},
		{"bridge_first_action":"light", "bridge_lamp_lit":true, "bridge_later_supply_due":true},
		{"bridge_first_action":"rescue", "bridge_resident_rescued":true, "bridge_later_supply_due":true, "bridge_supply_claimed":true},
		{"bridge_first_action":3},
		{"bridge_lamp_lit":"true"}]:
		checks["invalid_%s" % str(facts)] = not STATE.valid_bridge_facts(facts)
	var s := prepared()
	s.perform_bridge_action("light")
	s.health = 35
	s.arrows = 2
	checks.full_supply = s.claim_bridge_supply() == {"health":30.0,"arrows":4} and s.health == 65 and s.arrows == 6
	var legacy := config_for(s)
	for key in ["bridge_resident_rescued","bridge_lamp_lit","bridge_first_action","bridge_supply_claimed","bridge_later_supply_due"]: legacy.erase_section_key("post_bow",key)
	checks.legacy_history = s.config_unavailable_reason(legacy) == ""
	s.restore_config(legacy)
	checks.legacy_restore = s.bridge_first_action == "" and not s.bridge_supply_claimed and not s.bridge_resident_rescued and not s.bridge_lamp_lit
	s.conversation_active = true
	s.logical_node = "B03"
	var unfinished := config_for(s)
	s.restore_config(unfinished)
	checks.unconfirmed_briefing = s.logical_node == "B03" and s.conversation_active and not s.bridge_briefing_acknowledged
	s.element_practice_complete = false
	checks.prerequisite = not s.perform_bridge_action("rescue") and s.bridge_first_action == ""
	s.free()
	return checks
