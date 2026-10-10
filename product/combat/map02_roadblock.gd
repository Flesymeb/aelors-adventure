extends "res://combat/bridge_encounter.gd"
## E01: independent outcomes, shared terrain navigation and pickup ownership.
const MEADOW_GROUND = preload("res://world/map02_ground.gd")
var navigation_map: RID
var death_remaining: Dictionary = {}

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	navigation_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(navigation_map, true)
	for i in state.E01_IDS.size():
		var enemy: CharacterBody3D = preload("res://combat/snaiel/scenes/entities/enemies/HybridEnemy.tscn").instantiate()
		enemy.set_script(preload("res://combat/map02_enemy_adapter.gd"))
		enemy.name = "MeadowRoadblock" if i == 0 else "MeadowRoadblockB"
		enemy.stable_id = state.E01_IDS[i]
		enemy.display_name = "路障近战者 · 前哨" if i == 0 else "路障近战者 · 后哨"
		enemy.encounter = self
		add_child(enemy)
		enemy.navigation_agent.set_navigation_map(navigation_map)
		enemy.visible = false
		enemy.collision_layer = 0
		enemies.append(enemy)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world) or world.is_queued_for_deletion(): return
		grounded = true
		for i in enemies.size():
			var supported := MEADOW_GROUND.place(world, enemies[i], MEADOW_GROUND.ROADBLOCK_ANCHORS[i])
			grounded = supported and grounded
		if grounded: break
	if not grounded:
		world.entry_failed.emit("草甸路障无法安全落地。")
		return
	for enemy in enemies: enemy.home = enemy.global_position
	restore_history()
	# One region covers both supported homes; overlapping regions are avoided.
	enemies[0].build_navigation()
	enemies[1].share_navigation(enemies[0].navigation_region)
	enemies[1]._choose_patrol_point()

func combat_allowed() -> bool:
	return grounded and state.current_map == state.MAP02 and state.cp02_claimed and state.lives > 0 and not state.recovery_pending and world.pause_owners.is_empty() and not world.training.player_locked() and not protected_player()

func protected_player() -> bool:
	var cp: Vector2 = world.checkpoint_xz()
	var player_xz := Vector2(world.player.global_position.x, world.player.global_position.z)
	return player_xz.distance_to(cp) < 5.0

func attack_slot_available(_requester: CharacterBody3D) -> bool:
	# E01's two actors fit the ordinary two-attacker cap.
	return combat_allowed()

func registry() -> Dictionary:
	var result := {}
	if combat_allowed():
		for enemy in enemies:
			if enemy.health > 0: result[enemy] = enemy.hitbox
	return result

func settle_defeat(enemy: CharacterBody3D) -> void:
	if not enemies.has(enemy) or state.reward_history.has(enemy.stable_id): return
	var drop: Dictionary = preload("res://inventory/loot_adapter.gd").roll()
	if not state.settle_roadblock(enemy.global_position, drop, enemy.stable_id): return
	death_remaining[enemy.stable_id] = 1.4
	world.training.feedback.reward(10)
	world.training.commit()
	if not drop.is_empty(): show_pickup(enemy.stable_id)
	world.training.tell("E01 路障已清除 · 前往 E02 调查押送路线" if state.roadblock_defeated() else "一名路障近战者已击败 · 另一名仍守着林路；可退回灯台整顿", 5)

func restore_history() -> void:
	death_remaining.clear()
	super()
	update_visibility()

func update_visibility() -> void:
	for enemy in enemies:
		var defeated: bool = state.reward_history.has(enemy.stable_id)
		enemy.visible = not defeated or death_remaining.get(enemy.stable_id, 0.0) > 0
		enemy.collision_layer = 0 if defeated else 2

func _physics_process(delta: float) -> void:
	if not grounded: return
	for id in death_remaining.keys(): death_remaining[id] = maxf(0, death_remaining[id] - delta)
	update_visibility()
	super(delta)

func _exit_tree() -> void:
	if navigation_map.is_valid(): NavigationServer3D.free_rid(navigation_map)

func _mcp_state() -> Dictionary:
	var result := super()
	var ready: bool = result.ready and is_instance_valid(world) and not world.is_queued_for_deletion()
	result.protected_checkpoint = protected_player() if ready else null
	result.combat_allowed = combat_allowed() if ready else null
	result.complete = state.roadblock_defeated() if ready else null
	result.remaining = state.roadblock_remaining() if ready else null
	result.actor_count = enemies.size()
	return result
