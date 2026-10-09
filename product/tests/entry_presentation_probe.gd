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
	sampled = true

func _mcp_state() -> Dictionary:
	return {"sampled":sampled,"controls_absent":controls_absent,"pending_teardown":pending_teardown,"checks":checks}
