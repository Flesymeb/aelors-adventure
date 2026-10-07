extends CanvasLayer
## Presentation only: authoritative facts remain in dialogue_state and Snaiel.
var world: Node3D
var state: Node
var root: Control
var vitals: PanelContainer
var health_text: Label
var xp_text: Label
var hp: ProgressBar
var xp: ProgressBar
var life_row: HBoxContainer
var life_icons: Array[TextureRect] = []
var life_textures: Array[AtlasTexture] = []
var tracker: PanelContainer
var tracker_text: Label
var tracker_title: Label
var prompt: Label
var notices: VBoxContainer
var notice_text: Label
var retry: Button
var notice_time := 0.0
var failed_slot := -1
var shown_xp := 0.0
var previous: Dictionary = {}
var notifications: Array[Dictionary] = []
var journal: Control

func _ready() -> void:
	name = "GameplayHUD"
	layer = 6
	state = world.dialogue_state
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = preload("res://ui/gameplay_theme.tres").duplicate()
	add_child(root)
	vitals = PanelContainer.new()
	vitals.name = "Vitals"
	vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vitals)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals.add_child(rows)
	health_text = label(rows)
	hp = meter(Color(0.68, 0.18, 0.12))
	rows.add_child(hp)
	xp_text = label(rows)
	xp = meter(Color(0.79, 0.61, 0.29))
	xp.max_value = 30
	rows.add_child(xp)
	life_row = HBoxContainer.new()
	life_row.name = "LifeLanterns"
	life_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var life_back := PanelContainer.new()
	life_back.name = "LifeBackplate"
	life_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(life_back)
	life_back.add_child(life_row)
	for column in 2:
		var texture := AtlasTexture.new()
		texture.atlas = preload("res://assets/ui/life_icons.svg")
		texture.region = Rect2(column * 64, 0, 64, 64)
		life_textures.append(texture)
	for i in 5:
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		life_row.add_child(icon)
		life_icons.append(icon)
	tracker = PanelContainer.new()
	tracker.name = "TrackedObjective"
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tracker)
	var track_rows := VBoxContainer.new()
	track_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.add_child(track_rows)
	tracker_title = label(track_rows)
	tracker_text = label(track_rows)
	tracker_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt = label(root)
	prompt.name = "ContextualInteraction"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notices = VBoxContainer.new()
	notices.name = "EventNotifications"
	root.add_child(notices)
	var card := PanelContainer.new()
	notices.add_child(card)
	var notice_rows := VBoxContainer.new()
	card.add_child(notice_rows)
	notice_text = label(notice_rows)
	notice_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	retry = Button.new()
	retry.text = "重试保存 [F5]"
	retry.pressed.connect(func(): world._save_opening(failed_slot))
	notice_rows.add_child(retry)
	restore_view()
	state.save_finished.connect(_save_finished)
	journal = preload("res://ui/quest_journal.tscn").instantiate()
	journal.world = world
	journal.state = state
	journal.audio = world.menu_audio
	var journal_layer := CanvasLayer.new()
	journal_layer.layer = 24
	add_child(journal_layer)
	journal_layer.add_child(journal)
	journal.hide()

func label(parent: Node) -> Label:
	var item := Label.new()
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func meter(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 9)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.06, 0.07, 0.04, 0.94)
	back.border_color = Color(0.56, 0.46, 0.26)
	back.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", back)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func restore_view() -> void:
	previous = _facts()
	shown_xp = state.experience
	notifications.clear()
	notice_time = 0
	failed_slot = -1
	if notices: notices.hide()

func _facts() -> Dictionary:
	return {"objective": state.objective(), "lives": state.lives, "recovery": state.recovery_pending, "steps": [state.q01_accepted, state.sword_owned, state.practice_hit, state.practice_defense, state.encounter_defeated, state.remnant_collected, state.bow_owned, state.bow_training_complete]}

func _save_finished(slot: int, error: int) -> void:
	# Restored histories are not events; router/load own their readiness notice.
	if world.pause_owners.has("entry") or world.restoring_interface: return
	if error != OK:
		failed_slot = slot
		notifications.clear()
		_show_notice("保存失败 · 请重试", true)
	else:
		failed_slot = -1
		if notice_time < 0: notice_time = 0
		notify("进度已保存" if slot == 0 else "存档 %d 已保存" % slot)

func notify(text: String, immediate := false, seconds := 2.7) -> void:
	if failed_slot >= 0: return
	# Timing instructions and rewards must not wait behind autosave chatter.
	if immediate:
		_show_notice(text, false, seconds)
		return
	if notice_time > 0 and notice_text.text == text: return
	for pending in notifications:
		if pending.text == text: return
	if notifications.size() < 3: notifications.append({"text": text})

func _show_notice(text: String, failure := false, seconds := 2.7) -> void:
	notice_text.text = text
	retry.visible = failure
	notice_time = -1 if failure else seconds
	notices.modulate.a = 1
	notices.show()

func _process(delta: float) -> void:
	var active: bool = world.pause_owners.is_empty()
	var facts := _facts()
	if not world.restoring_interface and not world.pause_owners.has("entry"):
		if facts.lives != previous.lives: notify("命火 %s%d · 剩余 %d" % ["+" if facts.lives > previous.lives else "", facts.lives - previous.lives, facts.lives])
		if facts.steps != previous.steps: notify("任务更新 · " + state.tracked_entry().title)
		if previous.recovery and not facts.recovery and state.health > 0 and state.persistence_error == "": notify("已返回河谷村庄灯台")
	previous = facts
	root.visible = active
	if active:
		shown_xp = move_toward(shown_xp, state.experience, delta * 22)
		if notice_time > 0:
			notice_time = maxf(0, notice_time - delta)
			notices.modulate.a = minf(1, notice_time / 0.4)
		if notice_time == 0:
			if notifications.is_empty(): notices.hide()
			else: _show_notice(notifications.pop_front().text)
	var view := get_viewport().get_visible_rect().size
	var scale_now: float = state.text_scale
	root.theme.default_font_size = int(18 * scale_now)
	vitals.position = Vector2(20, 20)
	vitals.custom_minimum_size.x = 270 * minf(scale_now, 1.35)
	health_text.text = "艾洛  ·  %d / 100" % int(ceil(state.health))
	xp_text.text = "等级 1   ·   %d / 30 XP" % state.experience
	xp_text.add_theme_font_size_override("font_size", int(15 * scale_now))
	hp.value = state.health
	xp.value = shown_xp
	for i in 5:
		life_icons[i].texture = life_textures[0 if i < state.lives else 1]
		life_icons[i].custom_minimum_size = Vector2(28, 36) * minf(scale_now, 1.3)
	var life_back: PanelContainer = life_row.get_parent()
	life_back.position = Vector2(view.x - life_back.size.x - 20, 20)
	tracker.position = Vector2(view.x - minf(430 * scale_now, view.x * 0.43) - 20, life_back.position.y + life_back.size.y + 12)
	tracker.custom_minimum_size.x = minf(430 * scale_now, view.x * 0.43)
	tracker.size.x = tracker.custom_minimum_size.x
	tracker_title.text = "任务日志 [J]    " + ("展开 [H]" if state.tracker_collapsed else "收起 [H]")
	tracker_title.add_theme_font_size_override("font_size", int(14 * scale_now))
	tracker_text.visible = not state.tracker_collapsed
	tracker_text.text = short_action(state.tracked_entry().action)
	tracker.visible = not state.tracked_entry().complete
	var hint := ""
	if active:
		if world.training: hint = world.training.interaction_prompt()
		if world.bow_training and world.bow_training.interaction_prompt() != "": hint = world.bow_training.interaction_prompt()
		if hint == "" and world.isha.can_interact(world.player): hint = "[E] 与伊莎交谈"
	prompt.text = hint
	prompt.visible = hint != ""
	var ammo_top := view.y - 64 * scale_now
	var prompt_height := maxf(prompt.get_minimum_size().y, 28 * scale_now)
	prompt.size = Vector2(view.x * 0.6, prompt_height)
	# Control may retain a larger minimum while the new font layout settles.
	# Position by its actual clamped size, including during a scale change.
	prompt.position = Vector2(view.x * 0.2, ammo_top - prompt.size.y - 18)
	notices.size.x = view.x * 0.5
	notice_text.custom_minimum_size.x = view.x * 0.5 - 32
	notices.position = Vector2(view.x * 0.25, prompt.position.y - maxf(notices.size.y, notices.get_combined_minimum_size().y) - 18)

func short_action(text: String) -> String:
	return {"rescue": "与广场边的伊莎交谈" if not state.q01_accepted else _next_action(), "sword": _next_action(), "bow": "返回伊莎处" if state.bow_training_complete else ("找草地边的罗恩" if not state.bow_owned else "瞄准草靶 · 蓄力后松开")}.get(state.tracked_quest, text)

func _next_action() -> String:
	if not state.sword_owned: return "找村口的赫斯"
	if not state.practice_hit: return "用剑击中赫斯旁的草靶"
	if not state.practice_defense: return "靠近赫斯 · 挡住或躲开模拟攻击"
	if not state.encounter_defeated: return "沿路前往训练怪"
	if not state.remnant_collected: return "靠近金色残响"
	if not state.bow_owned: return "找草地边的罗恩"
	return "瞄准罗恩前方草靶" if not state.bow_training_complete else "返回伊莎处"

func _mcp_state() -> Dictionary:
	return {"hud_visible": root.visible, "lives": state.lives, "lit_lanterns": state.lives, "health": hp.value, "xp_target": state.experience, "tracked": state.tracked_quest, "collapsed": state.tracker_collapsed, "objective": tracker_text.text, "prompt": prompt.text, "notice": notice_text.text if notices.visible else "", "notice_remaining": notice_time, "retry_slot": failed_slot, "journal_open": journal.visible}
