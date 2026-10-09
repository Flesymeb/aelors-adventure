extends Node3D
## An inactive CH01 passage. No transport or chapter-completion authority.
const GROUND := preload("res://forest_ground.gd")
const ANCHOR := Vector2(133,151)
var return_passage := false
var anchor: Vector2 = ANCHOR
var world: Node3D
var state: Node
var grounded := false
var elapsed := 0.0
var rejected_entries := 0
var light: OmniLight3D
var flow: MeshInstance3D
var particles: CPUParticles3D
var prompted := false
var stones: Array[Node3D] = []

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	# Retained authored textured rock silhouettes; effects use native materials.
	for side in [-1,1]:
		var stone = preload("res://env models/rocks/scenes/big rock 2.tscn").instantiate()
		stone.name = "PassageStoneLeft" if side < 0 else "PassageStoneRight"
		stone.position.x = side * 1.2
		var bounds: AABB = stone.mesh.get_aabb()
		stone.scale = Vector3(1.1,4.2,1.0) / bounds.size
		stone.position.y = -bounds.position.y * stone.scale.y
		add_child(stone)
		stone.create_convex_collision()
		stone.get_child(0).collision_layer = 1
		stones.append(stone)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.12,0.74,1,0.45)
	material.emission_enabled = true
	material.emission = Color(0.06,0.56,1)
	material.emission_energy_multiplier = 1.5
	var column := CylinderMesh.new()
	column.top_radius = 0.08
	column.bottom_radius = 0.24
	column.height = 4.6
	column.material = material
	flow = MeshInstance3D.new()
	flow.name = "InterruptedBlueFlow"
	flow.mesh = column
	flow.position.y = 2.3
	add_child(flow)
	light = OmniLight3D.new()
	light.light_color = Color(0.12,0.66,1)
	light.omni_range = 6
	light.light_energy = 1.7
	light.position.y = 1.8
	add_child(light)
	particles = CPUParticles3D.new()
	particles.name = "BlueFlowParticles"
	particles.amount = 30
	particles.lifetime = 2
	particles.direction = Vector3.UP
	particles.spread = 12
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 1.8
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.4
	particles.scale_amount_min = 0.025
	particles.scale_amount_max = 0.05
	particles.color = Color(0.2,0.8,1)
	var mote := SphereMesh.new()
	mote.radius = 0.5
	mote.height = 1
	mote.material = material
	particles.mesh = mote
	particles.position.y = 0.3
	add_child(particles)
	visible = false
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		var excluded: Array[RID] = []
		for stone in stones: excluded.append(stone.get_child(0).get_rid())
		var hit: Dictionary = GROUND.support(world,anchor,excluded)
		if not hit.is_empty():
			global_position = hit.position
			grounded = true
			visible = true
			return
	push_error("Inactive chapter pillar lacks authored ground support")

func _physics_process(delta: float) -> void:
	if not grounded: return
	elapsed += delta
	# No shader TIME: product pause suspends the actual presentation clock.
	var active: bool = return_passage or state.passage_missing_conditions().is_empty()
	var pulse := 0.85 if active or state.reduced_motion else 0.35 + 0.4 * pow(maxf(0,sin(elapsed*2.0)),2)
	flow.scale.x = pulse
	flow.scale.z = pulse
	light.light_energy = pulse * 2
	particles.emitting = not state.reduced_motion
	var near: bool = world.player.global_position.distance_to(global_position) < 2.5
	if near and not prompted and world.pause_owners.is_empty():
		world.training.tell("[E] 返回河谷聚落" if return_passage else ("[E] 前往林缘草甸" if active else "蓝色柱群尚未激活 · [E] 查看缺少的条件"),3)
	prompted = near

func _unhandled_input(event: InputEvent) -> void:
	if not grounded or not world.pause_owners.is_empty() or world.training.player_locked(): return
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo and world.player.global_position.distance_to(global_position) < 2.5:
		if not return_passage and not state.passage_missing_conditions().is_empty():
			rejected_entries += 1
			world.training.tell("通道未开放 · " + "；".join(state.passage_missing_conditions()),6)
		elif not world.training.can_save() or not world.bow_training.can_save():
			world.training.tell("请先退出战斗，等攻击与箭落定后再出发", 4)
		elif world.entry_router:
			world.entry_router.travel_to(state.GROUND.MAP_ID if return_passage else state.MAP02)
		else: world.training.tell("请从标题进入冒险后再出发", 4)
		get_viewport().set_input_as_handled()

func _mcp_state() -> Dictionary:
	return {"grounded":grounded,"active":return_passage or state.passage_missing_conditions().is_empty(),"destination":"河谷聚落" if return_passage else "林缘草甸","missing_conditions":state.passage_missing_conditions(),"rejected_entries":rejected_entries,"presentation_time":elapsed,"position":str(global_position)}
