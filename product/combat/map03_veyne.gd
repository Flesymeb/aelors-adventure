extends Node3D
## Presentation/attempt owner. DialogueState alone owns durable Boss/key facts.
const GROUND = preload("res://world/map03_ground.gd")
const HOME := Vector2(-4,-12)
const RIFT_RADIUS := 0.65
var world: Node3D
var state: Node
var actor: CharacterBody3D
var device: Node3D
var reinforcements: Node3D
var grounded := false
var arena_samples := 0
var approach_samples := 0
var phase := "waiting"
var reveal_elapsed := 0.0
var reveal_starts := 0
var battle_starts := 0
var phase_starts := 0
var victory_commits := 0
var reveal_camera: Camera3D
var music: AudioStreamPlayer
var cue: AudioStreamPlayer
var effects: AudioStreamPlayer3D
var owns_score := false
var prior_exploration_paused := false
var victory_pending := false
var victory_time := 0.0
var skip_armed := false
var reveal_panel: PanelContainer
var reveal_caption: Label
var rifts: Array = []
var rift_timer := 4.5
var rift_waves := 0
var rift_contacts := 0
var paused_by_menu := false

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	process_mode = Node.PROCESS_MODE_PAUSABLE
	actor = preload("res://assets/bosses/veyne_actor.tscn").instantiate()
	actor.encounter = self
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(actor)
	device = preload("res://world/veyne_release_key.tscn").instantiate()
	add_child(device)
	device.configure(self)
	reinforcements = preload("res://combat/veyne_reinforcements.gd").new()
	reinforcements.name = "RiftReinforcements"
	add_child(reinforcements)
	reinforcements.configure(self)
	reveal_camera = Camera3D.new()
	reveal_camera.name = "RevealCamera"
	reveal_camera.fov = 58
	add_child(reveal_camera)
	music = AudioStreamPlayer.new()
	music.name = "VeyneMusic"
	music.bus = "Music"
	music.volume_db = -22
	var stream := preload("res://assets/audio/warden_battle.ogg").duplicate() as AudioStreamOggVorbis
	stream.loop = true
	music.stream = stream
	add_child(music)
	cue = AudioStreamPlayer.new()
	cue.bus = "Music"
	cue.volume_db = -14
	add_child(cue)
	effects = AudioStreamPlayer3D.new()
	effects.bus = "Effects"
	effects.volume_db = -10
	effects.max_distance = 15
	actor.add_child(effects)
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	reveal_panel = PanelContainer.new()
	reveal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_panel.theme = preload("res://dialogue_theme.tres")
	reveal_panel.add_theme_stylebox_override("panel",world.training.hud.frame())
	layer.add_child(reveal_panel)
	reveal_caption = Label.new()
	reveal_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reveal_caption.add_theme_color_override("font_color",Color(0.9,0.95,1))
	reveal_panel.add_child(reveal_caption)
	reveal_panel.hide()
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or world.is_queued_for_deletion(): return
		if not GROUND.place(world,actor,HOME) or not GROUND.place(world,device,Vector2(-5.0,-13)): continue
		arena_samples = 0
		for x in [-5.0,-4.0,-3.0]:
			for z in [-9.0,-11.0,-13.0]:
				if GROUND.route_clear(world,Vector2(x,z)): arena_samples += 1
		approach_samples = 0
		for z in [-5.0,-6.0,-6.5,-7.0,-7.5,-8.0,-8.7,-9.0]:
			if GROUND.route_clear(world,Vector2(-4,z)): approach_samples += 1
		if arena_samples != 9 or approach_samples != 8:
			world.entry_failed.emit("裂隙祭坛的原生石地缺少通行净空。")
			return
		actor.home = actor.global_position
		grounded = true
		restore_history()
		return
	world.entry_failed.emit("裂隙祭坛缺少原生地面支撑。")

func combat_allowed() -> bool:
	return grounded and phase == "battle" and not state.veyne_defeated and state.ln02_purified and state.health > 0 and not state.recovery_pending and state.lives > 0 and world.pause_owners.is_empty() and not world.training.player_locked()

func registry() -> Dictionary:
	if not combat_allowed(): return {}
	var result: Dictionary = {actor:actor.hitbox}
	result.merge(reinforcements.registry())
	return result

func can_save() -> bool: return phase not in ["reveal","phase_transition","battle"] and not victory_pending

func _process(delta: float) -> void:
	if not grounded: return
	var size := get_viewport().get_visible_rect().size
	reveal_caption.add_theme_font_size_override("font_size",int(18*minf(state.text_scale,1.5)))
	reveal_panel.size = Vector2(size.x*0.76,0)
	reveal_panel.position = Vector2(size.x*0.12,size.y-maxf(110,reveal_panel.get_combined_minimum_size().y)-24)
	reveal_panel.visible = phase in ["reveal","phase_transition"]
	var presentation := phase in ["reveal","phase_transition"]
	var paused: bool = world.pause_owners.keys().any(func(owner): return owner != "veyne_presentation")
	music.stream_paused = paused
	cue.stream_paused = paused
	effects.stream_paused = paused
	if presentation:
		if paused: actor.animator.pause(); return
		if not actor.animator.is_playing(): actor.animator.play()
		reveal_elapsed += delta
		if not Input.is_key_pressed(KEY_SPACE): skip_armed = true
		if reveal_elapsed >= (2.4 if phase == "phase_transition" else 3.0): finish_presentation()
	elif phase == "waiting" and state.ln02_purified and not state.veyne_defeated and not paused and state.health > 0 and not state.recovery_pending:
		if world.player.global_position.z < -8.6 and world.player.global_position.x < -2.5 and world.player.global_position.distance_to(actor.home) < 4.8 and world.warden_encounter.phase not in ["battle","reveal"]: begin_reveal()
	elif phase == "battle" and not paused:
		if state.health <= 0 or state.recovery_pending or world.player.global_position.z > -7.2: interrupt(); return
		if actor.pressure_phase:
			rift_timer -= delta
			if rift_timer <= 0: spawn_rifts(); rift_timer = 5.2
			update_rifts(delta)
	elif phase == "victory" and not paused:
		if victory_pending: settle_defeat()
		victory_time += delta
		if victory_time > 2.8: release_score()

func _input(event: InputEvent) -> void:
	if phase in ["reveal","phase_transition"] and skip_armed and world.pause_owners.size() == 1 and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		finish_presentation()
		get_viewport().set_input_as_handled()

func begin_reveal() -> void:
	if phase != "waiting" or state.veyne_defeated: return
	reveal_starts += 1
	_start_presentation("reveal","维恩 · 裂隙祭坛\n青色灯束横移躲避 · 金色近身挥击可振刀\n空格跳过 · Esc 暂停","Reveal")
	claim_score()
	play_cue("reveal")

func _start_presentation(kind: String, caption: String, clip: String) -> void:
	phase = kind
	reveal_elapsed = 0
	skip_armed = false
	world.training.interrupt("reveal")
	actor.interrupt_action()
	world.player.velocity = Vector3.ZERO
	world._set_pause_owner("veyne_presentation",true)
	actor.character.play(clip,1,true)
	reveal_caption.text = caption
	reveal_panel.show()
	# Fixed camera avoids motion even when Reduced Motion is enabled.
	reveal_camera.global_position = actor.home + Vector3(0.6,1.8,3.0)
	reveal_camera.look_at(actor.home+Vector3.UP*1.0)
	reveal_camera.current = true

func finish_presentation() -> void:
	if phase not in ["reveal","phase_transition"]: return
	var second := phase == "phase_transition"
	world.player.camera.current = true
	world._set_pause_owner("veyne_presentation",false)
	actor.character.play("Idle",1,true)
	phase = "battle"
	actor.engaged = true
	reveal_panel.hide()
	cue.stop()
	if second:
		reinforcements.summon()
		rift_timer = 2.0
		world.training.tell("维恩 · 裂隙苏醒：紫色危险区先预告后生效；两名近战增援已出现。",5)
	else: battle_starts += 1
	music.volume_db = -19 if second else -22
	music.pitch_scale = 1.04 if second else 1.0
	music.play()

func begin_second_phase() -> void:
	if phase != "battle" or phase_starts > 0 or state.veyne_defeated: return
	phase_starts += 1
	clear_rifts()
	_start_presentation("phase_transition","维恩 · 裂隙苏醒\n紫色区域将先预告后生效 · 保持移动\n空格跳过 · Esc 暂停","Cast")
	play_cue("phase")

func spawn_rifts() -> void:
	if not grounded or phase != "battle" or not actor.pressure_phase or state.health <= 0 or state.recovery_pending or not world.pause_owners.is_empty(): return
	clear_rifts()
	rift_waves += 1
	# Bounded stationary zones leave most of the native platform safe.
	var player_xz := Vector2(world.player.global_position.x,world.player.global_position.z)
	var spots := [Vector2(clampf(player_xz.x,-5.0,-3.0),clampf(player_xz.y,-13,-9)),Vector2(-5.0 if player_xz.x > -4 else -3.0,-12.6)]
	for xz in spots:
		var support: Dictionary = GROUND.support(world,xz,[actor.get_rid(),world.player.get_rid()])
		if support.is_empty(): continue
		var mesh: MeshInstance3D = preload("res://assets/bosses/veyne_effects.tscn").instantiate()
		mesh.material_override = mesh.material_override.duplicate()
		mesh.material_override.set_shader_parameter("radial",1.0)
		mesh.material_override.set_shader_parameter("warning_color",Color(0.8,0.25,1,0.9))
		mesh.scale = Vector3(RIFT_RADIUS*2,RIFT_RADIUS*2,1)
		add_child(mesh)
		mesh.global_position = support.position+Vector3.UP*0.04
		var source := SnaielDamageSource.new()
		source.entity = actor
		source.instance = rift_waves
		source.damage_attributes.health = 12
		for key in ["unparryable","unblockable","ranged_contact"]: source.set_meta(key,true)
		source.set_meta("attack_origin",support.position)
		source.set_meta("attack_direction",Vector3.FORWARD)
		add_child(source)
		rifts.append({"mesh":mesh,"source":source,"elapsed":0.0,"center":support.position})
	play_effect("rift_warning")

func update_rifts(delta: float) -> void:
	for rift in rifts:
		rift.elapsed += delta
		rift.mesh.material_override.set_shader_parameter("progress",minf(1,rift.elapsed/1.2))
		rift.source.can_damage = rift.elapsed >= 1.2 and rift.elapsed <= 1.8
		if rift.source.can_damage:
			var point: Vector3 = world.player.global_position
			var planar := Vector2(point.x-rift.center.x,point.z-rift.center.z)
			if planar.length() <= RIFT_RADIUS and absf(point.y-rift.center.y) < 1.4:
				var query := PhysicsRayQueryParameters3D.create(rift.center+Vector3.UP,point+Vector3.UP,1,[actor.get_rid(),world.player.get_rid()])
				if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
					var result: Dictionary = world.training.player_hitbox.contact(rift.source,point+Vector3.UP)
					if result.get("accepted",false): rift_contacts += 1
		if rift.elapsed > 1.8: rift.mesh.hide()
	if not rifts.is_empty() and rifts[0].elapsed > 2.0: clear_rifts()

func clear_rifts() -> void:
	for rift in rifts:
		rift.source.can_damage = false
		rift.mesh.hide()
		rift.mesh.queue_free()
		rift.source.queue_free()
	rifts.clear()

func set_menu_paused(paused: bool) -> void:
	music.stream_paused = paused
	cue.stream_paused = paused
	effects.stream_paused = paused
	if paused and not paused_by_menu:
		# Close obsolete contact/windows immediately; resume from ordinary AI.
		actor.interrupt_action()
		clear_rifts()
		for unit in reinforcements.units:
			if is_instance_valid(unit): unit.interrupt_action()
		if phase == "battle": actor.phase = "idle"; actor.character.play("Idle",1,true)
	paused_by_menu = paused

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
	cue.pitch_scale = 0.6 if kind == "reveal" else (0.7 if kind == "phase" else 1.0)
	cue.play()

func play_effect(kind: String) -> void:
	effects.stream = preload("res://assets/training/impact.ogg") if kind in ["beam","rift_warning"] else preload("res://assets/training/soft_impact.ogg")
	effects.pitch_scale = 0.65 if kind == "beam" else (1.2 if kind == "rift_warning" else 0.9)
	effects.play()

func settle_defeat() -> void:
	if state.veyne_defeated: return
	phase = "victory"
	actor.interrupt_action()
	actor.engaged = false
	clear_rifts()
	reinforcements.clear_wave()
	victory_pending = true
	var snapshot: Dictionary = state.adventure_snapshot()
	if not state.defeat_veyne(): return
	if not world.training.commit(): state.restore_adventure(snapshot); return
	victory_pending = false
	victory_commits += 1
	victory_time = 0
	actor.collision_layer = 0
	music.stop()
	play_cue("victory")
	world.training.tell("维恩已败 · 法术瓦解。检查祭坛取得解除钥印；四位村民与召唤核心仍待处理。",7)
	state.progression_changed.emit()

func interrupt() -> void:
	if not grounded: return
	actor.interrupt_action()
	clear_rifts()
	reinforcements.clear_wave(true)
	world.player.camera.current = true
	world._set_pause_owner("veyne_presentation",false)
	release_score()
	reveal_panel.hide()
	phase = "victory" if state.veyne_defeated else "waiting"
	victory_pending = false
	phase_starts = 0
	rift_timer = 4.5
	music.pitch_scale = 1.0
	actor.reset_encounter()

func restore_history() -> void:
	if grounded: interrupt()

func _exit_tree() -> void:
	if is_instance_valid(music): release_score()

func _mcp_state() -> Dictionary:
	return {"grounded":grounded,"phase":phase,"arena_samples":arena_samples,"approach_samples":approach_samples,"reveal_elapsed":reveal_elapsed,"reveal_starts":reveal_starts,"battle_starts":battle_starts,"phase_starts":phase_starts,"victory_commits":victory_commits,"victory_pending":victory_pending,"rift_waves":rift_waves,"rift_contacts":rift_contacts,"rifts":rifts.size(),"wave_count":reinforcements.wave_count if reinforcements else 0,"reinforcements":reinforcements.units.size() if reinforcements else 0,"music_playing":music.playing if music else false,"normal_camera":world.player.camera.current if world else false,"combat_allowed":combat_allowed() if grounded else false}
