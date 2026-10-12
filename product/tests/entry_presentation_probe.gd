extends Node
## Opt-in scene only. No title hook, progression bypass or player-save writes.
var controls_absent: Dictionary = {}
var pending_teardown: Dictionary = {}
var checks: Dictionary = {}
var departure_lifecycle: Dictionary = {}
var observer_lifecycle: Dictionary = {}
var audio_lifecycle: Dictionary = {}
var sampled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lifecycle: Dictionary = preload("res://tests/entry_lifecycle_test.gd").run(self)
	controls_absent = lifecycle.before
	pending_teardown = lifecycle.pending_teardown
	checks.lifecycle = lifecycle.checks
	departure_lifecycle = lifecycle.departure
	observer_lifecycle = lifecycle.observers
	audio_lifecycle = lifecycle.audio
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
	return {"sampled":sampled,"controls_absent":controls_absent,"pending_teardown":pending_teardown,"departure_lifecycle":departure_lifecycle,"observer_lifecycle":observer_lifecycle,"audio_lifecycle":audio_lifecycle,"checks":checks}

static func qualify_live_inputs(router: Node) -> Dictionary:
	# Call only in an opted-in probe or from the runtime reader. No commands,
	# preference applications, seeking, saves or history snapshots with side effects.
	if not is_instance_valid(router) or not is_instance_valid(router.state):
		return {"ready":false,"reason":"entry/state unavailable","checks":{}}
	var state: Node = router.state
	var facts: Dictionary = state.training_snapshot().duplicate(true)
	var preferences: Dictionary = state.preference_snapshot()
	var audio_before: Dictionary = state.audio_observation()
	var audio: Dictionary = router.audio._mcp_state() if is_instance_valid(router.audio) else {"ready":false}
	var entry: Dictionary = router._mcp_state()
	var opening: Dictionary = router.opening._mcp_state() if is_instance_valid(router.opening) else {"ready":false}
	var repeated: Dictionary = router.opening._mcp_state() if is_instance_valid(router.opening) else {"ready":false}
	var checks := {
		"facts_preserved":facts == state.training_snapshot(),
		"preferences_preserved":preferences == state.preference_snapshot(),
		"audio_configuration_preserved":audio_before == state.audio_observation(),
		"audio_readiness_explicit":audio.get("ready") is bool,
		"separate_live_routes":not audio.get("ready",false) or audio.get("voice_bus") == "Effects" and audio.get("music_bus") == "Music",
		"entry_readiness_explicit":entry.get("ready") is bool and entry.get("player_ready") is bool,
		"opening_readiness_explicit":opening.get("ready") is bool,
		"opening_read_does_not_advance":opening.get("elapsed") == repeated.get("elapsed") and opening.get("beat") == repeated.get("beat"),
		"qualified_opening_fields":not opening.get("ready",false) or opening.has_all(["beat","beat_elapsed","elapsed","pause_owners","timeline_paused","inputs_armed","finished"])}
	var live: Dictionary = preload("res://tests/entry_lifecycle_test.gd").live_read_checks(router)
	return {"ready":true,"checks":checks,"audio":audio,"output":audio_before,"opening":opening,"route":entry.get("route"),"control_ready":entry.get("departure_control_ready"),"observations":live.get("observations", {}),"live_observation_ready":live.get("ready", false)}
