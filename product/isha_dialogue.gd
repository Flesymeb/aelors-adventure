extends CanvasLayer
signal closed
signal menu_requested
signal progress_changed
var state: Node
var opened := false
var nested_menu := false
var focused_choice := -1
var reveal_count := 0.0
var reveal_complete := false
var advance_armed := false
var last_action_ms := -1000
var root: Control
var panel: Panel
var reading_scroll: ScrollContainer
var speaker: Label
var body: RichTextLabel
var choices_box: VBoxContainer
var choice_buttons: Array[Button] = []
var footer: Label
var portraits: Array[TextureRect] = []
var advance_button: Button
var sound: AudioStreamPlayer
var panel_content: VBoxContainer

func _ready() -> void:
	root = $Root
	root.hide()
	sound = AudioStreamPlayer.new()
	sound.volume_db = -18
	add_child(sound)
	_build()
	get_viewport().size_changed.connect(_layout)

func _build() -> void:
	panel = Panel.new()
	panel.name = "ReadingSurface"
	var paper := StyleBoxTexture.new()
	paper.texture = load("res://assets/dialogue/borders/PNG/Default/Panel/panel-013.png")
	paper.modulate_color = Color(0.90, 0.82, 0.64)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		paper.set_texture_margin(side, 10)
		paper.set_content_margin(side, 24)
	panel.add_theme_stylebox_override("panel", paper)
	root.add_child(panel)
	reading_scroll = ScrollContainer.new()
	reading_scroll.name = "ReadingScroll"
	reading_scroll.follow_focus = true
	reading_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(reading_scroll)
	panel_content = VBoxContainer.new()
	panel_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_content.add_theme_constant_override("separation", 12)
	reading_scroll.add_child(panel_content)
	speaker = Label.new()
	speaker.name = "Speaker"
	speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_content.add_child(speaker)
	body = RichTextLabel.new()
	body.name = "DialogueBody"
	body.fit_content = true
	body.scroll_active = false
	body.focus_mode = Control.FOCUS_NONE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("line_separation", 8)
	panel_content.add_child(body)
	choices_box = VBoxContainer.new()
	choices_box.name = "Choices"
	choices_box.add_theme_constant_override("separation", 8)
	panel_content.add_child(choices_box)
	advance_button = Button.new()
	advance_button.text = "◇  继续 [E]"
	advance_button.pressed.connect(advance)
	_style_choice(advance_button)
	panel_content.add_child(advance_button)
	footer = Label.new()
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.text = "E 补全 / 继续 · ↑↓ 选择 · Enter 确认 · Esc 暂时离开 · F10 设置 · F5 存档"
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(footer)
	# Portrait slots bind only distributable, qualified art. Missing art is an
	# explicit delivery gap, never replaced with the PRD reference screenshot.
	for path in ["res://assets/dialogue/aelor_portrait.png", "res://assets/dialogue/isha_portrait.png"]:
		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(path): portrait.texture = load(path)
		root.add_child(portrait)
		portraits.append(portrait)
	_layout()

func _style_choice(button: Button) -> void:
	for variant in ["normal", "hover", "focus", "pressed", "disabled"]:
		var frame := StyleBoxTexture.new()
		frame.texture = load("res://assets/dialogue/borders/PNG/Default/Panel/panel-003.png")
		frame.modulate_color = Color(0.82, 0.73, 0.54)
		if variant in ["hover", "focus"]: frame.modulate_color = Color(1.0, 0.87, 0.55)
		if variant == "pressed": frame.modulate_color = Color(0.71, 0.57, 0.33)
		if variant == "disabled": frame.modulate_color = Color(0.64, 0.60, 0.50)
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			frame.set_texture_margin(side, 10)
			frame.set_content_margin(side, 10)
		button.add_theme_stylebox_override(variant, frame)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _layout() -> void:
	if not is_instance_valid(panel) or not state:
		return
	var size := get_viewport().get_visible_rect().size
	var font_size := int(24 * state.text_scale)
	var large: bool = state.text_scale >= 1.5
	var height := size.y * (0.79 if large else 0.58)
	panel.position = Vector2(size.x * 0.16, size.y - height - 18)
	panel.size = Vector2(size.x * 0.68, height)
	reading_scroll.position = Vector2(24, 20)
	panel_content.add_theme_font_size_override("font_size", font_size)
	speaker.add_theme_font_size_override("font_size", font_size + 3)
	body.add_theme_font_size_override("normal_font_size", font_size)
	body.custom_minimum_size.y = 90 if not large else 145
	for button in choice_buttons:
		button.add_theme_font_size_override("font_size", font_size)
		button.custom_minimum_size.y = font_size + 22
	advance_button.add_theme_font_size_override("font_size", font_size)
	footer.add_theme_font_size_override("font_size", int(16 * state.text_scale))
	# Keep advance/return hints outside the scrolling story and choices.
	var footer_height := float(int(16 * state.text_scale) * 2 + 12)
	footer.position = Vector2(24, panel.size.y - footer_height - 20)
	footer.size = Vector2(panel.size.x - 48, footer_height)
	reading_scroll.size = panel.size - Vector2(48, 52 + footer_height)
	if focused_choice >= 0 and focused_choice < choice_buttons.size():
		reading_scroll.ensure_control_visible.call_deferred(choice_buttons[focused_choice])
	for i in portraits.size():
		portraits[i].position = Vector2(0 if i == 0 else size.x * 0.84, size.y * 0.25)
		portraits[i].size = Vector2(size.x * 0.16, size.y * 0.73)

func open_dialogue(restored := false) -> void:
	opened = true
	state.begin()
	root.show()
	advance_armed = restored
	_show_node(restored)
	var tween := create_tween()
	root.modulate.a = 0.0
	tween.tween_property(root, "modulate:a", 1.0, 0.15)

func _show_node(full := false) -> void:
	var node: Dictionary = state.NODES.data[state.logical_node]
	speaker.text = "—  %s  —" % node.speaker
	body.text = node.text
	reveal_count = float(body.text.length()) if full or state.instant_text else 0.0
	body.visible_characters = int(reveal_count)
	reveal_complete = full or state.instant_text
	focused_choice = -1
	for child in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()
	choice_buttons.clear()
	reading_scroll.scroll_vertical = 0
	var definitions: Array = node.get("choices", [])
	for i in definitions.size():
		var button := Button.new()
		button.name = "Choice%d" % i
		button.text = "◇  " + definitions[i].text
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not reveal_complete
		_style_choice(button)
		button.pressed.connect(_choose.bind(i))
		button.focus_entered.connect(_focus_choice.bind(i))
		button.mouse_entered.connect(_focus_choice.bind(i))
		choices_box.add_child(button)
		choice_buttons.append(button)
	advance_button.visible = definitions.is_empty() or not reveal_complete
	for i in portraits.size():
		portraits[i].modulate = Color.WHITE if (i == 1) == (node.speaker == "伊莎") else Color(0.6, 0.6, 0.6)
	_layout()

func _process(delta: float) -> void:
	if not opened or nested_menu or reveal_complete:
		return
	reveal_count += delta * state.reveal_speed
	body.visible_characters = mini(int(reveal_count), body.text.length())
	if body.visible_characters >= body.text.length(): _complete_line()

func _complete_line() -> void:
	reveal_complete = true
	body.visible_characters = -1
	for button in choice_buttons: button.disabled = false
	advance_button.visible = choice_buttons.is_empty()

func _intent_allowed() -> bool:
	if not opened or nested_menu:
		return false
	var now := Time.get_ticks_msec()
	if now - last_action_ms < 220:
		return false
	last_action_ms = now
	return true

func advance() -> void:
	if not _intent_allowed(): return
	if not reveal_complete:
		_complete_line()
		return
	if not choice_buttons.is_empty(): return
	var node: Dictionary = state.NODES.data[state.logical_node]
	if node.get("next", "close") == "close":
		leave()
	else:
		state.logical_node = node.next
		_play("select_007")
		_show_node()

func _focus_choice(index: int) -> void:
	if not reveal_complete or nested_menu: return
	focused_choice = index
	for i in choice_buttons.size():
		choice_buttons[i].text = ("◆  " if i == index else "◇  ") + state.NODES.data[state.logical_node].choices[i].text
	# Mouse and keyboard focus share the same visible reading position.
	reading_scroll.ensure_control_visible(choice_buttons[index])

func _choose(index: int) -> void:
	if not reveal_complete or not _intent_allowed(): return
	if state.choose(index):
		_play("confirmation_001")
		_show_node()
		progress_changed.emit()

func _play(cue: String) -> void:
	var path := "res://assets/dialogue/sounds/Audio/%s.ogg" % cue
	if ResourceLoader.exists(path):
		sound.stream = load(path)
		sound.play()

func handle_input(event: InputEvent) -> bool:
	if not opened or nested_menu: return false
	if event is InputEventKey:
		if not event.pressed:
			if event.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER]: advance_armed = true
			return true
		if event.echo: return true
		if event.keycode == KEY_ESCAPE:
			leave()
		elif event.keycode == KEY_F10:
			menu_requested.emit()
		elif event.keycode in [KEY_UP, KEY_DOWN] and reveal_complete and not choice_buttons.is_empty():
			focused_choice = posmod(focused_choice + (1 if event.keycode == KEY_DOWN else -1), choice_buttons.size())
			choice_buttons[focused_choice].grab_focus()
		elif event.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER] and advance_armed:
			advance_armed = false
			if reveal_complete and focused_choice >= 0:
				_choose(focused_choice)
			else:
				advance()
		return true
	return event is InputEventMouseMotion

func leave() -> void:
	if nested_menu: return
	opened = false
	root.hide()
	# Keep logical progress after abandonment; finishing D03 starts a repeat at
	# the preparation reminder. No reward is granted by opening or leaving.
	state.conversation_active = state.logical_node != "D03" or not reveal_complete
	closed.emit()

func _mcp_state() -> Dictionary:
	var choice_layout: Array = []
	for button in choice_buttons:
		choice_layout.append({"text": button.text, "disabled": button.disabled, "focused": button.has_focus(), "rect": _rect_observation(button.get_global_rect())})
	var minimum := panel_content.get_combined_minimum_size()
	return {"opened": opened, "node": state.logical_node, "speaker": speaker.text, "body": body.text, "visible_characters": body.visible_characters, "reveal_complete": reveal_complete, "focused_choice": focused_choice, "choices_disabled": not reveal_complete, "nested_menu": nested_menu, "text_scale": state.text_scale, "reveal_speed": state.reveal_speed, "portraits_bound": portraits.size() == 2 and portraits[0].texture != null and portraits[1].texture != null, "panel_rect": _rect_observation(panel.get_global_rect()), "reading_minimum": [minimum.x, minimum.y], "scroll_rect": _rect_observation(reading_scroll.get_global_rect()), "scroll_vertical": reading_scroll.scroll_vertical, "choices": choice_layout}

func _rect_observation(rect: Rect2) -> Dictionary:
	return {"position": [rect.position.x, rect.position.y], "size": [rect.size.x, rect.size.y]}
