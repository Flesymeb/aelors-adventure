extends Control
var host: Control
var slots: Array[Dictionary] = []
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column: VBoxContainer = host.create_page(self, "加载冒险", true)
	for slot in [1, 2]:
		var facts: Dictionary = host.state.slot_preview(slot)
		slots.append(facts)
		host.paragraph(column, "手动存档 %d" % slot)
		if facts.reason != "": host.paragraph(column, facts.reason)
		else: host.paragraph(column, "%s · %s\n%s\n经验 %d · 命数 %d · 箭 %d" % [facts.chapter, facts.time, facts.progress, facts.experience, facts.lives, facts.arrows])
		var item: Button = host.button(column, "加载存档 %d" % slot, func(): host.router.enter_adventure("load", slot), 2)
		item.disabled = facts.reason != ""
		item.focus_mode = Control.FOCUS_NONE if item.disabled else Control.FOCUS_ALL
		item.tooltip_text = facts.reason
	var back: Button = host.button(column, "返回", close)
	back.grab_focus.call_deferred()
	host.reflow(self)
func close() -> void:
	host.audio.play_cue("back")
	hide()
func _mcp_state() -> Dictionary:
	return {"slots": slots, "visible": visible}
