extends Control
## Shared title/adventure settings. Effective values belong to AdventureState.
var host: Control
var feedback: Label
var group := ""
var page: Control
var bindings: Node
var owns_bindings := false
var capturing := ""
var capture_button: Button
var column: BoxContainer
const GROUPS := {"audio": "声音", "graphics": "画面", "controls": "操作", "reading": "阅读与反馈"}
const KEY_LABELS := {"roll": "翻滚", "dodge": "闪避", "shoulder": "切换肩位", "jump": "跳跃", "sprint": "奔跑（按住）", "forward": "前进", "back": "后退", "left": "向左", "right": "向右", "crouch": "蹲伏", "prone": "俯卧", "perspective": "切换视角"}
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if host.pause_world:
		bindings = host.pause_world.player
	else:
		# Only the existing binding adapter; never instantiate an actor/scene.
		bindings = preload("res://player_controller.gd").new()
		bindings._setup_controls()
		owns_bindings = true
	build()

func _exit_tree() -> void:
	if owns_bindings and is_instance_valid(bindings): bindings.free()

func build() -> void:
	var old_focus := get_viewport().gui_get_focus_owner()
	var focus_name := str(old_focus.name) if old_focus and page and page.is_ancestor_of(old_focus) else ""
	if page:
		remove_child(page)
		page.queue_free()
	page = Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	column = host.create_page(page, "设置" if group == "" else GROUPS[group], true)
	column.search_depth = 3
	if group == "":
		for key in GROUPS:
			var item: Button = host.button(column, GROUPS[key], open_group.bind(key))
			item.name = key.capitalize()
		host.paragraph(column, "更改立即生效，并独立于冒险存档保留。")
	else:
		match group:
			"audio":
				slider("主音量", "master_volume", 0, 1, 0.05, true)
				slider("音乐音量", "music_volume", 0, 1, 0.05, true)
				slider("音效音量", "effects_volume", 0, 1, 0.05, true)
				toggle("静音", "muted_sound")
			"graphics":
				cycle("画质", "graphics_quality", ["normal", "low"], ["标准", "低"])
				host.paragraph(column, "低画质降低三维渲染分辨率、阴影距离与植被细节；界面保持清晰。")
				toggle("减少动态", "reduced_motion")
			"controls":
				slider("鼠标灵敏度", "mouse_sensitivity", 0.25, 2.5, 0.05)
				for action in bindings.CONTROL_DEFAULTS:
					var item: Button = host.button(column, KEY_LABELS[action] + " · " + bindings.key_prompt(action), capture.bind(action))
					item.name = action.capitalize()
				host.button(column, "恢复默认按键", func():
					var error: String = bindings.restore_controls()
					build()
					feedback.text = "默认按键已保存" if error == "" else error)
				host.button(column, "重试保存按键", func():
					var error: String = bindings._save_controls()
					feedback.text = "按键已保存" if error == "" else error)
				host.paragraph(column, "I 背包 · E 交互 · F 旧灯 · 1 剑 / 2 弓 · J 日志 · H 收起目标 · Esc 暂停。保留键不能改绑。")
			"reading":
				cycle("文字缩放", "text_scale", [1.0, 1.5, 2.0], ["100%", "150%", "200%"])
				cycle("对白速度", "reveal_speed", [15.0, 30.0, 45.0, 60.0], ["15 字/秒", "30 字/秒", "45 字/秒", "60 字/秒"])
				toggle("即时显示对白", "instant_text")
				slider("镜头震动", "camera_shake", 0, 1, 0.1, true)
				toggle("伤害数字", "damage_numbers")
	var footer: BoxContainer = page.get_meta("footer_column")
	feedback = host.paragraph(footer, host.state.preference_error if host.state.preference_error != "" else "设置会在下次启动时保留。")
	feedback.name = "SettingsFeedback"
	host.button(footer, "返回", close)
	if group == "":
		host.button(column, "恢复默认设置", func():
				host.state.reset_preferences()
				commit())
	var retry_save: Button = host.button(column, "重试保存设置", commit)
	retry_save.name = "RetrySavePreferences"
	host.reflow(page)
	var next_focus: Control = column.find_child(focus_name, true, false) if focus_name != "" else null
	if next_focus:
		next_focus.grab_focus.call_deferred()
	else: column.focus_first.call_deferred()
	_keep_focus_visible.call_deferred()

func open_group(key: String) -> void:
	group = key
	build()

func toggle(label: String, key: String) -> void:
	var item: Button = host.button(column, "", func():
		host.state.set(key, not host.state.get(key))
		commit()
		build())
	item.name = key.capitalize()
	item.text = label + " · " + ("开启 ✓" if host.state.get(key) else "关闭")

func cycle(label: String, key: String, values: Array, labels: Array) -> void:
	var item: Button = host.button(column, label + " · " + labels[maxi(0, values.find(host.state.get(key)))], func():
		host.state.set(key, values[(values.find(host.state.get(key)) + 1) % values.size()])
		commit()
		build())
	item.name = key.capitalize()

func slider(label: String, key: String, low: float, high: float, increment: float, percent := false) -> void:
	var row := VBoxContainer.new()
	row.name = key.capitalize() + "Row"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var value_label: Label = host.paragraph(row, "")
	var control := HSlider.new()
	control.name = key.capitalize()
	control.min_value = low
	control.max_value = high
	control.step = increment
	control.value = host.state.get(key)
	control.custom_minimum_size.y = 40
	control.focus_mode = Control.FOCUS_ALL
	row.add_child(control)
	control.set_meta("focus_row", row)
	control.focus_entered.connect(func(): host.audio.play_cue("focus"))
	control.focus_entered.connect(_keep_focus_visible.call_deferred)
	var update := func(value: float): value_label.text = label + " · " + ("%d%%" % int(round(value * 100)) if percent else "%.2f" % value)
	update.call(control.value)
	control.value_changed.connect(func(value: float):
		host.state.set(key, value)
		update.call(value)
		commit())

func _keep_focus_visible() -> void:
	if not page or not is_inside_tree(): return
	# Container sorting and font wrapping settle after a rebuild.
	await get_tree().process_frame
	if not is_instance_valid(page): return
	var focus := get_viewport().gui_get_focus_owner()
	if focus and page.is_ancestor_of(focus):
		var scroll: ScrollContainer = page.find_child("PageScroll", true, false)
		if scroll.is_ancestor_of(focus): scroll.ensure_control_visible(focus.get_meta("focus_row", focus))

func capture(action: String) -> void:
	capturing = action
	capture_button = get_viewport().gui_get_focus_owner()
	feedback.text = "按一个未占用的键设置“%s” · Esc 取消" % KEY_LABELS[action]

func handle_input(event: InputEvent) -> bool:
	if capturing == "" or not event is InputEventKey: return false
	if event.echo or not event.pressed: return true
	if event.keycode == KEY_ESCAPE:
		capturing = ""
		feedback.text = "按键修改已取消"
	else:
		var error: String = bindings.rebind_control(capturing, event.keycode)
		if error != "":
			feedback.text = error
			host.audio.play_cue("failure")
		else:
			capture_button.text = KEY_LABELS[capturing] + " · " + bindings.key_prompt(capturing)
			capturing = ""
			feedback.text = "按键已保存"
	return true

func _input(event: InputEvent) -> void:
	if not host.pause_world and handle_input(event): get_viewport().set_input_as_handled()

func commit() -> void:
	var error: int = host.state.save_preferences()
	feedback.text = "设置已保存" if error == OK else host.state.preference_error
	if error != OK: host.audio.play_cue("failure")
	host.reflow(host)
	host.reflow(page)
	if host.pause_world:
		host.pause_world.dialogue._layout()
		if host.pause_world.failure_panel: host.pause_world._layout_failure()

func close() -> void:
	capturing = ""
	host.audio.play_cue("back")
	if group != "":
		var previous := group
		group = ""
		build()
		column.find_child(previous.capitalize(), false, false).grab_focus.call_deferred()
	else:
		host.refresh()
		host.reflow(host)
		hide()

func _mcp_state() -> Dictionary:
	var live := is_inside_tree() and not is_queued_for_deletion()
	var viewport := get_viewport() if live else null
	var focus: Control = viewport.gui_get_focus_owner() if viewport else null
	var row: Control = focus.get_meta("focus_row", focus) if focus else null
	var page_ready := live and is_instance_valid(page) and not page.is_queued_for_deletion()
	var scroll := page.find_child("PageScroll", true, false) as ScrollContainer if page_ready else null
	var state: Node = host.state if is_instance_valid(host) and not host.is_queued_for_deletion() else null
	var state_ready := is_instance_valid(state) and not state.is_queued_for_deletion()
	var bindings_ready := is_instance_valid(bindings) and not bindings.is_queued_for_deletion()
	var feedback_ready := live and is_instance_valid(feedback) and not feedback.is_queued_for_deletion()
	var observation := {"ready": live and is_node_ready() and state_ready and page_ready, "group": group, "capturing": capturing, "preferences": state.preference_snapshot() if state_ready else null, "bindings": bindings.effective_bindings.duplicate() if bindings_ready else null, "binding_error": bindings.control_persistence_error if bindings_ready else null, "visible": visible if live else null, "focus_rect": str(row.get_global_rect()) if is_instance_valid(row) and not row.is_queued_for_deletion() else null, "viewport_rect": str(scroll.get_global_rect()) if is_instance_valid(scroll) and not scroll.is_queued_for_deletion() else null, "feedback": feedback.text if feedback_ready else null, "feedback_rect": str(feedback.get_global_rect()) if feedback_ready else null, "scroll": scroll.scroll_vertical if is_instance_valid(scroll) and not scroll.is_queued_for_deletion() else null}
	observation["focus_name"] = str(focus.name) if page_ready and is_instance_valid(focus) and not focus.is_queued_for_deletion() and page.is_ancestor_of(focus) else null
	if state_ready: observation.merge(state.audio_observation())
	return observation
