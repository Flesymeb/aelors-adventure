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
	var departure: Dictionary = departure_lifecycle_checks()
	checks.merge(departure.checks)
	return {"checks": checks, "before": before, "pending_teardown": pending, "departure": departure}


static func departure_lifecycle_checks() -> Dictionary:
	# Actual callbacks, detached and disabled: no product startup/save/audio.
	var router: Node = preload("res://ui/game_entry_router.gd").new()
	var world: Node = preload("res://preview_controller.gd").new()
	var transition: Node = preload("res://ui/chapter_transition.gd").new()
	router.world = world
	router.source_world = world
	router.transition = transition
	router.destination_map = preload("res://world/map02_ground.gd").MAP02_ID
	router.route = "travel_story"
	var direct_before: Dictionary = transition._mcp_state()
	var world_before: Dictionary = world._mcp_state()
	var before: Dictionary = router._mcp_state()
	var unchanged: bool = before == router._mcp_state() and direct_before == transition._mcp_state() and world_before == world._mcp_state()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	transition.process_mode = Node.PROCESS_MODE_DISABLED
	world.queue_free()
	transition.queue_free()
	var direct_pending: Dictionary = transition._mcp_state()
	var world_pending: Dictionary = world._mcp_state()
	var pending: Dictionary = router._mcp_state()
	# Free immediately to exercise invalid handles, then leave the persistent
	# owner alive. Both before and pending callbacks use the real scripts.
	world.free()
	transition.free()
	var absent: Dictionary = router._mcp_state()
	var checks := {
		"departure_initial_projection": before.departure_phase == direct_before.phase and before.departure_transition_ready == false,
		"departure_actual_world_callback": before.departure_controls_present == world_before.controls_ready and before.departure_control_ready == false,
		"departure_read_only": unchanged and router.route == "travel_story",
		"departure_pending_direct_unready": direct_pending.ready == false and world_pending.ready == false,
		"departure_pending_null": pending.departure_phase == null and pending.departure_transition_ready == null and pending.departure_control_ready == null,
		"departure_invalid_handles_null": absent.departure_phase == null and absent.departure_world_ready == null and absent.departure_controls_present == null,
		"departure_owner_boundary_survives": absent.route == "travel_story" and absent.departure_destination == before.departure_destination and absent.departure_transition_present == false and absent.departure_source_present == false,
		"departure_no_state_assumption": before.departure_current_map == null and absent.departure_cp02_claimed == null and absent.departure_lives == null}
	router.free()
	return {"checks":checks,"before":before,"direct_before":direct_before,"world_before":world_before,"pending":pending,"direct_pending":direct_pending,"world_pending":world_pending,"absent":absent}

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
		if path == "ui/illustrated_opening.gd":
			checks.opening_skip_initial = initial.skip_hold == 0.0 and initial.pause_menu_present == false
			checks.opening_streams_unavailable = initial.music_playing == null and initial.music_paused == null and initial.ambience_paused == null and initial.cue_paused == null
		if path == "ui/menu_audio.gd":
			checks.menu_streams_unavailable = initial.music_position == null and initial.music_paused == null and initial.voice_paused == null
		if path == "ui/title_settings.gd":
			checks.settings_focus_unavailable = initial.focus_name == null and pending.focus_name == null
	checks.merge(detached_audio_checks())
	return checks

static func detached_audio_checks() -> Dictionary:
	# Exercise real assigned dependencies and freed handles without entering the
	# tree, playing audio, invoking _ready, or loading/writing user preferences.
	# Standalone probes have no AdventureState _ready to register audio buses.
	# Godot exposes Master for an unregistered requested bus; measure that
	# boundary without creating buses. Live routing is checked separately below.
	var music_bus_index := AudioServer.get_bus_index("Music")
	var effects_bus_index := AudioServer.get_bus_index("Effects")
	var bus_count := AudioServer.bus_count
	var expected_music_bus := "Music" if music_bus_index >= 0 else "Master"
	var expected_voice_bus := "Effects" if effects_bus_index >= 0 else "Master"
	var observer: Node = preload("res://ui/menu_audio.gd").new()
	observer.state = preload("res://dialogue_state.gd").new()
	observer.music = AudioStreamPlayer.new()
	observer.music.bus = "Music"
	observer.voice = AudioStreamPlayer.new()
	observer.voice.bus = "Effects"
	var before: Dictionary = observer._mcp_state()
	var repeated: Dictionary = observer._mcp_state()
	observer.music.free()
	observer.voice.free()
	var freed_streams: Dictionary = observer._mcp_state()
	observer.state.free()
	var freed_state: Dictionary = observer._mcp_state()
	observer.free()
	return {"detached_audio_read_only": before == repeated,
		"detached_audio_not_started": before.ready == false and before.music_playing == false and before.playing == false,
		"detached_audio_routes": before.music_bus == expected_music_bus and before.voice_bus == expected_voice_bus,
		"detached_audio_bus_registry_unchanged": AudioServer.bus_count == bus_count and AudioServer.get_bus_index("Music") == music_bus_index and AudioServer.get_bus_index("Effects") == effects_bus_index,
		"freed_streams_unavailable": freed_streams.ready == false and freed_streams.music_position == null and freed_streams.music_paused == null and freed_streams.voice_paused == null,
		"freed_audio_state_unavailable": freed_state.ready == false and freed_state.muted == null}

static func live_read_checks(router: Node) -> Dictionary:
	# Opt-in check of the actual current entry boundary. Do not call the mutable
	# adventure_snapshot() helper or apply preferences while measuring reads.
	var state: Node = router.state
	var preferences: Dictionary = state.preference_snapshot()
	var history: Dictionary = state.training_snapshot().duplicate(true)
	var choices: Array = state.confirmed_choices.duplicate(true)
	var route: String = router.route
	var observed: Dictionary = router._mcp_state()
	var departure_before: Dictionary = router._departure_observation()
	var departure_after: Dictionary = router._departure_observation()
	var audio_before: Dictionary = router.audio._mcp_state()
	var audio_after: Dictionary = router.audio._mcp_state()
	var checks := {"router_ready_shape": observed.ready == true and observed.route == route,
		"audio_ready_shape": audio_before.ready == true and audio_before.music_bus == "Music" and audio_before.voice_bus == "Effects",
		"preferences_unchanged": state.preference_snapshot() == preferences,
		"history_unchanged": state.training_snapshot() == history and state.confirmed_choices == choices,
		"route_unchanged": router.route == route,
		"departure_read_only": departure_before == departure_after,
		"departure_nullable_shape": [null, true, false].has(departure_before.departure_transition_ready) and [null, true, false].has(departure_before.departure_control_ready),
		"playback_not_reset": audio_after.music_position >= audio_before.music_position and audio_after.music_playing == audio_before.music_playing,
		"audio_pause_unchanged": audio_after.music_paused == audio_before.music_paused and audio_after.voice_paused == audio_before.voice_paused and audio_after.last_cue == audio_before.last_cue}
	if is_instance_valid(router.opening):
		var opening: Node = router.opening
		var before: Dictionary = opening._mcp_state()
		var after: Dictionary = opening._mcp_state()
		checks.opening_ready_shape = before.ready == true and before.beat is int and before.image is String
		checks.opening_clock_unchanged = before.elapsed == after.elapsed and before.beat_elapsed == after.beat_elapsed and before.finished == after.finished
		checks.opening_pause_unchanged = before.pause_owners == after.pause_owners and before.timeline_paused == after.timeline_paused
		checks.opening_skip_unchanged = before.skip_hold == after.skip_hold and before.inputs_armed == after.inputs_armed and before.pause_menu_present == after.pause_menu_present
		checks.opening_audio_unchanged = before.music_playing == after.music_playing and before.music_paused == after.music_paused and before.ambience_paused == after.ambience_paused and before.cue_paused == after.cue_paused
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
