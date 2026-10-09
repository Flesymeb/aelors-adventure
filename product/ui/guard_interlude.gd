extends CanvasLayer
## Opening presentation adapted to a same-world earned boundary.
## Uses the same fullscreen, gentle zoom and native margin wear as the opening.
signal completed
const ART := "res://assets/cinematics/guard_approach/"
var world: Node3D
var state: Node
var slides: Array = []
var chapter_title := ""
var beat := 0
var elapsed := 0.0
var total_elapsed := 0.0
var paused := false
var finished := false
var armed := false
var skip_hold := 0.0
var root: Control
var picture: TextureRect
var captions: Label
var plate: PanelContainer
var actions: HBoxContainer
var pause_button: Button
var veil: ColorRect
var wear: Control
var previous_disable_3d := false
var released := false

static func eligible(adventure: Node) -> bool:
	return adventure.guard_briefing_available() and adventure.guard_briefing_acknowledged and not adventure.guard_interlude_seen and not adventure.guards_defeated() and available()

static func available() -> bool:
	for name in ["guard_01.png","guard_02.png","guard_03.png"]:
		if not ResourceLoader.exists(ART+name): return false
	return FileAccess.file_exists(ART+"SOURCE.json")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	state = world.dialogue_state
	var storyboard: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART+"storyboard.json"))
	slides = storyboard.slides
	chapter_title = storyboard.get("title", "第一章·桥后的踪迹")
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = preload("res://ui/title_theme.tres")
	add_child(root)
	picture = TextureRect.new()
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(picture)
	wear = Control.new()
	wear.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wear.draw.connect(_draw_wear)
	root.add_child(wear)
	plate = PanelContainer.new()
	var frame := StyleBoxTexture.new()
	frame.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-013.png")
	frame.modulate_color = Color(0.9,0.82,0.64)
	frame.set_content_margin_all(18)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: frame.set_texture_margin(side,10)
	plate.add_theme_stylebox_override("panel",frame)
	root.add_child(plate)
	captions = Label.new()
	captions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	captions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	captions.add_theme_color_override("font_color",Color(0.14,0.10,0.05))
	plate.add_child(captions)
	veil = ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color.BLACK
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation",12)
	root.add_child(actions)
	pause_button = Button.new()
	pause_button.text = "暂停 [Esc]"
	pause_button.pressed.connect(toggle_pause)
	actions.add_child(pause_button)
	var skip := Button.new()
	skip.text = "跳过 · 返回守卫目标"
	skip.pressed.connect(finish)
	actions.add_child(skip)
	for button in actions.get_children():
		var button_frame := frame.duplicate() as StyleBoxTexture
		button_frame.modulate_color = Color(0.40,0.30,0.18)
		button_frame.set_content_margin_all(10)
		button.add_theme_stylebox_override("normal",button_frame)
		button.add_theme_stylebox_override("hover",button_frame)
		button.add_theme_stylebox_override("pressed",button_frame)
		button.add_theme_color_override("font_color",Color(1,0.94,0.80))
		button.add_theme_color_override("font_hover_color",Color.WHITE)
		button.add_theme_color_override("font_pressed_color",Color.WHITE)
	get_viewport().size_changed.connect(_layout)
	world._set_pause_owner("guard_interlude",true)
	previous_disable_3d = world.get_viewport().disable_3d
	world.get_viewport().disable_3d = true
	_show_beat()
	_layout()
	_refresh_presentation()

func _show_beat() -> void:
	picture.texture = load(ART+slides[beat].image)
	captions.text = chapter_title + "\n" + slides[beat].caption

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	captions.add_theme_font_size_override("font_size",int(24*state.text_scale))
	captions.custom_minimum_size.x = size.x*0.88-36
	plate.custom_minimum_size.x = size.x*0.88
	plate.size = Vector2(size.x*0.88,0)
	plate.position = Vector2(size.x*0.06,size.y-plate.size.y-28)
	for button in actions.get_children(): button.add_theme_font_size_override("font_size",int(18*state.text_scale))
	actions.position = Vector2(maxf(16,size.x-actions.size.x-24),24)

func _process(delta: float) -> void:
	if finished: return
	if not armed:
		if not Input.is_key_pressed(KEY_SPACE) and not Input.is_key_pressed(KEY_ENTER) and not Input.is_key_pressed(KEY_E): armed = true
		return
	if paused: return
	elapsed += delta
	total_elapsed += delta
	if Input.is_key_pressed(KEY_SPACE):
		skip_hold += delta
		if skip_hold >= 0.8: finish(); return
	else: skip_hold = 0
	if elapsed >= float(slides[beat].duration_seconds):
		elapsed -= float(slides[beat].duration_seconds)
		if beat == slides.size()-1: finish(); return
		beat += 1
		_show_beat()
	_refresh_presentation()
	_layout()

func _refresh_presentation() -> void:
	var motion: bool = not state.reduced_motion and state.graphics_quality != "low"
	var duration := float(slides[beat].duration_seconds)
	picture.pivot_offset = get_viewport().get_visible_rect().size*0.5
	picture.scale = Vector2.ONE*(1.02+0.02*elapsed/duration if motion else 1.0)
	# Black boundaries never blend two story identities into one composition.
	veil.color.a = maxf(1.0-clampf(elapsed/0.18,0,1),clampf((elapsed-duration+0.18)/0.18,0,1))
	wear.queue_redraw()

func _draw_wear() -> void:
	if state.graphics_quality == "low": return
	var size := wear.size
	for edge in 16:
		var opacity := 0.008*float(16-edge)
		wear.draw_rect(Rect2(edge*2,0,2,size.y),Color(0.12,0.08,0.04,opacity))
		wear.draw_rect(Rect2(size.x-edge*2-2,0,2,size.y),Color(0.12,0.08,0.04,opacity))
	for mark in 36:
		var pos := Vector2(fmod(mark*137.1,size.x),6+fmod(mark*47.3,20))
		wear.draw_circle(pos,1.0+fmod(mark*0.7,2),Color(0.3,0.2,0.1,0.07))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if armed: toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if not armed or finished: return
	paused = not paused
	armed = false
	pause_button.text = "继续 [Esc]" if paused else "暂停 [Esc]"
	skip_hold = 0

func finish() -> void:
	if finished or not armed: return
	finished = true
	state.guard_interlude_seen = true
	# A safe same-map boundary, never a guard victory or departure commit.
	_release_world()
	world._save_opening(0)
	world.training.tell(state.guard_objective(),5)
	completed.emit()
	queue_free()

func _release_world() -> void:
	if released or not is_instance_valid(world) or world.is_queued_for_deletion(): return
	released = true
	world.get_viewport().disable_3d = previous_disable_3d
	world._set_pause_owner("guard_interlude",false)

func _exit_tree() -> void:
	# Interrupted playback remains unseen and replayable; never commits a save.
	_release_world()

func _mcp_state() -> Dictionary:
	return {"beat":beat+1,"image":slides[beat].image if not slides.is_empty() else null,"elapsed":total_elapsed,"caption":captions.text if is_instance_valid(captions) else null,"paused":paused,"finished":finished,"inputs_armed":armed,"zoom":picture.scale.x if is_instance_valid(picture) else null,"transition_alpha":veil.color.a if is_instance_valid(veil) else null}
