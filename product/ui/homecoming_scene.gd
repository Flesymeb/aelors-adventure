extends CanvasLayer
## Presentation of a committed village arrival; no reward or save authority.
signal completed
const DURATION := 12.0
const CAST = preload("res://data/rescue_cast.json")
const SCENES = [preload("res://actors/oren_captive.tscn"),preload("res://actors/captive_villager_a.tscn"),preload("res://actors/captive_villager_b.tscn"),preload("res://actors/captive_villager_c.tscn")]
var world: Node3D
var elapsed := 0.0
var paused := false
var armed := false
var finished := false
var released := false
var camera: Camera3D
var previous_camera: Camera3D
var panel: PanelContainer
var caption: Label
var actions: HBoxContainer
var pause_button: Button
var skip_button: Button
var actor_modes: Dictionary = {}
var hud_visibility: Dictionary = {}
var video: VideoStreamPlayer
var video_clock := 0.0
var stall := 0.0
var narration: AudioStreamPlayer
var narration_button: Button
var narration_enabled := true
var music: AudioStreamPlayer
var music_gain := 0.0

class Residents extends Node3D:
	var world: Node3D
	var actors: Array = []
	var grounded := false
	func configure(owner_world: Node3D) -> void:
		world = owner_world
		process_mode = Node.PROCESS_MODE_PAUSABLE
		build.call_deferred()
	func build() -> void:
		for i in 4:
			var actor: Node3D = load("res://ui/homecoming_scene.gd").SCENES[i].instantiate()
			actor.name = world.dialogue_state.CAPTIVE_IDS[i].capitalize()
			add_child(actor)
			actors.append(actor)
		for attempt in 120:
			await get_tree().physics_frame
			if not is_instance_valid(world): return
			var valid := true
			var center: Vector2 = world.GROUND.ISHA
			var positions := [Vector2(-1.5,0),Vector2(-3,-1.5),Vector2(-4,0.5),Vector2(-2.5,2.5)]
			for i in 4:
				valid = world.GROUND.place(world,actors[i],center+positions[i]) and valid
				actors[i].restore(true,true)
				actors[i].look_at(Vector3(world.isha.global_position.x,actors[i].global_position.y,world.isha.global_position.z))
			if valid: grounded = true; return
		world.entry_failed.emit("村庄团聚地点缺少安全支撑，请重试返回。")
	func selected() -> Node3D:
		if not grounded or not world.travel_safe(): return null
		for actor in actors:
			if world.player.global_position.distance_to(actor.global_position) > 2.3: continue
			var ray := PhysicsRayQueryParameters3D.create(world.player.global_position+Vector3.UP,actor.global_position+Vector3.UP,1,[world.player.get_rid()])
			var hit := get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty() or hit.collider == actor: return actor
		return null
	func interaction_prompt() -> String:
		var actor := selected()
		return "" if actor == null else "[E] 与"+actor.CAST.data[actor.captive_id].name+"交谈"
	func interact() -> bool:
		var actor := selected()
		if actor == null: return false
		var answers := {"oren":"伊莎，我回来了。谢谢你，艾洛。你的选择让大家都活着走出了墓殿。", "villager_a":"师父的铁钳还在等我修。村里的炉火又亮起来了。", "villager_b":"河岸的田没有荒，我们又能一起收获了。", "villager_c":"归路的灯还亮着。我会继续守好这座桥。"}
		world.training.tell(actor.CAST.data[actor.captive_id].name+"："+answers[actor.captive_id],8)
		return true

static func populate_village(owner_world: Node3D) -> Node3D:
	var residents := Residents.new()
	residents.name = "ReturnedVillagers"
	owner_world.add_child(residents)
	residents.configure(owner_world)
	return residents

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	previous_camera = get_viewport().get_camera_3d()
	camera = Camera3D.new()
	world.add_child(camera)
	camera.fov = 48
	world._set_pause_owner("homecoming",true)
	for layer_node in world.find_children("*","CanvasLayer",true,false):
		if layer_node == self: continue
		for item in layer_node.get_children():
			if item is CanvasItem: hud_visibility[item] = item.visible; item.hide()
	for actor in world.homecoming_residents.actors:
		actor_modes[actor] = actor.process_mode
		actor.process_mode = Node.PROCESS_MODE_ALWAYS
		actor.begin_assembly_performance()
	panel = PanelContainer.new()
	panel.theme = preload("res://dialogue_theme.tres")
	var frame := StyleBoxTexture.new()
	frame.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-013.png")
	frame.modulate_color = Color(0.9,0.82,0.64)
	frame.set_content_margin_all(18)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: frame.set_texture_margin(side,10)
	panel.add_theme_stylebox_override("panel",frame)
	add_child(panel)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color",Color(0.14,0.10,0.05))
	panel.add_child(caption)
	actions = HBoxContainer.new()
	actions.theme = panel.theme
	add_child(actions)
	pause_button = Button.new()
	pause_button.text = "暂停 [Esc]"
	pause_button.pressed.connect(func(): paused = not paused)
	actions.add_child(pause_button)
	skip_button = Button.new()
	skip_button.text = "继续村庄生活 [空格]"
	skip_button.pressed.connect(finish)
	actions.add_child(skip_button)
	narration_button = Button.new()
	narration_button.text = "英语旁白：开"
	narration_button.pressed.connect(func():
		narration_enabled = not narration_enabled
		narration_button.text = "英语旁白：开" if narration_enabled else "英语旁白：关"
	)
	actions.add_child(narration_button)
	for button in [pause_button,skip_button,narration_button]:
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		for variant in ["normal","hover","pressed","focus","disabled"]: button.add_theme_stylebox_override(variant,frame)
	video = VideoStreamPlayer.new()
	video.expand = true
	video.volume = 0
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(video)
	move_child(video,0)
	if not world.dialogue_state.reduced_motion and ResourceLoader.exists("res://assets/cinematics/ending/homecoming.ogv"):
		video.stream = load("res://assets/cinematics/ending/homecoming.ogv")
		video.play()
	video.hide()
	narration = AudioStreamPlayer.new()
	narration.bus = "Effects"
	narration.stream = preload("res://assets/cinematics/story_narration.wav")
	add_child(narration)
	if is_instance_valid(world.menu_audio) and is_instance_valid(world.menu_audio.music):
		music = world.menu_audio.music
		music_gain = music.volume_db
	narration.play()
	camera.current = true
	_layout()
	_frame()

func suspended() -> bool:
	return paused or world.pause_owners.keys().any(func(owner): return owner != "homecoming" and owner != "entry")

func _process(delta: float) -> void:
	if finished: return
	if not armed and not world.entry_router._confirmation_held(): armed = true
	pause_button.disabled = not armed
	skip_button.disabled = not armed or suspended()
	var frozen := suspended()
	for actor in actor_modes:
		actor.presentation.animation_player.speed_scale = 0.0 if frozen else 1.0
	video.paused = frozen
	narration.stream_paused = frozen
	narration.volume_db = 0.0 if narration_enabled else -80.0
	if is_instance_valid(music): music.volume_db = music_gain - (8.0 if narration.playing and narration_enabled and not frozen else 0.0)
	_layout()
	if frozen: return
	elapsed += delta
	if video.is_playing():
		var next := video.stream_position
		stall = stall + delta if next <= video_clock else 0.0
		video_clock = next
		if next > 0.03: video.show()
		if stall > 1.0: video.stop(); video.hide()
	_frame()
	if elapsed >= DURATION: finish()

func _frame() -> void:
	var center: Vector3 = world.homecoming_residents.actors[0].global_position.lerp(world.isha.global_position,0.5)
	var offset := Vector3(-5,2.7,5.8)
	if elapsed >= 4.0 and elapsed < 8.0: offset = Vector3(-4,2.4,5.4)
	if elapsed >= 8.0: offset = Vector3(-5.5,3.2,7.0)
	camera.global_position = center+offset
	camera.look_at(center+Vector3.UP)
	caption.text = "旁白：河谷的灯，再一次照亮归路。" if elapsed < 3.5 else "旁白：四位村民一同归来，伊莎拥抱了父亲。" if elapsed < 7.5 else "旁白：桥的另一边，新的清晨正等待着他们。"

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	caption.custom_minimum_size.x = view.x*0.88-36
	caption.add_theme_font_size_override("font_size",int(23*world.dialogue_state.text_scale))
	panel.custom_minimum_size.x = view.x*0.88
	panel.size = Vector2(view.x*0.88,0)
	panel.reset_size()
	panel.position = Vector2(view.x*0.06,view.y-panel.size.y-24)
	actions.position = Vector2(24,20)
	for button in [pause_button,skip_button,narration_button]: button.add_theme_font_size_override("font_size",int(17*world.dialogue_state.text_scale))
	video.size = view

func _input(event: InputEvent) -> void:
	if not armed or finished: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: paused = not paused; get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and not suspended(): finish(); get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: paused = true

func finish() -> void:
	if finished or not armed or suspended(): return
	finished = true
	_release()
	completed.emit()
	queue_free()

func _release() -> void:
	if released: return
	released = true
	if is_instance_valid(video): video.stop()
	if is_instance_valid(narration): narration.stop()
	if is_instance_valid(music): music.volume_db = music_gain
	for actor in actor_modes:
		if is_instance_valid(actor):
			actor.process_mode = actor_modes[actor]
			actor.presentation.animation_player.speed_scale = 1
			actor.end_assembly_performance()
	for item in hud_visibility:
		if is_instance_valid(item): item.visible = hud_visibility[item]
	if is_instance_valid(camera): camera.current = false; camera.queue_free()
	if is_instance_valid(previous_camera): previous_camera.current = true
	if is_instance_valid(world) and not world.is_queued_for_deletion():
		world._set_pause_owner("homecoming",false)
		world.player.set_controls_open(not world.pause_owners.is_empty())

func _exit_tree() -> void: _release()

func _mcp_state() -> Dictionary:
	return {"elapsed":elapsed,"paused":suspended(),"finished":finished,"caption":caption.text,"video_position":video_clock,"cast_count":actor_modes.size(),"narration_playing":narration.playing,"narration_paused":narration.stream_paused,"narration_position":narration.get_playback_position(),"narration_enabled":narration_enabled}
