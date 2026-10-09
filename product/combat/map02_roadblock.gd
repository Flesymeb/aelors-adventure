extends "res://combat/bridge_encounter.gd"
## Singleton E01. The inherited pickup unit uses the one reward/inventory owner.
var navigation_map: RID
var death_remaining := 0.0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	navigation_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(navigation_map, true)
	var enemy: CharacterBody3D = preload("res://combat/snaiel/scenes/entities/enemies/HybridEnemy.tscn").instantiate()
	enemy.set_script(preload("res://combat/map02_enemy_adapter.gd"))
	enemy.name = "MeadowRoadblock"
	enemy.stable_id = "map02_e01"
	enemy.display_name = "草甸路障 · 近战者"
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
		grounded = GROUND.place(world, enemies[0], preload("res://world/map02_ground.gd").ROADBLOCK)
		if grounded: break
	if not grounded:
		world.entry_failed.emit("草甸路障无法安全落地。")
		return
	enemies[0].home = enemies[0].global_position
	restore_history()
	enemies[0].build_navigation()

func combat_allowed() -> bool:
	return grounded and state.current_map == state.MAP02 and state.cp02_claimed and state.lives > 0 and not state.recovery_pending and world.pause_owners.is_empty() and not world.training.player_locked() and not protected_player()

func protected_player() -> bool:
	var cp: Vector2 = world.checkpoint_xz()
	var player_xz := Vector2(world.player.global_position.x, world.player.global_position.z)
	return player_xz.distance_to(cp) < 5.0

func attack_slot_available(_requester: CharacterBody3D) -> bool:
	return combat_allowed()

func registry() -> Dictionary:
	return {enemies[0]:enemies[0].hitbox} if combat_allowed() and enemies[0].health > 0 else {}

func settle_defeat(enemy: CharacterBody3D) -> void:
	var drop: Dictionary = preload("res://inventory/loot_adapter.gd").roll()
	if not state.settle_roadblock(enemy.global_position, drop): return
	death_remaining = 1.4
	world.training.feedback.reward(10)
	world.training.commit()
	if not drop.is_empty(): show_pickup(enemy.stable_id)
	world.training.tell("草甸路障已清除 · 押送路线仍待调查；可返回灯台整顿", 5)

func restore_history() -> void:
	death_remaining = 0
	super()

func _physics_process(delta: float) -> void:
	if not grounded: return
	death_remaining = maxf(0, death_remaining - delta)
	var defeated: bool = state.reward_history.has("map02_e01")
	enemies[0].visible = not defeated or death_remaining > 0
	enemies[0].collision_layer = 0 if defeated else 2
	super(delta)

func _exit_tree() -> void:
	if navigation_map.is_valid(): NavigationServer3D.free_rid(navigation_map)

func _mcp_state() -> Dictionary:
	var result := super()
	result.protected_checkpoint = protected_player()
	result.combat_allowed = combat_allowed()
	result.complete = state.reward_history.has("map02_e01")
	return result
