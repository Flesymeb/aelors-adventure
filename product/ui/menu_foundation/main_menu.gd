extends MainMenu
## MainMenu submenu lifecycle adapted from Maaack Godot-Menus-Template (MIT).
var return_focus: Control
var audio: Node
var state: Node
var background: TextureRect
var _background_motion := Vector2.ZERO
func _open_sub_menu(menu: PackedScene) -> Node:
	return_focus = get_viewport().gui_get_focus_owner()
	return super._open_sub_menu(menu)
func _close_sub_menu() -> void:
	super._close_sub_menu()
	if is_instance_valid(return_focus): return_focus.grab_focus.call_deferred()
# Keep cancellation in the product's unhandled-input path, after submenu input.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == null and is_visible_in_tree():
		menu_buttons_box_container.focus_first()
func _process(delta: float) -> void:
	if not background: return
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
		var size_now := get_viewport_rect().size
		var scale_now: float = state.text_scale
		panel.custom_minimum_size.x = minf((660 if wide else 384) * scale_now, size_now.x - 80 if wide else size_now.x * 0.55)
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if wide else Control.SIZE_SHRINK_BEGIN
		parent.theme.default_font_size = int(22 * scale_now)
		title.add_theme_font_size_override("font_size", int((32 if wide else 42) * scale_now))
		scroll.custom_minimum_size.y = minf(column.get_combined_minimum_size().y, maxf(120, size_now.y - 140 - header.get_combined_minimum_size().y - 12))
		if column.get_child_count() > 0 and column.get_child(0) is BaseButton and column.get_child(0).has_focus(): scroll.scroll_vertical = 0
	column.minimum_size_changed.connect(func(): layout.call_deferred())
	header.minimum_size_changed.connect(func(): layout.call_deferred())
	get_viewport().size_changed.connect(layout)
	parent.tree_exiting.connect(func():
		if get_viewport().size_changed.is_connected(layout): get_viewport().size_changed.disconnect(layout))
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
		audio.play_cue("confirm")
		if source_button == null: callback.call())
	if item.get_parent() == null: column.add_child(item)
	elif item.get_parent() != column: item.reparent(column)
	return item
func paragraph(column: BoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	theme = preload("res://ui/title_theme.tres")
	state = router.state
	audio = router.audio
	scene_loader = router.loader
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
	var column := create_page(self, "艾洛的冒险", false, source_column, source_heading)
	menu_buttons_box_container = column
	var subtitle := source_subtitle
	subtitle.reparent(get_meta("header_column") as VBoxContainer)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	subtitle.remove_theme_font_size_override("font_size")
	subtitle.text = "AELOR’S ADVENTURE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
		if is_instance_valid(return_focus): return_focus.grab_focus.call_deferred())
func try_exit_game() -> void:
	show_confirmation("离开河谷？", "退出游戏。下次可继续最近保存的冒险。", func(): get_tree().quit())
func _unhandled_input(event: InputEvent) -> void:
	if not visible or router.route != "title": return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if sub_menu: sub_menu.close()
		elif confirmation: confirmation.close()
		else: try_exit_game()
		get_viewport().set_input_as_handled()
func _mcp_state() -> Dictionary:
	var buttons := []
	for item in actions: buttons.append({"text": item.text, "disabled": item.disabled, "rect": str(item.get_global_rect())})
	return {"visible": visible, "submenu": str(sub_menu.name) if sub_menu else "", "confirmation": confirmation != null, "text_scale": state.text_scale, "actions": buttons}
