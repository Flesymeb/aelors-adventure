extends Node3D
const GROUND = preload("res://forest_ground.gd")
const ANCHORS = [Vector2(131,137),Vector2(135,137)]
var world: Node3D
var state: Node
var enemies: Array[CharacterBody3D] = []
var pickups: Dictionary = {}
var grounded = false
var pickup_delay = 0.0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	for i in 2:
		var enemy = preload("res://combat/BridgeEnemy.tscn").instantiate()
		enemy.name = "BridgePatrolA" if i == 0 else "BridgePatrolB"
		enemy.stable_id = "bridge_patrol_a" if i == 0 else "bridge_patrol_b"
		enemy.display_name = "桥边巡守 · 东哨" if i == 0 else "桥边巡守 · 西哨"
		enemy.encounter = self
		add_child(enemy)
		enemies.append(enemy)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world) or world.is_queued_for_deletion(): return
		# Qualify both anchors even if the first is rejected.
		var first := GROUND.place(world,enemies[0],ANCHORS[0])
		var second := GROUND.place(world,enemies[1],ANCHORS[1])
		grounded = first and second
		if grounded: break
	if not grounded: push_error("Bridge encounter lacks authored terrain support"); return
	for enemy in enemies: enemy.home = enemy.global_position
	restore_history()
	# One terrain-derived region for both agents avoids overlapping region edges.
	enemies[0].build_navigation()
	enemies[1].share_navigation(enemies[0].navigation_region)
	enemies[1]._choose_patrol_point()

func registry() -> Dictionary:
	var result = {}
	for enemy in enemies: result[enemy] = enemy.hitbox
	return result

func can_save() -> bool:
	for enemy in enemies:
		if enemy.engaged or enemy.melee.attacking: return false
	return true

func interrupt() -> void:
	for enemy in enemies: enemy.interrupt_action()

func restore_history() -> void:
	if not grounded: return
	for pickup in pickups.values(): pickup.queue_free()
	pickups.clear()
	for enemy in enemies:
		enemy.reset_encounter()
		if state.reward_history.has(enemy.stable_id) and not state.reward_history[enemy.stable_id].get("collected",false): show_pickup(enemy.stable_id)
	pickup_delay = 0.75

func settle_defeat(enemy: CharacterBody3D) -> void:
	if state.reward_history.has(enemy.stable_id): return
	var drop = preload("res://inventory/loot_adapter.gd").roll()
	state.reward_history[enemy.stable_id] = {"xp":10,"drop":drop,"position":enemy.global_position,"collected":drop.is_empty()}
	state.experience += 10
	world.training.feedback.reward(10)
	world.training.commit()
	if not drop.is_empty(): show_pickup(enemy.stable_id)

func show_pickup(id: String) -> void:
	var history: Dictionary = state.reward_history[id]
	var sprite = Sprite3D.new()
	sprite.texture = load(state.inventory.PROTOSET.data[history.drop.id].image)
	sprite.pixel_size = 0.006
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.modulate = Color(1,0.82,0.3)
	sprite.no_depth_test = false
	add_child(sprite)
	if world.meadow_slice:
		var anchor: Vector2 = Vector2(history.position.x, history.position.z)
		var ground = world.ground_policy
		if ground.entry_xz(history.position, state.MAP02) != anchor:
			var index: int = state.E01_IDS.find(id)
			anchor = ground.ROADBLOCK_ANCHORS[index] if index >= 0 else ground.PRESSURE_ANCHORS[state.PRESSURE_IDS.find(id)]
		if not ground.place(world, sprite, anchor):
			world.entry_failed.emit("保留的掉落缺少安全落脚点。")
			sprite.queue_free()
			return
		sprite.global_position += Vector3.UP * 0.62
	else:
		sprite.global_position = history.position + Vector3.UP * 0.7
	pickups[id] = sprite

func _physics_process(delta: float) -> void:
	if not grounded or world.training.player_locked(): return
	pickup_delay = maxf(0,pickup_delay - delta)
	if pickup_delay > 0: return
	for id in pickups.keys():
		var sprite: Sprite3D = pickups[id]
		if world.player.global_position.distance_to(sprite.global_position) > 1.65: continue
		var query = PhysicsRayQueryParameters3D.create(world.player.global_position + Vector3.UP,sprite.global_position,1,[world.player.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		var reward: Dictionary = state.reward_history[id]
		if not state.inventory.accept(reward.drop.id,reward.drop.quantity):
			world.training.tell("背包无法接收 · 使用物品后再来，掉落仍保留")
			pickup_delay = 1.0
			continue
		reward.collected = true
		sprite.queue_free()
		pickups.erase(id)
		world.training.commit()
		world.training.tell("已拾取 · " + ("疗伤药 [6]" if reward.drop.id == "healing" else "命火 · I 背包使用"),4)

func _mcp_state() -> Dictionary:
	var state_ready := is_instance_valid(state) and not state.is_queued_for_deletion()
	var observation := {"ready":grounded and state_ready and not is_queued_for_deletion(),"state_ready":state_ready,"grounded":grounded,"enemies":[],"rewards":state.reward_history if state_ready else null,"pickups":pickups.keys()}
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			observation.enemies.append(null)
			continue
		observation.enemies.append({"id":enemy.stable_id,"name":enemy.display_name,"hp":enemy.health,"phase":enemy.phase,"engaged":enemy.engaged,"position":str(enemy.global_position),"navigation_ready":enemy.navigation_ready})
	return observation
