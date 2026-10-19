extends "res://combat/bridge_encounter.gd"
## Nine persistent route patrols supplement the nine E01–E04 actors. They do
## not own story gates. Each 3-unit section has one private navigation map.
const ANCHORS_ROUTE := [Vector2(1,34),Vector2(6,35),Vector2(3,37),Vector2(1,49),Vector2(6,50),Vector2(3,53),Vector2(2,81),Vector2(8,82),Vector2(5,85)]
const RUSH_MODELS := [preload("res://assets/ambush/ambusher_a.gltf"),preload("res://assets/ambush/ambusher_b.gltf")]
var maps: Array[RID] = []
var recognition_remaining := 0.0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	for zone in 3:
		var map := NavigationServer3D.map_create()
		NavigationServer3D.map_set_active(map, true)
		maps.append(map)
		for kind in 3:
			var enemy: CharacterBody3D
			if kind == 1:
				enemy = preload("res://combat/ChannelRangedGuard.tscn").instantiate()
				enemy.set_script(preload("res://combat/map02_ranged_adapter.gd"))
			else:
				enemy = preload("res://combat/snaiel/scenes/entities/enemies/HybridEnemy.tscn").instantiate()
				enemy.set_script(preload("res://combat/map02_ambusher_adapter.gd") if kind == 2 else preload("res://combat/map02_enemy_adapter.gd"))
				if kind == 2:
					var old := enemy.get_node("Model")
					enemy.remove_child(old)
					old.free()
					var model: Node3D = RUSH_MODELS[zone % 2].instantiate()
					model.name = "Model"
					enemy.add_child(model)
			enemy.name = "RoutePatrol%d" % (zone * 3 + kind + 1)
			enemy.stable_id = state.ROUTE_PATROL_IDS[zone * 3 + kind]
			enemy.display_name = ["沿线巡卫","林路弓手","林路突袭者"][kind]
			enemy.encounter = self
			add_child(enemy)
			enemy.navigation_agent.set_navigation_map(map)
			enemy.hide()
			enemy.collision_layer = 0
			enemies.append(enemy)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion(): return
		var supported := true
		for i in enemies.size():
			supported = world.ground_policy.place(world, enemies[i], ANCHORS_ROUTE[i]) and supported
		if supported:
			grounded = true
			break
	if not grounded:
		world.entry_failed.emit("沿线巡逻队缺少真实地形支撑。")
		return
	for enemy in enemies: enemy.home = enemy.global_position
	restore_history()
	for zone in 3:
		var leader: CharacterBody3D = enemies[zone * 3]
		leader.build_navigation()
		for kind in range(1,3): enemies[zone * 3 + kind].share_navigation(leader.navigation_region)

func zone_available(zone: int) -> bool:
	if not state.cp02_claimed: return false
	if zone == 1: return state.roadblock_defeated()
	if zone == 2: return state.ambush_defeated()
	return true

func combat_allowed() -> bool:
	return grounded and state.current_map == state.MAP02 and state.health > 0 and not state.recovery_pending and world.pause_owners.is_empty() and not world.training.player_locked() and Vector2(world.player.global_position.x,world.player.global_position.z).distance_to(world.checkpoint_xz()) > 5.0

func attack_slot_available(requester: CharacterBody3D) -> bool:
	if not combat_allowed(): return false
	var occupied := 0
	for owner in [self,world.bridge_encounter,world.pressure_encounter,world.ambush_encounter,world.line_encounter]:
		if not is_instance_valid(owner): continue
		for enemy in owner.enemies:
			if enemy != requester and enemy.health > 0 and enemy.phase in ["telegraph","attack"]: occupied += 1
	return occupied < 2

func registry() -> Dictionary:
	var result := {}
	if combat_allowed():
		for enemy in enemies:
			if enemy.visible and enemy.health > 0 and enemy.hitbox.enabled: result[enemy] = enemy.hitbox
	return result

func can_save() -> bool:
	if not grounded: return false
	for enemy in enemies:
		if enemy.engaged or enemy.returning or enemy.phase in ["telegraph","attack","recovery","hurt","stagger"]: return false
	return true

func settle_defeat(enemy: CharacterBody3D) -> void:
	if not enemies.has(enemy) or not combat_allowed() or not zone_available(enemies.find(enemy) / 3) or state.reward_history.has(enemy.stable_id): return
	# Identical once-only reward schema; optional kills never satisfy E01–E04.
	super(enemy)

func restore_history() -> void:
	super()
	update_visibility()

func update_visibility() -> void:
	for i in enemies.size():
		var enemy: CharacterBody3D = enemies[i]
		var live: bool = zone_available(i / 3) and not state.reward_history.has(enemy.stable_id)
		enemy.visible = live
		enemy.collision_layer = 2 if live else 0
		enemy.hitbox.enabled = live
		enemy.process_mode = Node.PROCESS_MODE_PAUSABLE if live else Node.PROCESS_MODE_DISABLED

func telegraph(enemy: CharacterBody3D) -> void:
	world.training.feedback.spark(enemy.global_position + Vector3.UP * 1.5, Color(1,0.62,0.25))

func _physics_process(delta: float) -> void:
	if not grounded: return
	update_visibility()
	super(delta)

func _exit_tree() -> void:
	for map in maps:
		if map.is_valid(): NavigationServer3D.free_rid(map)
