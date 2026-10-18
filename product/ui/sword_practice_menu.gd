extends CanvasLayer
## Transient earned practice choice. Combat/progress remain owned by SwordTraining.
var training: Node3D
var panel: PanelContainer
var heading: Label
var description: Label
var choices: Array[Button] = []
var armed := false
var closed := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	training.world._set_pause_owner("sword_practice",true)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02,0.03,0.02,0.6)
	add_child(shade)
	panel = PanelContainer.new()
	panel.theme = preload("res://dialogue_theme.tres")
	var paper := StyleBoxTexture.new()
	paper.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-013.png")
	paper.modulate_color = Color(0.9,0.82,0.64)
	paper.set_content_margin_all(24)
	for side in 4: paper.set_texture_margin(side,12)
	panel.add_theme_stylebox_override("panel",paper)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	panel.add_child(column)
	heading = Label.new()
	heading.text = "赫斯 · 剑术复练"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color",Color(0.17,0.12,0.06))
	column.add_child(heading)
	description = Label.new()
	description.text = "用同一位对手练习 · 保留真实伤害与脱离规则\n无额外奖励；可退回赫斯处结束。"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color",Color(0.17,0.12,0.06))
	column.add_child(description)
	for mode in ["free","coached",""]:
		var button := Button.new()
		button.text = "自由切磋" if mode == "free" else "振刀反击指导" if mode == "coached" else "离开 [Esc]"
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.pressed.connect(choose.bind(mode))
		for variant in ["normal","hover","focus","pressed","disabled"]:
			var frame := StyleBoxTexture.new()
			frame.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-003.png")
			frame.modulate_color = Color(1,0.81,0.35) if variant in ["hover","focus"] else Color(0.7,0.6,0.42,0.45)
			frame.set_content_margin_all(14)
			for side in 4: frame.set_texture_margin(side,12)
			button.add_theme_stylebox_override(variant,frame)
			button.add_theme_color_override("font_"+variant+"_color",Color(0.14,0.10,0.05))
		column.add_child(button)
		choices.append(button)
	choices[0].grab_focus.call_deferred()
	_layout()

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var scale: float = training.state.text_scale
	panel.custom_minimum_size.x = minf(760,view.x-60)
	panel.size = Vector2(panel.custom_minimum_size.x,0)
	heading.add_theme_font_size_override("font_size",int(26*scale))
	description.add_theme_font_size_override("font_size",int(20*scale))
	for button in choices: button.add_theme_font_size_override("font_size",int(23*scale))
	panel.position = (view-panel.get_combined_minimum_size())*0.5

func _process(_delta: float) -> void:
	if not armed and not Input.is_key_pressed(KEY_E) and not Input.is_key_pressed(KEY_ENTER) and not Input.is_key_pressed(KEY_SPACE) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		armed = true
		choices[0].grab_focus.call_deferred()
	for button in choices: button.disabled = not armed
	_layout()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		choose("")
		get_viewport().set_input_as_handled()

func choose(mode: String) -> void:
	if closed or (mode != "" and not armed): return
	close()
	if mode != "": training.start_repractice(mode == "coached")

func close() -> void:
	if closed: return
	closed = true
	training.world._set_pause_owner("sword_practice",false)
	queue_free()

func _exit_tree() -> void:
	if not closed and is_instance_valid(training) and is_instance_valid(training.world):
		training.world._set_pause_owner("sword_practice",false)
