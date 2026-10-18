extends CanvasLayer
## Presentation of an already saved assembly. Never changes durable adventure facts.
signal completed
const DURATION := 7.2
var world: Node3D
var rescue: Node3D
var elapsed := 0.0
var paused := false
var finished := false
var armed := false
var released := false
var actors: Array = []
var actor_modes: Dictionary = {}
var hidden_presentations: Dictionary = {}
var animation_speeds: Dictionary = {}
var previous_camera: Camera3D
var camera: Camera3D
var plate: PanelContainer
var caption: Label
var actions: HBoxContainer
var pause_button: Button
var skip_button: Button
var beat := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 7
	previous_camera = get_viewport().get_camera_3d()
	camera = Camera3D.new()
	camera.name = "AssemblyCamera"
	world.add_child(camera)
	camera.fov = 50
	for visual in [world.player.get("visual"),world.training.get("feedback")]:
		if visual != null:
			hidden_presentations[visual] = visual.visible
			visual.hide()
	for id in world.dialogue_state.CAPTIVE_IDS:
		var actor: Node3D = rescue.captives[id]
		actors.append(actor)
		actor_modes[id] = actor.process_mode
		animation_speeds[id] = actor.presentation.animation_player.speed_scale
		# The world remains frozen. Only the existing cast performs during this beat.
		actor.process_mode = Node.PROCESS_MODE_ALWAYS
		actor.begin_assembly_performance()
	world._set_pause_owner("rescue_assembly",true)
	plate = PanelContainer.new()
	plate.theme = preload("res://dialogue_theme.tres")
	var frame := StyleBoxTexture.new()
	frame.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-013.png")
	frame.modulate_color = Color(0.9,0.82,0.64)
	frame.set_content_margin_all(14)
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
	pause_button.text = "暂停"
	pause_button.pressed.connect(func(): paused = not paused)
	actions.add_child(pause_button)
	skip_button = Button.new()
	skip_button.text = "跳过 [空格]"
	skip_button.pressed.connect(finish)
	actions.add_child(skip_button)
	for button in [pause_button,skip_button]:
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.disabled = true
		for variant in ["normal","hover","focus","pressed","disabled"]:
			var skin := frame.duplicate() as StyleBoxTexture
			skin.modulate_color = Color(1,0.84,0.43) if variant in ["hover","focus"] else Color(0.83,0.74,0.57)
			button.add_theme_stylebox_override(variant,skin)
			button.add_theme_color_override("font_"+variant+"_color",Color(0.14,0.10,0.05))
	pause_button.grab_focus.call_deferred()
	_layout()
	_update_beat()
	camera.current = true

func suspended() -> bool:
	return paused or world.pause_owners.keys().any(func(owner): return owner != "rescue_assembly")

func _process(delta: float) -> void:
	if finished: return
	if not is_instance_valid(world) or not is_instance_valid(rescue): finish(); return
	if not armed and not Input.is_key_pressed(KEY_SPACE) and not Input.is_key_pressed(KEY_ENTER) and not Input.is_key_pressed(KEY_E) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		armed = true
		pause_button.grab_focus.call_deferred()
	pause_button.disabled = not armed
	skip_button.disabled = not armed
	var frozen := suspended()
	for actor in actors:
		actor.presentation.animation_player.speed_scale = 0.0 if frozen else animation_speeds[actor.captive_id]
	plate.visible = not world.pause_owners.keys().any(func(owner): return owner != "rescue_assembly")
	actions.visible = plate.visible
	pause_button.text = "继续" if paused else "暂停"
	_layout()
	if frozen: return
	elapsed += delta
	_update_beat()
	if elapsed >= DURATION: finish()

func _update_beat() -> void:
	var next := 0 if elapsed < 2.4 else 1 if elapsed < 4.8 else 2
	if next == beat: return
	beat = next
	for i in actors.size(): actors[i].assembly_performance(beat,i)
	var center := Vector3.ZERO
	for actor in actors: center += actor.global_position
	center /= actors.size()
	var offset := Vector3(-3.8,2.7,-6.3)
	if not world.dialogue_state.reduced_motion and beat == 1: offset = Vector3(-3.1,2.5,-6.4)
	camera.global_position = center + offset
	camera.look_at(center+Vector3.UP*1.0)
	caption.text = caption_at(elapsed,world.dialogue_state.veyne_defeated)

static func caption_at(seconds: float, veyne_defeated: bool) -> String:
	if seconds < 2.4: return "奥伦：四个人都到了。蓝灯会护住这里，谢谢你，艾洛。"
	if seconds < 4.8: return "村民：我们会留在安全点，互相照应。"
	return "奥伦：两场战斗虽已结束，召唤核心仍需关闭。" if veyne_defeated else "奥伦：维恩仍在左阶的祭坛。我们安全了，但你的路还没有走完。"

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var scale: float = world.dialogue_state.text_scale
	caption.custom_minimum_size.x = view.x*0.88-36
	caption.add_theme_font_size_override("font_size",int(21*scale))
	plate.custom_minimum_size.x = view.x*0.88
	plate.size = Vector2(view.x*0.88,0)
	plate.reset_size()
	plate.position = Vector2(view.x*0.06,view.y-plate.size.y-24)
	for button in [pause_button,skip_button]: button.add_theme_font_size_override("font_size",int(16*scale))
	actions.reset_size()
	actions.position = Vector2(24,20)

func _input(event: InputEvent) -> void:
	if finished or suspended() or not armed: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		finish()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not finished:
		paused = true
		for actor in actors:
			if is_instance_valid(actor): actor.presentation.animation_player.speed_scale = 0

func finish() -> void:
	if finished: return
	finished = true
	_release()
	completed.emit()
	queue_free()

func _release() -> void:
	if released: return
	released = true
	for visual in hidden_presentations:
		if is_instance_valid(visual): visual.visible = hidden_presentations[visual]
	for actor in actors:
		if not is_instance_valid(actor): continue
		actor.presentation.animation_player.speed_scale = animation_speeds[actor.captive_id]
		actor.process_mode = actor_modes[actor.captive_id]
		actor.end_assembly_performance()
	if is_instance_valid(camera):
		camera.current = false
		camera.queue_free()
	if is_instance_valid(previous_camera): previous_camera.current = true
	if is_instance_valid(world) and not world.is_queued_for_deletion():
		world._set_pause_owner("rescue_assembly",false)
		# Retained control latch requires fresh keys/buttons after every modal.
		world.player.set_controls_open(not world.pause_owners.is_empty())

func _exit_tree() -> void:
	_release()

func _mcp_state() -> Dictionary:
	return {"elapsed":elapsed,"beat":beat,"paused":suspended(),"finished":finished,"armed":armed,"caption":caption.text,"cast_count":actors.size(),"camera_current":is_instance_valid(camera) and camera.current}
