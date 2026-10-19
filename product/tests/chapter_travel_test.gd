extends RefCounted
## Isolated logic checks; no progression or player-save writes on normal startup.
const STATE = preload("res://dialogue_state.gd")
const GUARDS = preload("res://tests/channel_guard_test.gd")
const BRIDGE = preload("res://tests/bridge_actions_test.gd")

class DiagnosticState extends "res://dialogue_state.gd":
	var diagnostic_save_requests := 0
	var diagnostic_commits: Array[Dictionary] = []
	func _ready() -> void:
		# No preferences, histories or file writes in this opt-in fixture.
		inventory = preload("res://inventory/product_inventory.gd").new()
		inventory.state = self
		add_child(inventory)
	func save_progress(_position: Vector3, _yaw: float, _slot := 0) -> Error:
		diagnostic_save_requests += 1
		diagnostic_commits.append(training_snapshot().duplicate(true))
		return OK
	func load_progress(_slot := 0) -> Dictionary:
		return {}

class DiagnosticRouter extends "res://ui/game_entry_router.gd":
	var diagnostic_ready := false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		state = DiagnosticState.new()
		state.name = "DiagnosticState"
		var prepared: Node = load("res://tests/chapter_travel_test.gd").earned()
		add_child(state)
		state.restore_config(load("res://tests/chapter_travel_test.gd").history(prepared))
		prepared.free()
		audio = preload("res://ui/menu_audio.gd").new()
		audio.state = state
		add_child(audio)
		world = preload("res://Preview.tscn").instantiate()
		world.name = "DiagnosticVillage"
		world.dialogue_state = state
		world.entry_router = self
		world.restored_position = {"position":Vector3(133,11,149),"map_id":state.GROUND.MAP_ID,"yaw":PI}
		world.entry_ready.connect(func(): player_ready = true)
		world.entry_failed.connect(func(message): entry_error = message)
		route = "diagnostic_initializing"
		add_child(world)
		world._set_pause_owner("entry", true)
		get_tree().paused = false
	func _process(delta: float) -> void:
		if route == "diagnostic_initializing":
			if player_ready and world.training.grounded and world.bow_training.grounded and world.bridge_encounter.grounded and world.chapter_pillar.grounded:
				diagnostic_ready = true
				world.training.restore_history()
				world.gameplay_hud.restore_view()
				world._set_pause_owner("entry", false)
				route = "world"
			return
		super(delta)
	func _mcp_state() -> Dictionary:
		var observation := super()
		observation.diagnostic_fixture = true
		observation.diagnostic_ready = diagnostic_ready
		observation.diagnostic_save_requests = state.diagnostic_save_requests if is_instance_valid(state) else null
		return observation

class MotionWorld extends Node3D:
	var dialogue_state: Node
	var pause_owners: Dictionary = {}
	var completion_count := 0
	func active_map_id() -> String: return dialogue_state.GROUND.MAP_ID
	func _set_pause_owner(owner: String, enabled: bool) -> void:
		if enabled: pause_owners[owner] = true
		else: pause_owners.erase(owner)

static func attach_motion_diagnostic(parent: Node, reduced := false, missing := false) -> CanvasLayer:
	# A decoder/lifecycle fixture only: no travel facts, inventory grants or saves.
	var stage := MotionWorld.new()
	stage.name = "MotionFixture"
	parent.add_child(stage)
	stage.dialogue_state = DiagnosticState.new()
	stage.add_child(stage.dialogue_state)
	stage.dialogue_state.reduced_motion = reduced
	var overlay := preload("res://ui/ChapterTransition.tscn").instantiate() as CanvasLayer
	overlay.name = "ArrivalPlayback"
	overlay.world = stage
	overlay.destination_map = stage.dialogue_state.MAP02
	if missing: overlay.motion_resource_path = "res://tests/fixtures/absent_arrival.ogv"
	overlay.completed.connect(func(): stage.completion_count += 1; overlay._release_world())
	stage.add_child(overlay)
	overlay.armed = true
	overlay.reveal_arrival()
	return overlay

static func attach_diagnostic(parent: Node) -> Node:
	# Prepared state is component support, never evidence of earned progression.
	# All save calls are intercepted before either world can autosave.
	var router := DiagnosticRouter.new()
	parent.add_child(router)
	return router

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
	checks.optional_patrols_not_required = not s.reward_history.has("bridge_patrol_a") and not s.reward_history.has("bridge_patrol_b") and s.objective() == s.guard_objective()
	s.dialogue_kind = "isha"
	s.begin()
	checks.readable_choice = s.logical_node == "G04" and s.current_nodes().G04.choices.size() == 2
	checks.consent = s.choose(0) and s.departure_confirmed and s.passage_missing_conditions().is_empty() and s.experience == xp
	checks.consent_objective = s.objective() == s.guard_objective() and s.objective().contains("按 E 出发")
	var source := history(s)
	checks.source_valid = s.config_unavailable_reason(source) == ""
	checks.merge(objective_projection_checks(source))
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
	checks.merge(motion_boundary_checks())
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

static func motion_boundary_checks() -> Dictionary:
	var transition = preload("res://ui/chapter_transition.gd")
	var checks := {
		"missing_motion_retains_fallback": transition.motion_spec({}).is_empty(),
		"invalid_motion_type_rejected": transition.motion_spec({"arrival_motion": "arrival.ogv"}).is_empty(),
		"unbounded_motion_rejected": transition.motion_spec({"arrival_motion": {"file": "arrival.ogv", "duration_seconds": 99}}).is_empty(),
		"other_media_path_rejected": transition.motion_spec({"arrival_motion": {"file": "../other.ogv", "duration_seconds": 5}}).is_empty(),
	}
	var overlay = transition.new()
	overlay.armed = true
	overlay.phase = "arrival"
	overlay.paused = true
	overlay.request_skip()
	checks.paused_skip_preserves_boundary = not overlay.skipped
	overlay.paused = false
	overlay.request_skip()
	checks.arrival_skip_consumed = overlay.skipped
	overlay.skipped = false
	overlay.phase = "loading"
	overlay.request_skip()
	checks.loading_skip_no_second_boundary = not overlay.skipped
	overlay.free()
	return checks

static func objective_projection_checks(source: ConfigFile) -> Dictionary:
	# Read-only projection on isolated restored facts; no ordinary Continue or
	# E01 completion claim, and no progress/reward setters to repair the journal.
	var restored := STATE.new()
	restored.restore_config(source)
	var facts := restored.training_snapshot().duplicate(true)
	var rewards := restored.reward_history.duplicate(true)
	var xp: int = restored.experience
	var objective: String = restored.objective()
	var rows: Array[Dictionary] = restored.quest_entries()
	var rescue_action := ""
	var guard_action := ""
	for row in rows:
		if row.id == "rescue": rescue_action = row.action
		if row.id == "guards": guard_action = row.action
	var checks := {
		"restored_farewell_objective": restored.departure_confirmed and restored.guards_defeated() and objective == restored.guard_objective() and objective.contains("按 E 出发"),
		"restored_journal_agreement": rescue_action == objective and guard_action == objective,
		"objective_reads_preserve_facts": restored.training_snapshot() == facts and restored.reward_history == rewards and restored.experience == xp,
	}
	restored.free()
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
	checks.bounded_playback = is_equal_approx(duration,21.6) # Two real 10s films and a 1.4s arrival boundary.
	checks.moving_departure_beats = storyboard.slides[0].get("video","") == "farewell.ogv" and storyboard.slides[1].get("video","") == "passage.ogv" and ResourceLoader.exists(transition.ART+"farewell.ogv") and ResourceLoader.exists(transition.ART+"passage.ogv")
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
	# Return travel has authored mesh bodies, without a Terrain3D node.
	terrain.name = "AuthoredTerrainCollision"
	actor.collision_layer = 2
	actor.collision_mask = 1
	router._suspend_source_collision()
	checks.authored_source_collision_suspended = actor.collision_layer == 0 and actor.collision_mask == 0 and terrain.collision_layer == 0
	router._restore_source_collision()
	checks.authored_source_collision_restored = actor.collision_layer == 2 and actor.collision_mask == 1 and terrain.collision_layer == 1 and router.source_collision_state.is_empty()
	source.free()
	router.free()
	return checks

static func departure_collision_checks(world: Node3D) -> Dictionary:
	# Opt-in live physics query. No movement, progression or save writes.
	var arch: Node3D = world.village.get_node("Terrain3D/Big rocks/Node3D")
	var body := arch.get_node("StaticBody3D") as StaticBody3D
	var extra := arch.get_node("MeshInstance3D6") as MeshInstance3D
	var extra_body := extra.get_node("DepartureRockBody") as StaticBody3D
	var checks := {
		"arch_visible_to_camera": body.collision_layer & world.player.arm.collision_mask != 0,
		"arch_solid_to_player": body.collision_layer & world.player.collision_mask != 0,
		"authored_arch_shapes_retained": body.get_child_count() == 5,
		"extra_native_triangles": extra_body.get_child(0).shape is ConcavePolygonShape3D,
		"extra_matches_mesh": extra_body.global_transform.is_equal_approx(extra.global_transform),
	}
	# Before the repair these same body-height rays missed on the world mask,
	# although querying layer 2 hit the authored small rock in the player stance.
	for height in [11.4, 12.1]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(131.8,13.38494,143.0043), Vector3(131.5,height,139.28), world.player.arm.collision_mask, [world.player.get_rid()])
		var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
		checks["original_occluder_%s" % height] = not hit.is_empty() and hit.collider == body
	return checks
