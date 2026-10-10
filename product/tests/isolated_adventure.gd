extends "res://ui/game_entry_router.gd"
## Explicit fresh-data launch only. All progression must be earned by input.
## In-memory histories intercept the existing state owner's persistence boundary.
class IsolatedState extends "res://dialogue_state.gd":
	var histories: Dictionary = {}
	func _ready() -> void:
		apply_global_audio()
		inventory = preload("res://inventory/product_inventory.gd").new()
		inventory.state = self
		add_child(inventory)
		inventory.restore()
	func save_progress(position: Vector3, yaw: float, slot := 0) -> Error:
		var config: ConfigFile = preload("res://tests/chapter_travel_test.gd").history(self)
		config.set_value("cinematic", "version", 1)
		config.set_value("cinematic", "completed", opening_completed)
		config.set_value("opening", "position", position)
		config.set_value("opening", "yaw", yaw)
		config.set_value("opening", "conversation", conversation_active)
		config.set_value("journal", "tracked", tracked_quest)
		config.set_value("journal", "collapsed", tracker_collapsed)
		histories[slot] = config
		save_feedback = "进度已保存"
		save_finished.emit(slot, OK)
		return OK
	func load_progress(slot := 0) -> Dictionary:
		if not histories.has(slot): return {}
		return restore_config(histories[slot])
	func slot_unavailable_reason(slot: int, allow_completed_opening := false) -> String:
		if not histories.has(slot): return "没有存档"
		return config_unavailable_reason(histories[slot], allow_completed_opening)
	func save_preferences() -> Error:
		apply_preferences()
		return OK
func create_adventure_state() -> Node:
	return IsolatedState.new()
