extends RefCounted
const STATE = preload("res://dialogue_state.gd")
const BRIDGE_TEST = preload("res://tests/bridge_actions_test.gd")
const ACTION = preload("res://combat/snaiel/ranged_action.gd")

static func prepared() -> Node:
	var state: Node = BRIDGE_TEST.prepared()
	state.perform_bridge_action("light")
	state.perform_bridge_action("rescue")
	state.guard_briefing_acknowledged = true
	state.experience = 40
	return state

static func run() -> Dictionary:
	var checks := {}
	var state := prepared()
	var starting: int = state.experience
	checks.distinct_ids = state.GUARD_IDS.size() == 3 and not state.GUARD_IDS.has("bridge_patrol_a")
	for id in state.GUARD_IDS:
		checks[id+"_settles"] = state.settle_guard(id,Vector3(133,11,142),{"id":"healing","quantity":1})
		checks[id+"_repeat"] = not state.settle_guard(id,Vector3.ZERO,{})
	checks.three_only = state.experience == starting+30 and state.reward_history.size() == 3 and state.guards_defeated()
	checks.passage_still_inactive = state.passage_missing_conditions() == ["完成离村交谈与目的地准备"]
	var config: ConfigFile = BRIDGE_TEST.config_for(state)
	config.set_value("opening","experience",state.experience)
	checks.valid_history = state.config_unavailable_reason(config) == ""
	var restored := STATE.new()
	restored.restore_config(config)
	checks.restore_no_award = restored.guards_defeated() and restored.experience == state.experience and not restored.settle_guard("channel_ranged",Vector3.ZERO,{})
	checks.pending_pickup_retained = not restored.reward_history.channel_ranged.collected
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
