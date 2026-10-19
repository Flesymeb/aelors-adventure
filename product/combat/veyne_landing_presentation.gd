extends Node3D
## One attempt-owned burst. This node never resolves contacts or damage.
const LIFETIME := 0.9
var world: Node3D
var settings: Node
var age := 0.0
var active := false
var last_attack := -1
var bursts := 0
@onready var dust: CPUParticles3D = $Dust
@onready var ring: MeshInstance3D = $Ring
@onready var sound: AudioStreamPlayer3D = $Impact

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	ring.material_override = ring.material_override.duplicate()
	dust.mesh = dust.mesh.duplicate()
	dust.mesh.material = dust.mesh.material.duplicate()
	clear()

func configure(owner_world: Node3D, state: Node) -> void:
	world = owner_world
	settings = state

static func distance_strength(distance: float) -> float:
	return clampf(1.0 - distance / 12.0, 0.0, 1.0)

func emit_once(point: Vector3, normal: Vector3, attack: int, player: Node3D) -> bool:
	if attack == last_attack: return false
	clear()
	last_attack = attack
	bursts += 1
	global_position = point + normal.normalized() * 0.055
	var up := normal.normalized()
	var tangent := Vector3.RIGHT.slide(up).normalized()
	if tangent.length_squared() < 0.1: tangent = Vector3.FORWARD.slide(up).normalized()
	global_basis = Basis(tangent, up, tangent.cross(up))
	var reduced: bool = settings != null and settings.reduced_motion
	dust.amount = 12 if settings != null and settings.graphics_quality == "low" else 24
	ring.show()
	ring.material_override.set_shader_parameter("effect_age", 0.0)
	ring.material_override.set_shader_parameter("reduced_motion", reduced)
	if not reduced:
		dust.show()
		dust.restart()
		dust.emitting = true
	sound.stream_paused = false
	sound.play()
	age = 0.0
	active = true
	if is_instance_valid(player) and player.has_method("start_camera_shake"):
		player.start_camera_shake(distance_strength(player.global_position.distance_to(point)), 0.24)
	return true

func _process(delta: float) -> void:
	if not active: return
	var paused := get_tree().paused
	if is_instance_valid(world):
		var owners = world.get("pause_owners")
		if owners is Dictionary: paused = paused or not owners.is_empty()
	sound.stream_paused = paused
	if paused: return
	age += delta
	ring.material_override.set_shader_parameter("effect_age", age)
	dust.mesh.material.set_shader_parameter("effect_clock", age)
	if age >= LIFETIME: clear()

func clear() -> void:
	active = false
	age = 0.0
	if is_instance_valid(dust): dust.emitting = false; dust.visible = false
	if is_instance_valid(ring): ring.hide()
	if is_instance_valid(sound): sound.stop(); sound.stream_paused = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and is_instance_valid(sound): sound.stream_paused = true
	elif what == NOTIFICATION_UNPAUSED and is_instance_valid(sound): sound.stream_paused = false

func snapshot() -> Dictionary:
	return {"active": active, "age": age, "bursts": bursts, "attack": last_attack,
		"position": global_position, "audio_bus": sound.bus, "audio_playing": sound.playing,
		"particles": dust.amount, "reduced_motion": settings.reduced_motion if settings else false}
