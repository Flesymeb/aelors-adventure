extends Node3D

const SOURCE_SCENE := preload("res://world.tscn")
const PLAYER_SCENE := preload("res://Player.tscn")
const ARCHERY_HUD := preload("res://archery_hud.gd")
const ENVIRONMENT_QUALITY := preload("res://environment_quality.gd")
const GROUND := preload("res://forest_ground.gd")
const SPAWN_XZ := GROUND.SPAWN

signal entry_ready
signal entry_failed(message: String)
var entry_router: Node
var village: Node3D
var player: CharacterBody3D
var dusk := false
var quality: Node
var weapon_label: Label
var help_label: Label
var controls_panel: PanelContainer
var controls_list: VBoxContainer
var controls_feedback: Label
var control_buttons: Array[Button] = []
var controls_selection := 0
var capturing_control := ""
var previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var ui_font: Font = preload("res://dialogue_theme.tres").default_font
var dialogue_state: Node
var dialogue: CanvasLayer
var isha: StaticBody3D
var pause_owners: Dictionary = {}
var objective_label: Label
var prompt_label: Label
var developer_ui := false
var restored_position: Dictionary = {}
var text_scale_button: Button
var speed_button: Button
var instant_button: Button
var feedback_options: Dictionary = {}
var bow_training: Node3D
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	village = SOURCE_SCENE.instantiate()
	village.name = "Forest"
	village.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(village)
	var source_camera := village.get_node_or_null("Camera/Camera") as Camera3D
	if source_camera:
		source_camera.current = false
	player = PLAYER_SCENE.instantiate()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var initial_height: float = village.get_node("Terrain3D").data.get_height(Vector3(SPAWN_XZ.x, 0, SPAWN_XZ.y))
	player.position = Vector3(SPAWN_XZ.x, initial_height + 0.1, SPAWN_XZ.y)
	player.configure_equipment(false, false)
	add_child(player)
	player.get_node("CameraArm/Camera").current = true
	_add_village_buildings()
	_place_player.call_deferred()
	quality = Node.new()
	quality.set_script(ENVIRONMENT_QUALITY)
	add_child(quality)
	quality.configure(village)
	if dialogue_state == null:
		dialogue_state = preload("res://dialogue_state.gd").new()
		dialogue_state.name = "OpeningState"
		add_child(dialogue_state)
		restored_position = dialogue_state.load_progress()
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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if entry_router else Input.MOUSE_MODE_CAPTURED


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
	var xz := GROUND.restored_xz(restored_position.get("position", Vector3.ZERO), restored_position.get("map_id", ""))
	# Terrain collision initialization may lag scene _ready. Keep physics disabled
	# until the actual collision surface and standing volume are available.
	var placed := false
	for attempt in 120:
		await get_tree().physics_frame
		placed = GROUND.place(self, player, xz)
		if not placed and xz != SPAWN_XZ:
			xz = SPAWN_XZ
			placed = GROUND.place(self, player, xz)
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
	if restored_position.has("yaw"): player.arm.rotation.y = restored_position.yaw
	if dialogue_state.persistence_error != "":
		_recovery_error(dialogue_state.persistence_error)
		return
	if dialogue_state.conversation_active and dialogue_state.lives > 0:
		_set_pause_owner("dialogue", true)
		dialogue.open_dialogue(true)
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
			KEY_4: _set_dusk(not dusk)
			KEY_F11:
				if developer_ui: quality.toggle_developer_lamps()
			KEY_R:
				if developer_ui: player.respawn()
			KEY_G: quality.toggle_quality()
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	if pause_owners.has("failure") and not controls_panel.visible and not _confirmation_held() and failure_pending == null:
		failure_armed = true
	# Retain product pause intent after restart or an external debug step.
	# Leave external freezes alone when there is no product pause owner.
	if not pause_owners.is_empty() and not get_tree().paused:
		get_tree().paused = true
	if objective_label:
		objective_label.text = dialogue_state.objective()
		objective_label.get_parent().visible = not dialogue.opened
		var hers_prompt: String = training.interaction_prompt() if training and pause_owners.is_empty() else ""
		var bow_prompt: String = bow_training.interaction_prompt() if bow_training and pause_owners.is_empty() else ""
		if bow_prompt != "": hers_prompt = bow_prompt
		var available: bool = pause_owners.is_empty() and (isha.can_interact(player) or hers_prompt != "")
		prompt_label.text = hers_prompt if hers_prompt != "" else ("[E] 与伊莎交谈" if available else "")
		prompt_label.get_parent().visible = available
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
	if now_paused != was_paused:
		player.set_controls_open(now_paused)
		get_tree().paused = now_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if now_paused else Input.MOUSE_MODE_CAPTURED


func _open_controls() -> void:
	capturing_control = ""
	previous_mouse_mode = Input.mouse_mode
	_set_pause_owner("controls", true)
	dialogue.nested_menu = dialogue.opened
	if failure_root:
		failure_root.hide()
		failure_pending = null
		failure_armed = false
	controls_panel.show()
	controls_feedback.text = "方向键选移动绑定 · Enter 修改 · Backspace 默认\nF6 字号 · F7 速度 · F8 即时文字 · F5 保存 · Esc 返回"
	control_buttons[controls_selection].grab_focus()


func _dialogue_closed() -> void:
	_save_opening(0)
	_set_pause_owner("dialogue", false)


func _save_opening(slot: int) -> void:
	if training and (not training.can_save() or (bow_training and not bow_training.can_save())):
		dialogue_state.save_feedback = "战斗中不能保存 · 请先退回安全处"
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


func _load_opening(slot: int) -> void:
	var reason: String = dialogue_state.slot_unavailable_reason(slot)
	if reason != "":
		_recovery_error(reason)
		return
	var previous: Dictionary = dialogue_state.adventure_snapshot()
	var restored: Dictionary = dialogue_state.load_progress(slot)
	if restored.is_empty():
		_recovery_error("读取存档失败，请重试。")
		return
	var old_position := player.global_position
	if not training.place_on_ground(player, GROUND.restored_xz(restored.position, restored.get("map_id", ""))) and not training.place_on_ground(player, SPAWN_XZ):
		dialogue_state.restore_adventure(previous)
		_recovery_error("存档位置无法安全落地 · 请重试或选择新游戏。")
		return
	# Promote the selected history only after confirming real ground.
	if dialogue_state.save_progress(player.global_position, restored.yaw) != OK:
		dialogue_state.restore_adventure(previous)
		player.global_position = old_position
		_recovery_error("保存恢复进度失败 · 冒险仍暂停，请重试。")
		return
	player.arm.rotation.y = restored.yaw
	training.restore_history()
	restored_position = restored
	_refresh_reading_controls()
	_finish_recovery()
	if dialogue_state.conversation_active:
		_set_pause_owner("dialogue", true)
		dialogue.open_dialogue(true)


func _add_reading_controls() -> void:
	text_scale_button = Button.new()
	text_scale_button.pressed.connect(_cycle_text_scale)
	controls_list.add_child(text_scale_button)
	speed_button = Button.new()
	speed_button.pressed.connect(_cycle_reveal_speed)
	controls_list.add_child(speed_button)
	instant_button = Button.new()
	instant_button.pressed.connect(_toggle_instant_text)
	controls_list.add_child(instant_button)
	for slot in [1, 2]:
		var row := HBoxContainer.new()
		controls_list.add_child(row)
		var save := Button.new()
		save.text = "保存到槽位 %d" % slot
		save.pressed.connect(_save_opening.bind(slot))
		row.add_child(save)
		var load_button := Button.new()
		load_button.text = "加载槽位 %d" % slot
		load_button.pressed.connect(_load_opening.bind(slot))
		row.add_child(load_button)
	for option in ["reduced_motion", "muted_sound"]:
		var toggle := CheckButton.new()
		toggle.text = "减少反馈动态" if option == "reduced_motion" else "静音战斗反馈"
		toggle.button_pressed = dialogue_state.get(option)
		toggle.toggled.connect(_set_feedback_option.bind(option))
		controls_list.add_child(toggle)
		feedback_options[option] = toggle
	_refresh_reading_controls()

func _set_feedback_option(value: bool, option: String) -> void:
	dialogue_state.set(option, value)
	_save_preferences()

func _refresh_reading_controls() -> void:
	text_scale_button.text = "文字缩放 [F6] · %d%%" % int(dialogue_state.text_scale * 100)
	speed_button.text = "显示速度 [F7] · %d 字/秒" % int(dialogue_state.reveal_speed)
	instant_button.text = "即时显示 [F8] · " + ("开启" if dialogue_state.instant_text else "关闭")
	for option in feedback_options:
		feedback_options[option].set_pressed_no_signal(dialogue_state.get(option))
	dialogue._layout()
	if failure_panel: _layout_failure()


func _cycle_text_scale() -> void:
	dialogue_state.text_scale = 1.0 if dialogue_state.text_scale >= 2.0 else dialogue_state.text_scale + 0.5
	_refresh_reading_controls()
	_save_preferences()


func _cycle_reveal_speed() -> void:
	dialogue_state.reveal_speed = 15.0 if dialogue_state.reveal_speed >= 60.0 else dialogue_state.reveal_speed + 15.0
	_refresh_reading_controls()
	_save_preferences()


func _toggle_instant_text() -> void:
	dialogue_state.instant_text = not dialogue_state.instant_text
	_refresh_reading_controls()
	_save_preferences()


func _mcp_state() -> Dictionary:
	# Read existing product authorities. These facts do not create a route,
	# award equipment, or assert connected-slice completion.
	var story_actors: Array[String] = []
	for actor in get_tree().get_nodes_in_group("isha"):
		story_actors.append(str(actor.get_path()))
	var position := player.global_position
	var velocity := player.velocity
	return {"failure": _failure_observation(), "pause_owners": pause_owners.keys(), "tree_paused": get_tree().paused, "developer_ui": developer_ui, "controls_visible": controls_panel.visible, "isha_distance": player.global_position.distance_to(isha.global_position), "interaction_available": isha.interaction_available, "objective": dialogue_state.objective(), "equipment": player.weapon_mode, "owns_sword": player.owns_sword, "owns_bow": player.owns_bow, "player_position": [position.x, position.y, position.z], "player_velocity": [velocity.x, velocity.y, velocity.z], "opening_progress": dialogue_state._mcp_state(), "story_actors": story_actors, "authored_map": SOURCE_SCENE.resource_path, "player_scene": PLAYER_SCENE.resource_path, "lamp_overlay": quality.developer_lamp_overlay}


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
	objective_label = Label.new()
	_add_hud_card(layout, objective_label, 22)
	prompt_label = Label.new()
	_add_hud_card(layout, prompt_label, 22)
	var settings_cue := Label.new()
	settings_cue.text = "F10 设置与存档"
	_add_hud_card(layout, settings_cue, 16)
	var archery_hud := Control.new()
	archery_hud.set_script(ARCHERY_HUD)
	archery_hud.player = player
	layer.add_child(archery_hud)


func _refresh_control_prompts() -> void:
	help_label.text = "%s/%s/%s/%s move · Mouse look · %s jump · %s sprint · %s shoulder\nUnarmed · Weapons require ownership · E interact / F old lamp (reserved)\n%s crouch · %s prone · %s roll · %s dodge · %s perspective\nF10 controls · 3 skin · 4 dusk/day · G graphics · R respawn · Esc cursor" % [
		player.key_prompt("forward"), player.key_prompt("left"), player.key_prompt("back"), player.key_prompt("right"),
		player.key_prompt("jump"), player.key_prompt("sprint"), player.key_prompt("shoulder"),
		player.key_prompt("crouch"), player.key_prompt("prone"), player.key_prompt("roll"), player.key_prompt("dodge"), player.key_prompt("perspective")]
	for i in control_buttons.size():
		var action: String = player.CONTROL_DEFAULTS.keys()[i]
		control_buttons[i].text = "%s    [%s]" % [player.CONTROL_LABELS[action], player.key_prompt(action)]


func _add_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	controls_panel = PanelContainer.new()
	controls_panel.name = "LocomotionControls"
	controls_panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(controls_panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.065, 0.97)
	style.border_color = Color(0.65, 0.55, 0.32)
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	controls_panel.add_theme_stylebox_override("panel", style)
	controls_list = VBoxContainer.new()
	controls_list.add_theme_constant_override("separation", 3)
	controls_list.add_theme_font_override("font", ui_font)
	controls_list.add_theme_font_size_override("font_size", 17)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.custom_minimum_size = Vector2(580, 580)
	controls_panel.add_child(scroll)
	scroll.add_child(controls_list)
	controls_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "LOCOMOTION CONTROLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_list.add_child(title)
	for action in player.CONTROL_DEFAULTS:
		var button := Button.new()
		button.pressed.connect(_begin_capture.bind(String(action)))
		button.focus_entered.connect(_select_control.bind(control_buttons.size()))
		controls_list.add_child(button)
		control_buttons.append(button)
	controls_feedback = Label.new()
	controls_feedback.custom_minimum_size.x = 490
	controls_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_list.add_child(controls_feedback)
	var restore := Button.new()
	restore.text = "Restore defaults [Backspace]"
	restore.pressed.connect(_restore_controls)
	controls_list.add_child(restore)
	var close := Button.new()
	close.text = "Return to exploration [Esc / F10]"
	close.pressed.connect(_close_controls)
	controls_list.add_child(close)
	_add_reading_controls()
	var title_return := Button.new()
	title_return.text = "返回标题"
	title_return.pressed.connect(_return_to_title)
	controls_list.add_child(title_return)
	controls_panel.hide()


func _select_control(index: int) -> void:
	controls_selection = index


func _begin_capture(action: String) -> void:
	# A GUI button held while the panel closes can emit its callback later.
	# It must not arm the next visit's capture or consume exploration input.
	if not controls_panel.visible:
		return
	capturing_control = action
	controls_feedback.text = "Press an unused key for %s. Esc cancels.\nE / F and menu keys stay reserved." % player.CONTROL_LABELS[action]


func _restore_controls() -> void:
	capturing_control = ""
	var error: String = player.restore_controls()
	controls_feedback.text = "Default controls restored." if error == "" else error
	control_buttons[controls_selection].grab_focus()


func _close_controls() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus: focus.release_focus()
	controls_panel.hide()
	_set_pause_owner("controls", false)
	dialogue.nested_menu = false
	if dialogue.opened:
		# A release handled by the nested menu never reaches the dialogue.
		# Rearm only when all advance keys are up; a held key cannot submit.
		dialogue.advance_armed = not (Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER))
	capturing_control = ""
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
			if event.keycode == KEY_E and not player.blocked_keys.has(KEY_E) and bow_training and bow_training.interact():
				return true
			if event.keycode == KEY_E and not player.blocked_keys.has(KEY_E) and training and training.interact():
				return true
			if event.keycode == KEY_E and not player.blocked_keys.has(KEY_E) and isha.can_interact(player):
				if dialogue_state.dialogue_kind != "isha":
					dialogue_state.conversation_active = false
				dialogue_state.dialogue_kind = "isha"
				_set_pause_owner("dialogue", true)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				dialogue.open_dialogue()
				return true
		return false
	if event is InputEventKey:
		if event.echo: return true
		if not event.pressed:
			# Focused GUI buttons commit on release. World controls remain
			# gated by controls_open; only active key capture consumes it.
			return capturing_control != ""
		if capturing_control != "":
			if event.keycode == KEY_ESCAPE:
				capturing_control = ""
				controls_feedback.text = "Key change cancelled. Enter to try again."
			else:
				var error: String = player.rebind_control(capturing_control, event.keycode)
				if error == "":
					controls_feedback.text = "%s now uses %s. Esc returns to exploration." % [player.CONTROL_LABELS[capturing_control], player.key_prompt(capturing_control)]
					capturing_control = ""
				else:
					controls_feedback.text = error + " Esc cancels."
		elif event.keycode in [KEY_ESCAPE, KEY_F10]:
			_close_controls()
		elif event.keycode == KEY_BACKSPACE:
			_restore_controls()
		elif event.keycode == KEY_F5:
			_save_opening(0)
		elif event.keycode == KEY_F6:
			_cycle_text_scale()
		elif event.keycode == KEY_F7:
			_cycle_reveal_speed()
		elif event.keycode == KEY_F8:
			_toggle_instant_text()
		elif event.keycode in [KEY_UP, KEY_DOWN]:
			return false # Native focus traverses bindings, save controls and title return.
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			if control_buttons.has(get_viewport().gui_get_focus_owner()):
				_begin_capture(player.CONTROL_DEFAULTS.keys()[controls_selection])
			else:
				return false
		else:
			return false
		return true
	# Mouse clicks may reach controls buttons; the player suppresses all world
	# mouse input while the panel is open. Mouse motion never drives its camera.
	return not event is InputEventMouseButton


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

func _save_preferences() -> void:
	var error: Error = dialogue_state.save_preferences()
	controls_feedback.text = "设置已保存" if error == OK else "设置仅本次生效 · 保存失败，请重试"


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
	training.tell("冒险已恢复 · 检查点已保存")


func _new_adventure() -> void:
	var previous: Dictionary = dialogue_state.adventure_snapshot()
	var old_position := player.global_position
	if not training.place_on_ground(player, SPAWN_XZ):
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
	restored_position = {}
	player.arm.rotation = Vector3.ZERO
	_finish_recovery()
	training.tell("新冒险已开始 · 检查点已保存")


func _failure_observation() -> Dictionary:
	var actions := []
	for button in failure_buttons:
		actions.append({"label": button.text, "disabled": button.disabled, "focused": button.has_focus()})
	var focus := get_viewport().gui_get_focus_owner()
	return {"visible": failure_root != null and failure_root.visible, "selection": failure_selection, "armed": failure_armed, "busy": failure_busy, "focus_owner": str(focus.get_path()) if focus else "", "text_scale": dialogue_state.text_scale, "actions": actions, "message": failure_body.text if failure_body else ""}
