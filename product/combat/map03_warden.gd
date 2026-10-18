extends Node3D
## Encounter/presentation owner. DialogueState alone commits durable outcomes.
const GROUND = preload("res://world/map03_ground.gd")
const HOME := Vector2(3.8,-12)
var world: Node3D
var state: Node
var actor: CharacterBody3D
var device: Node3D
var grounded := false
var arena_samples := 0
var phase := "waiting"
var reveal_elapsed := 0.0
var reveal_starts := 0
var battle_starts := 0
var victory_commits := 0
var reveal_camera: Camera3D
var music: AudioStreamPlayer
var cue: AudioStreamPlayer
var effects: AudioStreamPlayer3D
var prior_exploration_paused := false
var owns_score := false
var victory_pending := false
var victory_time := 0.0
var skip_armed := false
var pressure_cues := 0
var pressure_music_mix := 0.0
var reveal_panel: PanelContainer
var reveal_caption: Label
var defeat_scene: CanvasLayer
var presentation_box := AABB()
var reveal_feedback_was_visible := false
var reveal_text_scale := -1.0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	# This owner handles modal recovery; the actor and the ordinary world stay
	# pausable. Only its designated native presentation clip is sampled by hand.
	process_mode = Node.PROCESS_MODE_ALWAYS
	actor = preload("res://assets/bosses/warden_actor.tscn").instantiate()
	actor.encounter = self
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(actor)
	device = preload("res://world/warden_release_device.tscn").instantiate()
	add_child(device)
	device.configure(self)
	reveal_camera = Camera3D.new()
	reveal_camera.name = "RevealCamera"
	reveal_camera.fov = 55
	add_child(reveal_camera)
	music = AudioStreamPlayer.new()
	music.name = "WardenMusic"
	music.bus = "Music"
	music.volume_db = -22
	var stream := preload("res://assets/audio/warden_battle.ogg").duplicate() as AudioStreamOggVorbis
	stream.loop = true
	music.stream = stream
	add_child(music)
	cue = AudioStreamPlayer.new()
	cue.name = "WardenCue"
	cue.bus = "Music"
	cue.volume_db = -12
	add_child(cue)
	effects = AudioStreamPlayer3D.new()
	effects.name = "WardenEffects"
	effects.bus = "Effects"
	effects.volume_db = -10
	effects.max_distance = 15
	actor.add_child(effects)
	var overlay := CanvasLayer.new()
	overlay.name = "WardenRevealCaption"
	overlay.layer = 6
	add_child(overlay)
	reveal_panel = PanelContainer.new()
	reveal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_panel.theme = preload("res://dialogue_theme.tres")
	reveal_panel.add_theme_stylebox_override("panel",world.training.hud.frame())
	overlay.add_child(reveal_panel)
	reveal_caption = Label.new()
	reveal_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reveal_caption.add_theme_color_override("font_color",Color(1,0.92,0.72))
	reveal_caption.text = "锁印看守
正面重击可振刀 · 紫色震荡须离开或闪避
空格跳过 · Esc 暂停"
	reveal_panel.add_child(reveal_caption)
	reveal_panel.hide()
	defeat_scene = preload("res://ui/warden_defeat_scene.gd").new()
	defeat_scene.name = "WardenAftermath"
	defeat_scene.encounter = self
	add_child(defeat_scene)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or world.is_queued_for_deletion(): return
		if not GROUND.place(world,actor,HOME) or not GROUND.place(world,device,Vector2(5.1,-14)): continue
		arena_samples = 0
		for x in [2.0,3.8,5.0]:
			for z in [-9.0,-11.5,-13.0]:
				if GROUND.route_clear(world,Vector2(x,z)): arena_samples += 1
		if arena_samples != 9:
			world.entry_failed.emit("看守院的原生石地缺少闪避净空。")
			return
		actor.home = actor.global_position
		grounded = true
		restore_history()
		return
	world.entry_failed.emit("看守院缺少原生地面支撑。")

func combat_allowed() -> bool:
	return grounded and phase == "battle" and not state.warden_defeated and state.ln02_purified and state.health > 0 and not state.recovery_pending and state.lives > 0 and world.pause_owners.is_empty() and not world.training.player_locked()

func registry() -> Dictionary:
	return {actor:actor.hitbox} if grounded and combat_allowed() else {}

func can_save() -> bool: return phase not in ["reveal","battle"] and not victory_pending and not (is_instance_valid(defeat_scene) and defeat_scene.active)

func _process(delta: float) -> void:
	if not grounded: return
	if defeat_scene.active: return
	var viewport := get_viewport().get_visible_rect().size
	reveal_caption.add_theme_font_size_override("font_size",int(18*state.text_scale))
	reveal_panel.size = Vector2(viewport.x*0.7, maxf(100,reveal_caption.get_minimum_size().y+24))
	reveal_panel.position = Vector2(viewport.x*0.15,viewport.y-reveal_panel.size.y-26)
	reveal_panel.visible = phase == "reveal"
	var paused: bool = not world.pause_owners.is_empty()
	var reveal_paused: bool = phase == "reveal" and (world.pause_owners.size() != 1 or not world.pause_owners.has("warden_reveal"))
	if phase == "reveal":
		reveal_panel.visible = not reveal_paused
		if not is_equal_approx(reveal_text_scale,state.text_scale):
			reveal_text_scale = state.text_scale
			frame_presentation()
	music.stream_paused = paused
	if phase == "battle" and not paused:
		pressure_music_mix = move_toward(pressure_music_mix,1.0 if actor.pressure_phase else 0.0,delta)
		music.volume_db = lerpf(-22,-18,pressure_music_mix)
		music.pitch_scale = lerpf(1.0,1.06,pressure_music_mix)
	cue.stream_paused = reveal_paused if phase == "reveal" else paused
	effects.stream_paused = paused
	if phase == "reveal":
		if reveal_paused or get_tree().paused: return
		actor.character.advance_presentation(delta*actor.animator.get_animation("warden/Reveal").length/3.2)
		reveal_elapsed += delta
		if not Input.is_key_pressed(KEY_SPACE): skip_armed = true
		if reveal_elapsed >= 3.2: finish_reveal()
	elif phase == "waiting" and state.ln02_purified and not state.warden_defeated and not paused and state.health > 0 and not state.recovery_pending and (world.get("veyne_encounter") == null or world.veyne_encounter.phase not in ["reveal","battle","phase_transition"]):
		if world.player.global_position.z < -8.6 and world.player.global_position.x > 1.2 and world.player.global_position.distance_to(actor.home) < 4.6: begin_reveal()
	elif phase == "battle" and not paused:
		if state.health <= 0 or state.recovery_pending or world.player.global_position.z > -7.2: interrupt()
	elif phase == "victory" and not paused:
		if victory_pending: settle_defeat()
		victory_time += delta
		if victory_time > 3: release_score()

func _input(event: InputEvent) -> void:
	if phase == "reveal" and skip_armed and world.pause_owners.size() == 1 and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		finish_reveal()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT] and phase == "reveal" and is_instance_valid(world) and not world.pause_owners.has("controls"):
		world._open_controls()

func begin_reveal() -> void:
	if phase != "waiting" or state.warden_defeated: return
	phase = "reveal"
	reveal_panel.show()
	reveal_starts += 1
	reveal_elapsed = 0
	skip_armed = false
	world.training.interrupt("reveal")
	reveal_feedback_was_visible = world.training.feedback.visible
	world.training.feedback.hide()
	world.player.velocity = Vector3.ZERO
	world.player.release_encounter_camera()
	world.player.controls_open = true
	world._set_pause_owner("warden_reveal",true)
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	actor.character.begin_presentation("Reveal")
	presentation_box = actor.character.presentation_bounds(actor.model)
	frame_presentation()
	reveal_camera.current = true
	claim_score()
	play_cue("reveal")
	world.training.tell("锁印看守 · 正面重击可振刀；紫色震荡离开范围或闪避，不能振刀。空格跳过。",6)

func finish_reveal() -> void:
	if phase != "reveal": return
	actor.character.end_presentation(false)
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.player.camera.current = true
	world._set_pause_owner("warden_reveal",false)
	world.player.controls_open = not world.pause_owners.is_empty()
	world.player.suppress_held_combat_actions()
	world.training.feedback.visible = reveal_feedback_was_visible
	phase = "battle"
	reveal_panel.hide()
	battle_starts += 1
	actor.engaged = true
	cue.stop()
	music.play()

func enter_pressure_phase() -> void:
	if phase != "battle" or pressure_cues != 0: return
	pressure_cues += 1
	play_cue("pressure")
	world.training.tell("锁印看守 · 石核躁动：重击后接震荡，留意每次收招。",4)

func claim_score() -> void:
	if owns_score: return
	owns_score = true
	prior_exploration_paused = world.menu_audio.music.stream_paused
	world.menu_audio.music.stream_paused = true

func release_score() -> void:
	music.stop(); cue.stop(); effects.stop()
	if owns_score and is_instance_valid(world.menu_audio) and is_instance_valid(world.menu_audio.music): world.menu_audio.music.stream_paused = prior_exploration_paused
	owns_score = false

func play_cue(kind: String) -> void:
	cue.stream = preload("res://assets/dialogue/sounds/Audio/confirmation_001.ogg") if kind == "victory" else preload("res://assets/training/impact.ogg")
	cue.pitch_scale = 0.55 if kind == "reveal" else (0.72 if kind == "pressure" else 1.0)
	cue.play()

func play_effect(kind: String) -> void:
	effects.stream = preload("res://assets/training/impact.ogg") if kind == "shockwave" else preload("res://assets/training/soft_impact.ogg")
	effects.pitch_scale = 0.55 if kind == "shockwave" else 0.8
	effects.play()

func settle_defeat() -> void:
	if state.warden_defeated or actor.health > 0: return
	phase = "victory"
	# The retained on_death has already cancelled contact and selected Death.
	# Interrupting again would replace the collapse with the Idle state.
	world.player.release_encounter_camera()
	actor.engaged = false
	victory_pending = true
	var snapshot: Dictionary = state.adventure_snapshot()
	if not state.defeat_warden(): return
	if not world.training.commit():
		state.restore_adventure(snapshot)
		return
	victory_pending = false
	victory_commits += 1
	victory_time = 0
	actor.collision_layer = 0
	music.stop()
	play_cue("victory")
	defeat_scene.begin()
	world.training.tell("看守已败 · 检查院内锁印装置，取得应急解除器。四位村民尚未释放。",7)
	state.progression_changed.emit()

func interrupt() -> void:
	if not grounded: return
	if is_instance_valid(defeat_scene): defeat_scene.shutdown()
	actor.character.end_presentation(false)
	actor.interrupt_action()
	if phase == "reveal": world.training.feedback.visible = reveal_feedback_was_visible
	world.player.camera.current = true
	world._set_pause_owner("warden_reveal",false)
	world.player.controls_open = not world.pause_owners.is_empty()
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	release_score()
	reveal_panel.hide()
	phase = "victory" if state.warden_defeated else "waiting"
	victory_pending = false
	pressure_cues = 0
	pressure_music_mix = 0.0
	music.volume_db = -22
	music.pitch_scale = 1.0
	actor.reset_encounter()

func restore_history() -> void:
	if grounded: interrupt()

func _exit_tree() -> void:
	if is_instance_valid(defeat_scene): defeat_scene.shutdown()
	if is_instance_valid(actor) and is_instance_valid(actor.character): actor.character.end_presentation(false)
	if is_instance_valid(music): release_score()
	if is_instance_valid(world) and is_instance_valid(world.player):
		world.player.camera.current = true
		world._set_pause_owner("warden_reveal",false)
		world._set_pause_owner("warden_aftermath",false)

func frame_presentation() -> void:
	# Fit the actual posed native stone pieces, then retain the nearby device
	# in the aftermath. Do not tune to the capsule or an unrelated Ranger box.
	var box := presentation_box
	if defeat_scene.active:
		box = box.expand(device.global_position).expand(device.global_position+Vector3.UP*1.4)
	var center := box.get_center()
	var radius := maxf(box.size.length()*0.5,1.0)
	var view := get_viewport().get_visible_rect().size
	var half_vertical := deg_to_rad(reveal_camera.fov)*0.5
	var half_horizontal := atan(tan(half_vertical)*view.x/maxf(view.y,1.0))
	var caption_scale := clampf(state.text_scale-1.0,0.0,1.0)
	var distance := radius/sin(minf(half_vertical,half_horizontal)*(0.77-0.1*caption_scale))+0.4
	var best := center+Vector3(0,0.6,1).normalized()*distance
	var best_score := -INF
	var exclusions: Array[RID] = [actor.get_rid(),world.player.get_rid()]
	var space := get_world_3d().direct_space_state
	for direction in [Vector3(0,0.6,1),Vector3(-1,0.6,1),Vector3(1,0.6,1),Vector3(0,1,0)]:
		var candidate: Vector3 = center+direction.normalized()*distance
		var clear := 0
		for target_point in [center,actor.global_position+Vector3.UP,device.global_position+Vector3.UP]:
			if space.intersect_ray(PhysicsRayQueryParameters3D.create(candidate,target_point,1,exclusions)).is_empty(): clear += 1
		var score: float = clear*10.0-direction.normalized().y
		if score > best_score: best_score = score; best = candidate
	reveal_camera.global_position = best
	reveal_camera.look_at(center,Vector3.FORWARD if absf((best-center).normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP)
	if caption_scale > 0: reveal_camera.look_at(center-reveal_camera.global_basis.y*radius*0.32*caption_scale)

func _mcp_state() -> Dictionary:
	return {"pressure_cues":pressure_cues,"pressure_music_mix":pressure_music_mix,"grounded":grounded,"arena_samples":arena_samples,"phase":phase,"reveal_elapsed":reveal_elapsed,"reveal_starts":reveal_starts,"battle_starts":battle_starts,"victory_commits":victory_commits,"victory_pending":victory_pending,"defeated":state.warden_defeated if state else null,"lock_released":state.warden_lock_released if state else null,"emergency_tool":state.emergency_release_tool if state else null,"music_playing":music.playing if music else null,"music_paused":music.stream_paused if music else null,"score_owned":owns_score,"can_save":can_save()}
