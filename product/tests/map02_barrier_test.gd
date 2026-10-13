extends RefCounted
## Explicit disposable fixtures only. No startup hooks, player-save writes or earned-route claim.
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const LINE = preload("res://tests/map02_line_defense_test.gd")
const ROADBLOCK = preload("res://tests/map02_roadblock_test.gd")
const GROUND = preload("res://world/map02_ground.gd")

static func prepared() -> Node:
	var state: Node = LINE.prepared()
	for id in state.LINE_IDS: state.settle_line(Vector3(9,1,95),{},id)
	state.acquire_mf02()
	return state

class CircuitState extends HISTORY.DiagnosticState:
	var histories: Dictionary = {}
	func _ready() -> void:
		super()
		apply_global_audio()
	func save_progress(position: Vector3, yaw: float, slot := 0) -> Error:
		diagnostic_save_requests += 1
		var config: ConfigFile = load("res://tests/chapter_travel_test.gd").history(self)
		config.set_value("opening","position",position)
		config.set_value("opening","yaw",yaw)
		config.set_value("journal","tracked",tracked_quest)
		histories[slot] = config
		save_feedback = "进度已保存"
		save_finished.emit(slot,OK)
		return OK
	func load_progress(slot := 0) -> Dictionary:
		return restore_config(histories[slot]) if histories.has(slot) else {}
	func slot_unavailable_reason(slot: int, allow_completed_opening := false) -> String:
		return config_unavailable_reason(histories[slot],allow_completed_opening) if histories.has(slot) else "没有存档"
	func save_preferences() -> Error:
		return OK

class DiagnosticCircuitRouter extends ROADBLOCK.DiagnosticMeadowRouter:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		state = CircuitState.new(); state.name = "DiagnosticState"; add_child(state)
		var source: Node = load("res://tests/map02_barrier_test.gd").prepared()
		state.restore_config(load("res://tests/chapter_travel_test.gd").history(source)); source.free()
		state.selected_equipment = "lamp"
		audio = preload("res://ui/menu_audio.gd").new(); audio.state = state; add_child(audio)
		world = preload("res://world/map02_entry.tscn").instantiate(); world.name = "DiagnosticMeadow"
		world.dialogue_state = state; world.entry_router = self
		world.restored_position = {"position":Vector3(9,0,105),"map_id":state.MAP02,"yaw":PI}
		world.entry_ready.connect(func(): player_ready = true)
		world.entry_failed.connect(func(message): entry_error = message)
		route = "diagnostic_initializing"; add_child(world)
		world._set_pause_owner("entry",true)
		get_tree().paused = false

static func attach_diagnostic(parent: Node) -> Node:
	var router := DiagnosticCircuitRouter.new()
	router.name = "LN01Diagnostic"
	parent.add_child(router)
	return router

static func run() -> Dictionary:
	var checks := {}
	var locked: Node = LINE.prepared()
	checks.no_prerequisite_bypass = not locked.reveal_ln01() and not locked.cut_ln01_supply() and not locked.purify_ln01_location()
	locked.free()
	var state: Node = prepared()
	var xp: int = state.experience
	var life: int = state.lives
	var health: float = state.health
	checks.before_reveal = not state.cut_ln01_supply() and not state.purify_ln01_location()
	checks.reveal_once = state.reveal_ln01() and not state.reveal_ln01()
	checks.wrong_order_recoverable = not state.purify_ln01_location() and not state.ln01_supply_cut and not state.ln01_location_purified and state.experience == xp and state.health == health
	var legacy := HISTORY.history(state)
	for key in ["ln01_revealed","ln01_supply_cut","ln01_location_purified"]: legacy.erase_section_key("post_bow",key)
	checks.legacy_valid = state.config_unavailable_reason(legacy) == ""
	var restored := preload("res://dialogue_state.gd").new()
	restored.restore_config(legacy)
	checks.legacy_concealed = not restored.ln01_revealed and not restored.ln01_supply_cut and not restored.ln01_location_purified
	checks.supply_once = state.cut_ln01_supply() and not state.cut_ln01_supply()
	var config := HISTORY.history(state)
	checks.partial_valid = state.config_unavailable_reason(config) == ""
	var wire := ConfigFile.new()
	checks.serialization = wire.parse(config.encode_to_text()) == OK
	restored.restore_config(wire)
	checks.partial_restoration = restored.ln01_revealed and restored.ln01_supply_cut and not restored.ln01_location_purified and restored.experience == xp
	checks.completion_once = restored.purify_ln01_location() and not restored.purify_ln01_location()
	var complete := HISTORY.history(restored)
	checks.completed_valid = restored.config_unavailable_reason(complete) == ""
	state.restore_config(complete)
	checks.completed_restoration = state.ln01_location_purified and state.ln01_supply_cut and state.lives == life and state.health == health and state.experience == xp
	var invalid := HISTORY.history(state)
	invalid.set_value("post_bow","ln01_supply_cut",false)
	checks.invalid_order_rejected = state.config_unavailable_reason(invalid) != ""
	invalid = HISTORY.history(state)
	invalid.set_value("post_bow","mf02_acquired",false)
	checks.unearned_save_rejected = state.config_unavailable_reason(invalid) != ""
	invalid = HISTORY.history(state)
	invalid.set_value("post_bow","ln01_revealed","true")
	checks.wrong_type_rejected = state.config_unavailable_reason(invalid) != ""
	state.health = 0; state.recovery_pending = true; state.lives -= 1
	checks.death_history_valid = state.config_unavailable_reason(HISTORY.history(state)) == "" and state.ln01_location_purified
	var dead: Node = prepared()
	dead.reveal_ln01(); dead.health = 0; dead.recovery_pending = true
	checks.dead_action_rejected = not dead.cut_ln01_supply() and not dead.purify_ln01_location() and not dead.ln01_supply_cut
	dead.free()
	state.health = 100; state.recovery_pending = false
	checks.supply_independent = not state.line_supply_claimed and state.ln01_location_purified
	checks.projections = state.objective().contains("通道已稳定") and state.mf02_information().contains("通道已稳定") and state.quest_entries().any(func(row): return row.id == "ln01" and row.complete)
	var scene: PackedScene = load("res://world/Map02Barrier.tscn")
	var module: Node = scene.instantiate() if scene else null
	checks.scene_loads = module != null and module.get_script() == preload("res://world/map02_barrier.gd")
	if module: module.free()
	checks.texture_variants = load("res://assets/effects/ln01_supply.tres").albedo_texture != load("res://assets/effects/ln01_location.tres").albedo_texture
	checks.transparent_edges = true
	for path in ["res://assets/effects/ln01_supply.tres", "res://assets/effects/ln01_location.tres"]:
		var image: Image = load(path).albedo_texture.get_image()
		if image.is_compressed() and image.decompress() != OK:
			checks.transparent_edges = false
		elif image.get_pixel(0, 0).a != 0:
			checks.transparent_edges = false
	checks.node_stances = GROUND.LN01_SUPPLY.distance_to(GROUND.LN01_LOCATION) > 4 and GROUND.LN01_CLUE.y < GROUND.LN01_PASSAGE.y and GROUND.LN01_SUPPLY.y < GROUND.LN01_PASSAGE.y and GROUND.LN01_LOCATION.y < GROUND.LN01_PASSAGE.y
	checks.restored_position = GROUND.entry_xz(Vector3(9,3,107),GROUND.MAP02_ID) == GROUND.LN01_LOCATION
	state.free(); restored.free()
	return checks
