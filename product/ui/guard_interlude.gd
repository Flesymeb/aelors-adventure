extends CanvasLayer
## Earned live-world briefing. The world stays paused; only selected visual clips advance.
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
var previous_camera: Camera3D
var camera: Camera3D
var previous_mouse_mode: Input.MouseMode
var encounter: Node3D
var hidden_presentations: Dictionary = {}
var ambience: AudioStreamPlayer
var isha_animation: AnimationPlayer
var isha_animation_record: Dictionary = {}
var live_ready := false
var released := false

static func eligible(adventure: Node) -> bool:
	return adventure.guard_briefing_available() and adventure.guard_briefing_acknowledged and not adventure.guard_interlude_seen and not adventure.guards_defeated() and available()

static func available() -> bool:
	return ResourceLoader.exists("res://combat/ChannelMeleeGuard.tscn") and ResourceLoader.exists("res://combat/ChannelRangedGuard.tscn") and FileAccess.file_exists(ART+"storyboard.json")

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
	picture.hide()
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
		button.add_theme_stylebox_override("focus",button_frame)
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.add_theme_color_override("font_color",Color(1,0.94,0.80))
		button.add_theme_color_override("font_hover_color",Color.WHITE)
		button.add_theme_color_override("font_pressed_color",Color.WHITE)
	get_viewport().size_changed.connect(_layout)
	previous_mouse_mode = Input.mouse_mode
	world._set_pause_owner("guard_interlude",true)
	previous_disable_3d = world.get_viewport().disable_3d
	world.get_viewport().disable_3d = false
	for label in world.find_children("*","Label3D",true,false):
		hidden_presentations[label] = label.visible
		label.hide()
	previous_camera = get_viewport().get_camera_3d()
	camera = Camera3D.new()
	camera.name = "GuardRouteCamera"
	camera.fov = 54
	world.add_child(camera)
	camera.current = true
	encounter = world.get("channel_guards")
	live_ready = is_instance_valid(encounter) and encounter.begin_presentation()
	for visual in [world.get("gameplay_hud"),world.get("weapon_label")]:
		if is_instance_valid(visual):
			hidden_presentations[visual] = visual.visible
			visual.hide()
	var isha: Node3D = world.get("isha")
	if is_instance_valid(isha):
		isha_animation = isha.get("idle_player")
		if is_instance_valid(isha_animation):
			isha_animation_record = {"callback":isha_animation.callback_mode_process,"position":isha_animation.current_animation_position}
			isha_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	ambience = AudioStreamPlayer.new()
	ambience.name = "GuardBriefingAir"
	ambience.bus = "Effects"
	ambience.stream = preload("res://assets/cinematics/opening/ambience.ogg")
	ambience.volume_db = -19
	add_child(ambience)
	ambience.play()
	_show_beat()
	_layout()
	_refresh_presentation()

func _show_beat() -> void:
	captions.text = chapter_title + "\n" + slides[beat].caption
	if not live_ready: captions.text += "\n桥后的三名守卫仍在原处；准备好后再前往。"
	_update_camera()

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	captions.add_theme_font_size_override("font_size",int(24*state.text_scale))
	captions.custom_minimum_size.x = size.x*0.88-36
	plate.custom_minimum_size.x = size.x*0.88
	plate.size = Vector2(size.x*0.88,0)
	plate.position = Vector2(size.x*0.06,size.y-plate.get_combined_minimum_size().y-28)
	for button in actions.get_children(): button.add_theme_font_size_override("font_size",int(18*state.text_scale))
	actions.position = Vector2(maxf(16,size.x-actions.size.x-24),24)

func _process(delta: float) -> void:
	if finished: return
	if not armed:
		if not Input.is_key_pressed(KEY_SPACE) and not Input.is_key_pressed(KEY_ENTER) and not Input.is_key_pressed(KEY_E) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): armed = true
		return
	var suspended: bool = paused or world.pause_owners.keys().any(func(owner): return owner != "guard_interlude")
	ambience.stream_paused = suspended
	plate.visible = not world.pause_owners.keys().any(func(owner): return owner != "guard_interlude")
	actions.visible = plate.visible
	if suspended: return
	if live_ready: encounter.presentation_step(delta,beat,elapsed)
	if is_instance_valid(isha_animation): isha_animation.advance(delta)
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
	var duration := float(slides[beat].duration_seconds)
	# Cuts remain intelligible under Reduced Motion; only the optional dolly stops.
	_update_camera()
	veil.color.a = maxf(1.0-clampf(elapsed/0.18,0,1),clampf((elapsed-duration+0.18)/0.18,0,1))
	wear.queue_redraw()

func _update_camera() -> void:
	if not is_instance_valid(camera): return
	var player: Node3D = world.get("player")
	var isha: Node3D = world.get("isha")
	var target := player.global_position + Vector3.UP if is_instance_valid(player) else Vector3.ZERO
	var offset := Vector3(-5,3.2,-6)
	if beat == 0:
		# The connected approach: begin over the restored bridge route.
		var bridge: Node3D = world.get("bridge_actions")
		if is_instance_valid(bridge) and is_instance_valid(bridge.get("lamp")): target = bridge.lamp.global_position.lerp(bridge.trapped_position,0.6) + Vector3.UP
		elif live_ready: target = encounter.enemies[0].home.lerp(target,0.55)
		offset = Vector3(-6,4,-7)
	elif beat == 1 and is_instance_valid(isha):
		target = isha.global_position + Vector3.UP*1.15
		offset = Vector3(-2.8,1.1,3.4)
	elif live_ready:
		target = Vector3.ZERO
		for enemy in encounter.enemies: target += enemy.global_position
		target = target/3.0 + Vector3.UP
		offset = Vector3(6.0,3.2,1.6)
	var dolly := 0.0 if state.reduced_motion else clampf(elapsed/float(slides[beat].duration_seconds),0,1)*0.6
	camera.global_position = target + offset + Vector3(dolly,0,0)
	camera.look_at(target,Vector3.UP)

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not finished:
		paused = true
		armed = false
		skip_hold = 0
		if is_instance_valid(pause_button): pause_button.text = "继续 [Esc]"
		if is_instance_valid(ambience): ambience.stream_paused = true

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
	if is_instance_valid(encounter): encounter.end_presentation()
	if is_instance_valid(isha_animation) and not isha_animation_record.is_empty():
		isha_animation.seek(isha_animation_record.position,true)
		isha_animation.callback_mode_process = isha_animation_record.callback
	if is_instance_valid(ambience): ambience.stop()
	for visual in hidden_presentations:
		if is_instance_valid(visual): visual.visible = hidden_presentations[visual]
	if is_instance_valid(camera):
		camera.current = false
		camera.queue_free()
	if is_instance_valid(previous_camera): previous_camera.current = true
	world.get_viewport().disable_3d = previous_disable_3d
	world._set_pause_owner("guard_interlude",false)
	var player: Node = world.get("player")
	if is_instance_valid(player): player.set_controls_open(not world.pause_owners.is_empty())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if not world.pause_owners.is_empty() else previous_mouse_mode

func _exit_tree() -> void:
	# Interrupted playback remains unseen and replayable; never commits a save.
	_release_world()

func _mcp_state() -> Dictionary:
	return {"beat":beat+1,"shot":slides[beat].get("shot","") if not slides.is_empty() else null,"elapsed":total_elapsed,"caption":captions.text if is_instance_valid(captions) else null,"paused":paused,"finished":finished,"inputs_armed":armed,"live_cast":live_ready,"camera_current":is_instance_valid(camera) and camera.current,"transition_alpha":veil.color.a if is_instance_valid(veil) else null}
