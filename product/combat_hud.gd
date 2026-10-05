extends CanvasLayer
var training: Node3D
var root: Control
var vitals: Label
var checkpoint: Label
var checkpoint_card: PanelContainer
var hp: ProgressBar
var xp: ProgressBar
var status: Label
var enemy: VBoxContainer
var enemy_name: Label
var enemy_hp: ProgressBar
var shown_xp = 0.0

func _ready() -> void:
	layer = 5
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = preload("res://dialogue_theme.tres").duplicate()
	root.theme.set_color("font_color", "Label", Color(1, 0.91, 0.73))
	root.theme.set_color("font_outline_color", "Label", Color(0.07, 0.06, 0.03))
	root.theme.set_constant("outline_size", "Label", 5)
	add_child(root)
	var card = PanelContainer.new()
	card.name = "Vitals"
	card.position = Vector2(18, 104)
	card.custom_minimum_size = Vector2(250, 90)
	card.add_theme_stylebox_override("panel", frame())
	root.add_child(card)
	var rows = VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rows)
	vitals = Label.new()
	rows.add_child(vitals)
	checkpoint_card = PanelContainer.new()
	checkpoint_card.name = "Checkpoint"
	checkpoint_card.add_theme_stylebox_override("panel", frame())
	root.add_child(checkpoint_card)
	checkpoint = Label.new()
	checkpoint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	checkpoint_card.add_child(checkpoint)
	hp = meter(Color(0.7, 0.16, 0.10), 100)
	rows.add_child(hp)
	xp = meter(Color(0.8, 0.59, 0.22), 30)
	rows.add_child(xp)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(status)
	enemy = VBoxContainer.new()
	enemy.custom_minimum_size = Vector2(190, 50)
	root.add_child(enemy)
	enemy_name = Label.new()
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy.add_child(enemy_name)
	enemy_hp = meter(Color(0.75, 0.18, 0.11), 24)
	enemy.add_child(enemy_hp)
	shown_xp = training.state.experience

func frame() -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-013.png")
	style.modulate_color = Color(0.25, 0.22, 0.17, 0.94)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 10)
		style.set_content_margin(side, 12)
	return style

func meter(color: Color, maximum: float) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.max_value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(220, 10)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.06, 0.04, 0.88)
	bg.border_color = Color(0.59, 0.48, 0.29)
	bg.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", bg)
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _process(delta: float) -> void:
	var state: Node = training.state
	root.visible = training.world.pause_owners.is_empty()
	var viewport = get_viewport().get_visible_rect().size
	var size = int(18 * state.text_scale)
	vitals.add_theme_font_size_override("font_size", size)
	vitals.text = "艾洛 · HP %d/100\n等级 1 · XP %d/30" % [int(ceil(state.health)), state.experience]
	checkpoint.add_theme_font_size_override("font_size", size)
	checkpoint.text = "◇ 剩余命数 %d\n检查点：CP01 河谷村庄" % state.lives
	checkpoint_card.position = Vector2(viewport.x - checkpoint_card.size.x - 18, 18)
	hp.value = state.health
	if training.world.pause_owners.is_empty():
		shown_xp = move_toward(shown_xp, state.experience, delta * 22)
	xp.value = shown_xp
	status.position = Vector2(viewport.x * 0.2, viewport.y - 105)
	status.size = Vector2(viewport.x * 0.6, 90)
	status.add_theme_font_size_override("font_size", int(20 * state.text_scale))
	status.text = training.notice if training.notice_time > 0 else ""
	var opponent: CharacterBody3D = training.monster
	var point = opponent.global_position + Vector3.UP * 2.1
	var camera: Camera3D = training.player.camera
	var in_view = not camera.is_position_behind(point)
	var pixel = camera.unproject_position(point) if in_view else Vector2(-1000, -1000)
	enemy.visible = opponent.engaged and opponent.health > 0 and in_view and Rect2(Vector2.ZERO, viewport).has_point(pixel) and opponent.line_clear(training.player.global_position)
	enemy.position = pixel - Vector2(110, 50)
	enemy_hp.value = opponent.health
	enemy_name.text = "◇ 抬手预告" if opponent.phase == "telegraph" else "训练怪 · %d/24" % int(opponent.health)
	enemy_name.add_theme_font_size_override("font_size", int(17 * state.text_scale))
	if training.notice_time > 0: status.add_theme_color_override("font_color", Color(1, 0.91, 0.64))

func _mcp_state() -> Dictionary:
	return {"health": hp.value, "experience_target": training.state.experience, "experience_displayed": xp.value, "enemy_bar_visible": enemy.visible, "enemy_hp": enemy_hp.value, "status": status.text}
