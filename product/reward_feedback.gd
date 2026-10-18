extends CanvasLayer
## Short lived UI, world particles and sound are emitted only by settled outcomes.
var training: Node3D
var cues: Array[Dictionary] = []
var sounds: Array[AudioStreamPlayer] = []
var sparks: Array[CPUParticles3D] = []
var cue_serial := 0
var sword_readout_emissions := 0
var last_sword_readout: Dictionary = {}
var finisher_hint: Label
const MAX_CONTACT_VOICES := 8
const MAX_CONTACT_BURSTS := 6

func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_PAUSABLE
	finisher_hint = Label.new()
	finisher_hint.theme = preload("res://dialogue_theme.tres")
	finisher_hint.add_theme_color_override("font_color", Color(1, 0.91, 0.67))
	finisher_hint.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.04))
	finisher_hint.add_theme_constant_override("outline_size", 4)
	finisher_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finisher_hint.visible = false
	add_child(finisher_hint)

func clear_feedback() -> void:
	if finisher_hint: finisher_hint.visible = false
	for cue in cues:
		if is_instance_valid(cue.label): cue.label.queue_free()
	cues.clear()
	_clear_sounds()
	for particles in sparks:
		if is_instance_valid(particles): particles.queue_free()
	sparks.clear()

func sound(stream: AudioStream, volume: float, pitch = 1.0) -> void:
	if training.state.muted_sound: return
	while sounds.size() >= MAX_CONTACT_VOICES:
		var oldest := sounds.pop_front() as AudioStreamPlayer
		if is_instance_valid(oldest):
			oldest.stop()
			oldest.queue_free()
	var audio = AudioStreamPlayer.new()
	audio.bus = "Effects"
	audio.stream = stream
	audio.volume_db = volume
	audio.pitch_scale = pitch
	add_child(audio)
	sounds.append(audio)
	audio.finished.connect(func(): sounds.erase(audio); audio.queue_free())
	audio.play()

func swing() -> void:
	# Existing qualified Kenney stem; no template WAV licensing assumed.
	sound(preload("res://assets/dialogue/sounds/Audio/pluck_002.ogg"), -24, 0.55)

func add_cue(text: String, position: Vector2, color: Color, lifetime = 1.0) -> Dictionary:
	var label = Label.new()
	label.text = text
	label.theme = preload("res://dialogue_theme.tres")
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.03))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", int(26 * training.state.text_scale))
	label.position = position
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	cue_serial += 1
	var cue := {"id": cue_serial, "label": label, "origin": position, "time": 0.0, "duration": lifetime}
	cues.append(cue)
	return cue

func reward(amount: int) -> void:
	var size = get_viewport().get_visible_rect().size
	add_cue("+%d XP" % amount, Vector2(size.x * 0.48, size.y * 0.42), Color(1, 0.8, 0.24), 1.6)
	sound(preload("res://assets/dialogue/sounds/Audio/confirmation_001.ogg"), -15)
	spark(training.player.global_position + Vector3.UP * 1.25, Color(1, 0.8, 0.2))

func impact(point: Vector3, outcome: String, hp_loss: float, kind = "hit", contact: Dictionary = {}) -> void:
	# Outcome and material choose the cue; misses never enter this boundary.
	var color = Color(1, 0.72, 0.43)
	var stream: AudioStream = preload("res://assets/training/hurt_contact.ogg")
	var volume = -16.0
	var pitch = 1.0
	match kind:
		"straw":
			color = Color(0.85, 0.72, 0.40)
			stream = preload("res://assets/training/straw_impact.ogg")
			volume = -20.0
		"obstruction":
			color = Color(0.70, 0.79, 0.84)
			stream = preload("res://assets/training/impact.ogg")
			volume = -21.0
			pitch = 0.68
		"block":
			color = Color(0.67, 0.87, 1.0)
			stream = preload("res://assets/training/block_contact.ogg")
			volume = -16.0
		"parry":
			color = Color(1, 0.94, 0.65)
			stream = preload("res://assets/training/parry_contact.ogg")
			volume = -14.0
		"hurt", "death":
			color = Color(1, 0.46, 0.38)
			stream = preload("res://assets/training/lethal_contact.ogg") if kind == "death" else preload("res://assets/training/hurt_contact.ogg")
			volume = -13.0
			pitch = 0.7 if kind == "death" else 0.85
		"defeat":
			color = Color(0.95, 0.70, 0.45)
			stream = preload("res://assets/training/lethal_contact.ogg")
			volume = -14.0
	var camera: Camera3D = training.player.camera
	if not camera.is_position_behind(point):
		var loss_text := str(int(hp_loss)) if is_equal_approx(hp_loss, roundf(hp_loss)) else str(snappedf(hp_loss, 0.1))
		var text = outcome if hp_loss <= 0 or not training.state.damage_numbers else (outcome + " −" + loss_text).strip_edges()
		if text != "":
			var cue := add_cue(text, Vector2.ZERO, color)
			cue["world_point"] = point
			cue["hp_loss"] = hp_loss
			cue["kind"] = kind
			# Copy the resolved Snaiel contact, never infer a hit from the current
			# weapon or attack. Arrow and sword contacts share this presentation.
			cue["source_id"] = contact.get("source_id", 0)
			cue["attack_instance"] = contact.get("attack_instance", 0)
			cue["receiver"] = contact.get("receiver", "")
			cue["hp_before"] = contact.get("hp_before", 0.0)
			cue["hp_after"] = contact.get("hp_after", 0.0)
			cue["outcome"] = contact.get("outcome", kind)
			cue["simulated"] = contact.get("simulated", false)
			cue["sword_hit"] = hp_loss > 0 and training.sword_source != null and cue.source_id == training.sword_source.get_instance_id()
			if cue.sword_hit:
				sword_readout_emissions += 1
				last_sword_readout = _contact_observation(cue)
			cue.label.position = impact_position(cue, 0)
	sound(stream, volume, pitch)
	spark(point, color, kind)
	if kind in ["hurt", "hit", "parry", "defeat"]: training.player.start_camera_shake()

func impact_position(cue: Dictionary, drift: float) -> Vector2:
	var view := get_viewport().get_visible_rect().size
	var anchor: Vector2 = training.player.camera.unproject_position(cue.world_point)
	var extent: Vector2 = cue.label.get_minimum_size()
	# Beside the contact, clear of the face, hands and central aim/loot marker.
	var pos := anchor + Vector2(72, -30 - drift)
	if pos.x + extent.x > view.x - 16: pos.x = anchor.x - 72 - extent.x
	var obstacles: Array[Rect2] = training.hud.readout_obstacles()
	for other in cues:
		if other != cue and other.label.visible:
			obstacles.append(other.label.get_global_rect().grow(8))
	for obstacle in obstacles:
		if Rect2(pos, extent).intersects(obstacle): pos.y = obstacle.end.y + 8
	pos.x = clampf(pos.x, 16, maxf(16, view.x - extent.x - 16))
	pos.y = clampf(pos.y, 16, maxf(16, view.y - extent.y - 16))
	return pos

func spark(point: Vector3, color: Color, kind := "reward") -> void:
	if training.state.reduced_motion: return
	while sparks.size() >= MAX_CONTACT_BURSTS:
		var oldest := sparks.pop_front() as CPUParticles3D
		if is_instance_valid(oldest): oldest.queue_free()
	var particles = CPUParticles3D.new()
	particles.amount = 8
	particles.lifetime = 0.25
	particles.one_shot = true
	particles.explosiveness = 1
	particles.direction = Vector3.UP
	particles.spread = 100
	particles.initial_velocity_min = 0.35
	particles.initial_velocity_max = 1.0
	particles.gravity = Vector3(0, -2, 0)
	particles.scale_amount_min = 0.02
	particles.scale_amount_max = 0.035
	particles.color = color
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	var mesh: Mesh
	match kind:
		"block", "parry":
			# Short metal chips versus a narrow, brighter upward deflection fan.
			var shard := BoxMesh.new()
			shard.size = Vector3(0.24, 1.8 if kind == "parry" else 0.75, 0.24)
			mesh = shard
			particles.particle_flag_align_y = true
			particles.spread = 35 if kind == "parry" else 85
			particles.initial_velocity_min = 1.2 if kind == "parry" else 0.6
			particles.initial_velocity_max = 2.0 if kind == "parry" else 1.1
			particles.lifetime = 0.22 if kind == "parry" else 0.16
		"straw", "obstruction":
			var chip := BoxMesh.new()
			chip.size = Vector3(0.35, 1.6, 0.25) if kind == "straw" else Vector3(0.85, 0.7, 0.6)
			mesh = chip
			particles.amount = 6
			particles.angular_velocity_min = -180
			particles.angular_velocity_max = 180
			particles.lifetime = 0.32 if kind == "straw" else 0.18
		"hit", "hurt", "death", "defeat":
			var mote := SphereMesh.new()
			mote.radius = 0.4
			mote.height = 0.8
			mesh = mote
			particles.amount = 9 if kind in ["death", "defeat"] else 5
			particles.spread = 150
			particles.initial_velocity_min = 0.15
			particles.initial_velocity_max = 0.55
			particles.lifetime = 0.3 if kind in ["death", "defeat"] else 0.18
		_:
			var mote := SphereMesh.new()
			mote.radius = 0.5
			mote.height = 1
			mesh = mote
	if training.state.graphics_quality == "low": particles.amount = mini(particles.amount, 4)
	mesh.material = material
	particles.mesh = mesh
	training.add_child(particles)
	sparks.append(particles)
	particles.global_position = point
	particles.finished.connect(func(): sparks.erase(particles); particles.queue_free())
	particles.restart()

func _clear_sounds() -> void:
	for source in sounds:
		if is_instance_valid(source):
			source.stop()
			source.queue_free()
	sounds.clear()

func _notification(what: int) -> void:
	# Preserve paused visual lifetimes, but never resume an obsolete contact tail.
	if what == NOTIFICATION_PAUSED: _clear_sounds()

func _process(delta: float) -> void:
	# Only show the remapped control while the existing late-link is legal.
	finisher_hint.visible = training.can_link_finisher() and training.finisher_eligible() and training.world.pause_owners.is_empty()
	if finisher_hint.visible:
		finisher_hint.text = "〔%s〕 重击终结" % training.player.key_prompt("heavy")
		finisher_hint.add_theme_font_size_override("font_size", int(20 * minf(training.state.text_scale, 1.5)))
		finisher_hint.reset_size()
		var view := get_viewport().get_visible_rect().size
		finisher_hint.position = Vector2((view.x - finisher_hint.size.x) * 0.5, view.y * 0.72)
	if training.state.muted_sound and not sounds.is_empty():
		for source in sounds:
			if is_instance_valid(source):
				source.stop()
				source.queue_free()
		sounds.clear()
	for cue in cues.duplicate():
		cue.time += delta
		var fraction: float = cue.time / cue.duration
		cue.label.modulate.a = clampf(1.0 - fraction, 0, 1)
		cue.label.add_theme_font_size_override("font_size", int(26 * training.state.text_scale))
		cue.label.reset_size()
		var drift := 0.0 if training.state.reduced_motion else 44 * fraction
		if cue.has("world_point"):
			var camera: Camera3D = training.player.camera
			cue.label.visible = not camera.is_position_behind(cue.world_point) and Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).has_point(camera.unproject_position(cue.world_point))
			if cue.label.visible: cue.label.position = impact_position(cue, drift)
		else:
			cue.label.position = cue.origin + Vector2(0, -drift)
		if fraction >= 1:
			cue.label.queue_free()
			cues.erase(cue)

func _contact_observation(cue: Dictionary) -> Dictionary:
	return {"id": cue.id, "source_id": cue.get("source_id", 0), "attack_instance": cue.get("attack_instance", 0), "receiver": cue.get("receiver", ""), "world_point": cue.get("world_point", Vector3.ZERO), "outcome": cue.get("outcome", ""), "simulated": cue.get("simulated", false), "hp_before": cue.get("hp_before", 0.0), "hp_after": cue.get("hp_after", 0.0), "hp_loss": cue.get("hp_loss", 0.0)}

func _mcp_state() -> Dictionary:
	var readouts: Array[Dictionary] = []
	var sword_cue: Dictionary = {}
	for cue in cues:
		var readout := _contact_observation(cue)
		readout.merge({"text": cue.label.text, "rect": str(cue.label.get_global_rect()), "visible": cue.label.visible, "age": cue.time, "duration": cue.duration, "kind": cue.get("kind", "reward")})
		readouts.append(readout)
		# Track the latest emitted sword cue through expiry without selecting
		# an older cue. Settlement history survives expiry and cleanup.
		if cue.id == last_sword_readout.get("id", 0): sword_cue = cue
	return {"readouts": readouts, "cue_emissions": cue_serial, "sword_readout_emissions": sword_readout_emissions,
		"sword_cue_active": not sword_cue.is_empty(), "sword_cue_id": last_sword_readout.get("id", 0),
		"sword_cue_age": sword_cue.get("time", 0.0), "sword_cue_duration": sword_cue.get("duration", 0.0),
		"sword_cue_visible": sword_cue.label.visible if not sword_cue.is_empty() else false,
		"sword_source_id": last_sword_readout.get("source_id", 0), "sword_attack_instance": last_sword_readout.get("attack_instance", 0),
		"sword_receiver": last_sword_readout.get("receiver", ""), "sword_hp_before": last_sword_readout.get("hp_before", 0.0),
		"sword_hp_after": last_sword_readout.get("hp_after", 0.0), "sword_hp_loss": last_sword_readout.get("hp_loss", 0.0)}


static func make_remnant() -> Node3D:
	# Shared with the established golden XP remnant presentation.
	var remnant := Node3D.new()
	remnant.name = "ExperienceRemnant"
	var glow = CPUParticles3D.new()
	glow.amount = 14
	glow.lifetime = 1.4
	glow.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	glow.emission_sphere_radius = 0.2
	glow.direction = Vector3.UP
	glow.initial_velocity_min = 0.15
	glow.initial_velocity_max = 0.3
	glow.gravity = Vector3.ZERO
	glow.scale_amount_min = 0.03
	glow.scale_amount_max = 0.055
	glow.color = Color(1, 0.78, 0.18)
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1
	mesh.material = material
	glow.mesh = mesh
	glow.position.y = 0.65
	remnant.add_child(glow)
	var label = Label3D.new()
	label.text = "◇ 经验残响"
	label.font = preload("res://dialogue_theme.tres").default_font
	label.font_size = 44
	label.pixel_size = 0.005
	label.position.y = 1.25
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	remnant.add_child(label)

	return remnant
