extends CanvasLayer
## Presentation consumes a new durable victory; it never operates the device.
const DURATION := 7.0
var encounter: Node3D
var active := false
var elapsed := 0.0
var armed := false
var consumed_commit := 0
var plate: PanelContainer
var caption: Label
var actions: HBoxContainer
var pause_button: Button
var skip_button: Button
var feedback_was_visible := false
var last_text_scale := -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 7
	plate = PanelContainer.new()
	plate.theme = preload("res://dialogue_theme.tres")
	var frame := StyleBoxTexture.new()
	frame.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-013.png")
	frame.modulate_color = Color(0.9,0.82,0.64)
	frame.set_content_margin_all(16)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: frame.set_texture_margin(side,10)
	plate.add_theme_stylebox_override("panel",frame)
	add_child(plate)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_color_override("font_color",Color(0.14,0.10,0.05))
	plate.add_child(caption)
	actions = HBoxContainer.new()
	actions.theme = plate.theme
	actions.add_theme_constant_override("separation",14)
	add_child(actions)
	pause_button = Button.new()
	pause_button.text = "暂停 [Esc]"
	pause_button.pressed.connect(func(): encounter.world._open_controls())
	actions.add_child(pause_button)
	skip_button = Button.new()
	skip_button.text = "跳过 [空格]"
	skip_button.pressed.connect(finish)
	actions.add_child(skip_button)
	for button in [pause_button,skip_button]:
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		for variant in ["normal","hover","focus","pressed","disabled"]:
			var skin := frame.duplicate() as StyleBoxTexture
			skin.modulate_color = Color(1,0.84,0.43) if variant in ["hover","focus"] else Color(0.83,0.74,0.57)
			button.add_theme_stylebox_override(variant,skin)
			button.add_theme_color_override("font_"+variant+"_color",Color(0.14,0.10,0.05))
	hide()

func begin() -> bool:
	if active or not encounter.state.warden_defeated or encounter.actor.health > 0 or encounter.victory_pending or encounter.victory_commits <= consumed_commit: return false
	consumed_commit = encounter.victory_commits
	active = true
	elapsed = 0.0
	armed = false
	var world: Node3D = encounter.world
	feedback_was_visible = world.training.feedback.visible
	world.training.feedback.hide()
	world.training.interrupt("cinematic")
	# Contact already resolved; do not freeze its brief hit tint for the full collapse.
	if is_instance_valid(encounter.actor.hit_response): encounter.actor.hit_response.clear()
	world.player.velocity = Vector3.ZERO
	world.player.release_encounter_camera()
	world._set_pause_owner("warden_aftermath",true)
	encounter.actor.character.begin_presentation("Death")
	encounter.presentation_box = encounter.actor.character.presentation_bounds(encounter.actor.model)
	encounter.frame_presentation()
	encounter.reveal_camera.current = true
	_layout()
	show()
	return true

func suspended() -> bool:
	return encounter.world.pause_owners.keys().any(func(owner): return owner != "warden_aftermath")

func _process(delta: float) -> void:
	if not active: return
	# Our pause owner intentionally holds ordinary gameplay. Manual native
	# pose sampling below is the only world presentation that may advance.
	if not Input.is_key_pressed(KEY_SPACE) and not Input.is_key_pressed(KEY_ENTER) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not armed: pause_button.grab_focus.call_deferred()
		armed = true
	var paused := suspended()
	encounter.cue.stream_paused = paused
	plate.visible = not paused
	actions.visible = not paused
	pause_button.disabled = not armed or paused
	skip_button.disabled = not armed or paused
	_layout()
	if paused: return
	elapsed += delta
	encounter.actor.character.advance_presentation(delta)
	if elapsed >= DURATION: finish()

static func caption_for(released: bool) -> String:
	return "看守的石躯崩落，锁印装置停止了抵抗。\n"+("应急解除器已取得；仍须用旧灯逐人确认村民安全。" if released else "院内的锁印装置尚未操作。靠近后按 E 检查，取得应急解除器。")

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var state: Node = encounter.state
	if not is_equal_approx(last_text_scale,state.text_scale):
		last_text_scale = state.text_scale
		encounter.frame_presentation()
	caption.text = caption_for(state.warden_lock_released)
	caption.custom_minimum_size.x = view.x*0.88-36
	caption.add_theme_font_size_override("font_size",int(20*state.text_scale))
	plate.custom_minimum_size.x = view.x*0.88
	plate.size = Vector2(view.x*0.88,0)
	plate.reset_size()
	plate.position = Vector2(view.x*0.06,view.y-plate.size.y-20)
	for button in [pause_button,skip_button]: button.add_theme_font_size_override("font_size",int(16*state.text_scale))
	actions.reset_size()
	actions.position = Vector2(24,20)

func _input(event: InputEvent) -> void:
	if not active or suspended() or not armed: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		finish()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT] and active and not suspended():
		encounter.world._open_controls()

func finish() -> void:
	if not active: return
	shutdown()
	encounter.release_score()

func shutdown() -> void:
	if not active: return
	active = false
	hide()
	if is_instance_valid(encounter.actor): encounter.actor.character.end_presentation(true)
	var world: Node3D = encounter.world
	if is_instance_valid(world) and not world.is_queued_for_deletion():
		world.training.feedback.visible = feedback_was_visible
		world.player.camera.current = true
		world._set_pause_owner("warden_aftermath",false)
		world.player.suppress_held_combat_actions()

func _exit_tree() -> void:
	shutdown()

func _mcp_state() -> Dictionary:
	return {"active":active,"elapsed":elapsed,"armed":armed,"caption":caption.text if caption else "","paused":suspended() if active else false}
