extends MainMenu
## MainMenu submenu lifecycle adapted from Maaack Godot-Menus-Template (MIT).
var pause_world: Node3D
var cinematic: Control
var return_scroll := 0
var return_focus: Control
var audio: Node
var state: Node
var background: TextureRect
var _background_motion := Vector2.ZERO
func _open_sub_menu(menu: PackedScene) -> Node:
	return_focus = get_viewport().gui_get_focus_owner()
	return_scroll = find_child("PageScroll", true, false).scroll_vertical
	return super._open_sub_menu(menu)
func _close_sub_menu() -> void:
	super._close_sub_menu()
	find_child("PageScroll", true, false).scroll_vertical = return_scroll
	_restore_parent_focus.call_deferred()
# Keep cancellation in the product's unhandled-input path, after submenu input.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == null and is_visible_in_tree():
		menu_buttons_box_container.focus_first()
func _process(delta: float) -> void:
	if not background or not is_visible_in_tree(): return
	var target := Vector2.ZERO
	if not state.reduced_motion:
		target = -(get_viewport().get_mouse_position() / get_viewport_rect().size - Vector2(0.5, 0.5)).clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5)) * 8.0
	_background_motion = _background_motion.lerp(target, 1.0 - exp(-5.5 * delta))
	background.offset_left = -12 + _background_motion.x
	background.offset_top = -12 + _background_motion.y
	background.offset_right = 12 + _background_motion.x
	background.offset_bottom = 12 + _background_motion.y
func create_page(parent: Control, heading: String, wide := false, source_column: BoxContainer = null, source_heading: Label = null) -> BoxContainer:
	parent.theme = preload("res://ui/title_theme.tres").duplicate()
	var margin := MarginContainer.new()
	margin.name = "PageMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(margin)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 40)
	var alignment := HBoxContainer.new()
	alignment.alignment = BoxContainer.ALIGNMENT_CENTER if wide else BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(alignment)
	var panel := PanelContainer.new()
	panel.name = "Parchment"
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	alignment.add_child(panel)
	var paper := StyleBoxTexture.new()
	paper.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-013.png")
	paper.modulate_color = Color(0.87, 0.79, 0.61, 0.97)
	for side in 4:
		paper.set_texture_margin(side, 16)
		paper.set_content_margin(side, 26)
	panel.add_theme_stylebox_override("panel", paper)
	var grain := TextureRect.new()
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noise := NoiseTexture2D.new()
	var generator := FastNoiseLite.new()
	generator.frequency = 0.14
	noise.noise = generator
	grain.texture = noise
	grain.modulate = Color(0.34, 0.23, 0.12, 0.12)
	grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.add_child(grain)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	outer.add_child(header)
	parent.set_meta("header_column", header)
	var scroll := ScrollContainer.new()
	scroll.name = "PageScroll"
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var footer := VBoxContainer.new()
	footer.name = "PageFooter"
	outer.add_child(footer)
	parent.set_meta("footer_column", footer)
	var column := source_column if source_column != null else VBoxContainer.new()
	if column.get_parent(): column.get_parent().remove_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	if source_column == null: column.set_script(preload("res://ui/menu_foundation/capture_focus.gd"))
	column.search_depth = 2
	scroll.add_child(column)
	var title := source_heading if source_heading != null else Label.new()
	if title.get_parent(): title.get_parent().remove_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	title.name = "Heading"
	title.text = heading
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)
	var divider := TextureRect.new()
	var lamp := AtlasTexture.new()
	lamp.atlas = preload("res://assets/ui/main_menu_icons.svg")
	lamp.region = Rect2(320, 0, 64, 64)
	divider.texture = lamp
	divider.custom_minimum_size = Vector2(0, 46)
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(divider)
	var layout := func():
		if not is_instance_valid(parent) or not parent.is_inside_tree() or not is_instance_valid(panel): return
		var size_now := get_viewport_rect().size
		var scale_now: float = state.text_scale
		panel.custom_minimum_size.x = minf((parent.get_meta("page_width", 660) if wide else 384) * scale_now, size_now.x - 80 if wide else size_now.x * 0.55)
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if wide else Control.SIZE_SHRINK_BEGIN
		parent.theme.default_font_size = int(22 * scale_now)
		title.add_theme_font_size_override("font_size", int((parent.get_meta("page_heading_size", 32) if wide else 42) * scale_now))
		scroll.custom_minimum_size.y = minf(column.get_combined_minimum_size().y, maxf(120, size_now.y - 140 - header.get_combined_minimum_size().y - footer.get_combined_minimum_size().y - 24))
		if column.get_child_count() > 0 and column.get_child(0) is BaseButton and column.get_child(0).has_focus(): scroll.scroll_vertical = 0
	column.minimum_size_changed.connect(func(): layout.call_deferred())
	header.minimum_size_changed.connect(func(): layout.call_deferred())
	footer.minimum_size_changed.connect(func(): layout.call_deferred())
	get_viewport().size_changed.connect(layout)
	parent.tree_exiting.connect(func():
		if is_inside_tree() and get_viewport().size_changed.is_connected(layout): get_viewport().size_changed.disconnect(layout))
	parent.set_meta("page_layout", layout)
	layout.call_deferred()
	if parent == self: menu_container = panel
	return column
func button(column: BoxContainer, text: String, callback: Callable, icon_index := -1, source_button: Button = null) -> Button:
	var item := source_button if source_button != null else Button.new()
	item.text = text
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.custom_minimum_size.y = 48
	item.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	for variant in ["normal", "hover", "focus", "pressed", "disabled"]:
		var frame := StyleBoxTexture.new()
		frame.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-003.png")
		frame.modulate_color = Color(0.75, 0.65, 0.44, 0.2)
		if variant == "hover": frame.modulate_color = Color(0.98, 0.82, 0.42, 0.75)
		if variant == "focus": frame.modulate_color = Color(1.0, 0.81, 0.35, 1.0)
		if variant == "pressed": frame.modulate_color = Color(0.64, 0.48, 0.25, 1.0)
		if variant == "disabled": frame.modulate_color = Color(0.60, 0.56, 0.45, 0.15)
		for side in 4:
			frame.set_texture_margin(side, 16)
			frame.set_content_margin(side, 12)
		item.add_theme_stylebox_override(variant, frame)
	if icon_index >= 0:
		var icon := AtlasTexture.new()
		icon.atlas = preload("res://assets/ui/main_menu_icons.svg")
		icon.region = Rect2(icon_index * 64, 0, 64, 64)
		item.icon = icon
		item.expand_icon = true
		item.add_theme_constant_override("icon_max_width", 30)
		item.add_theme_constant_override("h_separation", 18)
	item.focus_entered.connect(func():
		if not item.disabled: audio.play_cue("focus"))
	item.mouse_entered.connect(func():
		if not item.disabled: audio.play_cue("focus"))
	item.gui_input.connect(func(event: InputEvent):
		if item.disabled and event is InputEventMouseButton and event.pressed: audio.play_cue("unavailable"))
	item.pressed.connect(func():
		if item.disabled: return
		if (source_button == null or pause_world != null or cinematic != null) and not item.is_visible_in_tree(): return
		audio.play_cue("confirm")
		if source_button == null or pause_world != null or cinematic != null: callback.call())
	if item.get_parent() == null: column.add_child(item)
	elif item.get_parent() != column: item.reparent(column)
	return item
func paragraph(column: BoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(label)
	return label
func reflow(page: Control) -> void:
	if page.has_meta("page_layout"): page.get_meta("page_layout").call_deferred()

var router: Node
var continue_button: Button
var status_label: Label
var confirmation: Control
var actions: Array[Button] = []
func get_game_scene_path() -> String:
	return "res://Preview.tscn"
func load_game_scene() -> void:
	new_game()
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = preload("res://ui/title_theme.tres")
	state = pause_world.dialogue_state if pause_world else router.state
	audio = router.audio if router else pause_world.menu_audio
	scene_loader = router.loader if router else null
	# Use the copied Maaack scene's editable runtime nodes, then reflow them
	# into the already qualified product parchment layout.
	var source_menu: Control = %MenuContainer
	var source_column: BoxContainer = %MenuButtonsBoxContainer
	var source_heading: Label = source_menu.get_node("TitleMargin/TitleContainer/TitleLabel")
	var source_subtitle: Label = source_menu.get_node("SubTitleMargin/SubTitleContainer/SubTitleLabel")
	var source_new: Button = %NewGameButton
	var source_settings: Button = %OptionsButton
	var source_load: Button = %CreditsButton
	var source_exit: Button = %ExitButton
	background = $BackgroundTextureRect
	background.texture = preload("res://assets/ui/main_menu_background.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := create_page(self, "开场暂停" if cinematic else ("暂停" if pause_world else "艾洛的冒险"), pause_world != null or cinematic != null, source_column, source_heading)
	menu_buttons_box_container = column
	var subtitle := source_subtitle
	subtitle.reparent(get_meta("header_column") as VBoxContainer)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	subtitle.remove_theme_font_size_override("font_size")
	subtitle.text = "AELOR’S ADVENTURE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if cinematic:
		background.hide()
		_build_cinematic(column, source_new, source_settings, source_load, source_exit)
		source_menu.queue_free()
		reflow(self)
		return
	if pause_world:
		_build_pause(column, source_new, source_settings, source_load, source_exit)
		source_menu.queue_free()
		reflow(self)
		return
	actions.append(button(column, "新游戏", new_game, 0, source_new))
	continue_button = button(column, "继续", func(): router.enter_adventure("continue", 0), 1)
	column.move_child(continue_button, 1)
	actions.append(continue_button)
	actions.append(button(column, "加载", func(): _open_sub_menu(preload("res://ui/load_menu.tscn")), 2, source_load))
	actions.append(button(column, "设置", func(): _open_sub_menu(preload("res://ui/title_settings.tscn")), 3, source_settings))
	actions.append(button(column, "退出", try_exit_game, 4, source_exit))
	for index in actions.size(): column.move_child(actions[index], index)
	source_menu.queue_free()
	for index in actions.size(): actions[index].name = ["NewGameButton", "ContinueButton", "LoadButton", "SettingsButton", "ExitButton"][index]
	status_label = paragraph(column, "")
	status_label.add_theme_font_size_override("font_size", int(16 * state.text_scale))
	refresh()
	actions[0].grab_focus.call_deferred()
	reflow(self)
func refresh() -> void:
	if cinematic:
		status_label.text = "河谷遇袭 · %d / 4\n演出已暂停 · 尚未替换冒险进度" % (cinematic.beat + 1)
		return
	if pause_world:
		status_label.text = "第一章 · 河谷聚落\n检查点：河谷村庄灯台 · 命数 %d / 5" % state.lives
		return
	status_label.add_theme_font_size_override("font_size", int(16 * state.text_scale))
	var reason: String = state.slot_unavailable_reason(0, true)
	continue_button.disabled = reason != ""
	continue_button.focus_mode = Control.FOCUS_NONE if continue_button.disabled else Control.FOCUS_ALL
	continue_button.tooltip_text = reason
	status_label.text = reason if reason != "" else "河谷聚落 · 自动恢复档"
	if reason == "" and state.slot_preview(0).get("lives", 3) == 0:
		status_label.text = "命数已耗尽 · 继续可选择恢复方式"
func new_game() -> void:
	if FileAccess.file_exists(state.SAVE_PATH):
		show_confirmation("开始新的冒险？", "新的冒险将替换自动恢复进度。两个手动存档会保留。", func(): router.enter_adventure("new", 0))
	else: router.enter_adventure("new", 0)
func show_confirmation(heading: String, message: String, action: Callable) -> void:
	if confirmation: return
	return_focus = get_viewport().gui_get_focus_owner()
	confirmation = preload("res://ui/menu_foundation/confirmation_window.tscn").instantiate()
	confirmation.host = self
	confirmation.heading = heading
	confirmation.message = message
	confirmation.action = action
	add_child(confirmation)
	menu_container.hide()
	confirmation.closed.connect(func():
		confirmation.queue_free()
		confirmation = null
		menu_container.show()
		_restore_parent_focus.call_deferred())
func try_exit_game() -> void:
	show_confirmation("离开河谷？", "退出游戏。下次可继续最近保存的冒险。", func(): get_tree().quit())
func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or (pause_world == null and cinematic == null and router.route != "title"): return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if sub_menu: sub_menu.close()
		elif confirmation: confirmation.close()
		else:
			if cinematic: cinematic.close_pause()
			elif pause_world: pause_world._close_controls()
			else: try_exit_game()
		get_viewport().set_input_as_handled()
func _mcp_state() -> Dictionary:
	var buttons := []
	for item in actions: buttons.append({"text": item.text, "disabled": item.disabled, "rect": str(item.get_global_rect())})
	return {"visible": visible, "submenu": str(sub_menu.name) if sub_menu else "", "confirmation": confirmation != null, "text_scale": state.text_scale, "preferences": state.preference_snapshot(), "caller": "cinematic" if cinematic else ("pause" if pause_world else "title"), "actions": buttons}

func _build_cinematic(column: BoxContainer, resume: Button, settings: Button, unused: Button, quit_button: Button) -> void:
	for item in [resume, settings, unused, quit_button]:
		for connection in item.pressed.get_connections(): item.pressed.disconnect(connection.callable)
	unused.queue_free()
	actions.append(button(column, "继续开场", cinematic.close_pause, 1, resume))
	actions.append(button(column, "设置", func(): _open_sub_menu(preload("res://ui/title_settings.tscn")), 3, settings))
	actions.append(button(column, "跳过开场", cinematic.finish))
	actions.append(button(column, "返回标题", func(): show_confirmation("返回标题？", "开场尚未完成。原有存档会保留，下次新游戏从开场重新开始。", router.return_to_title)))
	actions.append(button(column, "退出", try_exit_game, 4, quit_button))
	for index in actions.size(): column.move_child(actions[index], index)
	status_label = paragraph(column, "")
	refresh()
	column.focus_first.call_deferred()

func _build_pause(column: BoxContainer, resume: Button, settings: Button, slots: Button, exit_button_source: Button) -> void:
	for item in [resume, settings, slots, exit_button_source]:
		for connection in item.pressed.get_connections(): item.pressed.disconnect(connection.callable)
	# Reuse MainMenu nodes/lifecycle; never restore the source window's saved
	# boolean pause state. The product owner keeps the pause_world frozen throughout.
	actions.append(button(column, "继续冒险", pause_world._close_controls, 1, resume))
	actions.append(button(column, "存档与加载", func(): _open_sub_menu(preload("res://ui/load_menu.tscn")), 2, slots))
	actions.append(button(column, "设置", func(): _open_sub_menu(preload("res://ui/title_settings.tscn")), 3, settings))
	actions.append(button(column, "帮助", open_help))
	actions.append(button(column, "返回标题", func(): show_confirmation("返回标题？", "未保存的探索进度将不会保留。", pause_world._return_to_title)))
	actions.append(button(column, "退出", try_exit_game, 4, exit_button_source))
	for index in actions.size():
		column.move_child(actions[index], index)
		actions[index].name = ["Resume", "SaveLoad", "Settings", "Help", "ReturnTitle", "Quit"][index]
	status_label = paragraph(column, "")
	pause_world.controls_feedback = status_label
	refresh()

func open_pause() -> void:
	refresh()
	show()
	menu_buttons_box_container.focus_first.call_deferred()

func handle_menu_input(event: InputEvent) -> bool:
	if sub_menu and sub_menu.has_method("handle_input") and sub_menu.handle_input(event): return true
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_F10]:
		if sub_menu: sub_menu.close()
		elif confirmation: confirmation.close()
		elif pause_world: pause_world._close_controls()
		return true
	return false

func open_help() -> void:
	var page := Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return_focus = get_viewport().gui_get_focus_owner()
	return_scroll = find_child("PageScroll", true, false).scroll_vertical
	add_child(page)
	menu_container.hide()
	var column := create_page(page, "旅途指南", true)
	paragraph(column, "移动与观察：鼠标环视，滚轮调整距离。操作页可查看与修改移动按键。")
	paragraph(column, "E 与附近人物交谈。J 查看任务日志，H 收起目标。")
	if state.sword_owned: paragraph(column, "1 巡路剑 · 左键挥剑 · 右键防御 · Q 振刀。")
	if state.bow_owned: paragraph(column, "2 巡路弓 · 右键瞄准 · 左键蓄力后释放。箭用尽可找罗恩补充。")
	button(page.get_meta("footer_column"), "返回", func(): page.hide())
	page.hidden.connect(func():
		page.queue_free()
		sub_menu = null
		menu_container.show()
		find_child("PageScroll", true, false).scroll_vertical = return_scroll
		_restore_parent_focus.call_deferred())
	# Help is an ordinary child page with the same cancellation contract.
	page.set_script(preload("res://ui/menu_help.gd"))
	sub_menu = page
	column.focus_first.call_deferred()

func _restore_parent_focus() -> void:
	# Deferred child cleanup may finish after loading/resuming hid the parent.
	if not is_visible_in_tree() or not menu_container.is_visible_in_tree(): return
	if is_instance_valid(return_focus) and return_focus.is_visible_in_tree(): return_focus.grab_focus()
