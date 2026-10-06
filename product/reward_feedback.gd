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
	audio.stream = stream
	audio.volume_db = volume
	audio.pitch_scale = pitch
	add_child(audio)
	sounds.append(audio)
	audio.finished.connect(func(): sounds.erase(audio); audio.queue_free())
	audio.play()

func add_cue(text: String, position: Vector2, color: Color, lifetime = 1.0) -> void:
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
	cues.append({"label": label, "origin": position, "time": 0.0, "duration": lifetime})

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
		var text = outcome if hp_loss <= 0 else (outcome + " −%s" % snappedf(hp_loss, 0.1))
		add_cue(text, camera.unproject_position(point) + Vector2(-25, -45), color)
	sound(stream, volume, pitch)
	spark(point, color)

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
	for cue in cues.duplicate():
		cue.time += delta
		var fraction: float = cue.time / cue.duration
		cue.label.modulate.a = clampf(1.0 - fraction, 0, 1)
		if not training.state.reduced_motion: cue.label.position = cue.origin + Vector2(0, -44 * fraction)
		if fraction >= 1:
			cue.label.queue_free()
			cues.erase(cue)
