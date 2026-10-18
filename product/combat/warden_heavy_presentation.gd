extends Node3D
## One attack-owned stone response. Physics supplies contact; this owns no damage.
const LIFETIME := 1.35
var settings: Node
var attack := -1
var settled := false
var active := false
var age := 0.0
var contact_kind := ""
var bursts := 0
var ring: MeshInstance3D
var dust: CPUParticles3D
var impact: AudioStreamPlayer3D
var swing: AudioStreamPlayer3D

func configure(state: Node) -> void:
	settings = state
	process_mode = Node.PROCESS_MODE_PAUSABLE
	top_level = true
	ring = MeshInstance3D.new()
	ring.name = "StoneContactRing"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.45,1.45)
	ring.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/landing_impact.gdshader")
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	dust = CPUParticles3D.new()
	dust.name = "StoneDust"
	dust.emitting = false
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.lifetime = 0.55
	dust.direction = Vector3.UP
	dust.spread = 65
	dust.gravity = Vector3(0,-1.3,0)
	dust.initial_velocity_min = 0.4
	dust.initial_velocity_max = 1.1
	dust.scale_amount_min = 0.12
	dust.scale_amount_max = 0.3
	var dust_mesh := QuadMesh.new()
	dust_mesh.size = Vector2.ONE
	var dust_material := StandardMaterial3D.new()
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust_material.albedo_texture = preload("res://assets/bosses/landing/dust.png")
	dust_material.albedo_color = Color(0.52,0.46,0.35,0.35)
	dust_mesh.material = dust_material
	dust.mesh = dust_mesh
	var fade := Gradient.new()
	fade.set_color(0,Color(1,1,1,0.65))
	fade.set_color(1,Color(1,1,1,0))
	dust.color_ramp = fade
	add_child(dust)
	impact = AudioStreamPlayer3D.new()
	impact.name = "StoneImpact"
	impact.stream = preload("res://assets/audio/warden_heavy_contact.ogg")
	impact.bus = "Effects"
	impact.volume_db = -10
	impact.pitch_scale = 0.72
	impact.max_distance = 18
	add_child(impact)
	swing = AudioStreamPlayer3D.new()
	swing.name = "HeavySwing"
	swing.stream = preload("res://assets/dialogue/sounds/Audio/pluck_002.ogg")
	swing.bus = "Effects"
	swing.volume_db = -21
	swing.pitch_scale = 0.35
	swing.max_distance = 14
	add_child(swing)
	clear()

func begin(id: int) -> void:
	clear()
	attack = id
	settled = false
	contact_kind = ""

func play_swing(point: Vector3) -> void:
	# Swing is legal on a miss and must never masquerade as stone/victim impact.
	swing.global_position = point
	swing.play()

func world_contact(hit: Dictionary, id: int) -> bool:
	if id != attack or settled or hit.is_empty(): return false
	if not hit.get("point") is Vector3 or not hit.get("normal") is Vector3: return false
	var normal: Vector3 = hit.normal
	if normal.length_squared() < 0.5: return false
	settled = true
	bursts += 1
	contact_kind = "floor" if normal.y >= 0.55 else "stone"
	global_position = hit.point + normal * 0.035
	var tangent := Vector3.RIGHT.slide(normal).normalized()
	if tangent.length_squared() < 0.1: tangent = Vector3.FORWARD.slide(normal).normalized()
	global_basis = Basis(tangent,normal,tangent.cross(normal)).orthonormalized()
	var reduced: bool = settings != null and settings.reduced_motion
	ring.material_override.set_shader_parameter("effect_age",0.0)
	ring.material_override.set_shader_parameter("reduced_motion",reduced)
	ring.show()
	dust.amount = 8 if settings != null and settings.graphics_quality == "low" else 14
	if not reduced:
		dust.show()
		dust.restart()
		dust.emitting = true
	impact.stream_paused = false
	impact.play()
	age = 0
	active = true
	return true

func _process(delta: float) -> void:
	if not active: return
	age += delta
	ring.material_override.set_shader_parameter("effect_age",age)
	if age >= LIFETIME: clear()

func clear() -> void:
	active = false
	age = 0
	if is_instance_valid(ring): ring.hide()
	if is_instance_valid(dust): dust.emitting = false; dust.hide()
	for voice in [impact,swing]:
		if is_instance_valid(voice): voice.stop(); voice.stream_paused = false

func _notification(what: int) -> void:
	if what not in [NOTIFICATION_PAUSED,NOTIFICATION_UNPAUSED]: return
	for voice in [impact,swing]:
		if is_instance_valid(voice): voice.stream_paused = what == NOTIFICATION_PAUSED

func snapshot() -> Dictionary:
	return {"active":active,"age":age,"attack":attack,"settled":settled,"contact_kind":contact_kind,
		"bursts":bursts,"position":global_position,"audio_bus":impact.bus if impact else "",
		"audio_playing":impact.playing if impact else false,"particles":dust.amount if dust else 0}
