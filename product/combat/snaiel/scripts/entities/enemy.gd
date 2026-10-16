extends CharacterBody3D
## Scoped Snaiel Enemy: injected target, blackboard decisions, single locomotion,
## animation recipients, health/death and bone-bound contact lifecycle.
signal dead
var target: CharacterBody3D
var enabled_policy: Callable
var ground_query: Callable
var contact_policy: Callable
var result_listener: Callable
var attack_cue: Callable
var acquired_cue: Callable
var home = Vector3.ZERO
var health: float:
	get: return health_component.health if health_component else 24.0
var phase = "idle"
var clock: float:
	get: return melee_events.timeline.current_animation_position if melee_events and melee_events.attacking else 0.0
var engaged = false
var locked_direction = Vector3.ZERO
var attack_origin = Vector3.ZERO
var practice_replay = false
var model: Node3D
var animator: AnimationPlayer
var model_height = 0.0
var returning = false
var lost_time = 0.0
var patrol_index = 0
var patrol_wait = 0.0
var patrol_point = Vector3.ZERO
var previous_fist = Vector3.ZERO
var navigation_region: NavigationRegion3D
var owns_navigation_region = false
var navigation_ready = false
var navigation_clock = 0.0
var navigation_check_clock = 0.0
var navigation_iteration = 0
var navigation_region_iteration = 0
var navigation_probe_path = PackedVector3Array()
var navigation_status = "unbuilt"
var hurt_remaining = 0.0
var hit_response: Node
@onready var character: Node = $CharacterAnimations
@onready var health_component: SnaielHealth = $HealthComponent
@onready var hitbox: SnaielHitbox = $HitboxComponent
@onready var blackboard: SnaielBlackboard = $Blackboard
@onready var melee_events: SnaielMeleeAnimations = $MeleeAnimations
@onready var melee: SnaielMelee = $MeleeComponent
@onready var source: SnaielDamageSource = $MeleeComponent/Fist
@onready var handler: SnaielHitHandler = $HitInteractionHandler
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent
var behavior: SnaielBehaviorTree

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	model = $Model
	var bounds = AABB()
	var first = true
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = (model.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	model_height = bounds.size.y
	if model_height > 0:
		var factor = 1.72 / model_height
		model.scale *= factor
		model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor
	preload("res://actors/mesh_qualification.gd").qualify_tree(model)
	character.configure(model)
	animator = character.anim_player
	hit_response = preload("res://combat/enemy_hit_response.gd").new()
	hit_response.name = "EnemyHitResponse"
	add_child(hit_response)
	hit_response.configure(model)
	var strategy = SnaielMeleeAttack.new()
	strategy.attack_name = &"Punch"
	strategy.damage_attributes.health = 6.0
	strategy.anticipation = 0.9
	strategy.strike_delay = 0.22
	strategy.contact_time = 0.20
	strategy.recovery = 1.0
	melee_events.configure([strategy])
	melee.melee_animations = melee_events
	# Reparent the damage source to the real posed hand socket. No body scan.
	source.reparent(character.contact_socket, false)
	source.position = character.palm_offset
	melee.weapons = {&"fist": melee.get_path_to(source)}
	source.entity = self
	source.parried.connect(on_parried)
	melee.configure()
	melee_events.stage_changed.connect(on_attack_stage)
	melee_events.attacking_finished.connect(_attack_finished)
	hitbox.entity = self
	hitbox.policy = handler.handle_interaction
	hitbox.resolved.connect(_resolved_contact)
	handler.blackboard = blackboard
	handler.health_component = health_component
	handler.eligibility = func(): return enabled_policy.is_valid() and enabled_policy.call()
	handler.reaction = on_hurt
	health_component.zero_health.connect(on_death)
	behavior = SnaielBehaviorTree.new()
	behavior.name = "BehaviorTree"
	behavior.actor = self
	behavior.blackboard = blackboard
	behavior.root_node = $EnemyActions
	add_child(behavior)
	previous_fist = source.global_position

func _exit_tree() -> void:
	if is_instance_valid(hit_response): hit_response.clear()
	if owns_navigation_region and is_instance_valid(navigation_region): navigation_region.queue_free()

func _resolved_contact(result: Dictionary) -> void:
	# Only the complete post-HP hitbox result starts the local visual. Hurt/death
	# drivers remain untouched; the external listener owns contact audio/readout.
	var attack_name := ""
	var contact_source = instance_from_id(int(result.get("source_id", 0)))
	if is_instance_valid(contact_source) and contact_source.get_parent() is SnaielMelee:
		var attack: SnaielMelee = contact_source.get_parent()
		if attack.melee_animations and attack.attack_level >= 0 and attack.attack_level < attack.melee_animations.attacks.size():
			attack_name = str(attack.melee_animations.attacks[attack.attack_level].attack_name)
	hit_response.resolved(result, attack_name)
	if result_listener.is_valid(): result_listener.call(result)

func build_navigation() -> void:
	if owns_navigation_region and is_instance_valid(navigation_region): navigation_region.queue_free()
	navigation_ready = false
	navigation_probe_path.clear()
	navigation_status = "synchronizing"
	navigation_check_clock = 0
	navigation_clock = 0
	# Navigation polygons sample only actual authored terrain and occupied volume.
	# They are invisible navigation data, with no collision floor or substitute map.
	var mesh = NavigationMesh.new()
	var vertices = PackedVector3Array()
	var cells: Dictionary = {}
	for z in range(-8, 9):
		for x in range(-8, 9):
			var sample: Dictionary = ground_query.call(home + Vector3(x * 0.75, 0, z * 0.75))
			if sample.is_empty(): continue
			var point: Vector3 = sample.position
			if not navigation_sample_clear(point): continue
			cells[Vector2i(x, z)] = vertices.size()
			vertices.append(point + Vector3.UP * 0.04)
	mesh.vertices = vertices
	for z in range(-8, 8):
		for x in range(-8, 8):
			var keys = [Vector2i(x, z), Vector2i(x + 1, z), Vector2i(x + 1, z + 1), Vector2i(x, z + 1)]
			if not (cells.has(keys[0]) and cells.has(keys[1]) and cells.has(keys[2]) and cells.has(keys[3])): continue
			var a: int = cells[keys[0]]
			var b: int = cells[keys[1]]
			var c: int = cells[keys[2]]
			var d: int = cells[keys[3]]
			if maxf(absf(vertices[a].y - vertices[c].y), absf(vertices[b].y - vertices[d].y)) > 0.65: continue
			mesh.add_polygon(PackedInt32Array([a, d, c, b]))
	navigation_region = NavigationRegion3D.new()
	owns_navigation_region = true
	navigation_region.navigation_mesh = mesh
	get_parent().add_child(navigation_region)
	navigation_region.global_transform = Transform3D.IDENTITY
	navigation_region.set_navigation_map(navigation_agent.get_navigation_map())
	_choose_patrol_point()

func navigation_sample_clear(point: Vector3) -> bool:
	var shape = SphereShape3D.new()
	shape.radius = 0.38
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = point + Vector3.UP * 0.85
	query.collision_mask = 1
	query.exclude = [get_rid(), target.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func share_navigation(region: NavigationRegion3D) -> void:
	# The region owner alone frees it. Each agent validates its own home/path.
	navigation_region = region
	owns_navigation_region = false
	navigation_agent.set_navigation_map(region.get_navigation_map())
	invalidate_navigation()

func invalidate_navigation() -> void:
	navigation_ready = false
	navigation_check_clock = 0
	navigation_clock = 0
	navigation_probe_path.clear()
	navigation_status = "synchronizing"
	# Clear the pre-reset pursuit request; get_next_path_position updates the
	# agent only when ordinary movement resumes on a synchronized region.
	navigation_agent.target_position = global_position

func _refresh_navigation() -> void:
	navigation_ready = false
	navigation_probe_path.clear()
	if not is_instance_valid(navigation_region):
		navigation_status = "unbuilt"
		return
	var map = navigation_agent.get_navigation_map()
	var region = navigation_region.get_rid()
	navigation_iteration = NavigationServer3D.map_get_iteration_id(map)
	navigation_region_iteration = NavigationServer3D.region_get_iteration_id(region)
	if navigation_iteration == 0 or navigation_region_iteration == 0:
		navigation_status = "synchronizing"
		return
	if NavigationServer3D.region_get_map(region) != map or not NavigationServer3D.map_get_regions(map).has(region):
		navigation_status = "map_mismatch"
		return
	var mesh = navigation_region.navigation_mesh
	if not mesh or mesh.get_polygon_count() == 0:
		navigation_status = "empty_terrain"
		return
	var projected = NavigationServer3D.map_get_closest_point(map, home)
	if projected.distance_to(home) > 0.75:
		navigation_status = "home_off_mesh"
		return
	navigation_probe_path = NavigationServer3D.map_get_path(map, home, patrol_point, true, navigation_agent.navigation_layers)
	navigation_ready = navigation_probe_path.size() >= 2 and navigation_probe_path[-1].distance_to(patrol_point) <= 0.75
	navigation_status = "ready" if navigation_ready else "disconnected_terrain"

func reset_unit(defeated: bool, collected: bool) -> void:
	practice_replay = false
	interrupt_action()
	health_component.enabled = true
	health_component.health = 0 if defeated else health_component.max_health
	phase = "death" if defeated else "idle"
	engaged = false
	returning = false
	lost_time = 0
	velocity = Vector3.ZERO
	global_position = home
	invalidate_navigation()
	hitbox.reset_contacts()
	hitbox.enabled = not defeated
	behavior.enabled = not defeated
	collision_layer = 0 if defeated else 2
	visible = not collected
	if defeated:
		character.play("Death", 0, true)
		character.anim_tree.active = false
		animator.play("Death")
		animator.seek(animator.get_animation("Death").length, true)
		animator.pause()
	else:
		character.anim_tree.active = true
		character.play("Idle", 1, true)
	_choose_patrol_point()

func interrupt_action() -> void:
	if is_instance_valid(hit_response): hit_response.clear()
	melee.interrupt_attack()
	behavior.interrupt()
	blackboard.set_value("got_hit", false)
	blackboard.set_value("attacking", false)
	previous_fist = source.global_position

func line_clear(destination: Vector3) -> bool:
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, destination + Vector3.UP, 1, [get_rid(), target.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(delta: float) -> void:
	# Retry a pending region at 5 Hz, including while the encounter is not yet
	# earned. World pause stops this work with the rest of the enemy. Never use
	# another region's map iteration as proof of our own usable terrain.
	navigation_check_clock -= delta
	if navigation_check_clock <= 0 and home != Vector3.ZERO:
		_refresh_navigation()
		navigation_check_clock = 0.2
	if not target or not enabled_policy.is_valid() or not enabled_policy.call() or health <= 0: return
	if home == Vector3.ZERO: return
	navigation_clock -= delta
	var distance = global_position.distance_to(target.global_position)
	var perceives = distance <= 5.0 and target.global_position.distance_to(home) <= 6.0 and line_clear(target.global_position)
	update_perception(distance, perceives, delta)
	# Loss of sight during an attack closes contact immediately, before recovery.
	if melee.attacking and not perceives:
		melee.interrupt_attack()
		character.play("Idle")
		phase = "idle"
	var direction = target.global_position - global_position
	direction.y = 0
	blackboard.set_value("target", target)
	blackboard.set_value("target_dist", distance)
	blackboard.set_value("target_dir", direction.normalized())
	blackboard.set_value("perceives_player", perceives)
	blackboard.set_value("attacking", melee.attacking)
	blackboard.set_value("patrol_dist", global_position.distance_to(patrol_point))
	velocity.x = 0
	velocity.z = 0
	behavior.tick(delta)
	if not is_on_floor(): velocity.y -= 20 * delta
	else: velocity.y = 0
	move_and_slide()
	# AnimationTree is configured for physics processing; posed socket is sampled
	# once after physics and its contact window is owned by the melee event unit.
	_sample_contact()

func update_perception(_distance: float, perceives: bool, delta: float) -> void:
	# Default policy remains unchanged for every non-opted-in melee user.
	if perceives:
		lost_time = 0
		if not engaged:
			engaged = true
			behavior.interrupt()
			returning = false
			if acquired_cue.is_valid(): acquired_cue.call()
	else:
		lost_time += delta
		if engaged and (lost_time > 1.1 or target.global_position.distance_to(home) > 6.0):
			engaged = false
			returning = true
			interrupt_action()

func _sample_contact() -> void:
	var point = source.global_position
	if source.can_damage and contact_policy.is_valid():
		var shape = SphereShape3D.new()
		shape.radius = 0.26
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform.origin = point
		query.collision_mask = target.collision_layer
		query.exclude = [get_rid()]
		var hits = get_world_3d().direct_space_state.intersect_shape(query, 8)
		for hit in hits:
			if hit.collider == target and line_clear(target.global_position): contact_policy.call(source, point)
		if previous_fist.distance_to(point) > 0.01:
			var ray = PhysicsRayQueryParameters3D.create(previous_fist, point, target.collision_layer, [get_rid()])
			var hit = get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and hit.collider == target and line_clear(target.global_position): contact_policy.call(source, hit.position)
	previous_fist = point

func tick_hurt(_board: SnaielBlackboard) -> int:
	hurt_remaining -= float(blackboard.get_value("delta", 0.0))
	if hurt_remaining > 0: return SnaielBehaviorNode.RUNNING
	blackboard.set_value("got_hit", false)
	phase = "idle"
	character.execute("Idle", &"set_idle")
	return SnaielBehaviorNode.SUCCESS

func tick_attack(_board: SnaielBlackboard) -> int:
	if melee.attacking: return SnaielBehaviorNode.RUNNING
	if not engaged or not blackboard.get_value("perceives_player") or blackboard.get_value("target_dist") > 1.1: return SnaielBehaviorNode.FAILURE
	locked_direction = blackboard.get_value("target_dir")
	attack_origin = global_position
	model.rotation.y = atan2(locked_direction.x, locked_direction.z)
	melee.attack(0, true, false)
	return SnaielBehaviorNode.RUNNING

func tick_approach(_board: SnaielBlackboard) -> int:
	if returning:
		if global_position.distance_to(home) <= 0.35:
			returning = false
			return SnaielBehaviorNode.FAILURE
		_move_towards(home, "return", 1.25)
		return SnaielBehaviorNode.SUCCESS
	if not engaged: return SnaielBehaviorNode.FAILURE
	_move_towards(target.global_position, "chase", 1.25)
	return SnaielBehaviorNode.SUCCESS

func tick_patrol_wait(_board: SnaielBlackboard) -> int:
	patrol_wait += float(blackboard.get_value("delta", 0.0))
	phase = "idle"
	character.execute("Idle", &"set_idle")
	if patrol_wait < 2.0: return SnaielBehaviorNode.RUNNING
	patrol_wait = 0
	patrol_index = (patrol_index + 1) % 2
	_choose_patrol_point()
	return SnaielBehaviorNode.SUCCESS

func tick_patrol_move(_board: SnaielBlackboard) -> int:
	_move_towards(patrol_point, "patrol", 0.8)
	return SnaielBehaviorNode.SUCCESS

func _choose_patrol_point() -> void:
	var point = home + Vector3(-1.0 if patrol_index == 0 else 1.0, 0, 0)
	var support: Dictionary = ground_query.call(point) if ground_query.is_valid() else {}
	patrol_point = support.position if not support.is_empty() else home

func _move_towards(destination: Vector3, action: String, speed: float) -> void:
	if not navigation_ready:
		phase = "idle"
		character.execute("Idle", &"set_idle")
		return
	if navigation_clock <= 0:
		navigation_agent.target_position = destination
		navigation_clock = 0.2
	var next = navigation_agent.get_next_path_position()
	var direction = next - global_position
	direction.y = 0
	if direction.length() < 0.05:
		character.execute("Idle", &"set_idle")
		return
	direction = direction.normalized()
	var support: Dictionary = ground_query.call(global_position + direction * 0.5)
	if support.is_empty() or absf(support.position.y - global_position.y) > 0.7: return
	phase = action
	model.rotation.y = atan2(direction.x, direction.z)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	character.execute("Movement", &"move", [speed])

func on_attack_stage(stage: String) -> void:
	match stage:
		"anticipation":
			phase = "telegraph"
			character.play("Punch", 0.22, true)
		"strike":
			phase = "attack"
			character.set_speed(1)
			if attack_cue.is_valid(): attack_cue.call()
		"recovery": phase = "recovery"

func _attack_finished() -> void:
	phase = "idle"
	character.execute("Idle", &"set_idle")

func on_parried() -> void:
	interrupt_action()
	blackboard.set_value("got_hit", true)
	hurt_remaining = 0.6
	phase = "stagger"
	character.execute("HitAndDeath", &"hit")

func on_hurt(result: Dictionary) -> void:
	if result.outcome == "defeat": return
	interrupt_action()
	blackboard.set_value("got_hit", true)
	hurt_remaining = 0.6
	engaged = true
	phase = "hurt"
	velocity = Vector3.ZERO
	character.execute("HitAndDeath", &"hit")

func on_death() -> void:
	interrupt_action()
	behavior.enabled = false
	hitbox.enabled = false
	phase = "death"
	engaged = false
	collision_layer = 0
	velocity = Vector3.ZERO
	character.execute("HitAndDeath", &"death")
	dead.emit()

func receive_contact(damage_source: SnaielDamageSource, point: Vector3) -> Dictionary:
	return hitbox.contact(damage_source, point)

func _mcp_state() -> Dictionary:
	return {"health": health, "max_health": health_component.max_health, "phase": phase, "phase_time": clock, "engaged": engaged, "home": home, "animation": character.current_clip(), "animation_position": character.current_position(), "pose": character._mcp_state(), "practice_replay": practice_replay, "attack_instance": source.instance, "damage_window": source.can_damage, "hand_position": source.global_position, "last_contact": hitbox.last_result, "hit_response": hit_response.observation() if is_instance_valid(hit_response) else {}, "behavior": behavior._mcp_state(), "navigation_ready": navigation_ready, "navigation": navigation_state(), "target_reachable": navigation_agent.is_target_reachable(), "path_points": navigation_agent.get_current_navigation_path().size()}

func navigation_state() -> Dictionary:
	var map = navigation_agent.get_navigation_map()
	var region_valid = is_instance_valid(navigation_region)
	var region = navigation_region.get_rid() if region_valid else RID()
	var mesh = navigation_region.navigation_mesh if region_valid else null
	return {"status": navigation_status, "map": map.get_id(), "region": region.get_id(), "region_map": NavigationServer3D.region_get_map(region).get_id() if region_valid else 0, "iteration": navigation_iteration, "region_iteration": navigation_region_iteration, "vertices": mesh.vertices.size() if mesh else 0, "polygons": mesh.get_polygon_count() if mesh else 0, "probe_path": navigation_probe_path, "path": navigation_agent.get_current_navigation_path(), "target": navigation_agent.target_position, "owns_region": owns_navigation_region}
