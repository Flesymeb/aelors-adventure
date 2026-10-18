extends CanvasLayer
## Frames an already committed victory. The enemy's death driver owns motion;
## this view never starts/replays Death or changes key, rescue or core facts.
const DURATION := 4.2
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
var last_text_scale := -1.0
var feedback_was_visible := false

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
	if active or not encounter.state.veyne_defeated or encounter.victory_pending or encounter.victory_commits <= consumed_commit: return false
	consumed_commit = encounter.victory_commits
	active = true
	elapsed = 0.0
	armed = false
	var world: Node3D = encounter.world
	feedback_was_visible = world.training.feedback.visible
	world.training.feedback.hide()
	world.training.interrupt("cinematic")
	world.player.velocity = Vector3.ZERO
	world.player.release_encounter_camera()
	world._set_pause_owner("veyne_presentation",true)
	# Retain the live enemy's Death motion. A fixed grounded view avoids chasing
	# the falling rig, and is the same intelligible shot with Reduced Motion.
	encounter.presentation_box = encounter.actor.character.posed_bounds(encounter.actor.model)
	encounter.frame_presentation()
	encounter.reveal_camera.current = true
	_layout()
	show()
	return true

func suspended() -> bool:
	return encounter.world.pause_owners.keys().any(func(owner): return owner != "veyne_presentation")

func set_paused(paused: bool) -> void:
	if active:
		encounter.actor.character.set_speed(0.0 if paused else 1.0)
		encounter.cue.stream_paused = paused

func _process(delta: float) -> void:
	if not active: return
	# Transport freezes pause the tree without adding a product menu owner.
	# Keep the already laid-out view stable while its pausable rig is held.
	if get_tree().paused and not suspended(): return
	if not Input.is_key_pressed(KEY_SPACE) and not Input.is_key_pressed(KEY_ENTER) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not armed: pause_button.grab_focus.call_deferred()
		armed = true
	var paused := suspended()
	set_paused(paused)
	plate.visible = not paused
	actions.visible = not paused
	pause_button.disabled = not armed
	skip_button.disabled = not armed
	_layout()
	if paused: return
	elapsed += delta
	if elapsed >= DURATION: finish()

static func caption_for(assembled: bool, key_owned: bool) -> String:
	var key_line := "解除钥印已取得。" if key_owned else "解除钥印留在祭坛；靠近后按 E 检查。"
	var rescue_line := "村民已在蓝灯旁集合。" if assembled else "仍需确认四位村民的安全与集合。"
	return "维恩倒下，裂隙法术随之消散。\n"+key_line+"\n"+rescue_line+"召唤核心仍需关闭。"

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var state: Node = encounter.state
	if not is_equal_approx(last_text_scale,state.text_scale):
		last_text_scale = state.text_scale
		encounter.frame_presentation()
	caption.text = caption_for(state.rescue_assembled,state.veyne_release_key)
	caption.add_theme_font_size_override("font_size",int(20*state.text_scale))
	plate.custom_minimum_size.x = view.x*0.88
	plate.size = Vector2(view.x*0.88,0)
	plate.position = Vector2(view.x*0.06,view.y-plate.get_combined_minimum_size().y-20)
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
		set_paused(true)

func finish() -> void:
	if not active: return
	shutdown()
	encounter.release_score()
	# Settle the existing tree to its final Death pose without restarting its
	# state or introducing an AnimationPlayer that competes with that owner.
	var character: Node = encounter.actor.character
	character.anim_tree.advance(encounter.actor.animator.get_animation("veyne/Death").length)
	character.set_speed(0.0)

func shutdown() -> void:
	if not active: return
	active = false
	hide()
	if is_instance_valid(encounter.actor): encounter.actor.character.set_speed(1.0)
	var world: Node3D = encounter.world
	if is_instance_valid(world) and not world.is_queued_for_deletion():
		world.training.feedback.visible = feedback_was_visible
		world.player.camera.current = true
		world._set_pause_owner("veyne_presentation",false)
		world.player.suppress_held_combat_actions()

func _exit_tree() -> void:
	shutdown()

func _mcp_state() -> Dictionary:
	return {"active":active,"elapsed":elapsed,"armed":armed,"caption":caption.text if caption else "","paused":suspended() if active else false}
