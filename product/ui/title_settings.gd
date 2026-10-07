extends Control
var host: Control
var feedback: Label
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column: VBoxContainer = host.create_page(self, "设置", true)
	var size_button: Button = host.button(column, "文字缩放 · %d%%" % int(host.state.text_scale * 100), cycle_scale)
	size_button.name = "TextScale"
	var speed_button: Button = host.button(column, "对白速度 · %d 字/秒" % int(host.state.reveal_speed), cycle_speed)
	speed_button.name = "RevealSpeed"
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.25
	sensitivity.max_value = 2.5
	sensitivity.step = 0.05
	sensitivity.value = host.state.mouse_sensitivity
	var sensitivity_label: Label = host.paragraph(column, "鼠标灵敏度 · %.2f" % sensitivity.value)
	column.add_child(sensitivity)
	sensitivity.value_changed.connect(func(value: float):
		host.state.mouse_sensitivity = value
		sensitivity_label.text = "鼠标灵敏度 · %.2f" % value
		commit())
	for key in ["instant_text", "muted_sound", "reduced_motion"]:
		var label: String = {"instant_text": "即时显示对白", "muted_sound": "静音", "reduced_motion": "减少动态"}[key]
		var toggle := CheckButton.new()
		toggle.text = label
		toggle.button_pressed = host.state.get(key)
		toggle.toggled.connect(func(value: bool):
			host.state.set(key, value)
			if key == "muted_sound" and value: host.audio.voice.stop()
			commit())
		column.add_child(toggle)
	feedback = host.paragraph(column, "设置会在下次启动时保留。")
	host.button(column, "返回", close)
	size_button.grab_focus.call_deferred()
	host.reflow(self)
func commit() -> void:
	feedback.text = "设置已保存" if host.state.save_preferences() == OK else "设置保存失败，请重试。"
	if feedback.text.contains("失败"): host.audio.play_cue("failure")
	host.reflow(self)
func cycle_scale() -> void:
	host.state.text_scale = 1.5 if host.state.text_scale == 1.0 else (2.0 if host.state.text_scale == 1.5 else 1.0)
	find_child("TextScale", true, false).text = "文字缩放 · %d%%" % int(host.state.text_scale * 100)
	host.add_theme_font_size_override("font_size", int(22 * host.state.text_scale))
	host.reflow(host)
	commit()
func cycle_speed() -> void:
	host.state.reveal_speed = 45.0 if host.state.reveal_speed == 30.0 else (60.0 if host.state.reveal_speed == 45.0 else 30.0)
	find_child("RevealSpeed", true, false).text = "对白速度 · %d 字/秒" % int(host.state.reveal_speed)
	commit()
func close() -> void:
	host.refresh()
	host.reflow(host)
	host.audio.play_cue("back")
	hide()
