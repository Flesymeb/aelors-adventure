extends "res://combat/bridge_encounter.gd"
## E04 owns three fixed identities. It deliberately does not inherit E02's
## two-unit/save/supply assumptions; only the contact and pickup foundation.
@export var actor_anchors: Array[Vector2] = [Vector2(4,95), Vector2(9,95), Vector2(9,100)]
@export var cover_path := NodePath("Decorations-Forest/@rock_moss_set_01_rock06@28709")
var navigation_map: RID
var cover: Node3D
var death_remaining: Dictionary = {}
var active := false

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	navigation_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(navigation_map, true)
	for i in 3:
		var enemy: CharacterBody3D
		if i < 2:
			enemy = preload("res://combat/ChannelMeleeGuard.tscn").instantiate()
			enemy.set_script(preload("res://combat/map02_enemy_adapter.gd"))
		else:
			enemy = preload("res://combat/ChannelRangedGuard.tscn").instantiate()
			enemy.set_script(preload("res://combat/map02_ranged_adapter.gd"))
		enemy.name = ["LineMeleeA", "LineMeleeB", "LineArcher"][i]
		enemy.stable_id = state.LINE_IDS[i]
		enemy.display_name = ["结界近卫 · 西哨", "结界近卫 · 东哨", "结界弓守"][i]
		enemy.encounter = self
		add_child(enemy)
		if i < 2:
			enemy.acquired_cue = func(): world.training.tell("结界近卫 · 抬手后出拳；岩石挡箭，留意两侧近卫", 4)
		enemy.navigation_agent.set_navigation_map(navigation_map)
		enemy.visible = false
		enemy.collision_layer = 0
		enemies.append(enemy)
	# The selected authored rock and its retained collision provide cover.
	# Do not move/clone it or add a collision substitute to the live terrain.
	cover = world.village.get_node_or_null(cover_path)
	if not is_instance_valid(cover):
		world.entry_failed.emit("结界路段的原有岩石遮挡缺失。")
		return
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world) or world.is_queued_for_deletion(): return
		var supported := actor_anchors.size() == enemies.size()
		if not supported: break
		for i in enemies.size():
			var placed: bool = world.ground_policy.place(world, enemies[i], actor_anchors[i])
			supported = placed and supported
			if placed and not standing_clear(enemies[i]): supported = false
		if not supported: continue
		grounded = true
		break
	if not grounded:
		world.entry_failed.emit("结界守卫路段缺少安全站立空间。")
		return
	for enemy in enemies: enemy.home = enemy.global_position
	restore_history()
	enemies[0].build_navigation()
	for i in range(1, enemies.size()): enemies[i].share_navigation(enemies[0].navigation_region)

func standing_clear(body: Node3D) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = body.global_position + Vector3.UP * 0.90
	query.collision_mask = 1
	query.exclude = [world.player.get_rid()]
	if body is CollisionObject3D: query.exclude.append(body.get_rid())
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func combat_allowed() -> bool:
	return grounded and state.line_defense_available() and world.pause_owners.is_empty() and not world.training.player_locked() and not protected_player()

func protected_player() -> bool:
	var cp: Vector2 = world.checkpoint_xz()
	return Vector2(world.player.global_position.x, world.player.global_position.z).distance_to(cp) < 5.0

func attack_slot_available(requester: CharacterBody3D) -> bool:
	if not combat_allowed(): return false
	var count := 0
	for enemy in enemies:
		if enemy != requester and enemy.health > 0 and enemy.phase in ["telegraph", "attack"]: count += 1
	return count < 2

func can_save() -> bool:
	if not grounded or enemies.size() != 3: return false
	for i in range(2):
		var melee: CharacterBody3D = enemies[i]
		if melee.engaged or melee.returning or melee.melee.attacking or melee.hurt_remaining > 0 or melee.phase in ["telegraph", "attack", "recovery", "hurt", "stagger"]: return false
	return enemies[2].can_save()

func registry() -> Dictionary:
	if not combat_allowed(): return {}
	var result := {}
	for enemy in enemies:
		if enemy.health > 0 and enemy.hitbox.enabled: result[enemy] = enemy.hitbox
	return result

func interrupt() -> void:
	super()
	# Fresh combat control after pause/death/load; no queued strike or arrow.
	for i in mini(2, enemies.size()):
		var melee: CharacterBody3D = enemies[i]
		melee.engaged = false
		melee.returning = false
		melee.lost_time = 0
		melee.hurt_remaining = 0
		melee.velocity = Vector3.ZERO
		if melee.health > 0:
			melee.phase = "idle"
			melee.character.interrupt()
	pickup_delay = maxf(pickup_delay, 0.75)

func settle_defeat(enemy: CharacterBody3D) -> void:
	if not enemies.has(enemy) or state.reward_history.has(enemy.stable_id): return
	var drop: Dictionary = preload("res://inventory/loot_adapter.gd").roll()
	if not state.settle_line(enemy.global_position, drop, enemy.stable_id): return
	death_remaining[enemy.stable_id] = 1.4
	world.training.feedback.reward(10)
	world.training.commit()
	if not drop.is_empty(): show_pickup(enemy.stable_id)
	world.training.tell("结界守卫已清除 · 调查固定路标，恢复补给另行领取" if state.line_defeated() else "一名结界守卫已击败 · 用岩石隔断箭线，观察两侧近卫", 5)

func restore_history() -> void:
	death_remaining.clear()
	super()
	update_visibility()

func show_pickup(id: String) -> void:
	# E04's own anchor lookup avoids the base adapter's E02 fallback index.
	var index: int = state.LINE_IDS.find(id)
	if index < 0 or not state.reward_history.has(id) or pickups.has(id): return
	var history: Dictionary = state.reward_history[id]
	if history.get("collected", false) or history.get("drop", {}).is_empty(): return
	var sprite := Sprite3D.new()
	sprite.texture = load(state.inventory.PROTOSET.data[history.drop.id].image)
	sprite.pixel_size = 0.006
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.modulate = Color(1,0.82,0.3)
	add_child(sprite)
	var anchor := Vector2(history.position.x, history.position.z)
	if world.ground_policy.entry_xz(history.position, state.MAP02) != anchor: anchor = actor_anchors[index]
	if not world.ground_policy.place(world, sprite, anchor):
		world.entry_failed.emit("结界守卫的保留掉落缺少安全落脚点。")
		sprite.queue_free()
		return
	sprite.global_position += Vector3.UP * 0.62
	pickups[id] = sprite

func update_visibility() -> void:
	active = state.line_defense_available()
	for enemy in enemies:
		var defeated: bool = state.reward_history.has(enemy.stable_id)
		enemy.visible = active and (not defeated or death_remaining.get(enemy.stable_id, 0.0) > 0)
		enemy.collision_layer = 2 if active and not defeated else 0

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
	result.active = active
	result.complete = state.line_defeated() if ready else null
	result.remaining = state.line_remaining() if ready else null
	result.combat_allowed = combat_allowed() if ready else null
	result.actor_count = enemies.size()
	result.enemy_ids = state.LINE_IDS if ready else null
	result.can_save = can_save() if ready else null
	result.cover_position = cover.global_position if ready and is_instance_valid(cover) else null
	result.ranged = enemies[2]._mcp_state() if ready and enemies.size() > 2 else null
	return result
