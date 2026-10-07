extends "res://ui/menu_foundation/main_menu.gd"
var world: Node3D
var suspended = false
var description: Label
var fire_button: Button
var lightning_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$BackgroundTextureRect.hide()
	%MenuContainer.hide()
	var column = create_page(self,"元素能力",true)
	description = paragraph(column,"")
	fire_button = button(column,"选择火焰 · 1 技能点 [4]",choose.bind("fire"))
	lightning_button = button(column,"选择雷电 · 1 技能点 [5]",choose.bind("lightning"))
	fire_button.icon = preload("res://assets/ui/icons/fire.png")
	lightning_button.icon = preload("res://assets/ui/icons/lightning.png")
	for choice in [fire_button,lightning_button]:
		choice.expand_icon = true
		choice.add_theme_constant_override("icon_max_width",48)
	paragraph(column,"火焰：飞行弹体，可被墙挡住，18 直击 + 灼烧每秒 3，持续 3 秒。冷却 6 秒。\n雷电：12 米内清晰目标，22 伤害与短暂硬直。无合法目标不消耗冷却；释放后冷却 8 秒。")
	button(get_meta("footer_column"),"返回 [K / Esc]",close_panel)
	refresh()

func refresh() -> void:
	description.text = "等级 %d · 可用技能点 %d\n首次能力可自由选择；确认后消耗 1 点。练习靶在罗恩前方，可随时重试。" % [state.level(),state.pending_points()]
	fire_button.disabled = state.skills.has("fire") or state.pending_points() <= 0 or not state.lamp_owned
	lightning_button.disabled = state.skills.has("lightning") or state.pending_points() <= 0 or not state.lamp_owned
	fire_button.text = "火焰已解锁 [4]" if state.skills.has("fire") else "确认选择火焰 · 1 技能点"
	lightning_button.text = "雷电已解锁 [5]" if state.skills.has("lightning") else "确认选择雷电 · 1 技能点"
	reflow(self)

func choose(id: String) -> void:
	if not state.unlock_element(id): return
	world.training.commit()
	audio.play_cue("confirm")
	refresh()

func open_panel() -> void:
	if not state.lamp_owned or world.dialogue.opened: world.training.tell("取得旧灯并结束交谈后才能选择能力"); return
	world._set_pause_owner("skills",true)
	show()
	refresh()
	(fire_button if not fire_button.disabled else lightning_button).grab_focus.call_deferred()

func close_panel() -> void:
	suspended = false
	hide()
	world._set_pause_owner("skills",false)
	audio.play_cue("back")

func suspend_for_menu() -> void:
	suspended = true
	hide()

func resume_from_menu() -> void:
	suspended = false
	show()
	refresh()
	fire_button.grab_focus.call_deferred()

func _input(_event: InputEvent) -> void: pass
func _unhandled_input(_event: InputEvent) -> void: pass

func _mcp_state() -> Dictionary:
	return {"visible":visible,"pending_points":state.pending_points(),"skills":state.skills,"description":description.text}
