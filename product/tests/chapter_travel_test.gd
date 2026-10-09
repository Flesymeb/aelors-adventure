extends RefCounted
## Isolated logic checks; no progression or player-save writes on normal startup.
const STATE = preload("res://dialogue_state.gd")
const GUARDS = preload("res://tests/channel_guard_test.gd")
const BRIDGE = preload("res://tests/bridge_actions_test.gd")

static func earned() -> Node:
	var s := GUARDS.prepared()
	for id in s.GUARD_IDS: s.settle_guard(id, Vector3(133,11,142), {"id":"healing","quantity":1})
	return s

static func history(s: Node) -> ConfigFile:
	var c := BRIDGE.config_for(s)
	c.set_value("opening", "experience", s.experience)
	c.set_value("opening", "map_id", s.current_map)
	return c

static func run() -> Dictionary:
	var checks := {}
	var s := earned()
	var xp: int = s.experience
	checks.earned_farewell_only = s.departure_available() and s.passage_missing_conditions() == ["与伊莎确认离村"]
	s.dialogue_kind = "isha"
	s.begin()
	checks.readable_choice = s.logical_node == "G04" and s.current_nodes().G04.choices.size() == 2
	checks.consent = s.choose(0) and s.departure_confirmed and s.passage_missing_conditions().is_empty() and s.experience == xp
	var source := history(s)
	checks.source_valid = s.config_unavailable_reason(source) == ""
	var first_lives: int = s.lives
	checks.arrival = s.commit_arrival(s.MAP02) and s.current_map == s.MAP02 and s.cp02_claimed and s.lives == first_lives + 1 and s.experience == xp
	checks.repeat_arrival = s.commit_arrival(s.MAP02) and s.lives == first_lives + 1
	var destination := history(s)
	checks.destination_valid = s.config_unavailable_reason(destination) == ""
	var restored := STATE.new()
	var position: Dictionary = restored.restore_config(destination)
	checks.continue_map = position.map_id == s.MAP02 and restored.current_map == s.MAP02 and restored.cp02_claimed and restored.lives == s.lives
	checks.continue_no_claim = restored.commit_arrival(s.MAP02) and restored.lives == s.lives
	checks.return_both_directions = restored.commit_arrival(s.GROUND.MAP_ID) and restored.commit_arrival(s.MAP02) and restored.lives == s.lives
	restored.restore_config(source)
	checks.interrupted_source = restored.current_map == s.GROUND.MAP_ID and not restored.cp02_claimed and restored.lives == first_lives and restored.departure_confirmed
	checks.merge(resource_checks())
	checks.merge(collision_handoff_checks())
	destination.set_value("post_bow", "cp02_claimed", false)
	checks.reject_unsafe_map = s.config_unavailable_reason(destination) != ""
	s.free()
	restored.free()
	var unearned := STATE.new()
	unearned.logical_node = "G04"
	checks.no_unearned_consent = not unearned.choose(0) and not unearned.departure_confirmed
	unearned.free()
	return checks

static func resource_checks() -> Dictionary:
	var transition = preload("res://ui/chapter_transition.gd")
	var checks := {"departure_media_available": transition.available()}
	var storyboard: Variant = JSON.parse_string(FileAccess.get_file_as_string(transition.ART + "storyboard.json"))
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(transition.ART + "SOURCE.json"))
	checks.provenance = source is Dictionary and source.get("origin") == "generated" and source.get("usage_terms", "") != "" and source.get("files", []).size() == 3
	var referenced: Array = []
	var duration := 0.0
	if storyboard is Dictionary:
		for slide in storyboard.get("slides", []):
			referenced.append(slide.image)
			duration += float(slide.duration_seconds)
	checks.three_distinct_beats = referenced == ["farewell.png", "passage.png", "arrival.png"]
	checks.provenance_references = source is Dictionary and source.get("files", []).map(func(record): return record.get("file", "")) == referenced
	checks.bounded_playback = duration >= 3.0 and duration <= 6.0
	for file in ["farewell.png", "passage.png", "arrival.png"]:
		var texture := load(transition.ART + file) as Texture2D
		checks[file + "_imported"] = texture != null and texture.get_size() == Vector2(1672, 941)
	return checks

static func collision_handoff_checks() -> Dictionary:
	var router := preload("res://ui/game_entry_router.gd").new()
	var source := preload("res://preview_controller.gd").new()
	# A minimal fixture with the real forest's exposed physics properties.
	var village := Node3D.new()
	var terrain := StaticBody3D.new()
	terrain.name = "Terrain3D"
	village.add_child(terrain)
	source.add_child(village)
	source.village = village
	var actor := StaticBody3D.new()
	actor.collision_layer = 5
	actor.collision_mask = 3
	source.add_child(actor)
	router.source_world = source
	router._suspend_source_collision()
	var checks := {"source_collision_suspended":actor.collision_layer == 0 and actor.collision_mask == 0 and terrain.collision_layer == 0}
	router._restore_source_collision()
	checks.source_collision_restored = actor.collision_layer == 5 and actor.collision_mask == 3 and terrain.collision_layer == 1 and router.source_collision_state.is_empty()
	source.free()
	router.free()
	return checks
