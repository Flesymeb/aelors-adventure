extends RefCounted
## Explicit diagnostic only; never attached to the normal entry path.
static func run(_holder: Node) -> Dictionary:
	var world := preload("res://preview_controller.gd").new()
	var before: Dictionary = world._mcp_state()
	var unchanged: Dictionary = world._mcp_state()
	# Retain the actual object through the queued-deletion boundary. Disable
	# processing and avoid _ready: this test must not construct a second world.
	world.process_mode = Node.PROCESS_MODE_DISABLED
	world.queue_free()
	var pending: Dictionary = world._mcp_state()
	var checks := {"controls_absent": before.controls_ready == false and before.controls_visible == null and before.controls_submenu == null,
		"player_absent": before.player_ready == false and before.player_position == null,
		"read_only": before == unchanged,
		"pending_teardown": world.is_queued_for_deletion() and pending.ready == false and pending.controls_visible == null,
		"unavailable_state": before.preferences == null and before.objective == null and pending.tree_paused == null}
	checks.merge(observer_lifecycle_checks())
	return {"checks": checks, "before": before, "pending_teardown": pending}

static func observer_lifecycle_checks() -> Dictionary:
	# These are real observation implementations with no _ready invocation,
	# world construction, playback or save writes in the isolated fixture.
	var checks := {}
	for path in ["ui/game_entry_router.gd", "ui/illustrated_opening.gd", "ui/chapter_transition.gd", "ui/title_settings.gd", "ui/menu_audio.gd", "world/map02_entry.gd"]:
		var observer: Node = load("res://" + path).new()
		var initial: Dictionary = observer._mcp_state()
		var repeated: Dictionary = observer._mcp_state()
		observer.process_mode = Node.PROCESS_MODE_DISABLED
		observer.queue_free()
		var pending: Dictionary = observer._mcp_state()
		checks[path + "_initial_shape"] = initial.has("ready") and initial.ready == false
		checks[path + "_read_only"] = initial == repeated
		checks[path + "_pending_teardown"] = observer.is_queued_for_deletion() and pending.ready == false
	return checks

static func live_read_checks(router: Node) -> Dictionary:
	# Opt-in check of the actual current entry boundary. Do not call the mutable
	# adventure_snapshot() helper or apply preferences while measuring reads.
	var state: Node = router.state
	var preferences: Dictionary = state.preference_snapshot()
	var history: Dictionary = state.training_snapshot().duplicate(true)
	var choices: Array = state.confirmed_choices.duplicate(true)
	var route: String = router.route
	var observed: Dictionary = router._mcp_state()
	var audio_before: Dictionary = router.audio._mcp_state()
	var audio_after: Dictionary = router.audio._mcp_state()
	var checks := {"router_ready_shape": observed.ready == true and observed.route == route,
		"audio_ready_shape": audio_before.ready == true and audio_before.music_bus == "Music" and audio_before.voice_bus == "Effects",
		"preferences_unchanged": state.preference_snapshot() == preferences,
		"history_unchanged": state.training_snapshot() == history and state.confirmed_choices == choices,
		"route_unchanged": router.route == route,
		"playback_not_reset": audio_after.music_position >= audio_before.music_position and audio_after.music_playing == audio_before.music_playing}
	if is_instance_valid(router.opening):
		var opening: Node = router.opening
		var before: Dictionary = opening._mcp_state()
		var after: Dictionary = opening._mcp_state()
		checks.opening_ready_shape = before.ready == true and before.beat is int and before.image is String
		checks.opening_clock_unchanged = before.elapsed == after.elapsed and before.beat_elapsed == after.beat_elapsed and before.finished == after.finished
		checks.opening_pause_unchanged = before.pause_owners == after.pause_owners and before.timeline_paused == after.timeline_paused
	for node in router.find_children("*", "Control", true, false):
		var script: Script = node.get_script()
		if script == null or script.resource_path != "res://ui/title_settings.gd": continue
		var before: Dictionary = node._mcp_state()
		var after: Dictionary = node._mcp_state()
		checks.settings_ready_shape = before.ready == true and before.preferences is Dictionary and before.bindings is Dictionary
		checks.settings_read_only = before == after
	# Compare after every observer has run, including nested opening/settings.
	checks.preferences_unchanged = state.preference_snapshot() == preferences
	checks.history_unchanged = state.training_snapshot() == history and state.confirmed_choices == choices
	checks.route_unchanged = router.route == route
	return {"checks": checks, "route": route}
