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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	state = preload("res://dialogue_state.gd").new()
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
	canvas.layer = 100
	add_child(canvas)
	_show_title()

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
	loader.load_scene("res://world.tscn")

func _construct_world(_resource: PackedScene) -> void:
	if route != "loading": return
	var restored: Dictionary = {}
	if entry_kind == "new": state.reset_adventure()
	else:
		restored = state.load_progress(selected_slot)
		if restored.is_empty():
			_entry_failed("存档无法恢复。原进度已保留，请重试。")
			return
	var preview := load("res://Preview.tscn") as PackedScene
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
	if route != "initializing": return
	# Resource completion is not readiness: retain this screen until training
	# and player placements succeed and confirmation controls are released.
	player_ready = true

func _process(delta: float) -> void:
	if route == "loading" and loading: loading.update_progress(loader.progress, false)
	if route == "initializing":
		loading.update_progress(1.0, true)
		initialization_elapsed += delta
		if initialization_elapsed > 25.0:
			_entry_failed("安全落脚点未能准备好。请重试或返回标题。")
			return
		if not player_ready or _confirmation_held(): return
		if not world.training.grounded or not world.bow_training.grounded:
			return
		# Only promote a new/selected manual history after genuine safe readiness.
		if entry_kind == "new" or entry_kind == "load":
			if state.save_progress(world.player.global_position, world.player.arm.rotation.y) != OK:
				_entry_failed("保存恢复进度失败。原存档仍保留，请重试。")
				return
		initialized = true
		world.training.restore_history()
		world.gameplay_hud.restore_view()
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
	return Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER) or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)

func _entry_failed(message: String) -> void:
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
	route = "title"
	enter_adventure(entry_kind, selected_slot)

func return_to_title() -> void:
	if route == "returning": return
	loader.cancel()
	if route in ["loading", "initializing"]: state.restore_adventure(previous_history)
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
	var focus := get_viewport().gui_get_focus_owner()
	return {"route": route, "entry_kind": entry_kind, "selected_slot": selected_slot, "resource_status": loader.status, "resource_progress": loader.progress, "initialized": initialized, "player_ready": player_ready, "entry_error": entry_error, "world_present": is_instance_valid(world), "world_processing": world.is_processing() if is_instance_valid(world) else false, "tree_paused": get_tree().paused, "mouse_mode": Input.mouse_mode, "focus": str(focus.get_path()) if focus else "", "adventure": state._mcp_state()}
