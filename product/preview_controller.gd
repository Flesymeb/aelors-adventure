extends Node3D

const SOURCE_SCENE := preload("res://Demo/Slavica Free 2026 Version.scn")
const PLAYER_SCENE := preload("res://Player.tscn")
const ARCHERY_HUD := preload("res://archery_hud.gd")
const ENVIRONMENT_QUALITY := preload("res://environment_quality.gd")
const SPAWN_XZ := Vector2(20.0, 20.0)

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	village = SOURCE_SCENE.instantiate()
	village.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(village)
	var source_camera := village.get_node_or_null("Camera/Camera") as Camera3D
	if source_camera:
		source_camera.current = false
	player = PLAYER_SCENE.instantiate()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.configure_equipment(false, false)
	add_child(player)
	player.get_node("CameraArm/Camera").current = true
	_place_player.call_deferred()
	quality = Node.new()
	quality.set_script(ENVIRONMENT_QUALITY)
	add_child(quality)
	quality.configure(village)
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
	isha.position = Vector3(20.5, 0, 17.0)
	add_child(isha)
	_add_snowfall()
	_add_help()
	_add_controls()
	player.controls_changed.connect(_refresh_control_prompts)
	_refresh_control_prompts()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _place_player() -> void:
	await get_tree().physics_frame
	var xz := SPAWN_XZ
	if restored_position.has("position"):
		var saved: Vector3 = restored_position.position
		if Vector2(saved.x, saved.z).distance_to(SPAWN_XZ) < 35:
			xz = Vector2(saved.x, saved.z)
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(xz.x, 100.0, xz.y), Vector3(xz.x, -100.0, xz.y),
		1, [player.get_rid(), isha.get_rid()]
	)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		player.global_position = hit.position + Vector3(0, 0.08, 0)
	else:
		player.global_position = Vector3(xz.x, 0, xz.y)
	player.set_meta("spawn_position", player.global_position)
	if restored_position.has("yaw"): player.arm.rotation.y = restored_position.yaw
	if dialogue_state.conversation_active:
		_set_pause_owner("dialogue", true)
		dialogue.open_dialogue(true)
	var snow := player.get_node_or_null("LocalSnowfall") as CPUParticles3D
	if snow:
		snow.emitting = true
		snow.restart()


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
	# Retain product pause intent after restart or an external debug step.
	# Leave external freezes alone when there is no product pause owner.
	if not pause_owners.is_empty() and not get_tree().paused:
		get_tree().paused = true
	if objective_label:
		objective_label.text = dialogue_state.objective()
		objective_label.get_parent().visible = not dialogue.opened
		var available: bool = pause_owners.is_empty() and isha.can_interact(player)
		prompt_label.text = "[E] 与伊莎交谈" if available else ""
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
	controls_panel.show()
	controls_feedback.text = "方向键选移动绑定 · Enter 修改 · Backspace 默认\nF6 字号 · F7 速度 · F8 即时文字 · F5 保存 · Esc 返回"
	control_buttons[controls_selection].grab_focus()


func _dialogue_closed() -> void:
	_save_opening(0)
	_set_pause_owner("dialogue", false)


func _save_opening(slot: int) -> void:
	dialogue_state.save_progress(player.global_position, player.arm.rotation.y, slot)
	if controls_feedback:
		controls_feedback.text = dialogue_state.save_feedback + (" · 槽位 %d" % slot if slot > 0 else "")
	if dialogue.opened:
		dialogue.footer.text = (dialogue_state.reward_feedback + " · " if dialogue_state.reward_feedback != "" else "") + dialogue_state.save_feedback + " · F10 设置与存档 · Esc 离开"


func _load_opening(slot: int) -> void:
	var restored: Dictionary = dialogue_state.load_progress(slot)
	if restored.is_empty():
		controls_feedback.text = "槽位 %d 暂无存档" % slot
		return
	var saved: Vector3 = restored.position
	# Restore onto real ground after the UI releases the world, never trust saved Y.
	if Vector2(saved.x, saved.z).distance_to(SPAWN_XZ) > 35:
		controls_feedback.text = "存档位置不在开场安全区域"
		return
	restored_position = restored
	_close_controls()
	dialogue.root.hide()
	dialogue.opened = false
	_set_pause_owner("dialogue", false)
	_place_player.call_deferred()


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
	_refresh_reading_controls()


func _refresh_reading_controls() -> void:
	text_scale_button.text = "文字缩放 [F6] · %d%%" % int(dialogue_state.text_scale * 100)
	speed_button.text = "显示速度 [F7] · %d 字/秒" % int(dialogue_state.reveal_speed)
	instant_button.text = "即时显示 [F8] · " + ("开启" if dialogue_state.instant_text else "关闭")
	dialogue._layout()


func _cycle_text_scale() -> void:
	dialogue_state.text_scale = 1.0 if dialogue_state.text_scale >= 2.0 else dialogue_state.text_scale + 0.5
	_refresh_reading_controls()
	_save_opening(0)


func _cycle_reveal_speed() -> void:
	dialogue_state.reveal_speed = 15.0 if dialogue_state.reveal_speed >= 60.0 else dialogue_state.reveal_speed + 15.0
	_refresh_reading_controls()
	_save_opening(0)


func _toggle_instant_text() -> void:
	dialogue_state.instant_text = not dialogue_state.instant_text
	_refresh_reading_controls()
	_save_opening(0)


func _mcp_state() -> Dictionary:
	# Read existing product authorities. These facts do not create a route,
	# award equipment, or assert connected-slice completion.
	var story_actors: Array[String] = []
	for actor in get_tree().get_nodes_in_group("isha"):
		story_actors.append(str(actor.get_path()))
	var position := player.global_position
	var velocity := player.velocity
	return {"pause_owners": pause_owners.keys(), "tree_paused": get_tree().paused, "developer_ui": developer_ui, "controls_visible": controls_panel.visible, "isha_distance": player.global_position.distance_to(isha.global_position), "interaction_available": isha.interaction_available, "objective": dialogue_state.objective(), "equipment": player.weapon_mode, "owns_sword": player.owns_sword, "owns_bow": player.owns_bow, "player_position": [position.x, position.y, position.z], "player_velocity": [velocity.x, velocity.y, velocity.z], "opening_progress": dialogue_state._mcp_state(), "story_actors": story_actors, "authored_map": SOURCE_SCENE.resource_path, "player_scene": PLAYER_SCENE.resource_path, "lamp_overlay": quality.developer_lamp_overlay}


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
	controls_panel.hide()
	_set_pause_owner("controls", false)
	dialogue.nested_menu = false
	if dialogue.opened:
		# A release handled by the nested menu never reaches the dialogue.
		# Rearm only when all advance keys are up; a held key cannot submit.
		dialogue.advance_armed = not (Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER))
	capturing_control = ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if dialogue.opened else previous_mouse_mode


# Called at the start of the player's _input, before mouse attacks and before
# either script's _unhandled_input. Captured keys cannot leak into the world.
func handle_controls_input(event: InputEvent) -> bool:
	if dialogue.opened and not controls_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F5:
			_save_opening(0)
			return true
		return dialogue.handle_input(event)
	if not controls_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_F10:
				_open_controls()
				return true
			if event.keycode == KEY_E and not player.blocked_keys.has(KEY_E) and isha.can_interact(player):
				_set_pause_owner("dialogue", true)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				dialogue.open_dialogue()
				return true
		return false
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return true
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
			controls_selection = posmod(controls_selection + (1 if event.keycode == KEY_DOWN else -1), control_buttons.size())
			control_buttons[controls_selection].grab_focus()
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


func _add_snowfall() -> void:
	var snow := CPUParticles3D.new()
	snow.name = "LocalSnowfall"
	snow.position.y = 5.7
	snow.emitting = false
	snow.amount = 260
	snow.lifetime = 6.0
	snow.preprocess = 6.0
	snow.local_coords = false
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(9.0, 1.3, 9.0)
	snow.direction = Vector3(0.08, -1.0, 0.03)
	snow.spread = 12.0
	snow.initial_velocity_min = 0.65
	snow.initial_velocity_max = 1.55
	snow.gravity = Vector3(0.07, -0.18, 0.0)
	snow.scale_amount_min = 0.55
	snow.scale_amount_max = 1.25
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = Color(0.76, 0.85, 0.96, 0.78)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.055, 0.055)
	quad.material = material
	snow.mesh = quad
	player.add_child(snow)
