extends Control
## Presentation clock only. AdventureState/router own the single durable commit.
signal completed
var router: Node
var state: Node
var slides: Array = []
var pictures: Array[Texture2D] = []
var beat := 0
var elapsed := 0.0
var total_elapsed := 0.0
var finished := false
var inputs_armed := false
var skip_hold := 0.0
var pause_menu: Control
var image_current: TextureRect
var image_previous: TextureRect
var subtitle: Label
var caption_panel: PanelContainer
var toolbar: HBoxContainer
var hint: Label
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var cue: AudioStreamPlayer
var caption_text := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = preload("res://ui/title_theme.tres").duplicate()
	state = router.state
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/cinematics/opening/storyboard.json"))
	slides = data.slides
	for slide in slides: pictures.append(load("res://assets/cinematics/opening/" + slide.image))
	for index in 2:
		var picture := TextureRect.new()
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(picture)
		if index == 0: image_current = picture
		else: image_previous = picture
	caption_panel = PanelContainer.new()
	caption_panel.name = "SubtitleBackplate"
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.055, 0.045, 0.027, 0.9)
	back.border_color = Color(0.6, 0.48, 0.26, 0.65)
	back.set_border_width_all(1)
	back.set_content_margin_all(18)
	caption_panel.add_theme_stylebox_override("panel", back)
	caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption_panel)
	subtitle = Label.new()
	subtitle.name = "RuntimeSubtitle"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.96, 0.9, 0.73))
	caption_panel.add_child(subtitle)
	toolbar = HBoxContainer.new()
	toolbar.name = "OpeningActions"
	add_child(toolbar)
	for action in [router.title.button(toolbar, "暂停 [Esc]", open_pause), router.title.button(toolbar, "跳过开场", finish)]:
		var frame: StyleBoxTexture = action.get_theme_stylebox("normal").duplicate()
		frame.modulate_color = Color(0.87, 0.79, 0.61, 0.92)
		action.add_theme_stylebox_override("normal", frame)
	hint = Label.new()
	hint.name = "SkipHint"
	hint.add_theme_color_override("font_color", Color(0.96, 0.9, 0.73))
	hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	add_child(hint)
	music = AudioStreamPlayer.new()
	music.name = "OpeningMusic"
	music.bus = "Music"
	music.process_mode = Node.PROCESS_MODE_PAUSABLE
	music.stream = preload("res://assets/audio/settings_music.ogg")
	add_child(music)
	ambience = AudioStreamPlayer.new()
	ambience.name = "OpeningAmbience"
	ambience.bus = "Effects"
	ambience.process_mode = Node.PROCESS_MODE_PAUSABLE
	var air := preload("res://assets/cinematics/opening/ambience.ogg").duplicate() as AudioStreamOggVorbis
	air.loop = true
	ambience.stream = air
	ambience.volume_db = -15
	add_child(ambience)
	cue = AudioStreamPlayer.new()
	cue.name = "OpeningTransition"
	cue.bus = "Effects"
	cue.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cue)
	router.audio.music.stream_paused = true
	music.play()
	ambience.play()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_beat()
	_layout()

func _show_beat() -> void:
	image_current.texture = pictures[beat]
	image_previous.texture = pictures[beat - 1] if beat > 0 else null
	caption_text = str(slides[beat].caption)
	subtitle.text = caption_text
	music.volume_db = [-23.0, -30.0, -28.0, -22.0][beat]
	ambience.volume_db = -10 if beat in [1, 2] else -15
	if beat == 1:
		cue.stream = preload("res://assets/cinematics/opening/rift_transition.wav")
		cue.pitch_scale = 1.0
		cue.volume_db = -8
		cue.play()
	elif beat == 3:
		cue.stop()

func _process(delta: float) -> void:
	if finished: return
	_layout()
	if pause_menu:
		music.stream_paused = true
		cue.stream_paused = true
		ambience.stream_paused = true
		return
	if get_tree().paused: return
	if not inputs_armed:
		if router._confirmation_held(): return
		inputs_armed = true
	music.stream_paused = false
	cue.stream_paused = false
	ambience.stream_paused = false
	elapsed += delta
	total_elapsed += delta
	if Input.is_key_pressed(KEY_SPACE):
		skip_hold += delta
		if skip_hold >= 0.8: finish(); return
	else: skip_hold = 0
	if elapsed >= float(slides[beat].duration_seconds):
		elapsed -= float(slides[beat].duration_seconds)
		if beat == slides.size() - 1: finish(); return
		beat += 1
		_show_beat()
	var motion: bool = not state.reduced_motion and state.graphics_quality != "low"
	var zoom := 1.02 + 0.02 * elapsed / float(slides[beat].duration_seconds) if motion else 1.0
	image_current.pivot_offset = size * 0.5
	image_current.scale = Vector2.ONE * zoom
	image_previous.pivot_offset = size * 0.5
	image_previous.scale = Vector2.ONE * (1.04 if motion else 1.0)
	image_previous.modulate.a = 1.0 - clampf(elapsed / 0.5, 0, 1)
	image_current.modulate.a = clampf(elapsed / 0.5, 0, 1) if beat == 0 else 1.0
	queue_redraw()

func _layout() -> void:
	var view := get_viewport_rect().size
	var text_size: float = state.text_scale
	subtitle.add_theme_font_size_override("font_size", int(26 * text_size))
	subtitle.custom_minimum_size.x = view.x * 0.88 - 36
	caption_panel.custom_minimum_size.x = view.x * 0.88
	caption_panel.size = Vector2(view.x * 0.88, 0)
	caption_panel.position = Vector2(view.x * 0.06, view.y - caption_panel.size.y - 34)
	for control in toolbar.get_children(): control.add_theme_font_size_override("font_size", int(18 * text_size))
	toolbar.position = Vector2(view.x - toolbar.size.x - 32, 24)
	hint.add_theme_font_size_override("font_size", int(16 * text_size))
	hint.text = "按住空格跳过" if skip_hold == 0 else "跳过开场 · %d%%" % int(skip_hold / 0.8 * 100)
	hint.position = Vector2(32, 30)
	toolbar.visible = pause_menu == null
	caption_panel.visible = pause_menu == null
	hint.visible = pause_menu == null

func _draw() -> void:
	# Native canvas drawing avoids shader TIME, which is not the story clock.
	# Marks stay at the margins; faces and subtitles are deliberately clear.
	if state == null or state.graphics_quality == "low": return
	for edge in 16:
		var opacity := 0.008 * float(16 - edge)
		draw_rect(Rect2(edge * 2, 0, 2, size.y), Color(0.12, 0.08, 0.04, opacity))
		draw_rect(Rect2(size.x - edge * 2 - 2, 0, 2, size.y), Color(0.12, 0.08, 0.04, opacity))
	for mark in 36:
		var pos := Vector2(fmod(mark * 137.1, size.x), 6 + fmod(mark * 47.3, 20))
		draw_circle(pos, 1.0 + fmod(mark * 0.7, 2), Color(0.3, 0.2, 0.1, 0.07))
	if state.reduced_motion: return
	for mote in 10:
		var pos := Vector2(fmod(mote * 131.7 + total_elapsed * (2 + mote * 0.1), size.x), fmod(mote * 67.4 - total_elapsed * 3 + size.y * 2, size.y * 0.7))
		draw_circle(pos, 1.1, Color(0.82, 0.5 if beat in [1, 2] else 0.72, 0.32, 0.18))

func _unhandled_input(event: InputEvent) -> void:
	if finished or pause_menu or not inputs_armed: return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		open_pause()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_node_ready() and not finished:
		open_pause()

func open_pause() -> void:
	if pause_menu or finished: return
	skip_hold = 0
	pause_menu = preload("res://ui/menu_foundation/main_menu.tscn").instantiate()
	pause_menu.router = router
	pause_menu.cinematic = self
	pause_menu.name = "OpeningPause"
	add_child(pause_menu)
	get_tree().paused = true
	music.stream_paused = true
	cue.stream_paused = true
	ambience.stream_paused = true
	_layout()

func close_pause() -> void:
	if not pause_menu: return
	pause_menu.hide()
	pause_menu.queue_free()
	pause_menu = null
	inputs_armed = false
	skip_hold = 0
	get_tree().paused = false

func finish() -> void:
	if finished or not inputs_armed: return
	finished = true
	music.stop()
	cue.stop()
	ambience.stop()
	completed.emit()

func _exit_tree() -> void:
	if is_instance_valid(router) and is_instance_valid(router.audio):
		router.audio.music.stream_paused = false

func _mcp_state() -> Dictionary:
	var owners := ["cinematic"]
	if pause_menu:
		owners.append("opening_pause")
		if pause_menu.sub_menu: owners.append(str(pause_menu.sub_menu.name))
		if pause_menu.confirmation: owners.append("confirmation")
	return {"beat": beat + 1, "image": str(slides[beat].image), "beat_elapsed": elapsed, "elapsed": total_elapsed, "duration": 38, "caption": caption_text, "subtitle_rect": str(caption_panel.get_global_rect()), "text_scale": state.text_scale, "pause_owners": owners, "timeline_paused": pause_menu != null or not inputs_armed, "transition_alpha": image_previous.modulate.a, "zoom": image_current.scale.x, "nonessential_effects": state.graphics_quality != "low", "motion": not state.reduced_motion and state.graphics_quality != "low", "inputs_armed": inputs_armed, "finished": finished}
