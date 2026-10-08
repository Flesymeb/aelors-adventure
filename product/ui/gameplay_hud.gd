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
# Session observations of real presentations, never persisted or shown in UI.
var notice_event_id := ""
var notice_active_elapsed := 0.0
var sword_acquisition_emissions := 0
var sword_acquisition_active_elapsed := 0.0
var failed_slot := -1
var shown_xp := 0.0
var previous: Dictionary = {}
var notifications: Array[Dictionary] = []
var equipment_back: PanelContainer
var shortcut_row: HBoxContainer
var shortcut_slots: Dictionary = {}
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
	equipment_back = PanelContainer.new()
	equipment_back.name = "BottomShortcuts"
	equipment_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(equipment_back)
	shortcut_row = HBoxContainer.new()
	shortcut_row.name = "ShortcutIcons"
	shortcut_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shortcut_row.alignment = BoxContainer.ALIGNMENT_CENTER
	equipment_back.add_child(shortcut_row)
	for pair in [["sword","sword"],["bow","bow"],["lamp","lantern"],["fire","fire"],["lightning","lightning"],["item","potion"],["bag","backpack"],["ability","ability"],["journal","journal"]]:
		var slot = PanelContainer.new()
		slot.name = str(pair[0]).capitalize() + "Shortcut"
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame: StyleBox = root.theme.get_stylebox("panel", "PanelContainer").duplicate()
		frame.set_content_margin(SIDE_LEFT, 8)
		frame.set_content_margin(SIDE_RIGHT, 8)
		frame.set_content_margin(SIDE_TOP, 6)
		frame.set_content_margin(SIDE_BOTTOM, 6)
		slot.add_theme_stylebox_override("panel", frame)
		shortcut_row.add_child(slot)
		var column = VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(column)
		var icon = TextureRect.new()
		icon.texture = load("res://assets/ui/icons/%s.png" % pair[1])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(36,36)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.modulate = Color(1,0.84,0.48)
		column.add_child(icon)
		var key = label(column)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shortcut_slots[pair[0]] = {"panel":slot,"icon":icon,"key":key}
	shortcut_slots.bag.key.text = "I 背包"
	shortcut_slots.ability.key.text = "K 能力"
	shortcut_slots.journal.key.text = "J 日志"
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
	notice_event_id = ""
	notice_active_elapsed = 0.0
	sword_acquisition_active_elapsed = 0.0
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

func notify(text: String, immediate := false, seconds := 2.7, event_id := "") -> void:
	if failed_slot >= 0: return
	# Timing instructions and rewards must not wait behind autosave chatter.
	if immediate:
		_show_notice(text, false, seconds, event_id)
		return
	if notice_time > 0 and notice_text.text == text: return
	for pending in notifications:
		if pending.text == text: return
	if notifications.size() < 3: notifications.append({"text": text})

func _show_notice(text: String, failure := false, seconds := 2.7, event_id := "") -> void:
	notice_text.text = text
	notice_event_id = event_id
	notice_active_elapsed = 0.0
	if event_id == "sword_acquired":
		sword_acquisition_emissions += 1
		sword_acquisition_active_elapsed = 0.0
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
	# Always-process UI still lays out while the game tree is frozen. Transient
	# gameplay clocks advance only during active play, including Host stepping.
	if active and not get_tree().paused:
		shown_xp = move_toward(shown_xp, state.experience, delta * 22)
		if notice_time > 0:
			notice_active_elapsed += minf(delta, notice_time)
			if notice_event_id == "sword_acquired": sword_acquisition_active_elapsed += minf(delta, notice_time)
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
	xp_text.text = "等级 %d   ·   %d / %d XP" % [state.level(),state.xp_progress(),state.xp_threshold()]
	if state.pending_points() > 0: xp_text.text += " · %d 点 [K]" % state.pending_points()
	xp.max_value = state.xp_threshold()
	xp_text.add_theme_font_size_override("font_size", int(15 * scale_now))
	hp.value = state.health
	xp.value = state.xp_progress()
	# The plain root Control does not resize this card when its minima shrink.
	# Release both retained dimensions after current text/font/content updates;
	# following frames pick up queued container layout without replacing it.
	vitals.reset_size()
	for i in 5:
		life_icons[i].texture = life_textures[0 if i < state.lives else 1]
		life_icons[i].custom_minimum_size = Vector2(28, 36) * minf(scale_now, 1.3)
	var life_back: PanelContainer = life_row.get_parent()
	# A smaller child minimum does not release a root-owned Control's size.
	# Recompute from today's icon/theme minimum before dependent placement;
	# subsequent frames also pick up any queued container/font layout.
	life_back.reset_size()
	life_back.position = Vector2(view.x - life_back.size.x - 20, 20)
	tracker.position = Vector2(view.x - minf(430 * scale_now, view.x * 0.43) - 20, life_back.position.y + life_back.size.y + 12)
	tracker.custom_minimum_size.x = minf(430 * scale_now, view.x * 0.43)
	tracker.size.x = tracker.custom_minimum_size.x
	tracker_title.text = "任务日志 [J]    " + ("展开 [H]" if state.tracker_collapsed else "收起 [H]")
	tracker_title.add_theme_font_size_override("font_size", int(14 * scale_now))
	tracker_text.visible = not state.tracker_collapsed
	tracker_text.text = short_action(state.tracked_entry().action)
	# Release the retained expanded height after text/visibility changes.
	tracker.size = Vector2(tracker.custom_minimum_size.x, 0)
	tracker.visible = not state.tracked_entry().complete
	var hint := ""
	if active:
		if world.training: hint = world.training.interaction_prompt()
		if world.bow_training and world.bow_training.interaction_prompt() != "": hint = world.bow_training.interaction_prompt()
		if world.lamp_training and world.lamp_training.interaction_prompt() != "": hint = world.lamp_training.interaction_prompt()
		if world.bridge_actions and world.bridge_actions.interaction_prompt() != "": hint = world.bridge_actions.interaction_prompt()
		if hint == "" and world.isha.can_interact(world.player): hint = "[E] 与伊莎交谈"
	for pair in [["1","sword","巡路剑",state.sword_owned],["2","bow","巡路弓",state.bow_owned],["3","lamp","旧灯",state.lamp_owned]]:
		var slot: Dictionary = shortcut_slots[pair[1]]
		# Acquisition facts also drive the actual hand/back mounts. The bag's
		# compatibility mirror can settle on its next open/load; it must not
		# suppress a weapon that the player has just genuinely earned.
		slot.panel.visible = pair[3]
		slot.key.text = pair[0] + (" ◆" if world.player.weapon_mode == pair[1] else "")
		slot.panel.tooltip_text = pair[2]
		slot.icon.modulate = Color(1,0.85,0.4) if world.player.weapon_mode == pair[1] else Color(0.72,0.67,0.53)
	for pair in [["4","fire","火焰"],["5","lightning","雷电"]]:
		var cd = world.element_abilities.cooldowns[pair[1]] if world.element_abilities else 0.0
		var slot: Dictionary = shortcut_slots[pair[1]]
		slot.panel.visible = state.lamp_owned and state.skills.has(pair[1])
		slot.key.text = "%s · %.1fs" % [pair[0],cd] if cd > 0 else pair[0]
		slot.panel.tooltip_text = pair[2]
		slot.icon.modulate = Color(0.35,0.36,0.37) if cd > 0 else Color(1,0.85,0.4)
	var item_slot: Dictionary = shortcut_slots.item
	var item_count: int = state.inventory.count(state.quick_item)
	item_slot.panel.visible = item_count > 0
	item_slot.icon.texture = load(state.inventory.PROTOSET.data[state.quick_item].image)
	item_slot.key.text = "6 · %d" % item_count
	for slot in shortcut_slots.values():
		slot.key.add_theme_font_size_override("font_size",int(14 * scale_now))
		slot.icon.custom_minimum_size = Vector2(36,36) * minf(scale_now,1.25)
	# Width belongs to this root-owned panel, not to the number of earned slots.
	# Retain it while releasing height after a scale/ownership change. No wrapped
	# instruction label participates in its minimum-size calculation.
	equipment_back.custom_minimum_size.x = minf(310 * scale_now, view.x - 40)
	var shortcut_minimum := equipment_back.get_combined_minimum_size()
	equipment_back.size = Vector2(maxf(equipment_back.custom_minimum_size.x, shortcut_minimum.x), shortcut_minimum.y)
	equipment_back.position = Vector2((view.x - equipment_back.size.x) * 0.5,view.y - equipment_back.size.y - 12)
	prompt.text = hint
	prompt.visible = hint != ""
	var ammo_top := equipment_back.position.y - 12
	var prompt_height := maxf(prompt.get_minimum_size().y, 28 * scale_now)
	prompt.size = Vector2(view.x * 0.6, prompt_height)
	# Control may retain a larger minimum while the new font layout settles.
	# Position by its actual clamped size, including during a scale change.
	prompt.position = Vector2(view.x * 0.2, ammo_top - prompt.size.y - 18)
	# Notifications use the left edge, leaving the central actor/aim lane free.
	var notice_width := minf(380 * scale_now, view.x * 0.32)
	notice_text.custom_minimum_size.x = notice_width - 32
	notices.size = Vector2(notice_width, 0)
	notices.position = Vector2(20, prompt.position.y - maxf(notices.size.y, notices.get_combined_minimum_size().y) - 12)

func short_action(text: String) -> String:
	return {"rescue": "与广场边的伊莎交谈" if not state.q01_accepted else _next_action(), "sword": _next_action(), "bow": "返回伊莎处" if state.bow_training_complete else ("找草地边的罗恩" if not state.bow_owned else "瞄准草靶 · 蓄力后松开")}.get(state.tracked_quest, text)

func _next_action() -> String:
	if not state.sword_owned: return "转身沿土路 · 木屋旁找赫斯"
	if not state.practice_hit: return "用剑击中赫斯旁的草靶"
	if not state.practice_defense: return "靠近赫斯 · 挡住或躲开模拟攻击"
	if not state.encounter_defeated: return "土路河边 · 退回赫斯可脱离"
	if not state.remnant_collected: return "靠近金色残响"
	if not state.bow_owned: return "找草地边的罗恩"
	return "瞄准罗恩前方草靶" if not state.bow_training_complete else state.objective()

func _mcp_state() -> Dictionary:
	var observation := {"tracker_rect": str(tracker.get_global_rect()), "tracker_minimum": str(tracker.get_combined_minimum_size()), "hud_visible": root.visible, "lives": state.lives, "lit_lanterns": state.lives, "health": hp.value, "xp_target": state.experience, "tracked": state.tracked_quest, "collapsed": state.tracker_collapsed, "objective": tracker_text.text, "prompt": prompt.text, "notice": notice_text.text if notices.visible else "", "notice_remaining": notice_time, "retry_slot": failed_slot, "journal_open": journal.visible}
	# Read-only correlation for external captures. Layout may still be queued;
	observation.merge({"notice_event_id": notice_event_id, "notice_active_elapsed": notice_active_elapsed, "sword_acquisition_emissions": sword_acquisition_emissions, "sword_acquisition_active_elapsed": sword_acquisition_active_elapsed, "notice_visible_in_tree": notice_text.is_visible_in_tree()})
	# successive snapshots and ordinary frames establish settling externally.
	var viewport_rect := get_viewport().get_visible_rect()
	var rect := tracker.get_global_rect()
	var minimum := tracker.get_combined_minimum_size()
	var vitals_rect := vitals.get_global_rect()
	var vitals_minimum := vitals.get_combined_minimum_size()
	var vitals_children: Array[Dictionary] = []
	for child in vitals.get_child(0).get_children():
		var child_rect: Rect2 = child.get_global_rect()
		var child_minimum: Vector2 = child.get_combined_minimum_size()
		vitals_children.append({"path": str(child.get_path()), "x": child_rect.position.x, "y": child_rect.position.y, "w": child_rect.size.x, "h": child_rect.size.y, "minimum_w": child_minimum.x, "minimum_h": child_minimum.y, "visible": child.is_visible_in_tree()})
	var life_back: PanelContainer = life_row.get_parent()
	var life_rect := life_back.get_global_rect()
	var life_minimum := life_back.get_combined_minimum_size()
	observation.merge({
		"shortcut_rect": str(equipment_back.get_global_rect()),
		"shortcut_minimum": str(equipment_back.get_combined_minimum_size()),
		"prompt_rect": str(prompt.get_global_rect()),
		"notice_rect": str(notices.get_global_rect()),
		"process_frame": Engine.get_process_frames(),
		"physics_frame": Engine.get_physics_frames(),
		"viewport_rect": {"x": viewport_rect.position.x, "y": viewport_rect.position.y, "w": viewport_rect.size.x, "h": viewport_rect.size.y},
		"window_size": [get_window().size.x, get_window().size.y],
		"text_scale": state.text_scale,
		"vitals_geometry": {"x": vitals_rect.position.x, "y": vitals_rect.position.y, "w": vitals_rect.size.x, "h": vitals_rect.size.y, "minimum_w": vitals_minimum.x, "minimum_h": vitals_minimum.y, "custom_minimum_w": vitals.custom_minimum_size.x, "custom_minimum_h": vitals.custom_minimum_size.y},
		"vitals_children": vitals_children,
		"vitals_health_text": health_text.text,
		"vitals_xp_text": xp_text.text,
		"tracker_visible": tracker.visible,
		"tracker_visible_in_tree": tracker.is_visible_in_tree(),
		"objective_visible": tracker_text.visible,
		"objective_visible_in_tree": tracker_text.is_visible_in_tree(),
		"tracker_title": tracker_title.text,
		"objective_font_size": tracker_text.get_theme_font_size("font_size"),
		"objective_line_count": tracker_text.get_line_count(),
		"life_backplate_geometry": {"x": life_rect.position.x, "y": life_rect.position.y, "w": life_rect.size.x, "h": life_rect.size.y, "minimum_w": life_minimum.x, "minimum_h": life_minimum.y},
		"tracker_geometry": {"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y, "minimum_w": minimum.x, "minimum_h": minimum.y, "custom_minimum_w": tracker.custom_minimum_size.x, "custom_minimum_h": tracker.custom_minimum_size.y}
	})
	var slots: Dictionary = {}
	for id in shortcut_slots:
		var slot: Dictionary = shortcut_slots[id]
		slots[id] = {"visible": slot.panel.is_visible_in_tree(), "key": slot.key.text, "rect": str(slot.panel.get_global_rect())}
	observation["shortcuts"] = slots
	return observation
