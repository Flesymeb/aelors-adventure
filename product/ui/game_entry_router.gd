extends Node
## One entry owner; adventure facts remain in dialogue_state.gd.
var state: Node
var audio: Node
var loader: Node
var title: Control
var loading: Control
var world: Node3D
var route := "title"
var entry_kind := ""
var selected_slot := 0
var initialized := false
var player_ready := false
var entry_error := ""
var previous_history: Dictionary = {}
var canvas: CanvasLayer
var initialization_elapsed := 0.0
var opening: Control
var transition: CanvasLayer
var source_world: Node3D
var destination_map := ""
var travel_history: Dictionary = {}
var travel_resource := ""
var travel_started_ms := 0
var travel_finishing := false
var source_ui_visibility: Array[Dictionary] = []
var source_collision_state: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	state = create_adventure_state()
	state.name = "AdventureState"
	add_child(state)
	audio = preload("res://ui/menu_audio.gd").new()
	audio.name = "MenuAudio"
	audio.state = state
	add_child(audio)
	loader = preload("res://ui/menu_foundation/scene_loader.gd").new()
	loader.name = "SceneLoader"
	add_child(loader)
	loader.scene_loaded.connect(_construct_world)
	loader.load_failed.connect(_entry_failed)
	canvas = CanvasLayer.new()
	canvas.name = "EntryCanvas"
	canvas.layer = 100
	add_child(canvas)
	_show_title()

func create_adventure_state() -> Node:
	return preload("res://dialogue_state.gd").new()

func _show_title() -> void:
	get_viewport().disable_3d = false
	route = "title"
	initialized = false
	player_ready = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	title = preload("res://ui/menu_foundation/main_menu.tscn").instantiate()
	title.router = self
	canvas.add_child(title)

func enter_adventure(kind: String, slot: int) -> void:
	if route != "title": return
	entry_kind = kind
	selected_slot = slot
	previous_history = state.adventure_snapshot()
	entry_error = ""
	initialized = false
	player_ready = false
	route = "loading"
	title.hide()
	if kind == "new":
		route = "opening"
		opening = preload("res://ui/illustrated_opening.tscn").instantiate()
		opening.router = self
		opening.name = "IllustratedOpening"
		canvas.add_child(opening)
		opening.completed.connect(_opening_finished)
		return
	_start_loading()

func _opening_finished() -> void:
	if route != "opening": return
	opening.hide()
	opening.queue_free()
	opening = null
	_start_loading()

func _start_loading() -> void:
	route = "loading"
	get_tree().paused = false
	loading = preload("res://ui/menu_foundation/loading_screen.tscn").instantiate()
	loading.host = title
	canvas.add_child(loading)
	loading.retry_requested.connect(_retry)
	loading.back_requested.connect(return_to_title)
	# Let the real loading surface draw before requesting dependencies.
	_begin_entry.call_deferred()

func _begin_entry() -> void:
	await get_tree().process_frame
	if route != "loading": return
	if entry_kind != "new":
		var reason: String = state.slot_unavailable_reason(selected_slot, selected_slot == 0)
		if reason != "":
			_entry_failed(reason + "。请返回标题选择另一存档。")
			return
	loader.load_scene("res://world.tscn", true)

func _construct_world(_resource: PackedScene) -> void:
	if route != "loading": return
	var restored: Dictionary = {}
	if entry_kind == "new":
		state.reset_adventure()
		state.opening_completed = true
	else:
		restored = state.load_progress(selected_slot)
		if restored.is_empty():
			_entry_failed("存档无法恢复。原进度已保留，请重试。")
			return
	var preview := load(destination_resource(state.current_map)) as PackedScene
	if not preview:
		_entry_failed("冒险资源无法读取。请重试。")
		return
	world = preview.instantiate()
	if world == null:
		_entry_failed("冒险无法启动。请重试。")
		return
	world.name = "Adventure"
	world.entry_router = self
	world.dialogue_state = state
	world.restored_position = restored
	route = "initializing"
	initialization_elapsed = 0
	world.entry_ready.connect(_world_ready)
	world.entry_failed.connect(_entry_failed)
	add_child(world)
	# Training construction keeps its own physics placement alive but gates all
	# gameplay through this pause owner until every actor has actual support.
	world._set_pause_owner("entry", true)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _world_ready() -> void:
	if route not in ["initializing", "travel_initializing"]: return
	# Resource completion is not readiness: retain this screen until training
	# and player placements succeed and confirmation controls are released.
	player_ready = true

func _process(delta: float) -> void:
	if route == "travel_loading":
		_poll_travel()
		return
	if route == "travel_initializing":
		if Time.get_ticks_msec() - travel_started_ms > 30000:
			_travel_failed("落脚点尚未准备好，已返回上一处边界。")
			return
		if not transition.paused and player_ready and world.destination_ready() and not travel_finishing:
			travel_finishing = true
			_finish_travel()
		return
	if route == "loading" and loading: loading.update_progress(loader.progress, false)
	if route == "initializing":
		loading.update_progress(1.0, true)
		initialization_elapsed += delta
		if initialization_elapsed > 25.0:
			_entry_failed("安全落脚点未能准备好。请重试或返回标题。")
			return
		if not player_ready or _confirmation_held(): return
		if not world.destination_ready(): return
		# Only promote a new/selected manual history after genuine safe readiness.
		if entry_kind == "new" or entry_kind == "load":
			if state.save_progress(world.player.global_position, world.player.arm.rotation.y) != OK:
				_entry_failed("保存恢复进度失败。原存档仍保留，请重试。")
				return
		initialized = true
		world.restore_destination_history()
		if entry_kind == "new": world.gameplay_hud.notify("河谷村庄灯台已启用")
		world._set_pause_owner("entry", false)
		get_tree().paused = not world.pause_owners.is_empty()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED
		loading.queue_free()
		loading = null
		title.queue_free()
		title = null
		route = "game_over" if state.lives == 0 else "world"

func _confirmation_held() -> bool:
	return Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER) or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)

func _entry_failed(message: String) -> void:
	if route.begins_with("travel"):
		_travel_failed(message)
		return
	loader.cancel()
	if is_instance_valid(world):
		world.process_mode = Node.PROCESS_MODE_DISABLED
		world.queue_free()
		world = null
	state.restore_adventure(previous_history)
	initialized = false
	player_ready = false
	entry_error = message
	route = "error"
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	loading.show_error(message)
	audio.play_cue("failure")

func _retry() -> void:
	if route != "error": return
	loading.queue_free()
	loading = null
	# The completed presentation is an entry boundary, not a durable save yet.
	# Keep the original rollback history and retry only the loading/commit path.
	entry_error = ""
	initialized = false
	player_ready = false
	_start_loading()

func return_to_title() -> void:
	if route.begins_with("travel"):
		if route == "travel_reveal": return
		_travel_failed("")
	if route == "returning": return
	loader.cancel()
	if route in ["opening", "loading", "initializing", "error"]: state.restore_adventure(previous_history)
	if opening:
		opening.hide()
		opening.queue_free()
		opening = null
	if is_instance_valid(world):
		world.process_mode = Node.PROCESS_MODE_DISABLED
		world.player.set_controls_open(true)
		world.queue_free()
		world = null
	if loading: loading.queue_free(); loading = null
	if title: title.queue_free(); title = null
	route = "returning"
	# Wait for the old world/audio to leave the tree before drawing title.
	await get_tree().process_frame
	_show_title()
	audio.play_cue("back")

func _mcp_state() -> Dictionary:
	var viewport := get_viewport() if is_inside_tree() else null
	var focus: Control = viewport.gui_get_focus_owner() if viewport else null
	var tree := get_tree() if is_inside_tree() else null
	var loader_ready := is_instance_valid(loader) and not loader.is_queued_for_deletion()
	var state_ready := is_instance_valid(state) and not state.is_queued_for_deletion()
	var observation := {"ready": is_node_ready() and not is_queued_for_deletion(), "loader_ready": loader_ready, "state_ready": state_ready, "opening_present": is_instance_valid(opening) and not opening.is_queued_for_deletion(), "opening": opening._mcp_state() if is_instance_valid(opening) and not opening.is_queued_for_deletion() else null, "route": route, "entry_kind": entry_kind, "selected_slot": selected_slot, "resource_status": loader.status if loader_ready else null, "resource_progress": loader.progress if loader_ready else null, "initialized": initialized, "player_ready": player_ready, "entry_error": entry_error, "world_present": is_instance_valid(world) and not world.is_queued_for_deletion(), "world_processing": world.is_processing() if is_instance_valid(world) and not world.is_queued_for_deletion() else null, "loading_present": is_instance_valid(loading) and not loading.is_queued_for_deletion(), "tree_paused": tree.paused if tree else null, "mouse_mode": Input.mouse_mode, "focus": str(focus.get_path()) if focus else "", "adventure": state._mcp_state() if state_ready else null}
	# The entry owner already retains the rollback snapshot. Expose only facts
	# needed to compare it with AdventureState; do not create another history.
	for key in ["opening_completed", "logical_node", "q01_accepted", "experience", "sword_owned", "bow_owned", "lamp_owned", "lives", "arrows", "selected_equipment"]:
		observation["previous_" + key] = previous_history.get(key)
	observation.merge(_departure_observation())
	return observation

func _departure_observation() -> Dictionary:
	# Project the current authorities; never retain a disposable node snapshot.
	# The router keeps destination/route through teardown; absent dependencies
	# are explicitly unavailable rather than a remembered successful boundary.
	var live: bool = not is_queued_for_deletion()
	var transition_live: bool = live and is_instance_valid(transition) and not transition.is_queued_for_deletion()
	var world_live: bool = live and is_instance_valid(world) and not world.is_queued_for_deletion()
	var state_live: bool = live and is_instance_valid(state) and not state.is_queued_for_deletion()
	var presentation: Dictionary = transition._mcp_state() if transition_live else {}
	var gameplay: Dictionary = world._mcp_state() if world_live else {}
	return {
		"departure_destination": destination_map if live and destination_map != "" else null,
		"departure_transition_present": transition_live,
		"departure_source_present": live and is_instance_valid(source_world) and not source_world.is_queued_for_deletion(),
		"departure_phase": presentation.get("phase"),
		"departure_transition_ready": presentation.get("ready"),
		"departure_skipped": presentation.get("skipped"),
		"departure_inputs_armed": presentation.get("inputs_armed"),
		"departure_world_ready": gameplay.get("ready"),
		"departure_controls_present": gameplay.get("controls_ready"),
		"departure_product_paused": gameplay.get("product_paused"),
		"departure_control_ready": (route == "world" and player_ready and gameplay.get("ready", false) and gameplay.get("player_ready", false) and gameplay.get("controls_ready", false) and not gameplay.get("product_paused", true)) if world_live else null,
		"departure_current_map": state.current_map if state_live else null,
		"departure_equipment": state.selected_equipment if state_live else null,
		"departure_cp02_claimed": state.cp02_claimed if state_live else null,
		"departure_cp03_claimed": state.cp03_claimed if state_live else null,
		"departure_record_read": state.ritual_record_read if state_live else null,
		"destination_ready": world.destination_ready() if world_live else null,
		"departure_lives": state.lives if state_live else null}

func restore_map(slot: int) -> void:
	# Existing history-reader validation and title entry remain the only load owner.
	await return_to_title()
	enter_adventure("load", slot)

func travel_to(map_id: String) -> bool:
	if route != "world" or map_id == state.current_map or map_id not in [state.GROUND.MAP_ID, state.MAP02, state.MAP03]: return false
	if not state.departure_available() or not state.departure_confirmed or state.conversation_active or state.lives <= 0: return false
	if map_id == state.MAP03 and (state.current_map != state.MAP02 or not state.tomb_missing_conditions().is_empty()):
		world.training.tell("墓殿通道尚未开放 · " + "、".join(state.tomb_missing_conditions()), 6)
		return false
	if state.current_map == state.MAP03 and map_id != state.MAP02: return false
	if not world.travel_safe(): return false
	if not preload("res://ui/chapter_transition.gd").available():
		world.training.tell("通道暂时无法开启 · 请在村庄整顿后重试", 5)
		return false
	state.selected_equipment = world.player.weapon_mode
	# Save the valid source boundary before a presentation or resource request.
	if state.save_progress(world.player.global_position, world.player.arm.rotation.y) != OK: return false
	world.training.interrupt("travel")
	world.bow_training.clear_transients()
	world.element_abilities.clear_transients()
	world.player.cancel_aim()
	travel_history = state.adventure_snapshot()
	source_world = world
	destination_map = map_id
	transition = preload("res://ui/ChapterTransition.tscn").instantiate()
	transition.world = source_world
	transition.shorter = state.cp02_claimed
	transition.returning = map_id == state.GROUND.MAP_ID
	transition.destination_map = map_id
	transition.black_boundary.connect(_load_destination)
	route = "travel_story"
	add_child(transition)
	return true

func _load_destination() -> void:
	if route != "travel_story": return
	travel_resource = destination_resource(destination_map)
	var error := ResourceLoader.load_threaded_request(travel_resource, "PackedScene")
	if error != OK:
		_travel_failed("通道无法开启，已返回上一处落脚点。")
		return
	travel_started_ms = Time.get_ticks_msec()
	route = "travel_loading"

func _poll_travel() -> void:
	var status := ResourceLoader.load_threaded_get_status(travel_resource)
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or Time.get_ticks_msec() - travel_started_ms > 30000:
		_travel_failed("通道无法开启，已返回上一处落脚点。")
		return
	if status != ResourceLoader.THREAD_LOAD_LOADED or transition.paused: return
	var scene := ResourceLoader.load_threaded_get(travel_resource) as PackedScene
	if scene == null:
		_travel_failed("目的地无法准备，已返回上一处落脚点。")
		return
	source_ui_visibility.clear()
	for layer_node in source_world.find_children("*", "CanvasLayer", true, false):
		for item in layer_node.get_children():
			if item is CanvasItem:
				source_ui_visibility.append({"node":item,"visible":item.visible})
				item.hide()
	source_world.hide()
	source_world.process_mode = Node.PROCESS_MODE_DISABLED
	_suspend_source_collision()
	world = scene.instantiate()
	world.name = "TombAdventure" if destination_map == state.MAP03 else "MeadowAdventure" if destination_map == state.MAP02 else "VillageAdventure"
	world.dialogue_state = state
	world.entry_router = self
	# Boundary facts remain at the source until a grounded destination exists.
	world.restored_position = arrival_position(destination_map, state.current_map)
	player_ready = false
	travel_finishing = false
	route = "travel_initializing"
	world.entry_ready.connect(_world_ready)
	world.entry_failed.connect(_entry_failed)
	add_child(world)
	world._set_pause_owner("entry", true)
	get_tree().paused = false

func _finish_travel() -> void:
	if not state.commit_arrival(destination_map):
		_travel_failed("目的地尚未开放，已返回上一处落脚点。")
		return
	state.conversation_active = false
	if state.save_progress(world.player.global_position, world.player.arm.rotation.y) != OK:
		_travel_failed("无法保存新的落脚点，已返回上一处边界。")
		return
	world.restore_destination_history()
	route = "travel_reveal"
	await transition.reveal_arrival()
	# Input consumed by skip/confirmation cannot become an attack on arrival.
	while _confirmation_held(): await get_tree().process_frame
	world._set_pause_owner("entry", false)
	source_world.process_mode = Node.PROCESS_MODE_DISABLED
	source_world.queue_free()
	source_collision_state.clear()
	source_world = null
	transition.world = null
	transition.queue_free()
	transition = null
	get_tree().paused = not world.pause_owners.is_empty()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED
	route = "world"
	world.gameplay_hud.notify(state.checkpoint_name() + " · 落脚点已保存")

func _travel_failed(message: String) -> void:
	if is_instance_valid(world) and world != source_world:
		world.process_mode = Node.PROCESS_MODE_DISABLED
		world.queue_free()
	state.restore_adventure(travel_history)
	_restore_source_collision()
	world = source_world
	if is_instance_valid(transition):
		transition._release_world()
		transition.queue_free()
	transition = null
	if is_instance_valid(source_world):
		source_world.show()
		for visibility in source_ui_visibility:
			if is_instance_valid(visibility.node): visibility.node.visible = visibility.visible
		source_ui_visibility.clear()
		source_world.process_mode = Node.PROCESS_MODE_ALWAYS
		source_world._set_pause_owner("chapter_travel", false)
		player_ready = true
		if message != "": source_world.training.tell(message, 5)
	source_world = null
	travel_finishing = false
	route = "world"

# Processing/visibility do not remove physics bodies. During the overlapping
# scene handoff the source NPCs otherwise obstruct the destination's ground
# rays and standing volumes. Keep exact masks for a failed-travel rollback.
func _suspend_source_collision() -> void:
	source_collision_state.clear()
	for node in source_world.find_children("*", "", true, false):
		if node is CollisionObject3D or (is_instance_valid(source_world.village) and node == source_world.village.get_node_or_null("Terrain3D")):
			source_collision_state.append({"node":node,"layer":node.collision_layer,"mask":node.collision_mask})
			node.collision_layer = 0
			node.collision_mask = 0

func _restore_source_collision() -> void:
	for record in source_collision_state:
		if is_instance_valid(record.node):
			record.node.collision_layer = record.layer
			record.node.collision_mask = record.mask
	source_collision_state.clear()

func begin_new_adventure_from_world() -> void:
	await return_to_title()
	enter_adventure("new", 0)

func destination_resource(map_id: String) -> String:
	if map_id == state.MAP03: return "res://world/map03_entry.tscn"
	if map_id == state.MAP02: return "res://world/map02_entry.tscn"
	return "res://Preview.tscn"

func arrival_position(map_id: String, from_map: String) -> Dictionary:
	if map_id == state.MAP02 and from_map == state.MAP03:
		return {"position":Vector3(6,0,113),"map_id":state.MAP02,"yaw":0.0}
	return {"position":Vector3.ZERO,"map_id":"", "yaw":PI if map_id == state.MAP02 else 0.0}
