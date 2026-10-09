extends Node3D
## Optional CH01 melee only. Fixed bridge patrols retain their own owner/history.
const GROUND = preload("res://forest_ground.gd")
const UNIT = preload("res://combat/DynamicEnemy.tscn")
const REVISIT := 120.0
const LIMIT := 2
# Inspected bridge approach, away from teaching targets and fixed patrol homes.
const ANCHORS = [Vector2(126, 122), Vector2(130, 122)]
const RETURN_XZ = Vector2(126, 118)
const RETURN_ROUTE = [Vector2(126,118),Vector2(126,114),Vector2(124,113),Vector2(123,112),Vector2(123,111)]
var world: Node3D
var state: Node
var enemies: Array[CharacterBody3D] = []
var pickups: Dictionary = {}
var staged: Array[CharacterBody3D] = []
var staging_time := 0.0
var scan_time := 0.0
var recovery_hold := 15.0
var pickup_delay := 0.75
var initialized := false
var restore_generation := 0
var eligibility_reason := "initializing"
var last_placement := ""
var rng := RandomNumberGenerator.new()
var navigation_map: RID

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	rng.randomize()
	# Separate scoped map: no duplicate polygons over the fixed combat regions.
	navigation_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(navigation_map, true)
	restore_history.call_deferred()

func _exit_tree() -> void:
	if navigation_map.is_valid(): NavigationServer3D.free_rid(navigation_map)

func registry() -> Dictionary:
	var result := {}
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.activated and enemy.health > 0: result[enemy] = enemy.hitbox
	return result

func can_save() -> bool:
	for enemy in enemies:
		if is_instance_valid(enemy) and (enemy.engaged or enemy.melee.attacking): return false
	return staged.is_empty()

func interrupt() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.interrupt_action()

func protected_player() -> bool:
	if world.channel_guards and world.channel_guards.protected_player(): return true
	var xz := Vector2(world.player.global_position.x, world.player.global_position.z)
	for anchor in [GROUND.SPAWN, GROUND.ISHA, GROUND.HERS, GROUND.RONEN, Vector2(124,116), Vector2(130,130)]:
		if xz.distance_to(anchor) < 4.0: return true
	return false

func combat_allowed() -> bool:
	return initialized and state.element_practice_complete and not state.conversation_active and state.lives > 0 and world.pause_owners.is_empty() and not state.recovery_pending and recovery_hold <= 0 and not protected_player() and not world.training.monster.engaged and world.training.sim_phase == "idle" and world.bridge_encounter.can_save() and (world.channel_guards == null or world.channel_guards.can_save())

func spawn_reason() -> String:
	if not initialized or not world.training.grounded or not world.bow_training.grounded: return "terrain_initializing"
	if not state.element_practice_complete: return "teaching"
	if state.conversation_active or not world.pause_owners.is_empty(): return "dialogue_or_pause"
	if recovery_hold > 0 or state.recovery_pending or world.training.protection > 0: return "checkpoint_return"
	if state.lives <= 0 or world.training.player_locked(): return "player_unavailable"
	if protected_player(): return "protected_interaction"
	if world.training.monster.engaged or world.training.sim_phase != "idle" or not world.bridge_encounter.can_save() or (world.channel_guards and not world.channel_guards.can_save()): return "fixed_combat"
	if not world.element_abilities.can_save() or world.training.phase != "idle" or world.bow_training.pending_demo: return "active_action"
	if not staged.is_empty() or not registry().is_empty(): return "density"
	if not pickups.is_empty(): return "pending_pickup"
	if state.dynamic_remaining > 0: return "revisit_delay"
	var point: Vector3 = world.player.global_position
	if point.x < 118 or point.x > 134 or point.z < 108 or point.z > 128: return "outside_approach"
	return "eligible"

func clear_volume(point: Vector3, excludes: Array[RID] = []) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = point + Vector3.UP * 0.98
	query.collision_mask = 3
	query.exclude = excludes
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func support_point(xz: Vector2, excludes: Array[RID] = []) -> Dictionary:
	var hit: Dictionary = GROUND.support(world, xz, excludes)
	if hit.is_empty() or not clear_volume(hit.position, excludes): return {}
	return hit

func return_corridor(xz: Vector2) -> bool:
	# Full standing volume, support and bounded rise along the inspected plank
	# entrance back to the village; the eastern riverbank is not a return route.
	var route := [xz]
	route.append_array(RETURN_ROUTE)
	var previous := Vector3.INF
	for k in range(route.size()-1):
		var start: Vector2 = route[k]
		var end: Vector2 = route[k+1]
		var count := maxi(1, ceili(start.distance_to(end) / 0.5))
		for i in range(count + 1):
			var hit := support_point(start.lerp(end, float(i) / count), [world.player.get_rid()])
			if hit.is_empty(): return false
			if previous.is_finite() and absf(hit.position.y - previous.y) > 0.32: return false
			previous = hit.position
	return true

func outside_camera(point: Vector3) -> bool:
	# Conservative frustum test on the complete actor envelope, even if occluded.
	for x in [-0.65, 0.65]:
		for y in [0.0, 1.9]:
			for z in [-0.65, 0.65]:
				if world.player.camera.is_position_in_frustum(point + Vector3(x,y,z)): return false
	return true

func qualifying_point(xz: Vector2) -> Dictionary:
	var hit := support_point(xz)
	if hit.is_empty() or not return_corridor(xz): return {}
	var distance: float = world.player.global_position.distance_to(hit.position)
	if distance < 10.0 or distance > 27.0 or not outside_camera(hit.position): return {}
	for anchor in [GROUND.ENCOUNTER, GROUND.RONEN, Vector2(124,116), Vector2(130,130)]:
		if xz.distance_to(anchor) < 6.0: return {}
	for enemy in world.bridge_encounter.enemies:
		if enemy.health > 0 and enemy.global_position.distance_to(hit.position) < 10.0: return {}
	return hit

func new_unit(point: Vector3, id: String) -> CharacterBody3D:
	var enemy: CharacterBody3D = UNIT.instantiate()
	enemy.encounter = self
	enemy.stable_id = id
	enemy.name = id
	enemy.position = point + Vector3.UP * 0.08
	add_child(enemy)
	enemy.home = enemy.global_position
	enemy.navigation_agent.set_navigation_map(navigation_map)
	return enemy

func stage_wave() -> void:
	for enemy in enemies.duplicate():
		if enemy.health <= 0:
			enemy.queue_free()
			enemies.erase(enemy)
	var choices := ANCHORS.duplicate()
	# Random selection is bounded. Failed eligibility postpones the entire group.
	var start := rng.randi_range(0, choices.size()-1)
	for index in choices.size():
		var anchor: Vector2 = choices[(start + index) % choices.size()]
		var hit := qualifying_point(anchor)
		if hit.is_empty(): continue
		var points := [hit.position]
		if rng.randi_range(1,LIMIT) == 2:
			var second := qualifying_point(anchor + Vector2(0,1.5))
			if not second.is_empty(): points.append(second.position)
		for i in points.size():
			staged.append(new_unit(points[i], "ch01_dynamic_%d" % (state.dynamic_serial + i + 1)))
		staged[0].build_navigation()
		for i in range(1,staged.size()): staged[i].share_navigation(staged[0].navigation_region)
		staging_time = 0
		last_placement = "navigation_synchronizing"
		return
	last_placement = "no_eligible_point"

func finish_staging(delta: float) -> void:
	staging_time += delta
	var ready := true
	for enemy in staged:
		if not enemy.navigation_ready: ready = false
	if not ready and staging_time < 5.0: return
	# Recheck camera, occupied volume and player safety after asynchronous sync.
	var excludes: Array[RID] = []
	for enemy in staged: excludes.append(enemy.get_rid())
	var valid: bool = ready and combat_allowed() and state.dynamic_remaining <= 0 and registry().is_empty()
	var return_hit: Dictionary = GROUND.support(world, RETURN_XZ)
	if return_hit.is_empty(): valid = false
	for enemy in staged:
		if not clear_volume(enemy.home - Vector3.UP*0.08, excludes) or not outside_camera(enemy.home) or enemy.home.distance_to(world.player.global_position) < 10.0: valid = false
		if ready and not return_hit.is_empty():
			var path := NavigationServer3D.map_get_path(navigation_map, enemy.home, return_hit.position, true)
			if path.size() < 2 or path[-1].distance_to(return_hit.position) > 0.75: valid = false
	if valid:
		for enemy in staged:
			state.dynamic_serial += 1
			state.dynamic_instances[enemy.stable_id] = {"home":enemy.home,"position":enemy.home,"hp":enemy.health_component.max_health,"status":"active","xp":10}
			enemy.activated = true
			enemy.collision_layer = 2
			enemy.visible = true
			enemies.append(enemy)
		state.dynamic_remaining = REVISIT
		world.training.commit()
		last_placement = "spawned"
	else:
		for enemy in staged: enemy.queue_free()
		last_placement = "qualification_postponed"
	staged.clear()
	scan_time = 3.0

func restore_history() -> void:
	restore_generation += 1
	var generation := restore_generation
	initialized = false
	interrupt()
	for enemy in enemies: if is_instance_valid(enemy): enemy.queue_free()
	for enemy in staged: if is_instance_valid(enemy): enemy.queue_free()
	for pickup in pickups.values(): if is_instance_valid(pickup): pickup.queue_free()
	enemies.clear()
	staged.clear()
	pickups.clear()
	recovery_hold = 15.0
	pickup_delay = 0.75
	# Wait for real authored collision, without changing persisted instance facts.
	for attempt in 120:
		await get_tree().physics_frame
		if generation != restore_generation or not is_instance_valid(world) or is_queued_for_deletion(): return
		if not GROUND.support(world, RETURN_XZ).is_empty(): break
		if attempt == 119: return
	for id in state.dynamic_instances:
		var record: Dictionary = state.dynamic_instances[id]
		if record.status == "pending":
			show_pickup(id)
		elif record.status == "active":
			var hit := support_point(Vector2(record.home.x,record.home.z), [world.player.get_rid()])
			if hit.is_empty(): continue
			var enemy := new_unit(hit.position,id)
			enemy.home = record.home
			if enemies.is_empty(): enemy.build_navigation()
			else: enemy.share_navigation(enemies[0].navigation_region)
			# Physics owns restored placement; never materialize through an obstacle.
			var restored: Dictionary = record.duplicate(true)
			var position_hit := support_point(Vector2(record.position.x,record.position.z),[world.player.get_rid(),enemy.get_rid()])
			restored.position = position_hit.position + Vector3.UP*0.08 if not position_hit.is_empty() else enemy.home
			enemy.restore_record(restored)
			enemies.append(enemy)
	initialized = true

func record_unit(enemy: CharacterBody3D) -> void:
	if not state.dynamic_instances.has(enemy.stable_id): return
	var record: Dictionary = state.dynamic_instances[enemy.stable_id]
	if record.status != "active": return
	record.position = enemy.global_position
	record.hp = enemy.health

func settle_defeat(enemy: CharacterBody3D) -> void:
	if not state.dynamic_instances.has(enemy.stable_id): return
	var record: Dictionary = state.dynamic_instances[enemy.stable_id]
	if record.status != "active": return
	record.hp = 0.0
	record.position = enemy.global_position
	record.status = "pending"
	state.dynamic_remaining = REVISIT
	# Defeat stores reward ownership. XP is granted only at collectible settlement.
	world.training.commit()
	show_pickup(enemy.stable_id)
	pickup_delay = 0.75

func show_pickup(id: String) -> void:
	if pickups.has(id): return
	var record: Dictionary = state.dynamic_instances[id]
	var hit: Dictionary = GROUND.support(world,Vector2(record.position.x,record.position.z))
	if hit.is_empty(): return
	var remnant := preload("res://reward_feedback.gd").make_remnant()
	add_child(remnant)
	remnant.global_position = hit.position + Vector3.UP*0.08
	pickups[id] = remnant

func collect(id: String) -> bool:
	if not state.collect_dynamic_xp(id): return false
	if not world.training.commit():
		state.dynamic_instances[id].status = "pending"
		state.experience -= 10
		return false
	if pickups.has(id): pickups[id].queue_free(); pickups.erase(id)
	for enemy in enemies:
		if enemy.stable_id == id: enemy.visible = false
	world.training.feedback.reward(10)
	world.training.tell("经验残响已拾取 · +10 XP",4)
	return true

func _physics_process(delta: float) -> void:
	if not initialized: return
	recovery_hold = maxf(0,recovery_hold-delta)
	pickup_delay = maxf(0,pickup_delay-delta)
	if state.element_practice_complete and not state.conversation_active and not state.recovery_pending and state.lives > 0:
		state.dynamic_remaining = maxf(0,state.dynamic_remaining-delta)
	for enemy in enemies: record_unit(enemy)
	if not combat_allowed(): interrupt()
	if not staged.is_empty(): finish_staging(delta); return
	if not world.training.player_locked() and not state.conversation_active and world.pause_owners.is_empty() and pickup_delay <= 0:
		for id in pickups.keys():
			var remnant: Node3D = pickups[id]
			if world.player.global_position.distance_to(remnant.global_position) > 1.65: continue
			var query := PhysicsRayQueryParameters3D.create(world.player.global_position+Vector3.UP, remnant.global_position+Vector3.UP*0.65,1,[world.player.get_rid()])
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): collect(id)
	scan_time -= delta
	if scan_time > 0: return
	scan_time = 3.0
	eligibility_reason = spawn_reason()
	if eligibility_reason == "eligible": stage_wave()

func _mcp_state() -> Dictionary:
	return {"ready":initialized,"eligibility":spawn_reason() if is_instance_valid(world) and is_instance_valid(state) and initialized else "initializing","remaining":state.dynamic_remaining if is_instance_valid(state) else null,"recovery_hold":recovery_hold,"serial":state.dynamic_serial if is_instance_valid(state) else null,"instances":state.dynamic_instances.duplicate(true) if is_instance_valid(state) else null,"pickups":pickups.keys(),"active_count":registry().size(),"staged_count":staged.size(),"placement":last_placement}
