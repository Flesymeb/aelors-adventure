extends Node3D
## Optional CH02 branch only. Fixed encounters and CH01 retain their owners.
const GROUND = preload("res://world/map02_ground.gd")
const MELEE = preload("res://combat/Map02DynamicMelee.tscn")
const RANGED = preload("res://combat/Map02DynamicRanged.tscn")
const AMBUSHER = preload("res://combat/Map02DynamicAmbusher.tscn")
const AMBUSH_MODELS = [preload("res://assets/ambush/ambusher_a.gltf"), preload("res://assets/ambush/ambusher_b.gltf")]
const REVISIT := 120.0
const GROUP_CAP := 2
const ACTOR_CAP := 2
const ANCHORS = [Vector2(-7,50), Vector2(-7,53)]
const RETURN_XZ = Vector2(3,50)
const RETURN_ROUTE = [Vector2(-3,50), RETURN_XZ, Vector2(3,46), GROUND.ROADBLOCK, GROUND.ENTRY]
const BRANCH_MIN = Vector2(-10,46)
const BRANCH_MAX = Vector2(0,57)
var world: Node3D
var state: Node
var enemies: Array[CharacterBody3D] = []
var staged: Array[CharacterBody3D] = []
var pickups: Dictionary = {}
var death_remaining: Dictionary = {}
var navigation_map: RID
var navigation_region: NavigationRegion3D
var initialized := false
var grounded: bool:
	get: return initialized
var staging_time := 0.0
var staging_map_iteration := 0
var scan_time := 0.0
var recovery_hold := 15.0
var pickup_delay := 0.75
var restore_generation := 0
var last_placement := "initializing"
var corridor_samples := 0
var navigation_cells := 0
var rng := RandomNumberGenerator.new()

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	rng.randomize()
	navigation_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(navigation_map, true)
	restore_history.call_deferred()

func _exit_tree() -> void:
	if navigation_map.is_valid(): NavigationServer3D.free_rid(navigation_map)

func fixed_owners() -> Array:
	var owners := []
	for key in ["bridge_encounter", "pressure_encounter", "ambush_encounter", "line_encounter"]:
		var owner = world.get(key)
		if is_instance_valid(owner): owners.append(owner)
	return owners

func fixed_busy() -> bool:
	for owner in fixed_owners():
		if not owner.grounded or not owner.can_save(): return true
	return false

func protected_xz(xz: Vector2) -> bool:
	for anchor in [GROUND.ENTRY, GROUND.RETURN, GROUND.ROUTE_RECORD, GROUND.RECORD_APPROACH, GROUND.LINE_RECORD, GROUND.LINE_SUPPLY, GROUND.LN01_CLUE, GROUND.LN01_SUPPLY, GROUND.LN01_LOCATION, GROUND.LN01_PASSAGE, GROUND.LN01_EXIT]:
		if xz.distance_to(anchor) < 8.0: return true
	for anchor in GROUND.ROADBLOCK_ANCHORS + GROUND.PRESSURE_ANCHORS + GROUND.AMBUSH_ANCHORS + GROUND.LINE_ANCHORS:
		if xz.distance_to(anchor) < 10.0: return true
	return false

func protected_player() -> bool:
	return protected_xz(Vector2(world.player.global_position.x, world.player.global_position.z))

func combat_allowed() -> bool:
	return initialized and not state.core_closed and state.current_map == state.MAP02 and state.cp02_claimed and state.mf01_acquired and state.lives > 0 and not state.recovery_pending and not state.conversation_active and world.pause_owners.is_empty() and not world.training.player_locked() and world.training.protection <= 0 and recovery_hold <= 0 and not protected_player() and not fixed_busy()

func registry() -> Dictionary:
	var result := {}
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.activated and enemy.health > 0 and (enemy.archetype != "ambusher" or enemy.revealed): result[enemy] = enemy.hitbox
	return result

func active_count() -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.activated and enemy.health > 0: count += 1
	return count

func reveal(origin: Vector3) -> int:
	if not combat_allowed(): return 0
	var count := 0
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.archetype != "ambusher" or not enemy.activated or enemy.revealed or enemy.health <= 0 or origin.distance_to(enemy.global_position) > 7: continue
		var ray := PhysicsRayQueryParameters3D.create(origin + Vector3.UP, enemy.global_position + Vector3.UP, 1, [world.player.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		if enemy.reveal():
			count += 1
			world.training.feedback.spark(enemy.global_position + Vector3.UP, Color(0.4,0.85,1))
	if count > 0:
		world.training.feedback.sound(preload("res://assets/dialogue/sounds/Audio/confirmation_001.ogg"), -19, 0.75)
		world.training.tell("岔路伏击者已显形 · 看清抬手突进，可闪避、格挡或沿原路撤离", 5)
		world.training.commit()
	return count

func telegraph(actor: CharacterBody3D) -> void:
	world.training.feedback.spark(actor.global_position + Vector3.UP * 1.5, Color(1,0.62,0.25))

func ambusher_prompt() -> String:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.archetype == "ambusher" and enemy.activated and enemy.health > 0 and world.player.global_position.distance_to(enemy.home) < 10:
			return "[3] 旧灯 · [F] 显形 · 7 米范围（可绕行）" if not enemy.revealed else "伏击者抬手后突进 · 闪避或格挡，再反击"
	return ""

func can_save() -> bool:
	if not staged.is_empty(): return false
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.can_save(): return false
	return true

func interrupt() -> void:
	for enemy in enemies + staged:
		if is_instance_valid(enemy): enemy.interrupt_action()

func attack_slot_available(requester: CharacterBody3D) -> bool:
	if not combat_allowed(): return false
	var occupied := 0
	for enemy in enemies:
		if enemy == requester or not is_instance_valid(enemy) or enemy.health <= 0: continue
		if (enemy.archetype in ["melee", "ambusher"] and enemy.melee.attacking) or (enemy.archetype == "ranged" and enemy.action.executing_action): occupied += 1
	return occupied < 2

func spawn_reason() -> String:
	if not initialized or not world.training.grounded or not world.bow_training.grounded: return "terrain_initializing"
	if state.current_map != state.MAP02 or not state.cp02_claimed or not state.roadblock_defeated() or not state.mf01_acquired: return "route_prerequisites"
	if state.conversation_active or not world.pause_owners.is_empty(): return "dialogue_or_pause"
	if recovery_hold > 0 or state.recovery_pending or world.training.protection > 0: return "checkpoint_return"
	if state.lives <= 0 or world.training.player_locked(): return "player_unavailable"
	if protected_player(): return "protected_interaction"
	if fixed_busy(): return "fixed_combat"
	if not world.element_abilities.can_save() or world.training.phase != "idle" or world.bow_training.pending_demo: return "active_action"
	if not staged.is_empty() or active_count() > 0: return "density"
	for record in state.meadow_dynamic_instances.values():
		if record.status == "active": return "retained_active_instance"
		if record.status == "pending": return "pending_pickup"
	if state.meadow_dynamic_groups >= GROUP_CAP: return "visit_group_cap"
	if state.meadow_dynamic_remaining > 0: return "revisit_delay"
	var point := Vector2(world.player.global_position.x, world.player.global_position.z)
	if point.x < -16 or point.x > 2 or point.y < 44 or point.y > 59: return "outside_branch"
	return "eligible"

func clear_volume(point: Vector3, excludes: Array = [], mask := 3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = point + Vector3.UP * 0.98
	query.collision_mask = mask
	var exclusions: Array[RID] = []
	exclusions.assign(excludes)
	query.exclude = exclusions
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func support_point(xz: Vector2, excludes: Array = [], volume := true) -> Dictionary:
	var hit: Dictionary = GROUND.support(world, xz, excludes)
	if hit.is_empty() or (volume and not clear_volume(hit.position, excludes)): return {}
	return hit

func corridor_clear(route: Array, excludes: Array = []) -> bool:
	var previous := Vector3.INF
	corridor_samples = 0
	for k in range(route.size() - 1):
		var start: Vector2 = route[k]
		var end: Vector2 = route[k + 1]
		var count := maxi(1, ceili(start.distance_to(end) / 0.4))
		for index in range(count + 1):
			var hit := support_point(start.lerp(end, float(index) / count), excludes)
			if hit.is_empty() or (previous.is_finite() and absf(hit.position.y - previous.y) > 0.32): return false
			previous = hit.position
			corridor_samples += 1
	return true

func return_corridor(xz: Vector2, excludes: Array = []) -> bool:
	var route := [xz]
	route.append_array(RETURN_ROUTE)
	return corridor_clear(route, excludes)

func outside_camera(point: Vector3) -> bool:
	for x in [-0.65, 0.65]:
		for y in [0.0, 1.9]:
			for z in [-0.65, 0.65]:
				if world.player.camera.is_position_in_frustum(point + Vector3(x, y, z)): return false
	return true

func qualifying_point(xz: Vector2) -> Dictionary:
	if xz.x < BRANCH_MIN.x or xz.x > BRANCH_MAX.x or xz.y < BRANCH_MIN.y or xz.y > BRANCH_MAX.y or protected_xz(xz): return {}
	var excluded: Array[RID] = [world.player.get_rid()]
	var hit := support_point(xz, excluded)
	if hit.is_empty() or not return_corridor(xz, excluded): return {}
	var distance: float = world.player.global_position.distance_to(hit.position)
	if distance < 10 or distance > 27 or not outside_camera(hit.position): return {}
	for owner in fixed_owners():
		for enemy in owner.enemies:
			if enemy.health > 0 and enemy.global_position.distance_to(hit.position) < 12: return {}
	return hit

func build_navigation(excludes: Array[RID]) -> void:
	if is_instance_valid(navigation_region): navigation_region.queue_free()
	# One scoped terrain-derived region, with no new collision bodies/floors.
	var mesh := NavigationMesh.new()
	var vertices := PackedVector3Array()
	var cells := {}
	for z in range(25, 58):
		for x in range(-10, 5):
			var hit := support_point(Vector2(x, z), excludes)
			if hit.is_empty(): continue
			cells[Vector2i(x,z)] = vertices.size()
			vertices.append(hit.position + Vector3.UP * 0.04)
	mesh.vertices = vertices
	navigation_cells = cells.size()
	for z in range(25, 57):
		for x in range(-10, 4):
			var keys := [Vector2i(x,z),Vector2i(x+1,z),Vector2i(x+1,z+1),Vector2i(x,z+1)]
			if not (cells.has(keys[0]) and cells.has(keys[1]) and cells.has(keys[2]) and cells.has(keys[3])): continue
			var clear := true
			for edge in 4:
				var a: Vector2i = keys[edge]
				var b: Vector2i = keys[(edge+1)%4]
				if not corridor_clear([Vector2(a),Vector2(b)], excludes): clear = false; break
			if clear: mesh.add_polygon(PackedInt32Array([cells[keys[0]],cells[keys[3]],cells[keys[2]],cells[keys[1]]]))
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "MeadowDynamicNavigation"
	navigation_region.navigation_mesh = mesh
	add_child(navigation_region)
	navigation_region.global_transform = Transform3D.IDENTITY
	navigation_region.set_navigation_map(navigation_map)

func new_unit(point: Vector3, id: String, archetype: String, variant := 0) -> CharacterBody3D:
	var scene: PackedScene = AMBUSHER if archetype == "ambusher" else (RANGED if archetype == "ranged" else MELEE)
	var enemy: CharacterBody3D = scene.instantiate()
	if archetype == "ambusher":
		var old := enemy.get_node("Model")
		enemy.remove_child(old)
		old.free()
		var model: Node3D = AMBUSH_MODELS[variant].instantiate()
		model.name = "Model"
		enemy.add_child(model)
		enemy.variant = variant
		enemy.display_name = "岔路伏击者 · 赤角" if variant == 0 else "岔路伏击者 · 铁颚"
	enemy.encounter = self
	enemy.stable_id = id
	enemy.name = id
	enemy.position = point + Vector3.UP * 0.08
	add_child(enemy)
	enemy.home = enemy.global_position
	enemy.navigation_agent.set_navigation_map(navigation_map)
	return enemy

func stage_wave() -> void:
	if spawn_reason() != "eligible": return
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or enemy.health <= 0:
			if is_instance_valid(enemy): enemy.queue_free()
			enemies.erase(enemy)
	var start := rng.randi_range(0, ANCHORS.size()-1)
	for index in ANCHORS.size():
		var anchor: Vector2 = ANCHORS[(start+index)%ANCHORS.size()]
		var first := qualifying_point(anchor)
		if first.is_empty(): continue
		var points := [first.position]
		# First opportunity is mixed when two safe homes are available.
		if state.meadow_dynamic_groups == 0 or rng.randi_range(1,ACTOR_CAP) == 2:
			var second := qualifying_point(anchor + Vector2(0,1.7))
			if not second.is_empty(): points.append(second.position)
		for i in points.size():
			var archetype := "ranged" if i == 1 else ("melee" if points.size() == 2 or rng.randi_range(0,1) == 0 else "ranged")
			# Preserve the first mixed opportunity; the later group uses both
			# retained silhouettes when two safe homes qualify.
			if state.meadow_dynamic_groups > 0: archetype = "ambusher"
			staged.append(new_unit(points[i], "ch02_dynamic_%d" % (state.meadow_dynamic_serial+i+1), archetype, i if points.size() == 2 else rng.randi_range(0,1)))
		var excludes: Array[RID] = [world.player.get_rid()]
		for enemy in staged: excludes.append(enemy.get_rid())
		build_navigation(excludes)
		staging_map_iteration = NavigationServer3D.map_get_iteration_id(navigation_map)
		for enemy in staged:
			enemy.share_navigation(navigation_region)
			if enemy.archetype != "ranged": enemy._choose_patrol_point()
		staging_time = 0
		last_placement = "navigation_synchronizing"
		return
	last_placement = "no_eligible_point"

func finish_staging(delta: float) -> void:
	staging_time += delta
	# A newly uploaded region can report its own iteration before the map has
	# incorporated it. An old map iteration must not qualify this new group.
	var ready: bool = staging_time >= 0.05 and is_instance_valid(navigation_region) and NavigationServer3D.region_get_iteration_id(navigation_region.get_rid()) > 0 and NavigationServer3D.map_get_iteration_id(navigation_map) > staging_map_iteration
	if not ready and staging_time < 5: return
	var excludes: Array[RID] = [world.player.get_rid()]
	for enemy in staged: excludes.append(enemy.get_rid())
	var valid: bool = ready and combat_allowed() and state.meadow_dynamic_remaining <= 0 and state.meadow_dynamic_groups < GROUP_CAP and active_count() == 0
	var return_hit := support_point(RETURN_XZ, excludes)
	if return_hit.is_empty(): valid = false
	var paths_ready := ready
	for enemy in staged:
		if not clear_volume(enemy.home - Vector3.UP*0.08, excludes) or not outside_camera(enemy.home) or enemy.home.distance_to(world.player.global_position) < 10 or protected_xz(Vector2(enemy.home.x,enemy.home.z)) or not return_corridor(Vector2(enemy.home.x,enemy.home.z),excludes): valid = false
		if ready and not return_hit.is_empty():
			var path := NavigationServer3D.map_get_path(navigation_map, enemy.home, return_hit.position, true)
			if path.size() < 2 or path[-1].distance_to(return_hit.position) > 0.75: paths_ready = false
	# Region upload and map path synchronization are separate native phases.
	# Keep the invisible group staged until its actual route becomes usable.
	if valid and not paths_ready and staging_time < 5.0: return
	valid = valid and paths_ready
	if valid:
		var previous: Dictionary = state.meadow_dynamic_instances.duplicate(true)
		var serial: int = state.meadow_dynamic_serial
		var groups: int = state.meadow_dynamic_groups
		var remaining: float = state.meadow_dynamic_remaining
		for enemy in staged:
			state.meadow_dynamic_serial += 1
			state.meadow_dynamic_instances[enemy.stable_id] = {"chapter":"CH02","archetype":enemy.archetype,"instance_id":enemy.stable_id,"home":enemy.home,"position":enemy.home,"hp":enemy.health_component.max_health,"status":"active","xp":10 if enemy.archetype == "melee" else 15,"loot":[]}
			if enemy.archetype == "ambusher":
				state.meadow_dynamic_instances[enemy.stable_id].merge({"revealed":false,"variant":enemy.variant})
		state.meadow_dynamic_groups += 1
		state.meadow_dynamic_remaining = REVISIT
		valid = world.training.commit()
		if not valid:
			state.meadow_dynamic_instances = previous
			state.meadow_dynamic_serial = serial
			state.meadow_dynamic_groups = groups
			state.meadow_dynamic_remaining = remaining
	if valid:
		for enemy in staged:
			enemy.restore_record(state.meadow_dynamic_instances[enemy.stable_id])
			enemies.append(enemy)
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
	for enemy in enemies + staged:
		if is_instance_valid(enemy): enemy.queue_free()
	for pickup in pickups.values():
		if is_instance_valid(pickup): pickup.queue_free()
	enemies.clear()
	staged.clear()
	pickups.clear()
	death_remaining.clear()
	recovery_hold = 15
	pickup_delay = 0.75
	for attempt in 120:
		await get_tree().physics_frame
		if generation != restore_generation or not is_instance_valid(world) or is_queued_for_deletion(): return
		if not GROUND.support(world, GROUND.ENTRY).is_empty(): break
		if attempt == 119: return
	for id in state.meadow_dynamic_instances:
		var record: Dictionary = state.meadow_dynamic_instances[id]
		if record.status == "pending": show_pickup(id)
		elif record.status == "active":
			var hit := support_point(Vector2(record.home.x,record.home.z), [world.player.get_rid()])
			if hit.is_empty(): continue
			var enemy := new_unit(hit.position,id,record.archetype,record.get("variant",0))
			var restored := record.duplicate(true)
			restored.home = enemy.home
			var position_hit := support_point(Vector2(record.position.x,record.position.z),[world.player.get_rid(),enemy.get_rid()])
			restored.position = position_hit.position + Vector3.UP*0.08 if not position_hit.is_empty() else enemy.home
			enemy.restore_record(restored)
			enemies.append(enemy)
	if not enemies.is_empty():
		var excludes: Array[RID] = [world.player.get_rid()]
		for enemy in enemies: excludes.append(enemy.get_rid())
		build_navigation(excludes)
		for enemy in enemies:
			enemy.share_navigation(navigation_region)
			if enemy.archetype != "ranged": enemy._choose_patrol_point()
	initialized = true
	last_placement = "restored"

func record_unit(enemy: CharacterBody3D) -> void:
	if not state.meadow_dynamic_instances.has(enemy.stable_id): return
	var record: Dictionary = state.meadow_dynamic_instances[enemy.stable_id]
	if record.status != "active": return
	record.position = enemy.global_position
	record.hp = enemy.health
	if enemy.archetype == "ambusher": record.revealed = enemy.revealed

func settle_defeat(enemy: CharacterBody3D) -> void:
	if not state.meadow_dynamic_instances.has(enemy.stable_id): return
	var record: Dictionary = state.meadow_dynamic_instances[enemy.stable_id]
	if record.status != "active": return
	var drop: Dictionary = preload("res://inventory/loot_adapter.gd").roll()
	record.hp = 0.0
	record.position = enemy.global_position
	record.status = "pending"
	record.loot = [{"id":drop.id,"count":drop.quantity}] if not drop.is_empty() else []
	state.meadow_dynamic_remaining = REVISIT
	death_remaining[enemy.stable_id] = 1.4
	world.training.commit()
	show_pickup(enemy.stable_id)
	pickup_delay = 0.75
	world.training.tell("草甸游荡者已击败 · 金色残响保留经验与掉落",4)

func show_pickup(id: String) -> void:
	if pickups.has(id): return
	var record: Dictionary = state.meadow_dynamic_instances[id]
	if record.status != "pending": return
	var hit: Dictionary = GROUND.support(world,Vector2(record.position.x,record.position.z))
	if hit.is_empty(): return
	var remnant := preload("res://reward_feedback.gd").make_remnant()
	add_child(remnant)
	remnant.global_position = hit.position + Vector3.UP*0.08
	if not record.loot.is_empty():
		var item := Sprite3D.new()
		item.texture = load(state.inventory.PROTOSET.data[record.loot[0].id].image)
		item.pixel_size = 0.006
		item.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		item.position.y = 0.65
		item.modulate = Color(1,0.82,0.3)
		remnant.add_child(item)
	pickups[id] = remnant

func collect(id: String) -> bool:
	if not state.meadow_dynamic_instances.has(id) or state.meadow_dynamic_instances[id].status != "pending": return false
	var xp: int = state.experience
	var bag: Dictionary = state.inventory.snapshot()
	if not state.collect_meadow_reward(id):
		world.training.tell("背包无法接收 · 使用物品后再来，经验与掉落仍保留",4)
		pickup_delay = 1
		return false
	if not world.training.commit():
		state.meadow_dynamic_instances[id].status = "pending"
		state.experience = xp
		state.bag_history = bag
		state.inventory.restore()
		state.progression_changed.emit()
		return false
	if pickups.has(id): pickups[id].queue_free(); pickups.erase(id)
	var reward: int = state.meadow_dynamic_instances[id].xp
	world.training.feedback.reward(reward)
	world.training.tell("经验与掉落已拾取 · +%d XP" % reward,4)
	return true

func _physics_process(delta: float) -> void:
	if state.core_closed: return
	if not initialized: return
	recovery_hold = maxf(0,recovery_hold-delta)
	pickup_delay = maxf(0,pickup_delay-delta)
	if state.current_map == state.MAP02 and state.cp02_claimed and not state.conversation_active and not state.recovery_pending and state.lives > 0 and world.pause_owners.is_empty(): state.meadow_dynamic_remaining = maxf(0,state.meadow_dynamic_remaining-delta)
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		record_unit(enemy)
		if enemy.health <= 0:
			death_remaining[enemy.stable_id] = maxf(0,death_remaining.get(enemy.stable_id,0.0)-delta)
			enemy.visible = death_remaining[enemy.stable_id] > 0
	if not combat_allowed(): interrupt()
	if not staged.is_empty(): finish_staging(delta); return
	if not world.training.player_locked() and not state.conversation_active and not state.recovery_pending and state.lives > 0 and world.pause_owners.is_empty() and recovery_hold <= 0 and pickup_delay <= 0:
		for id in pickups.keys():
			var remnant: Node3D = pickups[id]
			if world.player.global_position.distance_to(remnant.global_position) > 1.65: continue
			var query := PhysicsRayQueryParameters3D.create(world.player.global_position+Vector3.UP,remnant.global_position+Vector3.UP*0.65,1,[world.player.get_rid()])
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): collect(id)
	scan_time -= delta
	if scan_time > 0: return
	scan_time = 3
	if spawn_reason() == "eligible": stage_wave()

func _mcp_state() -> Dictionary:
	var ready: bool = is_instance_valid(world) and is_instance_valid(state) and initialized
	var actors := []
	for enemy in enemies:
		if is_instance_valid(enemy): actors.append(enemy._mcp_state())
	return {"ready":ready,"combat_allowed":combat_allowed() if ready else false,"eligibility":spawn_reason() if ready else "initializing","remaining":state.meadow_dynamic_remaining if ready else null,"recovery_hold":recovery_hold,"serial":state.meadow_dynamic_serial if ready else null,"groups":state.meadow_dynamic_groups if ready else null,"group_cap":GROUP_CAP,"instances":state.meadow_dynamic_instances.duplicate(true) if ready else null,"pickups":pickups.keys(),"active_count":active_count(),"combat_count":registry().size(),"staged_count":staged.size(),"placement":last_placement,"navigation_cells":navigation_cells,"corridor_samples":corridor_samples,"enemies":actors}
