extends Control
var host: Control
var slots: Array[Dictionary] = []
var back: Button
var page: Control
var feedback: Label
var pending_slot := 0
var return_focus: Control
var return_scroll := 0
var slot_confirmation: Control
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()

func build() -> void:
	if page:
		remove_child(page)
		page.queue_free()
	page = Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	var column: BoxContainer = host.create_page(page, "存档与加载" if host.pause_world else "加载冒险", true)
	slots.clear()
	for slot in [1, 2]:
		var facts: Dictionary = host.state.slot_preview(slot)
		slots.append(facts)
		host.paragraph(column, "手动存档 %d" % slot)
		if facts.reason != "": host.paragraph(column, facts.reason)
		else: host.paragraph(column, "%s · %s\n%s · %s\n经验 %d · 命数 %d / 5 · 箭 %d" % [facts.chapter, facts.time, facts.checkpoint, facts.progress, facts.experience, facts.lives, facts.arrows])
		if host.pause_world:
			var save: Button = host.button(column, "保存到存档 %d" % slot, request.bind(slot, true), 2)
			save.name = "SaveSlot%d" % slot
			var safe: bool = host.pause_world.training.can_save() and host.pause_world.bow_training.can_save() and host.state.lives > 0
			save.disabled = not safe
			save.tooltip_text = "战斗或恢复期间不能保存" if not safe else ""
			if not safe:
				save.focus_mode = Control.FOCUS_NONE
				host.paragraph(column, save.tooltip_text)
		var item: Button = host.button(column, "加载存档 %d" % slot, request.bind(slot, false), 2)
		item.name = "LoadSlot%d" % slot
		item.disabled = facts.reason != ""
		item.focus_mode = Control.FOCUS_NONE if item.disabled else Control.FOCUS_ALL
		item.tooltip_text = facts.reason
	feedback = host.paragraph(column, "")
	back = host.button(page.get_meta("footer_column"), "返回", close)
	host.reflow(page)
	back.grab_focus.call_deferred()

func request(slot: int, saving: bool) -> void:
	if slot_confirmation: return
	return_focus = get_viewport().gui_get_focus_owner()
	return_scroll = page.find_child("PageScroll", true, false).scroll_vertical
	if saving and host.state.slot_preview(slot).reason != "暂无存档":
		confirm_slot("覆盖存档？", "将用当前安全进度替换手动存档 %d。" % slot, save_slot.bind(slot))
	elif not saving and host.pause_world:
		confirm_slot("加载存档？", "未保存的探索进度将不会保留。", load_slot.bind(slot))
	elif saving: save_slot(slot)
	else: load_slot(slot)

func confirm_slot(heading: String, message: String, action: Callable) -> void:
	slot_confirmation = preload("res://ui/menu_foundation/confirmation_window.tscn").instantiate()
	slot_confirmation.host = host
	slot_confirmation.heading = heading
	slot_confirmation.message = message
	slot_confirmation.action = action
	add_child(slot_confirmation)
	page.hide()
	slot_confirmation.closed.connect(func():
		slot_confirmation.queue_free()
		slot_confirmation = null
		page.show()
		page.find_child("PageScroll", true, false).scroll_vertical = return_scroll
		_restore_slot_focus.call_deferred())

func _restore_slot_focus() -> void:
	# Successful loading closes the entire pause page before this callback.
	if is_queued_for_deletion() or not is_visible_in_tree() or not page.is_visible_in_tree(): return
	if is_instance_valid(return_focus) and return_focus.is_visible_in_tree(): return_focus.grab_focus()

func save_slot(slot: int) -> void:
	pending_slot = slot
	host.pause_world._save_opening(slot)
	var result: String = host.state.save_feedback
	var error: bool = host.state.persistence_error != "" or result.contains("不能")
	build()
	feedback.text = result + " · 存档 %d" % slot
	host.audio.play_cue("failure" if error else "confirm")
	if error:
		host.button(feedback.get_parent(), "重试保存", save_slot.bind(slot))

func load_slot(slot: int) -> void:
	if host.pause_world: host.pause_world._load_opening(slot)
	else: host.router.enter_adventure("load", slot)
	if is_inside_tree() and host.pause_world and host.pause_world.restoring_interface == false and host.pause_world.controls_panel.visible:
		feedback.text = host.pause_world.controls_feedback.text
		host.audio.play_cue("failure")

func close() -> void:
	if slot_confirmation:
		slot_confirmation.close()
		return
	host.audio.play_cue("back")
	hide()

func _mcp_state() -> Dictionary:
	var observation := {"slots": slots, "visible": visible, "pending_slot": pending_slot, "confirmation": slot_confirmation != null}
	# Project the displayed previews and actual buttons, without rereading files
	# or restoring a history. Unknown facts stay null for an unavailable slot.
	for facts in slots:
		var slot: int = facts.slot
		var prefix := "slot%d_" % slot
		var item := page.find_child("LoadSlot%d" % slot, true, false) as Button
		observation[prefix + "available"] = not item.disabled if item else null
		for key in ["reason", "experience", "lives", "arrows", "progress", "chapter", "checkpoint", "time"]:
			observation[prefix + key] = facts.get(key)
	return observation
