extends Node3D
## Presentation/attempt owner. DialogueState alone owns durable Boss/key facts.
const GROUND = preload("res://world/map03_ground.gd")
const ARENA = preload("res://world/veyne_arena.gd")
const HOME := ARENA.HOME
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
var presentation_box := AABB()
var flight_skin_boxes := {}
var reveal_video: CanvasLayer
var defeat_scene: CanvasLayer

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	process_mode = Node.PROCESS_MODE_PAUSABLE
	actor = preload("res://assets/bosses/veyne_actor.tscn").instantiate()
	actor.encounter = self
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(actor)
	cache_flight_skin_bounds()
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
	reveal_camera.keep_aspect = Camera3D.KEEP_HEIGHT
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
	reveal_video = preload("res://ui/boss_reveal_video.gd").new()
	reveal_video.name = "BossRevealVideo"
	add_child(reveal_video)
	reveal_video.completed.connect(finish_presentation)
	reveal_video.fallback_requested.connect(_video_fallback)
	defeat_scene = preload("res://ui/veyne_defeat_scene.gd").new()
	defeat_scene.name = "VeyneDefeatScene"
	defeat_scene.encounter = self
	add_child(defeat_scene)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or world.is_queued_for_deletion(): return
		if not GROUND.place(world,actor,HOME) or not GROUND.place(world,device,ARENA.KEY): continue
		arena_samples = 0
		for x in [-10.0,-4.0,2.0]:
			for z in [-20.0,-25.0,-30.0]:
				if GROUND.route_clear(world,Vector2(x,z)): arena_samples += 1
		approach_samples = 0
		for z in [-5.0,-6.0,-8.7,-9.0,-10.0,-12.0,-14.0,-16.0,-18.0]:
			if GROUND.route_clear(world,Vector2(-4,z)): approach_samples += 1
		if arena_samples != 9 or approach_samples != 9:
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

func can_save() -> bool: return phase not in ["reveal","phase_transition","battle"] and not victory_pending and not defeat_scene.active

func _process(delta: float) -> void:
	if not grounded: return
	var size := get_viewport().get_visible_rect().size
	reveal_caption.add_theme_font_size_override("font_size",int(18*state.text_scale))
	reveal_panel.size = Vector2(size.x*0.76,0)
	reveal_panel.position = Vector2(size.x*0.12,size.y-maxf(110,reveal_panel.get_combined_minimum_size().y)-24)
	reveal_panel.visible = phase in ["reveal","phase_transition"] and not reveal_video.active
	var presentation := phase in ["reveal","phase_transition"]
	var paused: bool = world.pause_owners.keys().any(func(owner): return owner != "veyne_presentation")
	music.stream_paused = paused
	cue.stream_paused = paused
	effects.stream_paused = paused
	if defeat_scene.active: return
	if presentation:
		if paused: actor.animator.pause(); return
		frame_presentation()
		if not actor.animator.is_playing(): actor.animator.play()
		reveal_elapsed += delta
		if not Input.is_key_pressed(KEY_SPACE): skip_armed = true
		if not reveal_video.active and reveal_elapsed >= (2.4 if phase == "phase_transition" else 3.0): finish_presentation()
	elif phase == "waiting" and state.ln02_purified and not state.veyne_defeated and not paused and state.health > 0 and not state.recovery_pending:
		if ARENA.contains(Vector2(world.player.global_position.x,world.player.global_position.z)) and world.player.global_position.distance_to(actor.home) < 12.0 and world.warden_encounter.phase not in ["battle","reveal"]: begin_reveal()
	elif phase == "battle" and not paused:
		if state.health <= 0 or state.recovery_pending or world.player.global_position.z > -10.5: interrupt(); return
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_node_ready() and phase in ["reveal","phase_transition"] and is_instance_valid(world) and not world.pause_owners.has("controls"):
		world._open_controls()

func begin_reveal() -> void:
	if phase != "waiting" or state.veyne_defeated: return
	reveal_starts += 1
	_start_presentation("reveal","维恩 · 裂隙祭坛\n火息横移 · 冲锋侧闪 · 俯冲离开落点
青色灯束不可振刀 · 金色爪击可振刀\n空格跳过 · Esc 暂停","Reveal")
	claim_score()
	play_cue("reveal")
	if reveal_video.begin(state): reveal_panel.hide()

func _video_fallback() -> void:
	# Decoder failure resumes the original live shot rather than starting combat.
	if phase != "reveal": return
	reveal_elapsed = 0.0
	actor.character.play("Reveal",1,true)
	reveal_panel.show()

func _start_presentation(kind: String, caption: String, clip: String) -> void:
	phase = kind
	reveal_elapsed = 0
	skip_armed = false
	world.training.interrupt("reveal")
	actor.interrupt_action()
	world.player.release_encounter_camera()
	world.player.velocity = Vector3.ZERO
	world._set_pause_owner("veyne_presentation",true)
	presentation_box = actor.character.posed_bounds(actor.model)
	actor.character.play(clip,1,true)
	reveal_caption.text = caption
	reveal_panel.show()
	frame_presentation()
	reveal_camera.current = true

func presentation_points() -> Array[Vector3]:
	# Sample the live rig as well as mesh extents. Home is a retry anchor only.
	var points: Array[Vector3] = []
	for corner in 8: points.append(actor.model.global_transform*presentation_box.get_endpoint(corner))
	if actor.character.skeleton:
		var skeleton: Skeleton3D = actor.character.skeleton
		for bone in skeleton.get_bone_count():
			points.append(skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin)
	points.append(world.player.global_position)
	points.append(world.player.global_position+Vector3.UP*1.8)
	if is_instance_valid(defeat_scene) and defeat_scene.active:
		points.append(device.global_position)
		points.append(device.global_position+Vector3.UP)
	return points

func cache_flight_skin_bounds() -> void:
	# A weighted skinned vertex is inside the union of its bone-transformed
	# influence boxes. Cache bind-space extents once; pose only their corners
	# each tick rather than CPU-skinning every vertex during the attack.
	var skeleton: Skeleton3D = actor.character.skeleton
	for mesh in actor.model.find_children("*","MeshInstance3D",true,false):
		if not mesh.skin: continue
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences: int = weights.size()/vertices.size()
			for vertex in vertices.size():
				for influence in influences:
					var index := vertex*influences+influence
					if weights[index] <= 0: continue
					var bind: int = bones[index]
					var bone: int = mesh.skin.get_bind_bone(bind)
					if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(bind))
					if bone < 0: continue
					var point: Vector3 = mesh.skin.get_bind_pose(bind)*vertices[vertex]
					flight_skin_boxes[bone] = flight_skin_boxes[bone].expand(point) if flight_skin_boxes.has(bone) else AABB(point,Vector3.ZERO)

func flight_camera_subjects() -> Array[Vector3]:
	# Supply subjects, never a Camera3D transform. The player remains the sole
	# owner of orientation, projection and the native collision-backed arm.
	var points: Array[Vector3] = []
	if not grounded or phase != "battle" or state.health <= 0 or state.recovery_pending: return points
	var action: Node3D = actor.dragon_actions
	if action.kind != "dive" or action.stage not in ["warning","flight","active","recovery"]: return points
	var skeleton: Skeleton3D = actor.character.skeleton
	var box := AABB()
	var first := true
	for bone in flight_skin_boxes:
		var pose: Transform3D = skeleton.global_transform*skeleton.get_bone_global_pose(bone)
		var bounds: AABB = flight_skin_boxes[bone]
		for corner in 8:
			var point: Vector3 = pose*bounds.get_endpoint(corner)
			box = AABB(point,Vector3.ZERO) if first else box.expand(point)
			first = false
	for corner in 8:
		var point := box.get_endpoint(corner)
		points.append(point)
		# Anticipate the committed apex without chasing an airborne origin.
		points.append(point-actor.global_position+action.landing+Vector3.UP*5.0)
	for x in [-3.0,3.0]:
		for z in [-3.0,3.0]: points.append(action.landing + Vector3(x,0,z))
	for x in [-0.45,0.45]:
		for y in [0.0,1.9]: points.append(world.player.global_position + Vector3(x,y,0))
	return points

func flight_camera_occluders() -> Array:
	# Reuse the actual rig's cached skin influence volumes. These are
	# visibility bounds, not new collision or an alternate creature visual.
	# Invert each pose once before the player's bounded candidate search.
	var occluders: Array = []
	var skeleton: Skeleton3D = actor.character.skeleton
	for bone in flight_skin_boxes:
		var pose: Transform3D = skeleton.global_transform*skeleton.get_bone_global_pose(bone)
		occluders.append({"bounds":flight_skin_boxes[bone],"inverse_pose":pose.affine_inverse()})
	return occluders

func frame_presentation() -> void:
	var points := presentation_points()
	if points.is_empty(): return
	var box := AABB(points[0],Vector3.ZERO)
	for point in points: box = box.expand(point)
	var center := box.get_center()
	var radius := maxf(box.size.length()*0.5,1.0)
	var viewport_size := get_viewport().get_visible_rect().size
	var half_vertical := deg_to_rad(reveal_camera.fov)*0.5
	var half_horizontal := atan(tan(half_vertical)*viewport_size.x/maxf(viewport_size.y,1.0))
	var caption_scale := clampf(state.text_scale-1.0,0.0,1.0) if defeat_scene.active else 0.0
	var distance := radius/sin(minf(half_vertical,half_horizontal)*(0.78-0.10*caption_scale))+0.5
	var best := center+Vector3.UP*distance
	var best_score := -INF
	var exclusions: Array[RID] = [actor.get_rid(),world.player.get_rid()]
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = exclusions
	var space := get_world_3d().direct_space_state
	for direction in [Vector3(0,0.65,1),Vector3(1,0.8,1),Vector3(-1,0.8,1),Vector3(1,1,0),Vector3(-1,1,0),Vector3(0,1,-1),Vector3(0,1,0)]:
		var candidate: Vector3 = center+direction.normalized()*distance
		query.transform = Transform3D(Basis.IDENTITY,candidate)
		if not space.intersect_shape(query,1).is_empty(): continue
		var clear := 0
		for target_point in [center,actor.global_position+Vector3.UP,world.player.global_position+Vector3.UP]:
			var ray := PhysicsRayQueryParameters3D.create(candidate,target_point,1,exclusions)
			if space.intersect_ray(ray).is_empty(): clear += 1
		var score: float = clear*10.0-direction.normalized().y
		if score > best_score: best_score = score; best = candidate
	reveal_camera.global_position = best
	reveal_camera.look_at(center,Vector3.FORWARD if absf((best-center).normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP)
	if caption_scale > 0:
		# Reserve the larger caption's lower screen area for accessibility scales.
		reveal_camera.look_at(center-reveal_camera.global_basis.y*radius*0.38*caption_scale,Vector3.UP)

func finish_presentation() -> void:
	if phase not in ["reveal","phase_transition"]: return
	var second := phase == "phase_transition"
	reveal_video.shutdown()
	world.player.camera.current = true
	world._set_pause_owner("veyne_presentation",false)
	world.player.suppress_held_combat_actions()
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
	var spots := [Vector2(clampf(player_xz.x,-11.0,3.0),clampf(player_xz.y,-33,-19)),Vector2(-10.0 if player_xz.x > -4 else 2.0,-28)]
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
	if is_instance_valid(reveal_video): reveal_video.set_paused(paused)
	if is_instance_valid(defeat_scene): defeat_scene.set_paused(paused)
	# SceneTree pause suspends the pausable actor/timeline; combat_allowed()
	# rejects menu-time contacts. Retain clocks, footprint and instance dedup so
	# resume continues the same attack instead of silently starting a new one.
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
	if state.veyne_defeated or actor.health > 0: return
	phase = "victory"
	# on_death already cancelled attacks before selecting Death. Interrupting
	# again here travels the animation tree back to Idle and erases that motion.
	world.player.release_encounter_camera()
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
	defeat_scene.begin()
	world.training.tell("维恩已败 · 法术瓦解。检查祭坛取得解除钥印；四位村民与召唤核心仍待处理。",7)
	state.progression_changed.emit()

func interrupt() -> void:
	if not grounded: return
	if is_instance_valid(defeat_scene): defeat_scene.shutdown()
	if is_instance_valid(reveal_video): reveal_video.shutdown()
	actor.interrupt_action()
	world.player.release_encounter_camera()
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
	if is_instance_valid(defeat_scene): defeat_scene.shutdown()
	if is_instance_valid(reveal_video): reveal_video.shutdown()
	if is_instance_valid(music): release_score()

func _mcp_state() -> Dictionary:
	return {"grounded":grounded,"phase":phase,"arena_samples":arena_samples,"approach_samples":approach_samples,"reveal_elapsed":reveal_elapsed,"reveal_starts":reveal_starts,"battle_starts":battle_starts,"phase_starts":phase_starts,"victory_commits":victory_commits,"victory_pending":victory_pending,"rift_waves":rift_waves,"rift_contacts":rift_contacts,"rifts":rifts.size(),"wave_count":reinforcements.wave_count if reinforcements else 0,"reinforcements":reinforcements.units.size() if reinforcements else 0,"music_playing":music.playing if music else false,"normal_camera":world.player.camera.current if world else false,"combat_allowed":combat_allowed() if grounded else false}
