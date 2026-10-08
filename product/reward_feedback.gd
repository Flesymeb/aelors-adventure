extends CanvasLayer
## Short lived UI, world particles and sound are emitted only by settled outcomes.
var training: Node3D
var cues: Array[Dictionary] = []
var sounds: Array[AudioStreamPlayer] = []
var sparks: Array[CPUParticles3D] = []

func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_PAUSABLE

func clear_feedback() -> void:
	for cue in cues:
		if is_instance_valid(cue.label): cue.label.queue_free()
	cues.clear()
	for sound in sounds:
		if is_instance_valid(sound): sound.queue_free()
	sounds.clear()
	for particles in sparks:
		if is_instance_valid(particles): particles.queue_free()
	sparks.clear()

func sound(stream: AudioStream, volume: float, pitch = 1.0) -> void:
	if training.state.muted_sound: return
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
	var cue := {"label": label, "origin": position, "time": 0.0, "duration": lifetime}
	cues.append(cue)
	return cue

func reward(amount: int) -> void:
	var size = get_viewport().get_visible_rect().size
	add_cue("+%d XP" % amount, Vector2(size.x * 0.48, size.y * 0.42), Color(1, 0.8, 0.24), 1.6)
	sound(preload("res://assets/dialogue/sounds/Audio/confirmation_001.ogg"), -15)
	spark(training.player.global_position + Vector3.UP * 1.25, Color(1, 0.8, 0.2))

func impact(point: Vector3, outcome: String, hp_loss: float, kind = "hit") -> void:
	# Outcome and material choose the cue; misses never enter this boundary.
	var color = Color(1, 0.72, 0.43)
	var stream: AudioStream = preload("res://assets/training/soft_impact.ogg")
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
		"block", "parry":
			color = Color(0.67, 0.87, 1.0) if kind == "block" else Color(1, 0.94, 0.65)
			stream = preload("res://assets/training/impact.ogg")
			volume = -15.0 if kind == "block" else -11.0
			pitch = 0.9 if kind == "block" else 1.25
		"hurt", "death":
			color = Color(1, 0.46, 0.38)
			volume = -13.0
			pitch = 0.7 if kind == "death" else 0.85
		"defeat":
			color = Color(0.95, 0.70, 0.45)
			pitch = 0.72
	var camera: Camera3D = training.player.camera
	if not camera.is_position_behind(point):
		var loss_text := str(int(hp_loss)) if is_equal_approx(hp_loss, roundf(hp_loss)) else str(snappedf(hp_loss, 0.1))
		var text = outcome if hp_loss <= 0 or not training.state.damage_numbers else (outcome + " −" + loss_text).strip_edges()
		if text != "":
			var cue := add_cue(text, Vector2.ZERO, color)
			cue["world_point"] = point
			cue["hp_loss"] = hp_loss
			cue["kind"] = kind
			cue.label.position = impact_position(cue, 0)
	sound(stream, volume, pitch)
	spark(point, color)
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

func spark(point: Vector3, color: Color) -> void:
	if training.state.reduced_motion: return
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
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1
	mesh.material = material
	particles.mesh = mesh
	training.add_child(particles)
	sparks.append(particles)
	particles.global_position = point
	particles.finished.connect(func(): sparks.erase(particles); particles.queue_free())
	particles.restart()

func _process(delta: float) -> void:
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

func _mcp_state() -> Dictionary:
	var readouts: Array[Dictionary] = []
	for cue in cues:
		readouts.append({"text": cue.label.text, "rect": str(cue.label.get_global_rect()), "visible": cue.label.visible, "age": cue.time, "duration": cue.duration, "hp_loss": cue.get("hp_loss", 0), "kind": cue.get("kind", "reward")})
	return {"readouts": readouts}
