extends "res://combat/bridge_encounter.gd"
## Same terrain singleton, separate fixed identities, no patrol/dynamic authority.
const GUARD_ANCHORS := [Vector2(131,142),Vector2(135,142),Vector2(133,146)]
var navigation_map: RID
var active := false
var cover: MeshInstance3D
var cover_body: StaticBody3D
var death_exposure: Dictionary = {}

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	navigation_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(navigation_map,true)
	for i in 3:
		var enemy: CharacterBody3D = (preload("res://combat/ChannelRangedGuard.tscn") if i == 2 else preload("res://combat/ChannelMeleeGuard.tscn")).instantiate()
		enemy.name = ["ChannelMeleeA","ChannelMeleeB","ChannelArcher"][i]
		enemy.stable_id = state.GUARD_IDS[i]
		enemy.display_name = ["柱群近战 · 左哨","柱群近战 · 右哨","柱群弓守"][i]
		enemy.encounter = self
		add_child(enemy)
		enemy.navigation_agent.set_navigation_map(navigation_map)
		enemy.visible = false
		enemy.collision_layer = 0
		enemies.append(enemy)
	cover = preload("res://env models/rocks/scenes/big rock 2.tscn").instantiate()
	cover.name = "GuardRockCover"
	add_child(cover)
	# Native convex collision from the actual authored rock, no substitute wall.
	var size := cover.mesh.get_aabb().size
	cover.scale *= 2.4 / maxf(size.x,maxf(size.y,size.z))
	cover.create_convex_collision()
	cover_body = cover.get_child(0)
	cover_body.collision_layer = 1
	ground.call_deferred()

func _exit_tree() -> void:
	if navigation_map.is_valid(): NavigationServer3D.free_rid(navigation_map)

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		var supported := true
		for i in 3:
			if not GROUND.place(world,enemies[i],GUARD_ANCHORS[i]): supported = false
		var excluded: Array[RID] = [cover_body.get_rid()]
		var hit: Dictionary = GROUND.support(world,Vector2(133,139),excluded)
		if not supported or hit.is_empty(): continue
		cover.global_position = hit.position - Vector3.UP * cover.mesh.get_aabb().position.y * cover.scale.y
		grounded = true
		break
	if not grounded: push_error("Channel guards lack authored terrain/standing volume"); return
	for enemy in enemies: enemy.home = enemy.global_position
	restore_history()
	enemies[0].build_navigation()
	enemies[1].share_navigation(enemies[0].navigation_region)
	enemies[2].share_navigation(enemies[0].navigation_region)

func restore_history() -> void:
	death_exposure.clear()
	super()

func combat_allowed() -> bool:
	return grounded and state.guard_briefing_available() and state.guard_briefing_acknowledged and state.lives > 0 and not state.conversation_active and world.pause_owners.is_empty() and not state.recovery_pending and not world.training.player_locked()

func attack_slot_available(requester: CharacterBody3D) -> bool:
	var count := 0
	for enemy in enemies:
		if enemy != requester and enemy.phase in ["telegraph","attack"]: count += 1
	return count < 2

func can_save() -> bool:
	for enemy in enemies:
		if enemy.engaged or enemy.phase in ["telegraph","attack","recovery"]: return false
	for projectile in enemies[2].projectiles:
		if is_instance_valid(projectile) and not projectile.settled: return false
	return true

func protected_player() -> bool:
	return grounded and world.player.global_position.distance_to(enemies[0].home) < 15

func registry() -> Dictionary:
	if not combat_allowed(): return {}
	var result := {}
	for enemy in enemies:
		if enemy.health > 0: result[enemy] = enemy.hitbox
	return result

func settle_defeat(enemy: CharacterBody3D) -> void:
	if state.reward_history.has(enemy.stable_id): return
	var drop: Dictionary = preload("res://inventory/loot_adapter.gd").roll()
	if not state.settle_guard(enemy.stable_id,enemy.global_position,drop): return
	death_exposure[enemy.stable_id] = 1.4
	world.training.feedback.reward(10)
	world.training.commit()
	if not drop.is_empty(): show_pickup(enemy.stable_id)
	if state.guards_defeated(): world.training.tell("柱群三名守卫已击败 · 返回伊莎处；通道仍缺离村准备",5)

func _physics_process(delta: float) -> void:
	if not grounded: return
	active = state.guard_briefing_available() and state.guard_briefing_acknowledged
	for enemy in enemies:
		var defeated: bool = state.reward_history.has(enemy.stable_id)
		death_exposure[enemy.stable_id] = maxf(0,death_exposure.get(enemy.stable_id,0.0)-delta)
		enemy.visible = active and (not defeated or death_exposure[enemy.stable_id] > 0)
		enemy.collision_layer = 2 if active and not defeated else 0
	super(delta)

func _mcp_state() -> Dictionary:
	var result := super()
	result.active = active
	result.complete = state.guards_defeated() if result.state_ready else null
	result.missing_conditions = state.passage_missing_conditions() if result.state_ready else null
	result.enemy_ids = state.GUARD_IDS if result.state_ready else null
	result.ranged = enemies[2]._mcp_state() if enemies.size() > 2 and is_instance_valid(enemies[2]) and not enemies[2].is_queued_for_deletion() else null
	result.cover_position = str(cover.global_position) if is_instance_valid(cover) and not cover.is_queued_for_deletion() else null
	return result
