extends RefCounted
const TRAVEL = preload("res://tests/chapter_travel_test.gd")
const STATE = preload("res://dialogue_state.gd")

class IsolatedState extends "res://dialogue_state.gd":
	var commit_samples: Array[Dictionary] = []
	func save_progress(position: Vector3, yaw: float, slot := 0) -> Error:
		commit_samples.append({"map_id":current_map,"position":position,"yaw":yaw,"slot":slot,"xp":experience,"lives":lives,"rewards":reward_history.duplicate(true)})
		return OK
	func load_progress(_slot := 0) -> Dictionary:
		return {}

static func run() -> Dictionary:
	var checks := {}
	var state := TRAVEL.earned()
	state.departure_confirmed = true
	state.commit_arrival(state.MAP02)
	var xp: int = state.experience
	checks.once = state.settle_roadblock(Vector3(133,11,146), {"id":"healing","quantity":1}) and state.experience == xp + 10
	checks.repeat = not state.settle_roadblock(Vector3.ZERO, {}) and state.experience == xp + 10
	var c := TRAVEL.history(state)
	checks.valid = state.config_unavailable_reason(c) == ""
	var restored := STATE.new()
	restored.restore_config(c)
	checks.pending = not restored.reward_history.map02_e01.collected and restored.experience == xp + 10
	checks.reload_no_award = not restored.settle_roadblock(Vector3.ZERO,{}) and restored.experience == xp + 10
	restored.reward_history.map02_e01.collected = true
	var collected := TRAVEL.history(restored)
	checks.collected_valid = restored.config_unavailable_reason(collected) == ""
	restored.restore_config(collected)
	checks.collected_restored = restored.reward_history.map02_e01.collected and restored.reward_history.size() == 4
	restored.free()
	state.free()
	return checks
