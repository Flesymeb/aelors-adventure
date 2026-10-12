extends Node
## Explicit opt-in diagnostic scene. Prepared facts are never earned-route proof.
const STATE = preload("res://dialogue_state.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const CIRCUIT = preload("res://tests/map02_barrier_test.gd")
const TOMB_GROUND = preload("res://world/map03_ground.gd")
var logic_results: Dictionary = {}

class TombState extends CIRCUIT.CircuitState:
	var fail_save_after := -1
	func save_progress(position: Vector3, yaw: float, slot := 0) -> Error:
		if fail_save_after == 0:
			fail_save_after = -1
			diagnostic_save_requests += 1
			save_feedback = "诊断保存失败"
			save_finished.emit(slot, ERR_CANT_CREATE)
			return ERR_CANT_CREATE
		if fail_save_after > 0: fail_save_after -= 1
		return super(position, yaw, slot)

class DiagnosticTombRouter extends "res://ui/game_entry_router.gd":
	var diagnostic_ready := false
	var logic_results: Dictionary = {}
	var fail_next_destination := false
	var fixture_checkpoint_saved := false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		state = TombState.new()
		state.name = "DiagnosticState"
		add_child(state)
		var prepared: Node = load("res://tests/map03_entry_test.gd").prepared()
		state.restore_config(HISTORY.history(prepared))
		prepared.free()
		state.selected_equipment = "lamp"
		state.commit_arrival(state.MAP03)
		audio = preload("res://ui/menu_audio.gd").new()
		audio.name = "DiagnosticAudio"
		audio.state = state
		add_child(audio)
		_bind_tomb({"position":Vector3.ZERO,"map_id":"","yaw":0.0})
	func _bind_tomb(restored: Dictionary) -> void:
		world = load("res://world/map03_entry.tscn").instantiate()
		world.name = "DiagnosticTomb"
		world.dialogue_state = state
		world.entry_router = self
		world.restored_position = restored
		world.entry_ready.connect(func(): player_ready = true)
		world.entry_failed.connect(func(message): entry_error = message)
		player_ready = false
		diagnostic_ready = false
		route = "diagnostic_initializing"
		add_child(world)
		world._set_pause_owner("entry",true)
		get_tree().paused = false
	func _process(delta: float) -> void:
		if route == "diagnostic_initializing":
			if player_ready and world.destination_ready() and not _confirmation_held():
				if not fixture_checkpoint_saved:
					if state.save_progress(world.player.global_position,world.player.arm.rotation.y) != OK: return
					fixture_checkpoint_saved = true
				world.restore_destination_history()
				world._set_pause_owner("entry",false)
				get_tree().paused = not world.pause_owners.is_empty()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				diagnostic_ready = true
				route = "world"
			return
		super(delta)
	func destination_resource(map_id: String) -> String:
		if fail_next_destination:
			fail_next_destination = false
			return "res://tests/fixtures/absent_map03_diagnostic.tscn"
		return super(map_id)
	func configure_failure(mode: String) -> bool:
		if route != "world": return false
		if mode == "destination": fail_next_destination = true
		elif mode == "source_save": state.fail_save_after = 0
		elif mode == "arrival_save": state.fail_save_after = 1
		else: return false
		return true
	func diagnostic_restart() -> bool:
		# Explicit fixture-only replacement and native restore, never ordinary Continue proof.
		if route != "world" or state.current_map != state.MAP03 or not state.histories.has(0): return false
		var histories: Dictionary = state.histories.duplicate(true)
		world.process_mode = Node.PROCESS_MODE_DISABLED
		world.queue_free()
		state.queue_free()
		route = "diagnostic_restarting"
		await get_tree().process_frame
		state = TombState.new()
		state.name = "DiagnosticState"
		state.histories = histories
		add_child(state)
		var restored: Dictionary = state.load_progress(0)
		if restored.is_empty(): entry_error = "诊断存档无法恢复"; return false
		audio.state = state
		_bind_tomb(restored)
		return true
	func _mcp_state() -> Dictionary:
		var observation := super()
		observation.diagnostic_fixture = true
		observation.diagnostic_ready = diagnostic_ready
		observation.logic_results = logic_results
		observation.diagnostic_save_requests = state.diagnostic_save_requests if is_instance_valid(state) else null
		observation.memory_history_count = state.histories.size() if is_instance_valid(state) else null
		return observation

class RollbackWorld extends "res://preview_controller.gd":
	func _set_pause_owner(owner: String, active: bool) -> void:
		if active: pause_owners[owner] = true
		else: pause_owners.erase(owner)

func _ready() -> void:
	logic_results = run()
	var router := DiagnosticTombRouter.new()
	router.name = "TombEntryDiagnostic"
	router.logic_results = logic_results
	add_child(router)

static func prepared() -> Node:
	var state: Node = CIRCUIT.prepared()
	state.reveal_ln01()
	state.cut_ln01_supply()
	state.purify_ln01_location()
	return state

static func run() -> Dictionary:
	var checks := {}
	var locked: Node = CIRCUIT.prepared()
	checks.premature_tomb_rejected = not locked.commit_arrival(locked.MAP03) and locked.current_map == locked.MAP02 and not locked.cp03_claimed and not locked.tomb_missing_conditions().is_empty()
	checks.record_before_arrival_rejected = not locked.acquire_ritual_record()
	locked.free()
	var state: Node = prepared()
	var xp: int = state.experience
	var lives: int = state.lives
	var rewards: Dictionary = state.reward_history.duplicate(true)
	var source := HISTORY.history(state)
	checks.source_valid = state.config_unavailable_reason(source) == ""
	checks.arrival_once = state.commit_arrival(state.MAP03) and state.cp03_claimed and state.current_map == state.MAP03 and state.lives == mini(5,lives+1) and state.experience == xp
	checks.reentry_no_reward = state.commit_arrival(state.MAP03) and state.lives == mini(5,lives+1) and state.reward_history == rewards
	var arrival := HISTORY.history(state)
	checks.tomb_config_valid = state.config_unavailable_reason(arrival) == ""
	checks.record_once = state.acquire_ritual_record() and not state.acquire_ritual_record() and state.experience == xp and state.reward_history == rewards
	var record := HISTORY.history(state)
	checks.record_config_valid = state.config_unavailable_reason(record) == ""
	var decoded: Dictionary = preload("res://systems/history_config_reader.gd").decode(record.encode_to_text())
	checks.native_history_decode = decoded.reason == ""
	var restored := STATE.new()
	var position: Dictionary = restored.restore_config(record)
	checks.record_restore = position.map_id == state.MAP03 and restored.current_map == state.MAP03 and restored.cp03_claimed and restored.ritual_record_read and restored.experience == xp and restored.lives == state.lives and not restored.acquire_ritual_record()
	checks.restore_no_reward = restored.commit_arrival(restored.MAP03) and restored.lives == state.lives and restored.reward_history == rewards
	checks.return_progress_retained = restored.commit_arrival(restored.MAP02) and restored.mf01_acquired and restored.mf02_acquired and restored.ln01_location_purified and restored.ritual_record_read and restored.commit_arrival(restored.MAP03) and restored.lives == state.lives
	checks.record_projection = state.ritual_information().contains("仪式尚未完成") and state.ritual_information().contains("没有隐藏倒计时") and state.quest_entries().any(func(row): return row.id == "ritual_record" and row.complete)
	for key in ["cp03_claimed","ritual_record_read"]: source.erase_section_key("post_bow",key)
	checks.old_save_valid = state.config_unavailable_reason(source) == ""
	restored.restore_config(source)
	checks.old_save_defaults = restored.current_map == state.MAP02 and not restored.cp03_claimed and not restored.ritual_record_read and restored.lives == lives
	checks.adjacent_village_meadow = restored.commit_arrival(restored.GROUND.MAP_ID) and restored.commit_arrival(restored.MAP02) and restored.cp02_claimed and not restored.cp03_claimed and restored.lives == lives and restored.experience == xp and restored.reward_history == rewards
	var memory := TombState.new()
	memory.restore_config(record)
	checks.memory_commit = memory.save_progress(Vector3(2,0,-3),0.0) == OK and memory.histories.size() == 1
	var committed_text: String = memory.histories[0].encode_to_text()
	memory.fail_save_after = 0
	checks.failed_save_preserves_history = memory.save_progress(Vector3(0,0,5),0.0) == ERR_CANT_CREATE and memory.histories[0].encode_to_text() == committed_text and memory.histories.size() == 1
	memory.free()
	for change in [{"section":"post_bow","key":"cp03_claimed","value":false},{"section":"post_bow","key":"ritual_record_read","value":"true"},{"section":"post_bow","key":"ln01_location_purified","value":false},{"section":"post_bow","key":"mf01_acquired","value":false},{"section":"post_bow","key":"current_map","value":state.MAP02}]:
		var invalid := HISTORY.history(state)
		invalid.set_value(change.section,change.key,change.value)
		checks["reject_invalid_" + change.key] = state.config_unavailable_reason(invalid) != ""
	checks.outside_map_recovers_cp03 = TOMB_GROUND.entry_xz(Vector3(130,10,150),state.MAP03) == TOMB_GROUND.ENTRY and TOMB_GROUND.entry_xz(Vector3(4,0,-3),state.MAP02) == TOMB_GROUND.ENTRY
	checks.tomb_position_retained = TOMB_GROUND.entry_xz(Vector3(2,0,-3),state.MAP03) == Vector2(2,-3)
	var router := preload("res://ui/game_entry_router.gd").new()
	router.state = state
	checks.destination_binding = router.destination_resource(state.MAP03) == "res://world/map03_entry.tscn" and router.destination_resource(state.MAP02) == "res://world/map02_entry.tscn" and router.destination_resource(state.GROUND.MAP_ID) == "res://Preview.tscn"
	checks.return_boundary = router.arrival_position(state.MAP02,state.MAP03).map_id == state.MAP02
	router.free()
	checks.merge(rollback_checks())
	checks.merge(HISTORY.collision_handoff_checks(),true)
	state.free(); restored.free()
	return checks

static func rollback_checks() -> Dictionary:
	var state: Node = prepared()
	# Prepared component inventories have not entered the tree and therefore
	# have no live bag. Snapshot the durable facts, never that unready adapter.
	if is_instance_valid(state.inventory):
		state.inventory.free()
		state.inventory = null
	var router := preload("res://ui/game_entry_router.gd").new()
	var source := RollbackWorld.new()
	source.village = Node3D.new()
	source.add_child(source.village)
	var body := StaticBody3D.new()
	body.collision_layer = 5; body.collision_mask = 3
	source.village.add_child(body)
	source._set_pause_owner("chapter_travel",true)
	router.state = state
	router.source_world = source
	router.world = source
	router.travel_history = state.adventure_snapshot()
	var lives: int = state.lives
	var xp: int = state.experience
	router._suspend_source_collision()
	state.commit_arrival(state.MAP03)
	state.acquire_ritual_record()
	router._travel_failed("")
	var checks := {"rollback_source_facts": state.current_map == state.MAP02 and not state.cp03_claimed and not state.ritual_record_read and state.lives == lives and state.experience == xp,
		"rollback_source_collision": body.collision_layer == 5 and body.collision_mask == 3 and router.source_collision_state.is_empty(),
		"rollback_control_owner": router.route == "world" and router.player_ready and not source.pause_owners.has("chapter_travel") and router.source_world == null}
	source.free(); router.free(); state.free()
	return checks
