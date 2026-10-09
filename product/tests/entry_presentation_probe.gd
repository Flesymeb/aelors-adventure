extends Node
## Opt-in scene only. No title hook, progression bypass or player-save writes.
var controls_absent: Dictionary = {}
var pending_teardown: Dictionary = {}
var checks: Dictionary = {}
var sampled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lifecycle: Dictionary = preload("res://tests/entry_lifecycle_test.gd").run(self)
	controls_absent = lifecycle.before
	pending_teardown = lifecycle.pending_teardown
	checks.lifecycle = lifecycle.checks
	checks.guard_logic = preload("res://tests/channel_guard_test.gd").run()
	checks.travel_logic = preload("res://tests/chapter_travel_test.gd").run()
	checks.roadblock_logic = preload("res://tests/map02_roadblock_test.gd").run()
	checks.observation_boundaries = observation_boundaries()
	sampled = true

static func observation_boundaries() -> Dictionary:
	var result := {}
	for script in ["res://ui/title_settings.gd", "res://ui/menu_audio.gd", "res://ui/illustrated_opening.gd", "res://ui/chapter_transition.gd", "res://ui/game_entry_router.gd"]:
		var node: Node = load(script).new()
		var before: Dictionary = node._mcp_state()
		result[script + "_unavailable"] = before.get("ready") == false
		result[script + "_read_only"] = before == node._mcp_state()
		node.queue_free()
		var pending: Dictionary = node._mcp_state()
		result[script + "_teardown"] = pending.get("ready") == false
	return result

func _mcp_state() -> Dictionary:
	return {"sampled":sampled,"controls_absent":controls_absent,"pending_teardown":pending_teardown,"checks":checks}
