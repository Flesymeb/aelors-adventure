extends Node3D
## Bounded presentation only: drifting arena dust and supported charge trails.
## Does not own contacts, collision, damage, Boss movement or the camera.
var encounter: Node3D
var ambient: CPUParticles3D
var bursts: Array[CPUParticles3D] = []
var material: ShaderMaterial
var effect_clock := 0.0
var trail_clock := 0.0
var burst_index := 0
var was_battle := false
var last_low := false
const MAX_BURSTS := 4

func configure(owner_encounter: Node3D) -> void:
	encounter = owner_encounter
	process_mode = Node.PROCESS_MODE_PAUSABLE
	material = ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/veyne_dust.gdshader")
	ambient = _particles("ArenaDust", false)
	ambient.amount = 18
	ambient.lifetime = 4.0
	ambient.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ambient.emission_box_extents = Vector3(8.0, 0.25, 5.5)
	ambient.direction = Vector3(1.0, 0.15, 0.2)
	ambient.spread = 25.0
	ambient.initial_velocity_min = 0.12
	ambient.initial_velocity_max = 0.35
	ambient.scale_amount_min = 0.4
	ambient.scale_amount_max = 1.0
	for index in MAX_BURSTS:
		var burst := _particles("ChargeDust" + str(index), true)
		burst.amount = 12
		burst.lifetime = 0.9
		burst.explosiveness = 1.0
		burst.direction = Vector3.UP
		burst.spread = 70.0
		burst.initial_velocity_min = 0.4
		burst.initial_velocity_max = 1.3
		burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		burst.emission_sphere_radius = 0.65
		bursts.append(burst)

func _particles(label: String, one_shot: bool) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = label
	particles.emitting = false
	particles.one_shot = one_shot
	particles.local_coords = false
	particles.gravity = Vector3(0, 0.12, 0)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2(1.8, 1.8)
	quad.material = material
	particles.mesh = quad
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.65, 1.0])
	gradient.colors = PackedColorArray([Color(1,1,1,0), Color(1,1,1,0.65), Color(1,1,1,0.35), Color(1,1,1,0)])
	particles.color_ramp = gradient
	add_child(particles)
	particles.top_level = true
	return particles

func _process(delta: float) -> void:
	if not is_instance_valid(encounter) or not is_instance_valid(encounter.actor): return
	var paused: bool = get_tree().paused or not encounter.world.pause_owners.is_empty()
	if paused: return
	var battle: bool = encounter.combat_allowed()
	var reduced: bool = encounter.state.reduced_motion
	var low: bool = encounter.state.graphics_quality == "low"
	if not battle or reduced:
		if was_battle: clear()
		return
	if not was_battle or low != last_low:
		ambient.amount = 6 if low else 18
		ambient.global_position = encounter.actor.home + Vector3(0, 0.35, 0)
		ambient.show()
		ambient.emitting = true
		last_low = low
	was_battle = true
	effect_clock += delta
	material.set_shader_parameter("effect_clock", effect_clock)
	trail_clock -= delta
	var action: Node = encounter.actor.dragon_actions
	if action.kind == "charge" and action.stage == "active" and trail_clock <= 0.0:
		var support: Dictionary = encounter.actor.ground_query.call(encounter.actor.global_position)
		if not support.is_empty():
			var burst := bursts[burst_index]
			burst_index = (burst_index + 1) % MAX_BURSTS
			burst.amount = 5 if low else 12
			burst.global_position = support.position + Vector3.UP * 0.12
			burst.show()
			burst.restart()
			burst.emitting = true
		trail_clock = 0.24 if low else 0.16

func clear() -> void:
	was_battle = false
	trail_clock = 0.0
	if is_instance_valid(ambient):
		ambient.emitting = false
		ambient.hide()
	for burst in bursts:
		burst.emitting = false
		burst.hide()

func snapshot() -> Dictionary:
	return {"active":was_battle,"clock":effect_clock,"ambient_particles":ambient.amount if ambient else 0,
		"burst_pool":bursts.size(),"shader":"veyne_dust","camera_owner":false,"damage_owner":false}
