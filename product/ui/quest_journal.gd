extends "res://ui/menu_foundation/main_menu.gd"
## Maaack scene inheritance, CaptureFocus and submenu return lifecycle retained.
var world: Node3D
var selection := ""
var category := "current"
var suspended := false
var quest_list: VBoxContainer
var details: RichTextLabel
var detail_heading: Label
var track_button: Button
var footer_status: Label
var rows: Array[Dictionary] = []
var list_buttons: Array[Button] = []
var detail_column: VBoxContainer
var column: VBoxContainer
var entries_signature := ""

static func project_entries(owner: Node) -> Array[Dictionary]:
	var projected: Array[Dictionary] = owner.quest_entries().duplicate(true)
	for row in projected:
		if row.id != "route_record" or not owner.mf01_acquired: continue
		row.context = preload("res://ui/map_page.gd").mf01_navigation(owner)
		if not owner.e03_revealed:
			row.action = "从固定路碑沿树根左侧到旧灯调查处；3 装备旧灯，F 显形，靠近魔痕后 E 调查。"
	return projected

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$BackgroundTextureRect.hide()
	%MenuContainer.hide()
	set_meta("page_width", 1060)
	set_meta("page_heading_size", 24)
	column = create_page(self, "旅途日志", true)
	get_meta("header_column").get_child(1).hide()
	var tabs := HBoxContainer.new()
	get_meta("header_column").add_child(tabs)
	button(tabs, "当前", func(): _set_category("current"))
	button(tabs, "已完成", func(): _set_category("completed"))
	button(tabs, "帮助", func(): _set_category("help"))
	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 24)
	column.add_child(spread)
	quest_list = VBoxContainer.new()
	quest_list.set_script(preload("res://ui/menu_foundation/capture_focus.gd"))
	quest_list.search_depth = 2
	quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_list.size_flags_stretch_ratio = 0.38
	spread.add_child(quest_list)
	var right := VBoxContainer.new()
	detail_column = right
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.62
	spread.add_child(right)
	detail_heading = paragraph(right, "")
	details = RichTextLabel.new()
	preload("res://ui/quest_markup.gd").configure(details,preload("res://ui/gameplay_theme.tres").default_font,true)
	details.fit_content = false
	details.scroll_active = true
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(details)
	var footer: VBoxContainer = get_meta("footer_column")
	footer_status = paragraph(footer, "")
	var actions_row := HBoxContainer.new()
	footer.add_child(actions_row)
	track_button = button(actions_row, "追踪此任务", _track_selected)
	track_button.icon = preload("res://assets/ui/journal_icons.svg")
	button(actions_row, "返回 [J / Esc]", close_journal)
	visibility_changed.connect(func():
		if not visible and not suspended: world._set_pause_owner("journal", false))
	get_viewport().size_changed.connect(_layout_details)
	refresh_entries()

func _layout_details() -> void:
	var header: VBoxContainer = get_meta("header_column")
	var footer: VBoxContainer = get_meta("footer_column")
	var available := get_viewport_rect().size.y - 160 - header.get_combined_minimum_size().y - footer.get_combined_minimum_size().y
	details.custom_minimum_size.y = maxf(120, available - detail_heading.get_combined_minimum_size().y - 12)
	reflow(self)

func open_journal() -> void:
	world._set_pause_owner("journal", true)
	category = "current"
	selection = state.tracked_quest
	show()
	refresh_entries()
	for item in list_buttons:
		if item.get_meta("quest_id", "") == selection:
			item.grab_focus.call_deferred()
			return
	quest_list.focus_first.call_deferred()

func suspend_for_menu() -> void:
	suspended = true
	hide()

func resume_from_menu() -> void:
	suspended = false
	show()
	refresh_entries()
	quest_list.focus_first.call_deferred()

func close_journal() -> void:
	suspended = false
	world._set_pause_owner("journal", false)
	audio.play_cue("back")
	var focus := get_viewport().gui_get_focus_owner()
	if focus: focus.release_focus()
	hide()

func _set_category(value: String) -> void:
	category = value
	refresh_entries()
	quest_list.focus_first.call_deferred()

func refresh_entries() -> void:
	rows = project_entries(state)
	entries_signature = JSON.stringify(rows)
	details.fit_content = false
	details.scroll_active = true
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for child in quest_list.get_children():
		quest_list.remove_child(child)
		child.queue_free()
	list_buttons.clear()
	if category == "help":
		selection = ""
		paragraph(quest_list, "已学操作可随时回看")
		detail_heading.text = "行路与战斗"
		details.text = "%s / %s / %s / %s 移动\n鼠标环视 · 滚轮拉近 / 拉远\n%s 切肩 · %s 切换视角\nM 地图 · J 日志 · H 折叠目标 · Esc 暂停 · I 背包 · K 能力\n\n靠近人物后按 E 交谈。\n取得巡路剑后：左键挥剑，右键防御，适时按 E 振刀。\n取得巡路弓后：右键瞄准，按住左键蓄力，松开射箭；瞄准中滚轮不改变自由观察距离。\n\n旧灯：3 装备、F 显形、E 调查。元素：4 火焰、5 雷电。6 使用所设物品。\n完成练习后提示会收起；罗恩可以免费补箭。" % [world.player.key_prompt("forward"), world.player.key_prompt("left"), world.player.key_prompt("back"), world.player.key_prompt("right"), world.player.key_prompt("shoulder"), world.player.key_prompt("perspective")]
		track_button.disabled = true
	else:
		var visible_rows: Array[Dictionary] = []
		for row in rows:
			if row.complete == (category == "completed"): visible_rows.append(row)
		if visible_rows.is_empty():
			selection = ""
			paragraph(quest_list, "暂无已完成任务")
			detail_heading.text = "旅途仍在继续"
			details.text = "完成已接取的任务后，记录会出现在这里。"
			track_button.disabled = true
		else:
			var valid := false
			for row in visible_rows:
				if row.id == selection: valid = true
			if not valid: selection = visible_rows[0].id
			for row in visible_rows:
				var item := button(quest_list, row.title, _select_entry.bind(row.id))
				item.set_meta("quest_id", row.id)
				item.icon = preload("res://assets/ui/journal_check.png") if row.complete else preload("res://assets/ui/journal_icons.svg")
				item.tooltip_text = "正在追踪" if row.id == state.tracked_quest else "选择查看任务"
				list_buttons.append(item)
			_select_entry(selection)
	footer_status.add_theme_font_size_override("font_size", int(14 * state.text_scale))
	footer_status.text = "命火 %d / 5 · 检查点：%s\n倒下扣除一命；读档恢复所选记录。" % [state.lives, state.checkpoint_name()]
	if state.persistence_error != "": footer_status.text += "\n" + state.persistence_error + " · F5 重试保存"
	_layout_details.call_deferred()
	reflow(self)

func _select_entry(id: String) -> void:
	selection = id
	for row in rows:
		if row.id != id: continue
		# The earned route is a long reading entry. Use the retained page scroll
		# rather than nesting a second clipped reading viewport at large scales.
		var route_reading: bool = id == "route_record" and state.mf01_acquired
		details.fit_content = route_reading
		details.scroll_active = not route_reading
		details.size_flags_vertical = Control.SIZE_FILL if route_reading else Control.SIZE_EXPAND_FILL
		details.scroll_to_line(0)
		detail_heading.text = row.title + (" · 已完成" if row.complete else " · 当前")
		details.text = row.context + "\n\n当前行动\n" + row.action + "\n\n已完成步骤\n"
		if row.steps.is_empty(): details.text += "尚未完成步骤。"
		else:
			for step in row.steps: details.text += "✓ " + step + "\n"
		details.text = preload("res://ui/quest_markup.gd").format_text(details.text,true)
		track_button.disabled = row.complete or id == state.tracked_quest
		track_button.text = "正在追踪" if id == state.tracked_quest else "追踪此任务"
		_layout_details.call_deferred()
		reflow(self)
		return

func _track_selected() -> void:
	if not state.track_quest(selection): return
	state.tracker_collapsed = false
	world._save_opening(0)
	refresh_entries()

func _input(_event: InputEvent) -> void:
	# The world pause owner routes cancellation before player actions.
	pass

func _process(_delta: float) -> void:
	if visible and entries_signature != JSON.stringify(project_entries(state)): refresh_entries()

func _mcp_state() -> Dictionary:
	return {"visible": visible, "category": category, "selected": selection, "tracked": state.tracked_quest, "entries": rows, "details": details.text, "return_rules": footer_status.text}

func _unhandled_input(_event: InputEvent) -> void:
	pass
