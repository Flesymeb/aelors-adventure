extends Node3D

const SOURCE_SCENE := preload("res://world.tscn")
const PLAYER_SCENE := preload("res://Player.tscn")
const ARCHERY_HUD := preload("res://archery_hud.gd")
const ENVIRONMENT_QUALITY := preload("res://environment_quality.gd")
const GROUND := preload("res://forest_ground.gd")
const SPAWN_XZ := GROUND.SPAWN

signal entry_ready
signal entry_failed(message: String)
var ground_policy = GROUND
var meadow_slice := false
var menu_audio: Node
var entry_router: Node
var village: Node3D
var player: CharacterBody3D
var dusk := false
var quality: Node
var weapon_label: Label
var help_label: Label
var controls_panel: Control
var controls_feedback: Label
var previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var ui_font: Font = preload("res://dialogue_theme.tres").default_font
var dialogue_state: Node
var dialogue: CanvasLayer
var isha: StaticBody3D
var pause_owners: Dictionary = {}
var gameplay_hud: CanvasLayer
var restoring_interface := false
var developer_ui := false
var restored_position: Dictionary = {}
var bow_training: Node3D
var lamp_training: Node3D
var element_abilities: Node3D
var channel_guards: Node3D
var chapter_pillar: Node3D
var route_clue: Node3D
var ambush_encounter: Node3D
var line_encounter: Node3D
var line_record: Node3D
var barrier: Node3D
var pressure_encounter: Node3D
var bridge_encounter: Node3D
var dynamic_encounters: Node3D
var bridge_actions: Node3D
var inventory_panel: Control
var skill_panel: Control
var initial_skill_prompted = false
var training: Node3D
var failure_panel: PanelContainer
var failure_root: Control
var failure_scroll: ScrollContainer
var failure_title: Label
var failure_body: Label
var failure_hint: Label
var failure_buttons: Array[Button] = []
var failure_selection := 0
var failure_armed := false
var failure_pending: Button
var failure_busy := false


func create_lamp_training() -> Node3D:
	return preload("res://lamp_training.gd").new()

func create_element_abilities() -> Node3D:
	return preload("res://element_abilities.gd").new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	village = create_environment()
	village.name = "Forest"
	if not meadow_slice: GROUND.bind_departure_collision(village)
	village.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(village)
	var source_camera := village.get_node_or_null("Camera/Camera") as Camera3D
	if source_camera:
		source_camera.current = false
	player = PLAYER_SCENE.instantiate()
	player.ground_policy = ground_policy
	if meadow_slice: player.minimum_world_height = -25.0
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var spawn: Vector2 = checkpoint_xz()
	var initial_height: float = initial_spawn_height(spawn)
	player.position = Vector3(spawn.x, initial_height + 0.1, spawn.y)
	player.configure_equipment(false, false)
	add_child(player)
	player.get_node("CameraArm/Camera").current = true
	_add_village_buildings()
	_place_player.call_deferred()
	quality = Node.new()
	quality.set_script(preload("res://world/map02_quality.gd") if meadow_slice else ENVIRONMENT_QUALITY)
	add_child(quality)
	if dialogue_state == null:
		dialogue_state = preload("res://dialogue_state.gd").new()
		dialogue_state.name = "OpeningState"
		add_child(dialogue_state)
		restored_position = dialogue_state.load_progress()
	quality.state = dialogue_state
	quality.configure(village)
	if entry_router == null:
		menu_audio = preload("res://ui/menu_audio.gd").new()
		menu_audio.state = dialogue_state
		add_child(menu_audio)
	else: menu_audio = entry_router.audio
	dialogue = preload("res://IshaDialogue.tscn").instantiate()
	dialogue.state = dialogue_state
	add_child(dialogue)
	dialogue.closed.connect(_dialogue_closed)
	dialogue.menu_requested.connect(_open_controls)
	dialogue.progress_changed.connect(_save_opening.bind(0))
	isha = preload("res://Isha.tscn").instantiate()
	isha.position = Vector3(GROUND.ISHA.x, 0, GROUND.ISHA.y)
	add_child(isha)
	_add_help()
	_add_controls()
	player.controls_changed.connect(_refresh_control_prompts)
	_refresh_control_prompts()
	training = preload("res://sword_training.gd").new()
	training.name = "SwordTraining"
	training.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(training)
	training.configure(self)
	dialogue_state.sword_granted.connect(training.grant_sword)
	bow_training = preload("res://bow_training.gd").new()
	bow_training.name = "BowTraining"
	add_child(bow_training)
	bow_training.configure(self)
	dialogue_state.bow_granted.connect(bow_training.grant_bow)
	lamp_training = create_lamp_training()
	lamp_training.process_mode = Node.PROCESS_MODE_PAUSABLE
	lamp_training.name = "LampTraining"
	add_child(lamp_training)
	lamp_training.configure(self)
	element_abilities = create_element_abilities()
	element_abilities.process_mode = Node.PROCESS_MODE_PAUSABLE
	element_abilities.name = "ElementAbilities"
	add_child(element_abilities)
	element_abilities.configure(self)
	if meadow_slice:
		bridge_encounter = preload("res://combat/Map02Roadblock.tscn").instantiate()
	else:
		bridge_encounter = preload("res://combat/bridge_encounter.gd").new()
	bridge_encounter.process_mode = Node.PROCESS_MODE_PAUSABLE
	bridge_encounter.name = "BridgeEncounter"
	add_child(bridge_encounter)
	bridge_encounter.configure(self)
	if meadow_slice:
		pressure_encounter = preload("res://combat/Map02Pressure.tscn").instantiate()
		pressure_encounter.name = "Map02Pressure"
		pressure_encounter.process_mode = Node.PROCESS_MODE_PAUSABLE
		pressure_encounter.actor_anchors.assign(ground_policy.PRESSURE_ANCHORS)
		pressure_encounter.cover_xz = ground_policy.PRESSURE_COVER
		pressure_encounter.branch_supply_xz = ground_policy.PRESSURE_APPROACH
		pressure_encounter.victory_supply_xz = ground_policy.PRESSURE_FLANK[0]
		add_child(pressure_encounter)
		pressure_encounter.configure(self)
		route_clue = preload("res://world/map02_route_clue.gd").new()
		route_clue.name = "MF01RouteRecord"
		route_clue.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(route_clue)
		route_clue.configure(self)
		ambush_encounter = preload("res://combat/Map02Ambush.tscn").instantiate()
		ambush_encounter.name = "Map02Ambush"
		ambush_encounter.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(ambush_encounter)
		ambush_encounter.configure(self)
		line_encounter = preload("res://combat/Map02LineDefense.tscn").instantiate()
		line_encounter.name = "Map02LineDefense"
		line_encounter.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(line_encounter)
		line_encounter.configure(self)
		line_record = preload("res://world/map02_line_record.gd").new()
		line_record.name = "MF02LineRecord"
		line_record.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(line_record)
		line_record.configure(self)
		barrier = preload("res://world/Map02Barrier.tscn").instantiate()
		barrier.name = "LN01Barrier"
		add_child(barrier)
		barrier.configure(self)
		dynamic_encounters = preload("res://combat/map02_dynamic_encounters.gd").new()
		dynamic_encounters.name = "MeadowDynamicEncounters"
		dynamic_encounters.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(dynamic_encounters)
		dynamic_encounters.configure(self)
	if not meadow_slice:
		bridge_actions = preload("res://world/BridgeActions.tscn").instantiate()
		bridge_actions.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(bridge_actions)
		bridge_actions.configure(self)
		channel_guards = preload("res://combat/ChannelGuardEncounter.tscn").instantiate()
		channel_guards.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(channel_guards)
		channel_guards.configure(self)
		chapter_pillar = preload("res://world/ChapterPillar.tscn").instantiate()
		chapter_pillar.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(chapter_pillar)
		chapter_pillar.configure(self)
		dynamic_encounters = preload("res://combat/dynamic_encounters.gd").new()
		dynamic_encounters.name = "DynamicEncounters"
		dynamic_encounters.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(dynamic_encounters)
		dynamic_encounters.configure(self)
	_add_product_panels()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if entry_router else Input.MOUSE_MODE_CAPTURED


func create_environment() -> Node3D:
	return SOURCE_SCENE.instantiate()

func initial_spawn_height(spawn: Vector2) -> float:
	return village.get_node("Terrain3D").data.get_height(Vector3(spawn.x, 0, spawn.y))

func _add_village_buildings() -> void:
	# Retain authored medieval building meshes, materials and collision only.
	# The old Demo world, nature, floor and regeneration scripts never enter the tree.
	var placements := [
		["res://Prefabs/Town/Building/EA03_Town_House_Comp_01a_PRE.prefab.scn", Vector2(104, 94), 0.0],
		["res://Prefabs/Town/Building/EA03_Town_House_Comp_01a_PRE.prefab.scn", Vector2(131, 98), PI],
		["res://Prefabs/Town/Building/EA03_Town_House_Comp_01a_PRE.prefab.scn", Vector2(99, 111), PI * 0.5]
	]
	var structures := Node3D.new()
	structures.name = "VillageBuildings"
	village.add_child(structures)
	for placement in placements:
		var house: Node3D = load(placement[0]).instantiate()
		structures.add_child(house)
		house.rotation.y = placement[2]
		var xz: Vector2 = placement[1]
		var base := INF
		for dx in [-4, 0, 4]:
			for dz in [-4, 0, 4]:
				base = minf(base, village.get_node("Terrain3D").data.get_height(Vector3(xz.x + dx, 0, xz.y + dz)))
		house.position = Vector3(xz.x, base - 0.12, xz.y)


func _place_player() -> void:
	var xz: Vector2 = GROUND.restored_xz(restored_position.get("position", Vector3.ZERO), restored_position.get("map_id", ""))
	# Terrain collision initialization may lag scene _ready. Keep physics disabled
	# until the actual collision surface and standing volume are available.
	var placed := false
	for attempt in 120:
		await get_tree().physics_frame
		placed = ground_policy.place(self, player, xz)
		if not placed and xz != checkpoint_xz():
			xz = checkpoint_xz()
			placed = ground_policy.place(self, player, xz)
		if placed: break
	if not placed:
		if entry_router:
			entry_failed.emit("出生点无法安全落地。请重试或返回标题。")
			return
		push_error("Forest spawn has no safe collision support")
		_recovery_error("出生点尚未准备好 · 请重新启动或读取安全存档。")
		return
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.set_meta("spawn_position", player.global_position)
	player.prepare_restored_camera(float(restored_position.get("yaw", player.arm.rotation.y)))
	if dialogue_state.persistence_error != "":
		_recovery_error(dialogue_state.persistence_error)
		return
	if dialogue_state.conversation_active and dialogue_state.lives > 0:
		_set_pause_owner("dialogue", true)
		dialogue.open_dialogue(true)
	if dialogue_state.homecoming_completed and not meadow_slice:
		if not is_instance_valid(homecoming_residents): homecoming_residents = preload("res://ui/homecoming_scene.gd").populate_village(self)
		for attempt in 120:
			if homecoming_residents.grounded: break
			await get_tree().physics_frame
		if not homecoming_residents.grounded:
			entry_failed.emit("村庄团聚地点尚未准备好。")
			return
	entry_ready.emit()


func _unhandled_input(event: InputEvent) -> void:
	if player.controls_open:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F9:
				developer_ui = not developer_ui
				help_label.get_parent().visible = developer_ui
				weapon_label.get_parent().visible = developer_ui
			KEY_F8:
				if developer_ui: _set_dusk(not dusk)
			KEY_F11:
				if developer_ui: quality.toggle_developer_lamps()
			KEY_R:
				if developer_ui: player.respawn()
			KEY_G:
				if developer_ui: quality.toggle_quality()
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	# Continue may restore a committed briefing before its presentation completed.
	# Wait for the ordinary grounded, safe world boundary; never replay seen art.
	if not meadow_slice and player and player.has_meta("spawn_position") and dialogue_state.persistence_error == "" and not dialogue_state.conversation_active and training and training.can_save() and bow_training and bow_training.can_save():
		_try_guard_interlude()
	if skill_panel and not initial_skill_prompted and dialogue_state.lamp_owned and dialogue_state.pending_points() > 0 and dialogue_state.skills.is_empty() and pause_owners.is_empty() and not training.player_locked() and player.attack_timer <= 0 and player.switch_timer <= 0:
		initial_skill_prompted = true
		skill_panel.open_panel()
	if pause_owners.has("failure") and not controls_panel.visible and not _confirmation_held() and failure_pending == null:
		failure_armed = true
	# Retain product pause intent after restart or an external debug step.
	# Leave external freezes alone when there is no product pause owner.
	if pause_owners.keys().any(func(owner): return owner not in ["warden_reveal","veyne_presentation"]) and not get_tree().paused:
		get_tree().paused = true
	if weapon_label and player:
		var view_name := "FIRST PERSON" if player.first_person else ("LEFT SHOULDER" if player.shoulder_side < 0 else "RIGHT SHOULDER")
		var movement: String = player.traversal.action if player.traversal.action != "" else ("sprint" if player.traversal.sprinting else player.traversal.posture)
		var notice: String = player.traversal.feedback if player.traversal.feedback_time > 0 else movement.to_upper()
		weapon_label.text = "%s · %s · %s\n%s · GRAPHICS: %s" % [player.weapon_mode.to_upper(), player.SKIN_NAMES[player.skin_index].to_upper(), view_name, notice, "ENHANCED" if quality.enhanced else "BALANCED"]


func _set_dusk(enabled: bool) -> void:
	dusk = enabled
	quality.set_dusk(dusk)


func _input(event: InputEvent) -> void:
	# World actors are pausable. This owner stays alive to handle UI and releases.
	if not pause_owners.is_empty():
		player.track_modal_input(event)
		if handle_controls_input(event):
			get_viewport().set_input_as_handled()


func _set_pause_owner(owner_id: String, enabled: bool) -> void:
	var was_paused := not pause_owners.is_empty()
	if enabled: pause_owners[owner_id] = true
	else: pause_owners.erase(owner_id)
	var now_paused := not pause_owners.is_empty()
	_sync_dialogue_world_labels()
	if now_paused != was_paused:
		if now_paused and is_instance_valid(line_encounter): line_encounter.interrupt()
		player.set_controls_open(now_paused)
		get_tree().paused = now_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if now_paused else Input.MOUSE_MODE_CAPTURED


func _sync_dialogue_world_labels() -> void:
	# Dialogue owns the foreground even while its nested settings/save panel is
	# open. Suspend nearby training cues at their presentation owner; pausing a
	# Label3D's process does not stop its rendering through transparent portraits.
	var hidden_by_dialogue := pause_owners.has("dialogue")
	for module in [training, bow_training]:
		if not is_instance_valid(module): continue
		for label in module.find_children("*", "Label3D", true, false):
			if hidden_by_dialogue:
				if not label.has_meta("dialogue_cue_visibility"):
					label.set_meta("dialogue_cue_visibility", label.visible)
				label.hide()
			elif label.has_meta("dialogue_cue_visibility"):
				label.visible = bool(label.get_meta("dialogue_cue_visibility"))
				label.remove_meta("dialogue_cue_visibility")


func _open_controls() -> void:
	previous_mouse_mode = Input.mouse_mode
	_set_pause_owner("controls", true)
	if gameplay_hud.journal.visible: gameplay_hud.journal.suspend_for_menu()
	if gameplay_hud.map_page.visible: gameplay_hud.map_page.suspend_for_menu()
	if inventory_panel and inventory_panel.visible: inventory_panel.suspend_for_menu()
	if skill_panel and skill_panel.visible: skill_panel.suspend_for_menu()
	dialogue.nested_menu = dialogue.opened
	if failure_root:
		failure_root.hide()
		failure_pending = null
		failure_armed = false
	get_viewport().disable_3d = true
	controls_panel.open_pause()


func _dialogue_closed() -> void:
	_save_opening(0)
	_set_pause_owner("dialogue", false)
	_try_guard_interlude()

func _try_guard_interlude() -> void:
	if not is_instance_valid(channel_guards) or not channel_guards.grounded: return
	if not meadow_slice and pause_owners.is_empty() and get_node_or_null("GuardInterlude") == null and preload("res://ui/guard_interlude.gd").eligible(dialogue_state):
		var interlude = preload("res://ui/guard_interlude.tscn").instantiate()
		interlude.name = "GuardInterlude"
		interlude.world = self
		add_child(interlude)


func _save_opening(slot: int) -> void:
	if pause_owners.has("guard_interlude") or dialogue_state.lives <= 0 or (training and (not training.can_save() or (bow_training and not bow_training.can_save()))):
		dialogue_state.save_feedback = "当前不能保存 · 请先退回安全处或恢复冒险"
		if controls_feedback: controls_feedback.text = dialogue_state.save_feedback
		return
	if training:
		dialogue_state.selected_equipment = player.pending_weapon if player.switch_timer > 0 else player.weapon_mode
		dialogue_state.sword_selected = dialogue_state.selected_equipment == "sword"
	var error: Error = dialogue_state.save_progress(player.global_position, player.arm.rotation.y, slot)
	if training and slot == 0 and error == OK:
		training.commit_retry = false
	if controls_feedback:
		controls_feedback.text = dialogue_state.save_feedback + (" · 槽位 %d" % slot if slot > 0 else "")
	if dialogue.opened:
		dialogue.footer.text = (dialogue_state.reward_feedback + " · " if dialogue_state.reward_feedback != "" else "") + dialogue_state.save_feedback + " · F10 设置与存档 · Esc 离开"
		dialogue._layout_reading()


func _load_opening(slot: int) -> void:
	var reason: String = dialogue_state.slot_unavailable_reason(slot)
	if reason != "":
		_recovery_error(reason)
		return
	var previous: Dictionary = dialogue_state.adventure_snapshot()
	restoring_interface = true
	var restored: Dictionary = dialogue_state.load_progress(slot)
	if restored.is_empty():
		restoring_interface = false
		_recovery_error("读取存档失败，请重试。")
		return
	if restored.get("map_id", GROUND.MAP_ID) != active_map_id():
		dialogue_state.restore_adventure(previous)
		restoring_interface = false
		if entry_router: entry_router.restore_map(slot)
		else: _recovery_error("请返回标题读取此存档")
		return
	var old_position := player.global_position
	if not training.place_on_ground(player, restored_xz(restored.position, restored.get("map_id", ""))) and not training.place_on_ground(player, checkpoint_xz()):
		dialogue_state.restore_adventure(previous)
		restoring_interface = false
		_recovery_error("存档位置无法安全落地 · 请重试或选择新游戏。")
		return
	# Promote the selected history only after confirming real ground.
	if dialogue_state.save_progress(player.global_position, restored.yaw) != OK:
		dialogue_state.restore_adventure(previous)
		player.global_position = old_position
		restoring_interface = false
		_recovery_error("保存恢复进度失败 · 冒险仍暂停，请重试。")
		return
	player.prepare_restored_camera(float(restored.yaw))
	training.restore_history()
	if route_clue: route_clue.restore_history()
	if line_record: line_record.restore_history()
	if barrier: barrier.restore_history()
	if bridge_actions: bridge_actions.restore_history()
	if channel_guards: channel_guards.restore_history()
	gameplay_hud.restore_view()
	restoring_interface = false
	restored_position = restored
	_refresh_reading_controls()
	_finish_recovery()
	if dialogue_state.conversation_active:
		_set_pause_owner("dialogue", true)
		dialogue.open_dialogue(true)


func _refresh_reading_controls() -> void:
	dialogue._layout()
	if failure_panel: _layout_failure()


var homecoming_residents: Node3D

func contextual_interaction_target() -> Node3D:
	# This priority owns both the visible prompt and ordinary E recipient.
	for target in [homecoming_residents, barrier, route_clue, line_record, pressure_encounter, bridge_actions, lamp_training, bow_training, training]:
		if is_instance_valid(target) and target.interaction_prompt() != "": return target
	return null

func _mcp_state() -> Dictionary:
	# Lifecycle sampling reads authorities only, including partial construction.
	var tree := get_tree() if is_inside_tree() else null
	var player_ready := is_instance_valid(player) and not player.is_queued_for_deletion() and player.is_inside_tree()
	var controls_ready := is_instance_valid(controls_panel) and not controls_panel.is_queued_for_deletion() and controls_panel.is_inside_tree()
	var state_ready := is_instance_valid(dialogue_state) and not dialogue_state.is_queued_for_deletion()
	var isha_ready := is_instance_valid(isha) and not isha.is_queued_for_deletion() and isha.is_inside_tree()
	var story_actors: Array[String] = []
	if tree:
		for actor in tree.get_nodes_in_group("isha"):
			if not actor.is_queued_for_deletion(): story_actors.append(str(actor.get_path()))
	var position: Vector3 = player.global_position if player_ready else Vector3.ZERO
	var velocity: Vector3 = player.velocity if player_ready else Vector3.ZERO
	return {"ready": is_node_ready() and not is_queued_for_deletion(), "player_ready": player_ready, "controls_ready": controls_ready, "failure": _failure_observation(), "pause_owners": pause_owners.keys(), "pause_owner_count": pause_owners.size(), "product_paused": not pause_owners.is_empty(), "controls_pause_owned": pause_owners.has("controls"), "controls_submenu": str(controls_panel.sub_menu.name) if controls_ready and is_instance_valid(controls_panel.sub_menu) else null, "preferences": dialogue_state.preference_snapshot() if state_ready else null, "tree_paused": tree.paused if tree else null, "developer_ui": developer_ui, "controls_visible": controls_panel.visible if controls_ready else null, "isha_distance": player.global_position.distance_to(isha.global_position) if player_ready and isha_ready else null, "interaction_available": isha.interaction_available if isha_ready else null, "objective": dialogue_state.objective() if state_ready else null, "equipment": player.weapon_mode if player_ready else null, "owns_sword": player.owns_sword if player_ready else null, "owns_bow": player.owns_bow if player_ready else null, "player_position": [position.x, position.y, position.z] if player_ready else null, "player_velocity": [velocity.x, velocity.y, velocity.z] if player_ready else null, "opening_progress": dialogue_state._mcp_state() if state_ready else null, "story_actors": story_actors, "authored_map": "res://assets/maps/map02/Main.tscn" if meadow_slice else SOURCE_SCENE.resource_path, "player_scene": PLAYER_SCENE.resource_path, "lamp_overlay": quality.developer_lamp_overlay if is_instance_valid(quality) and not quality.is_queued_for_deletion() else null}


func _add_help() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var layout := VBoxContainer.new()
	layout.position = Vector2(18, 16)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 7)
	layer.add_child(layout)
	help_label = Label.new()
	_add_hud_card(layout, help_label, 15)
	weapon_label = Label.new()
	_add_hud_card(layout, weapon_label, 13)
	help_label.get_parent().hide()
	weapon_label.get_parent().hide()
	gameplay_hud = preload("res://ui/gameplay_hud.gd").new()
	gameplay_hud.world = self
	add_child(gameplay_hud)
	var archery_hud := Control.new()
	archery_hud.set_script(ARCHERY_HUD)
	archery_hud.player = player
	layer.add_child(archery_hud)


func _refresh_control_prompts() -> void:
	help_label.text = "%s/%s/%s/%s move · Mouse look · %s jump · %s sprint · %s shoulder\nUnarmed · Weapons require ownership · E interact / F old lamp reveal\n%s crouch · %s prone · %s roll · %s dodge · %s perspective\nF10 controls · 3 lamp · 4/5 elements · I bag · K skills · F8 dusk (dev) · G graphics · R respawn · Esc cursor" % [
		player.key_prompt("forward"), player.key_prompt("left"), player.key_prompt("back"), player.key_prompt("right"),
		player.key_prompt("jump"), player.key_prompt("sprint"), player.key_prompt("shoulder"),
		player.key_prompt("crouch"), player.key_prompt("prone"), player.key_prompt("roll"), player.key_prompt("dodge"), player.key_prompt("perspective")]



func _add_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	controls_panel = preload("res://ui/menu_foundation/main_menu.tscn").instantiate()
	controls_panel.router = entry_router
	controls_panel.pause_world = self
	layer.add_child(controls_panel)
	controls_panel.hide()


func _close_controls() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus: focus.release_focus()
	if controls_panel.sub_menu: controls_panel._close_sub_menu()
	if controls_panel.confirmation: controls_panel.confirmation.close(false)
	controls_panel.hide()
	get_viewport().disable_3d = false
	if gameplay_hud.journal.suspended: gameplay_hud.journal.resume_from_menu()
	if gameplay_hud.map_page.suspended: gameplay_hud.map_page.resume_from_menu()
	if inventory_panel and inventory_panel.suspended: inventory_panel.resume_from_menu()
	if skill_panel and skill_panel.suspended: skill_panel.resume_from_menu()
	_set_pause_owner("controls", false)
	dialogue.nested_menu = false
	if dialogue.opened:
		# A release handled by the nested menu never reaches the dialogue.
		# Rearm only when all advance keys are up; a held key cannot submit.
		dialogue.advance_armed = not (Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if not pause_owners.is_empty() else previous_mouse_mode
	if pause_owners.has("failure"):
		failure_root.show()
		failure_pending = null
		failure_armed = false
		_refresh_failure_slots()
		_focus_failure(failure_selection)


# Called at the start of the player's _input, before mouse attacks and before
# either script's _unhandled_input. Captured keys cannot leak into the world.
func handle_controls_input(event: InputEvent) -> bool:
	if pause_owners.has("guard_interlude") or pause_owners.has("chapter_travel") or pause_owners.has("entry"):
		# Let the interlude and its GUI own Esc, Space and navigation; do not
		# open a nested world menu or a save/action shortcut over the painting.
		return event is InputEventKey and event.keycode in [KEY_F10,KEY_F5,KEY_E,KEY_I,KEY_J,KEY_K,KEY_M]
	for panel in [inventory_panel, skill_panel]:
		if panel and panel.visible and not controls_panel.visible:
			if event is InputEventKey and event.pressed and not event.echo:
				if event.keycode in [KEY_ESCAPE, KEY_I if panel == inventory_panel else KEY_K]: panel.close_panel(); return true
				if event.keycode == KEY_F10: _open_controls(); return true
			return false
	if gameplay_hud and gameplay_hud.map_page.visible and not controls_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_M, KEY_ESCAPE]: gameplay_hud.map_page.close_panel(); return true
			if event.keycode == KEY_F10: _open_controls(); return true
			if event.keycode == KEY_F5:
				_save_opening(gameplay_hud.failed_slot if gameplay_hud.failed_slot >= 0 else 0)
				return true
		return false
	if gameplay_hud and gameplay_hud.journal.visible and not controls_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_J, KEY_ESCAPE]:
				gameplay_hud.journal.close_journal()
				return true
			if event.keycode == KEY_F10:
				_open_controls()
				return true
			if event.keycode == KEY_F5:
				_save_opening(gameplay_hud.failed_slot if gameplay_hud.failed_slot >= 0 else 0)
				gameplay_hud.journal.refresh_entries()
				return true
		return false
	if pause_owners.is_empty() and event is InputEventKey and event.pressed and not event.echo:
		if player.blocked_keys.has(event.keycode): return true
		if event.keycode == KEY_I:
			inventory_panel.open_panel()
			return true
		if event.keycode == KEY_K:
			skill_panel.open_panel()
			return true
		if event.keycode == KEY_F: return lamp_training.reveal()
		if event.keycode in [KEY_4,KEY_5]: return element_abilities.request("fire" if event.keycode == KEY_4 else "lightning")
		if event.keycode == KEY_6:
			if not training.player_locked() and not element_abilities.busy() and player.traversal.action == "" and training.phase == "idle":
				if dialogue_state.inventory.use_item(dialogue_state.quick_item): training.commit(); training.tell("物品已使用")
				else: training.tell("物品不可用 · I 查看背包")
			return true
		if event.keycode == KEY_M:
			gameplay_hud.map_page.open_panel()
			return true
		if event.keycode == KEY_J:
			gameplay_hud.journal.open_journal()
			return true
		if event.keycode == KEY_H:
			dialogue_state.tracker_collapsed = not dialogue_state.tracker_collapsed
			_save_opening(0)
			return true
		if event.keycode == KEY_F5:
			_save_opening(gameplay_hud.failed_slot if gameplay_hud.failed_slot >= 0 else 0)
			return true
	if pause_owners.has("failure") and not controls_panel.visible:
		return _handle_failure_input(event)
	if dialogue.opened and not controls_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F5:
			_save_opening(0)
			return true
		return dialogue.handle_input(event)
	if not controls_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_F10, KEY_ESCAPE]:
				_open_controls()
				return true
			if event.keycode == KEY_E and not player.blocked_keys.has(KEY_E):
				var target := contextual_interaction_target()
				if target and target.interact(): return true
			if event.keycode == KEY_E and not meadow_slice and not player.blocked_keys.has(KEY_E) and isha.can_interact(player):
				if dialogue_state.dialogue_kind != "isha":
					dialogue_state.conversation_active = false
				dialogue_state.dialogue_kind = "isha"
				_set_pause_owner("dialogue", true)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				dialogue.open_dialogue()
				return true
		return false
	return controls_panel.handle_menu_input(event)


func _add_hud_card(parent: Control, label: Label, font_size: int) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.065, 0.72)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", ui_font)
	label.add_theme_color_override("font_color", Color(0.91, 0.95, 0.98))
	label.add_theme_font_size_override("font_size", font_size)
	panel.add_child(label)



func open_ronen_dialogue() -> void:
	dialogue_state.dialogue_kind = "ronen"
	dialogue_state.conversation_active = false
	_set_pause_owner("dialogue", true)
	dialogue.open_dialogue()

func open_hers_dialogue() -> void:
	dialogue_state.dialogue_kind = "hers"
	dialogue_state.conversation_active = false
	_set_pause_owner("dialogue", true)
	dialogue.open_dialogue()

func show_failure() -> void:
	if pause_owners.has("failure"): return
	_set_pause_owner("failure", true)
	if not failure_panel: _build_failure()
	failure_busy = false
	failure_pending = null
	failure_armed = false
	failure_title.text = "冒险结束"
	failure_body.text = "命数已耗尽。加载早期存档，或开始新的冒险。"
	_refresh_failure_slots()
	_layout_failure()
	failure_root.show()
	failure_selection = 0
	_focus_failure.call_deferred(failure_selection)


func _build_failure() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FailureLayer"
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	failure_root = Control.new()
	failure_root.name = "GameOver"
	failure_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(failure_root)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.03, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	failure_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	failure_root.add_child(center)
	failure_panel = PanelContainer.new()
	failure_panel.name = "RecoveryPanel"
	# Local styles keep the shared dialogue palette and bindings unchanged.
	failure_panel.theme = preload("res://dialogue_theme.tres")
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.90, 0.82, 0.65, 1)
	paper.border_color = Color(0.68, 0.51, 0.26)
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(4)
	paper.set_content_margin_all(24)
	failure_panel.add_theme_stylebox_override("panel", paper)
	center.add_child(failure_panel)
	failure_scroll = ScrollContainer.new()
	failure_scroll.follow_focus = true
	failure_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	failure_panel.add_child(failure_scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	failure_scroll.add_child(column)
	failure_title = Label.new()
	failure_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(failure_title)
	var rule := HSeparator.new()
	column.add_child(rule)
	failure_body = Label.new()
	failure_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	failure_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(failure_body)
	for index in 4:
		var button := Button.new()
		button.name = ["LoadSlot1", "LoadSlot2", "NewGame", "ReturnToTitle"][index]
		button.text = ["加载槽位 1", "加载槽位 2", "新游戏", "返回标题"][index]
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_activate_failure.bind(index))
		button.focus_entered.connect(_remember_failure_focus.bind(index))
		# Reuse the dialogue component's already-bound CC0 frame and slicing.
		# Duplicate its styles so failure-specific feedback cannot alter dialogue.
		dialogue._style_choice(button)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		for variant in ["normal", "hover", "focus", "pressed", "disabled"]:
			var frame := button.get_theme_stylebox(variant).duplicate() as StyleBoxTexture
			frame.modulate_color = Color(0.80, 0.69, 0.48)
			if variant == "hover": frame.modulate_color = Color(0.94, 0.80, 0.55)
			if variant == "focus": frame.modulate_color = Color(1, 0.95, 0.75)
			if variant == "pressed": frame.modulate_color = Color(0.65, 0.49, 0.25)
			if variant == "disabled": frame.modulate_color = Color(0.69, 0.66, 0.59)
			button.add_theme_stylebox_override(variant, frame)
		var keyboard_ring := StyleBoxFlat.new()
		keyboard_ring.bg_color = Color(0, 0, 0, 0)
		keyboard_ring.border_color = Color(0.22, 0.13, 0.04)
		keyboard_ring.set_border_width_all(3)
		keyboard_ring.set_expand_margin_all(3)
		button.add_theme_stylebox_override("focus", keyboard_ring)
		button.add_theme_color_override("font_disabled_color", Color(0.32, 0.29, 0.24))
		column.add_child(button)
		failure_buttons.append(button)
	failure_hint = Label.new()
	failure_hint.text = "↑↓ / Tab 选择 · Enter 确认 · F10 设置"
	failure_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	failure_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(failure_hint)
	get_viewport().size_changed.connect(_layout_failure)


func _layout_failure() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var scale: float = dialogue_state.text_scale
	failure_scroll.custom_minimum_size = Vector2(minf(900, viewport_size.x - 96), minf(560 * scale, viewport_size.y - 96))
	failure_title.add_theme_font_size_override("font_size", int(32 * scale))
	failure_body.add_theme_font_size_override("font_size", int(20 * scale))
	failure_hint.add_theme_font_size_override("font_size", int(16 * scale))
	for button in failure_buttons:
		button.add_theme_font_size_override("font_size", int(22 * scale))


func _refresh_failure_slots() -> void:
	for index in 2:
		var reason: String = dialogue_state.slot_unavailable_reason(index + 1)
		failure_buttons[index].disabled = reason != ""
		failure_buttons[index].text = "加载槽位 %d" % (index + 1) + (" · " + reason if reason != "" else "")
	var enabled: Array[Button] = []
	for button in failure_buttons:
		button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
		if not button.disabled: enabled.append(button)
	for index in enabled.size():
		var button := enabled[index]
		var previous := button.get_path_to(enabled[posmod(index - 1, enabled.size())])
		var next := button.get_path_to(enabled[(index + 1) % enabled.size()])
		button.focus_neighbor_top = previous
		button.focus_previous = previous
		button.focus_neighbor_bottom = next
		button.focus_next = next


func _remember_failure_focus(index: int) -> void:
	failure_selection = index


func _focus_failure(index: int, direction := 1) -> void:
	if not failure_root.visible or controls_panel.visible: return
	for offset in failure_buttons.size():
		var candidate := posmod(index + offset * direction, failure_buttons.size())
		if not failure_buttons[candidate].disabled:
			failure_selection = candidate
			failure_buttons[candidate].grab_focus()
			return


func _confirmation_held() -> bool:
	return Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER) or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E)


func _handle_failure_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		if event.echo: return true
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			if event.pressed:
				if failure_armed and not failure_busy:
					failure_pending = failure_buttons[failure_selection]
				failure_armed = false
			else:
				var pending := failure_pending
				failure_pending = null
				if pending and pending == get_viewport().gui_get_focus_owner():
					_activate_failure(failure_buttons.find(pending))
			return true
		if event.pressed:
			if event.keycode == KEY_F10:
				_open_controls()
			elif event.keycode in [KEY_UP, KEY_DOWN, KEY_TAB]:
				failure_pending = null
				var direction := -1 if event.keycode == KEY_UP or (event.keycode == KEY_TAB and event.shift_pressed) else 1
				_focus_failure(failure_selection + direction, direction)
		return true
	# Consume world-facing mouse movement; native visible buttons receive clicks.
	return not event is InputEventMouseButton


func _activate_failure(index: int) -> void:
	if failure_busy or controls_panel.visible or not failure_root.visible or not pause_owners.has("failure"): return
	if index < 0 or index >= failure_buttons.size() or failure_buttons[index].disabled: return
	failure_busy = true
	failure_pending = null
	failure_armed = false
	failure_body.text = "正在恢复冒险…"
	match index:
		0, 1: _load_opening(index + 1)
		2: _new_adventure()
		3: _show_failure_title()
	failure_busy = false


func _recovery_error(message: String) -> void:
	if failure_body: failure_body.text = message
	controls_feedback.text = message


func _show_failure_title() -> void:
	_return_to_title()

func _return_to_title() -> void:
	if entry_router == null: return
	# Keep the committed safe boundary; never award/reset facts on title return.
	if training.commit_retry:
		_recovery_error("进度尚未保存。请重试保存后返回标题。")
		failure_busy = false
		return
	_set_pause_owner("title_return", true)
	entry_router.return_to_title()



func _finish_recovery() -> void:
	gameplay_hud.restore_view()
	if gameplay_hud.journal.visible or gameplay_hud.journal.suspended: gameplay_hud.journal.close_journal()
	if gameplay_hud.map_page.visible or gameplay_hud.map_page.suspended: gameplay_hud.map_page.close_panel()
	for panel in [inventory_panel,skill_panel]:
		if panel and (panel.visible or panel.suspended): panel.close_panel()
	var focus := get_viewport().gui_get_focus_owner()
	if focus: focus.release_focus()
	failure_pending = null
	failure_armed = false
	if controls_panel.visible: _close_controls()
	if failure_root: failure_root.hide()
	dialogue.root.hide()
	dialogue.opened = false
	dialogue.nested_menu = false
	_set_pause_owner("dialogue", false)
	_set_pause_owner("failure", false)
	player.velocity = Vector3.ZERO
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.set_meta("spawn_position", player.global_position)
	player._update_animation(false)
	training.tell("冒险已恢复")


func _new_adventure() -> void:
	if meadow_slice and entry_router:
		entry_router.begin_new_adventure_from_world()
		return
	var previous: Dictionary = dialogue_state.adventure_snapshot()
	var old_position := player.global_position
	if not training.place_on_ground(player, checkpoint_xz()):
		_recovery_error("检查点无法安全落地 · 冒险仍暂停，请重试。")
		return
	dialogue_state.reset_adventure()
	if dialogue_state.save_progress(player.global_position, 0.0) != OK:
		dialogue_state.restore_adventure(previous)
		player.global_position = old_position
		_recovery_error("新游戏保存失败 · 原冒险仍已结束，请重试。")
		return
	training.commit_retry = false
	training.restore_history()
	if bridge_actions: bridge_actions.restore_history()
	restored_position = {}
	player.arm.rotation = Vector3.ZERO
	_finish_recovery()
	training.tell("新冒险已开始 · 检查点已保存")


func _failure_observation() -> Dictionary:
	var actions := []
	for button in failure_buttons:
		if is_instance_valid(button) and not button.is_queued_for_deletion(): actions.append({"label": button.text, "disabled": button.disabled, "focused": button.has_focus()})
	var viewport := get_viewport() if is_inside_tree() else null
	var focus: Control = viewport.gui_get_focus_owner() if viewport else null
	return {"visible": is_instance_valid(failure_root) and not failure_root.is_queued_for_deletion() and failure_root.visible, "selection": failure_selection, "armed": failure_armed, "busy": failure_busy, "focus_owner": str(focus.get_path()) if focus else "", "text_scale": dialogue_state.text_scale if is_instance_valid(dialogue_state) and not dialogue_state.is_queued_for_deletion() else null, "actions": actions, "message": failure_body.text if is_instance_valid(failure_body) and not failure_body.is_queued_for_deletion() else null}

func _add_product_panels() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 24
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	inventory_panel = preload("res://ui/inventory_panel.tscn").instantiate()
	skill_panel = preload("res://ui/skill_panel.tscn").instantiate()
	for panel in [inventory_panel,skill_panel]:
		panel.world = self
		panel.state = dialogue_state
		panel.audio = menu_audio
		layer.add_child(panel)
		panel.hide()

func checkpoint_xz() -> Vector2:
	return ground_policy.SPAWN

func active_map_id() -> String:
	return dialogue_state.MAP02 if meadow_slice else GROUND.MAP_ID

func restored_xz(position: Vector3, map_id: String) -> Vector2:
	return ground_policy.entry_xz(position, map_id) if meadow_slice else GROUND.restored_xz(position, map_id)

func destination_ready() -> bool:
	return is_instance_valid(player) and player.has_meta("spawn_position") and is_instance_valid(training) and training.grounded and is_instance_valid(bow_training) and bow_training.grounded and is_instance_valid(bridge_encounter) and bridge_encounter.grounded and is_instance_valid(chapter_pillar) and chapter_pillar.grounded

func restore_destination_history() -> void:
	if dialogue_state.homecoming_completed and not meadow_slice and not is_instance_valid(homecoming_residents):
		homecoming_residents = preload("res://ui/homecoming_scene.gd").populate_village(self)
	training.restore_history()
	gameplay_hud.restore_view()

func travel_safe() -> bool:
	return pause_owners.is_empty() and training.can_save() and bow_training.can_save() and not training.player_locked() and player.attack_timer <= 0 and player.switch_timer <= 0 and player.traversal.action == ""
