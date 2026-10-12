extends Node
## Opt-in memory-only fixture. Prepared history never proves earned chapter travel.
const ENTRY = preload("res://tests/map03_entry_test.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const STATE = preload("res://dialogue_state.gd")
var router: Node
var logic_results: Dictionary = {}

func _ready() -> void:
	router = ENTRY.DiagnosticTombRouter.new()
	router.name = "LN02Diagnostic"
	add_child(router)

class FakePlayer extends Node3D:
	var weapon_mode := "lamp"
	var arm := Node3D.new()
	var current_animation := ""
	var attack_timer := 0.0
	func _play_animation(_clip: String, _speed: float) -> void: pass

class QuietFeedback extends RefCounted:
	func spark(_at: Vector3, _color: Color) -> void: pass
class QuietTraining extends RefCounted:
	var feedback := QuietFeedback.new()
	func tell(_text: String, _seconds: float) -> void: pass
class QuietHud extends RefCounted:
	func restore_view() -> void: pass
class QuietAudio extends RefCounted:
	var cues := 0
	func play_cue(_cue: String) -> void: cues += 1
class OperationWorld extends Node3D:
	var player := FakePlayer.new()
	var training := QuietTraining.new()
	var gameplay_hud := QuietHud.new()
	var menu_audio := QuietAudio.new()
	func _init() -> void:
		add_child(player)
		player.add_child(player.arm)

static func prepared() -> Node:
	var state: Node = ENTRY.prepared()
	state.commit_arrival(state.MAP03)
	return state

static func run() -> Dictionary:
	var checks := {}
	var locked := STATE.new()
	checks.no_entry_bypass = not locked.reveal_ln02() and not locked.cut_ln02_supply("north") and not locked.purify_ln02()
	locked.free()
	for order in [["north","south"],["south","north"]]:
		var state: Node = prepared()
		var xp: int = state.experience
		var lives: int = state.lives
		var first: String = order[0]
		var second: String = order[1]
		checks[first+"_concealed_rejected"] = not state.cut_ln02_supply(first) and not state.purify_ln02()
		checks[first+"_reveal_once"] = state.reveal_ln02() and not state.reveal_ln02()
		checks[first+"_cut_once"] = state.cut_ln02_supply(first) and not state.cut_ln02_supply(first)
		checks[first+"_early_preserves"] = not state.purify_ln02() and state.get("ln02_"+first+"_cut") and not state.get("ln02_"+second+"_cut") and state.ln02_remaining().size() == 1
		var partial := HISTORY.history(state)
		checks[first+"_partial_valid"] = state.config_unavailable_reason(partial) == ""
		var decoded: Dictionary = preload("res://systems/history_config_reader.gd").decode(partial.encode_to_text())
		checks[first+"_native_decode"] = decoded.reason == ""
		var restored := STATE.new()
		restored.restore_config(decoded.config)
		checks[first+"_partial_restored"] = restored.get("ln02_"+first+"_cut") and not restored.get("ln02_"+second+"_cut") and not restored.ln02_purified and restored.lives == lives
		checks[first+"_second_then_active_purify"] = restored.cut_ln02_supply(second) and not restored.ln02_purified and restored.purify_ln02() and not restored.purify_ln02()
		var complete := HISTORY.history(restored)
		checks[first+"_completed_valid"] = restored.config_unavailable_reason(complete) == ""
		state.restore_config(complete)
		checks[first+"_completed_restored"] = state.ln02_purified and state.ln02_north_cut and state.ln02_south_cut and state.experience == xp and state.lives == lives and state.commit_arrival(state.MAP03) and state.lives == lives
		checks[first+"_return_keeps_circuit"] = state.commit_arrival(state.MAP02) and state.ln02_purified and state.config_unavailable_reason(HISTORY.history(state)) == "" and state.commit_arrival(state.MAP03)
		checks[first+"_projection"] = state.objective().contains("入口结界已净化") and state.quest_entries().any(func(row): return row.id == "ln02" and row.complete)
		for key in ["ln02_revealed","ln02_north_cut","ln02_south_cut","ln02_purified"]:
			var invalid := HISTORY.history(state)
			invalid.set_value("post_bow",key,"true")
			checks[first+"_reject_type_"+key] = state.config_unavailable_reason(invalid) != ""
		var invalid := HISTORY.history(state)
		invalid.set_value("post_bow","ln02_"+first+"_cut",false)
		checks[first+"_reject_incomplete_purification"] = state.config_unavailable_reason(invalid) != ""
		invalid = HISTORY.history(state)
		invalid.set_value("post_bow","ln02_revealed",false)
		checks[first+"_reject_unrevealed_cut"] = state.config_unavailable_reason(invalid) != ""
		var legacy := HISTORY.history(state)
		for key in ["ln02_revealed","ln02_north_cut","ln02_south_cut","ln02_purified"]: legacy.erase_section_key("post_bow",key)
		checks[first+"_legacy_valid"] = state.config_unavailable_reason(legacy) == ""
		restored.restore_config(legacy)
		checks[first+"_legacy_closed"] = not restored.ln02_revealed and not restored.ln02_purified and not restored.ln02_north_cut and not restored.ln02_south_cut
		state.health = 0; state.recovery_pending = true
		checks[first+"_death_preserves"] = state.ln02_purified and state.config_unavailable_reason(HISTORY.history(state)) == "" and not state.cut_ln02_supply(first)
		state.free(); restored.free()
	checks.merge(rollback_checks())
	return checks

static func rollback_checks() -> Dictionary:
	var checks := {}
	var prepared_state: Node = prepared()
	var state := ENTRY.TombState.new()
	state.restore_config(HISTORY.history(prepared_state))
	prepared_state.free()
	state.selected_equipment = "lamp"
	var world := OperationWorld.new()
	Engine.get_main_loop().root.add_child(world)
	var circuit: Node = load("res://world/map03_barrier.tscn").instantiate()
	world.add_child(circuit)
	circuit.world = world
	circuit.state = state
	var xp: int = state.experience
	var lives: int = state.lives
	for operation in ["reveal","north","south","purify"]:
		state.fail_save_after = 0
		var before: Dictionary = state.adventure_snapshot()
		checks[operation+"_failed_save_rollback"] = not circuit.operate(operation) and before == state.adventure_snapshot() and circuit.activation_count == world.menu_audio.cues
		checks[operation+"_retry_commits_once"] = circuit.operate(operation) and not circuit.operate(operation) and circuit.activation_count == world.menu_audio.cues
	checks.no_reward_replay = state.experience == xp and state.lives == lives and circuit.activation_count == 4
	var committed: ConfigFile = state.histories[0]
	state.restore_config(committed)
	checks.completed_checkpoint_history = state.ln02_purified and state.lives == lives and circuit.activation_count == 4
	circuit.free(); world.free(); state.free()
	return checks

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture":true,"prepared_history":true,"save_storage":"memory only","logic_results":logic_results}
