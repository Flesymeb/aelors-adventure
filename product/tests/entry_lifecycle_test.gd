extends RefCounted
## Explicit diagnostic only; never attached to the normal entry path.
static func settings_audio_lifecycle_checks() -> Dictionary:
	# Assign disposable dependencies while detached. Never enter the tree,
	# register buses, apply/load preferences, or start/pause/seek playback.
	var state: Node = preload("res://dialogue_state.gd").new()
	var host: Control = preload("res://ui/title_menu.gd").new()
	host.state = state
	var settings: Node = preload("res://ui/title_settings.gd").new()
	settings.host = host
	var audio: Node = preload("res://ui/menu_audio.gd").new()
	audio.state = state
	audio.music = AudioStreamPlayer.new()
	audio.voice = AudioStreamPlayer.new()
	var before := {"settings": boundary_comparison(settings), "audio": boundary_comparison(audio)}
	settings.queue_free()
	audio.queue_free()
	var pending := {"settings": boundary_comparison(settings), "audio": boundary_comparison(audio)}
	var checks: Dictionary = lifecycle_comparison_checks(before, pending)
	checks.settings_preferences_available = before.settings.before.preferences is Dictionary
	checks.settings_preferences_preserved = before.settings.direct_before.preferences == pending.settings.direct_after.preferences
	checks.settings_focus_unavailable = before.settings.before.focus_name == null and pending.settings.before.focus_name == null
	checks.audio_not_started = before.audio.before.music_playing == false and before.audio.before.playing == false
	checks.audio_preferences_preserved = before.audio.direct_before.preferences == pending.audio.direct_after.preferences
	checks.audio_registry_preserved = before.audio.direct_before.buses == pending.audio.direct_after.buses and before.audio.direct_before.bus_count == pending.audio.direct_after.bus_count
	var result := {"selection": "settings_audio", "pre_ready": before, "pending_teardown": pending, "checks": checks}
	audio.music.free()
	audio.voice.free()
	settings.free()
	audio.free()
	host.free()
	state.free()
	return result

static func opening_router_lifecycle_checks() -> Dictionary:
	# The real router/opening callbacks run against detached state. No startup,
	# rollback/history write, playback advancement or opening completion occurs.
	var state: Node = preload("res://dialogue_state.gd").new()
	var router: Node = preload("res://ui/game_entry_router.gd").new()
	var opening: Node = preload("res://ui/illustrated_opening.gd").new()
	router.state = state
	router.opening = opening
	opening.state = state
	opening.router = router
	var before := {"router": boundary_comparison(router), "opening": boundary_comparison(opening)}
	router.queue_free()
	opening.queue_free()
	var pending := {"router": boundary_comparison(router), "opening": boundary_comparison(opening)}
	var checks: Dictionary = lifecycle_comparison_checks(before, pending)
	checks.opening_timeline_preserved = before.opening.direct_before.elapsed == pending.opening.direct_after.elapsed and before.opening.direct_before.beat_elapsed == pending.opening.direct_after.beat_elapsed and before.opening.direct_before.beat_index == pending.opening.direct_after.beat_index
	checks.opening_unavailable = before.opening.before.beat == null and before.opening.before.image == null and pending.opening.before.beat == null
	checks.opening_streams_unavailable = before.opening.before.music_playing == null and pending.opening.before.music_playing == null
	checks.router_history_preserved = before.router.direct_before.history == pending.router.direct_after.history and before.router.direct_before.previous_history == pending.router.direct_after.previous_history and before.router.direct_before.confirmed_choices == pending.router.direct_after.confirmed_choices
	checks.router_preferences_preserved = before.router.direct_before.preferences == pending.router.direct_after.preferences
	checks.opening_history_preserved = before.opening.direct_before.history == pending.opening.direct_after.history and before.opening.direct_before.opening_completed == pending.opening.direct_after.opening_completed
	checks.router_not_initialized = before.router.direct_before.initialized == false and pending.router.direct_after.initialized == false
	var result := {"selection": "opening_router", "pre_ready": before, "pending_teardown": pending, "checks": checks}
	opening.free()
	router.free()
	state.free()
	return result

static func boundary_comparison(owner: Node) -> Dictionary:
	# Each boundary retains raw measurements independently from assertions.
	var direct_before: Dictionary = direct_owner_fields(owner)
	var before: Dictionary = owner._mcp_state()
	var after: Dictionary = owner._mcp_state()
	return {"direct_before": direct_before, "before": before, "after": after, "direct_after": direct_owner_fields(owner)}

static func lifecycle_comparison_checks(before: Dictionary, pending: Dictionary) -> Dictionary:
	var checks := {}
	for name in before:
		for boundary in ["pre_ready", "pending_teardown"]:
			var comparison: Dictionary = before[name] if boundary == "pre_ready" else pending[name]
			var key: String = str(name) + "_" + boundary
			checks[key + "_read_only"] = comparison.before == comparison.after
			checks[key + "_owner_preserved"] = stable_raw_fields(comparison.direct_before) == stable_raw_fields(comparison.direct_after)
			checks[key + "_unready"] = comparison.before.get("ready") == false and comparison.after.get("ready") == false
			checks[key + "_detached"] = comparison.direct_before.inside_tree == false and comparison.direct_after.inside_tree == false
			checks[key + "_queued_boundary"] = comparison.direct_before.queued_for_deletion == (boundary == "pending_teardown") and comparison.direct_after.queued_for_deletion == (boundary == "pending_teardown")
	return checks

static func stable_raw_fields(value: Variant) -> Variant:
	# Timestamps remain in raw output, but are not owner-state mutations.
	if value is Dictionary:
		var result := {}
		for key in value:
			if key != "sample_us": result[key] = stable_raw_fields(value[key])
		return result
	if value is Array:
		var result := []
		for item in value: result.append(stable_raw_fields(item))
		return result
	return value

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
	var observers: Dictionary = observer_lifecycle_checks()
	checks.merge(observers.checks)
	var isha: Dictionary = isha_observer_checks()
	checks.merge(isha.checks)
	var departure: Dictionary = departure_lifecycle_checks()
	checks.merge(departure.checks)
	return {"checks": checks, "before": before, "pending_teardown": pending, "departure": departure, "isha": isha, "observers": observers.observations, "audio": observers.audio}


static func isha_observer_checks() -> Dictionary:
	# Detached real actor/player: no actor _ready, model import, world build,
	# conversation, progression or saves. Only this explicit fixture drives the
	# tiny clip; repeated observations must never assign, seek or start it.
	var actor: Node = preload("res://isha_npc.gd").new()
	var absent: Dictionary = actor._mcp_state()
	actor.idle_player = AnimationPlayer.new()
	actor.add_child(actor.idle_player)
	var initial: Dictionary = actor._mcp_state()
	var initial_repeated: Dictionary = actor._mcp_state()
	var library := AnimationLibrary.new()
	var clip := Animation.new()
	clip.length = 3.5
	clip.loop_mode = Animation.LOOP_LINEAR
	library.add_animation("Isha_Idle", clip)
	actor.idle_player.add_animation_library("", library)
	actor.idle_player.play("Isha_Idle")
	actor.idle_player.advance(0.625)
	var assigned: String = actor.idle_player.assigned_animation
	var playing: bool = actor.idle_player.is_playing()
	var initialized: Dictionary = actor._mcp_state()
	var initialized_repeated: Dictionary = actor._mcp_state()
	var playback_preserved: bool = actor.idle_player.assigned_animation == assigned and actor.idle_player.is_playing() == playing
	actor.idle_player.pause()
	var paused: Dictionary = actor._mcp_state()
	var paused_repeated: Dictionary = actor._mcp_state()
	var paused_preserved: bool = not actor.idle_player.is_playing() and actor.idle_player.assigned_animation == assigned
	actor.idle_player.stop()
	var stopped: Dictionary = actor._mcp_state()
	actor.idle_player.free()
	var freed: Dictionary = actor._mcp_state()
	actor.free()
	return {"checks": {
		"isha_absent_animation_unavailable": absent.idle_animation_ready == false and absent.idle_clip == null and absent.idle_position == null,
		"isha_unassigned_animation_unavailable": initial.idle_animation_ready == false and initial.idle_clip == null and initial.idle_position == null,
		"isha_unassigned_observation_read_only": initial == initial_repeated,
		"isha_initialized_idle_available": initialized.idle_animation_ready == true and initialized.idle_clip == "Isha_Idle" and is_equal_approx(initialized.idle_position, 0.625),
		"isha_initialized_playback_read_only": initialized == initialized_repeated and playback_preserved,
		"isha_paused_playback_read_only": paused == paused_repeated and paused_preserved,
		"isha_stopped_animation_unavailable": stopped.idle_animation_ready == false and stopped.idle_position == null,
		"isha_freed_animation_unavailable": freed.idle_animation_ready == false and freed.idle_clip == null and freed.idle_position == null},
		"absent": absent, "unassigned": initial, "initialized": initialized, "paused": paused, "stopped": stopped, "freed": freed}


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
	var observations := {}
	for path in ["ui/game_entry_router.gd", "ui/illustrated_opening.gd", "ui/chapter_transition.gd", "ui/title_settings.gd", "ui/menu_audio.gd", "world/map02_entry.gd", "world/chapter_pillar.gd"]:
		var observer: Node = load("res://" + path).new()
		var direct_before: Dictionary = direct_owner_fields(observer)
		var initial: Dictionary = observer._mcp_state()
		var repeated: Dictionary = observer._mcp_state()
		var direct_after: Dictionary = direct_owner_fields(observer)
		observer.process_mode = Node.PROCESS_MODE_DISABLED
		observer.queue_free()
		var pending: Dictionary = observer._mcp_state()
		observations[path] = {"direct_before": direct_before, "initial": initial, "repeated": repeated, "direct_after": direct_after, "pending": pending, "direct_pending": direct_owner_fields(observer)}
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
		if path == "world/chapter_pillar.gd":
			checks.pillar_unavailable = initial.active == null and initial.player_distance == null and initial.player_in_range == null and initial.interaction_eligible == null and pending.interaction_eligible == null
	var audio: Dictionary = detached_audio_checks()
	checks.merge(audio.checks)
	return {"checks": checks, "observations": observations, "audio": audio.observations}

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
	var direct_before: Dictionary = direct_owner_fields(observer)
	var before: Dictionary = observer._mcp_state()
	var repeated: Dictionary = observer._mcp_state()
	var direct_after: Dictionary = direct_owner_fields(observer)
	observer.music.free()
	observer.voice.free()
	var freed_streams: Dictionary = observer._mcp_state()
	observer.state.free()
	var freed_state: Dictionary = observer._mcp_state()
	observer.free()
	return {"checks": {"detached_audio_read_only": before == repeated,
		"detached_audio_not_started": before.ready == false and before.music_playing == false and before.playing == false,
		"detached_audio_routes": before.music_bus == expected_music_bus and before.voice_bus == expected_voice_bus,
		"detached_audio_bus_registry_unchanged": AudioServer.bus_count == bus_count and AudioServer.get_bus_index("Music") == music_bus_index and AudioServer.get_bus_index("Effects") == effects_bus_index,
		"freed_streams_unavailable": freed_streams.ready == false and freed_streams.music_position == null and freed_streams.music_paused == null and freed_streams.voice_paused == null,
		"freed_audio_state_unavailable": freed_state.ready == false and freed_state.muted == null}, "observations": {"direct_before": direct_before, "before": before, "repeated": repeated, "direct_after": direct_after, "freed_streams": freed_streams, "freed_state": freed_state}}

static func live_read_checks(router: Node) -> Dictionary:
	# Opt-in check of the actual current entry boundary. Do not call the mutable
	# adventure_snapshot() helper or apply preferences while measuring reads.
	if not is_instance_valid(router):
		return {"ready": false, "reason": "entry unavailable", "checks": {}, "observations": {}}
	if not router.is_inside_tree() or not router.is_node_ready() or router.is_queued_for_deletion() or not is_instance_valid(router.state) or router.state.is_queued_for_deletion() or not is_instance_valid(router.audio) or router.audio.is_queued_for_deletion():
		return {"ready": false, "reason": "live entry/state/audio unavailable", "checks": {}, "observations": {"direct": direct_owner_fields(router)}}
	var state: Node = router.state
	var direct_before: Dictionary = direct_owner_fields(router)
	var preferences: Dictionary = state.preference_snapshot()
	var history: Dictionary = state.training_snapshot().duplicate(true)
	var choices: Array = state.confirmed_choices.duplicate(true)
	var route: String = router.route
	var tree_paused: bool = router.get_tree().paused
	var mouse_mode: int = Input.mouse_mode
	var focused: Control = router.get_viewport().gui_get_focus_owner()
	var observed: Dictionary = router._mcp_state()
	var departure_before: Dictionary = router._departure_observation()
	var departure_after: Dictionary = router._departure_observation()
	var audio_before: Dictionary = router.audio._mcp_state()
	var audio_after: Dictionary = router.audio._mcp_state()
	var observations := {"direct_before": direct_before, "router": observed, "departure_before": departure_before, "departure_after": departure_after, "audio_before": audio_before, "audio_after": audio_after, "settings": {}}
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
		var opening_direct_before: Dictionary = direct_owner_fields(opening)
		var before: Dictionary = opening._mcp_state()
		var after: Dictionary = opening._mcp_state()
		observations.opening = {"direct_before": opening_direct_before, "before": before, "after": after, "direct_after": direct_owner_fields(opening)}
		checks.router_opening_matches_leaf = observed.opening == before
		checks.opening_ready_shape = before.ready == true and before.beat is int and before.image is String
		checks.opening_clock_unchanged = before.elapsed == after.elapsed and before.beat_elapsed == after.beat_elapsed and before.finished == after.finished
		checks.opening_pause_unchanged = before.pause_owners == after.pause_owners and before.timeline_paused == after.timeline_paused
		checks.opening_skip_unchanged = before.skip_hold == after.skip_hold and before.inputs_armed == after.inputs_armed and before.pause_menu_present == after.pause_menu_present
		checks.opening_audio_unchanged = before.music_playing == after.music_playing and before.music_paused == after.music_paused and before.ambience_paused == after.ambience_paused and before.cue_paused == after.cue_paused
	for node in router.find_children("*", "Control", true, false):
		var script: Script = node.get_script()
		if script == null or script.resource_path != "res://ui/title_settings.gd": continue
		var settings_direct_before: Dictionary = direct_owner_fields(node)
		var before: Dictionary = node._mcp_state()
		var after: Dictionary = node._mcp_state()
		observations.settings[str(node.get_path())] = {"direct_before": settings_direct_before, "before": before, "after": after, "direct_after": direct_owner_fields(node)}
		checks.settings_ready_shape = before.ready == true and before.preferences is Dictionary and before.bindings is Dictionary
		checks.settings_read_only = before == after
	# Compare after every observer has run, including nested opening/settings.
	checks.preferences_unchanged = state.preference_snapshot() == preferences
	checks.history_unchanged = state.training_snapshot() == history and state.confirmed_choices == choices
	checks.route_unchanged = router.route == route
	checks.pause_input_ownership_preserved = router.get_tree().paused == tree_paused and Input.mouse_mode == mouse_mode and router.get_viewport().gui_get_focus_owner() == focused
	observations.direct_after = direct_owner_fields(router)
	return {"ready": true, "checks": checks, "route": route, "observations": observations}

static func direct_owner_fields(owner: Node) -> Dictionary:
	# Independent raw reads in the opted-in fixture: no observer methods, bus
	# application, timeline advancement, snapshot mutation, playback or file I/O.
	var result := {"sample_us": Time.get_ticks_usec(), "bus_count": AudioServer.bus_count, "buses": {}}
	for bus in ["Master", "Music", "Effects"]:
		var index := AudioServer.get_bus_index(bus)
		var data := {"index": index, "available": index >= 0, "volume_db": null, "muted": null, "bypassed": null, "send": null, "effects": null}
		if index >= 0:
			data.merge({"volume_db": AudioServer.get_bus_volume_db(index), "muted": AudioServer.is_bus_mute(index), "bypassed": AudioServer.is_bus_bypassing_effects(index), "send": str(AudioServer.get_bus_send(index)), "effects": []}, true)
			for effect_index in AudioServer.get_bus_effect_count(index):
				var effect := AudioServer.get_bus_effect(index, effect_index)
				data.effects.append({"name": effect.resource_name, "enabled": AudioServer.is_bus_effect_enabled(index, effect_index), "gain_db": effect.volume_db if effect is AudioEffectAmplify else null})
		result.buses[bus] = data
	if not is_instance_valid(owner): return result
	result.merge({"inside_tree": owner.is_inside_tree(), "node_ready": owner.is_node_ready(), "queued_for_deletion": owner.is_queued_for_deletion()})
	var script: Script = owner.get_script()
	var script_path: String = script.resource_path
	# The disposable adventure overrides persistence through a router subclass.
	# Walk actual inheritance rather than losing direct baselines for that owner.
	while script_path not in ["res://ui/game_entry_router.gd", "res://ui/title_settings.gd", "res://ui/menu_audio.gd", "res://ui/illustrated_opening.gd"] and script.get_base_script() != null:
		script = script.get_base_script()
		script_path = script.resource_path
	var state: Node
	if script_path == "res://ui/game_entry_router.gd":
		state = owner.state
		result.merge({"route": owner.route, "initialized": owner.initialized, "player_ready": owner.player_ready, "previous_history": owner.previous_history.duplicate(true), "tree_paused": owner.get_tree().paused if owner.is_inside_tree() else null})
		result.audio = direct_owner_fields(owner.audio) if is_instance_valid(owner.audio) else null
		result.opening = direct_owner_fields(owner.opening) if is_instance_valid(owner.opening) else null
	elif script_path == "res://ui/title_settings.gd":
		state = owner.host.state if is_instance_valid(owner.host) else null
		result.merge({"group": owner.group, "capturing": owner.capturing})
	elif script_path == "res://ui/menu_audio.gd" or script_path == "res://ui/illustrated_opening.gd":
		state = owner.state
		var channels := ["music", "voice"] if script_path == "res://ui/menu_audio.gd" else ["music", "ambience", "cue"]
		result.streams = {}
		for channel in channels:
			var player: AudioStreamPlayer = owner.get(channel)
			result.streams[channel] = {"bus": str(player.bus), "playing": player.playing, "paused": player.stream_paused, "position": player.get_playback_position(), "volume_db": player.volume_db} if is_instance_valid(player) and not player.is_queued_for_deletion() else null
		if script_path == "res://ui/menu_audio.gd": result.last_cue = owner.last_cue
		else:
			result.merge({"beat_index": owner.beat, "beat_elapsed": owner.elapsed, "elapsed": owner.total_elapsed, "finished": owner.finished, "inputs_armed": owner.inputs_armed, "skip_hold": owner.skip_hold, "pause_menu_present": is_instance_valid(owner.pause_menu) and not owner.pause_menu.is_queued_for_deletion()})
	result.merge({"state_available": is_instance_valid(state) and not state.is_queued_for_deletion(), "preferences": null, "preference_error": null, "history": null, "confirmed_choices": null, "opening_completed": null})
	if result.state_available:
		result.preferences = {}
		for key in state.PREFERENCE_DEFAULTS: result.preferences[key] = state.get(key)
		result.preference_error = state.preference_error
		result.history = {}
		for key in state.TRAINING_KEYS: result.history[key] = state.get(key)
		for key in state.POST_DEFAULTS: result.history[key] = state.get(key)
		result.history = result.history.duplicate(true)
		result.confirmed_choices = state.confirmed_choices.duplicate(true)
		result.opening_completed = state.opening_completed
	return result
