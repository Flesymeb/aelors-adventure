extends "res://dialogue_state.gd"
## Explicit chapter-preview cheat state. Neither progress nor recovery markers
## are written to disk. A separate original AdventureState stays untouched.
var preview_chapter := 1
var preview_save_requests := 0
func _ready() -> void:
	inventory = preload("res://inventory/product_inventory.gd").new()
	inventory.state = self
	add_child(inventory)
	inventory.restore()
func save_progress(_position: Vector3, _yaw: float, slot := 0) -> Error:
	preview_save_requests += 1
	save_feedback = "章节预览 · 正式存档未改动"
	save_finished.emit(slot,OK)
	return OK
func load_progress(_slot := 0) -> Dictionary: return {}
func begin_opening_recovery() -> Error: return ERR_UNAVAILABLE
func clear_opening_recovery() -> Error: return OK
func prepare(chapter: int) -> void:
	reset_adventure()
	preview_chapter = chapter
	opening_completed = true
	q01_accepted = true
	sword_owned = true
	bow_owned = true
	lamp_owned = true
	selected_equipment = "sword"
	arrows = 30
	lives = 5
	health = 100
	experience = 120
	practice_hit = true
	practice_defense = true
	practice_parry = true
	encounter_defeated = true
	remnant_collected = true
	bow_training_complete = true
	bow_demonstrated = true
	trace_revealed = true
	trace_investigated = true
	skills = {"fire":1,"lightning":1}
	element_practice_complete = true
	if chapter >= 2:
		bridge_briefing_acknowledged = true
		bridge_resident_rescued = true
		bridge_lamp_lit = true
		bridge_first_action = "rescue"
		guard_briefing_acknowledged = true
		guard_interlude_seen = true
		departure_confirmed = true
		for id in GUARD_IDS: _preview_reward(id)
		current_map = MAP02
		cp02_claimed = true
	if chapter == 3:
		for id in E01_IDS + PRESSURE_IDS + AMBUSH_IDS + LINE_IDS: _preview_reward(id)
		mf01_acquired = true
		e03_revealed = true
		mf02_acquired = true
		ln01_revealed = true
		ln01_supply_cut = true
		ln01_location_purified = true
		current_map = MAP03
		cp03_claimed = true
	bag_history = {"sword":1,"bow":1,"lamp":1,"healing":3}
	if inventory: inventory.restore()
	# These are deliberately prepared preview facts, not earned game progress.
	# Their only owner is this disposable state, never the normal save reader.
func _preview_reward(id: String) -> void:
	reward_history[id] = {"xp":0,"collected":true,"position":Vector3.ZERO,"item":{}}
func _mcp_state() -> Dictionary:
	var result: Dictionary = super()
	result.chapter_preview = true
	result.earned_progress = false
	result.preview_chapter = preview_chapter
	result.preview_save_requests = preview_save_requests
	return result
