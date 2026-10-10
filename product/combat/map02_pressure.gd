extends "res://combat/bridge_encounter.gd"
## E02: one retained melee unit and one retained swept-projectile bow unit.
## Reward, branch supply and victory supply remain separate state authorities.
@export var actor_anchors: Array[Vector2] = [Vector2(128,157), Vector2(130,160)]
@export var cover_xz := Vector2(128,154)
@export var branch_supply_xz := Vector2(128,149)
@export var victory_supply_xz := Vector2(125,153)
var navigation_map: RID
var cover: MeshInstance3D
var cover_body: StaticBody3D
var death_remaining: Dictionary = {}
var active := false
var supplies: Dictionary = {}

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	navigation_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(navigation_map, true)
	for i in 2:
		var enemy: CharacterBody3D
		if i == 0:
			enemy = preload("res://combat/snaiel/scenes/entities/enemies/HybridEnemy.tscn").instantiate()
			enemy.set_script(preload("res://combat/map02_enemy_adapter.gd"))
		else:
			enemy = preload("res://combat/ChannelRangedGuard.tscn").instantiate()
			enemy.set_script(preload("res://combat/map02_ranged_adapter.gd"))
		enemy.name = "PressureMelee" if i == 0 else "PressureArcher"
		enemy.stable_id = state.PRESSURE_IDS[i]
		enemy.display_name = "押送近卫" if i == 0 else "押送弓守"
		enemy.encounter = self
		add_child(enemy)
		if i == 0:
			enemy.acquired_cue = func(): world.training.tell("押送近卫 · 抬手后出拳；岩石能挡箭，留意近卫绕行", 4)
		enemy.navigation_agent.set_navigation_map(navigation_map)
		enemy.visible = false
		enemy.collision_layer = 0
		enemies.append(enemy)
	cover = preload("res://env models/rocks/scenes/big rock 2.tscn").instantiate()
	cover.name = "PressureRockCover"
	add_child(cover)
	# Convex collision follows the selected authored rock, with enough actual
	# height to stop both player's tip sweep and the guard's swept arrow.
	cover.scale *= 2.25 / maxf(0.01, cover.mesh.get_aabb().size.y)
	cover.create_convex_collision()
	cover_body = cover.get_child(0)
	cover_body.collision_layer = 1
	cover_body.collision_mask = 0
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world) or world.is_queued_for_deletion(): return
		var hit: Dictionary = GROUND.support(world, cover_xz, [cover_body.get_rid()])
		if hit.is_empty(): continue
		cover.global_position = hit.position - Vector3.UP * cover.mesh.get_aabb().position.y * cover.scale.y
		var supported := true
		for i in enemies.size():
			var placed := GROUND.place(world, enemies[i], actor_anchors[i])
			supported = placed and supported
			if placed and not standing_clear(enemies[i]): supported = false
		if not supported: continue
		grounded = true
		break
	if not grounded:
		world.entry_failed.emit("押送路段缺少安全站立空间。")
		return
	for enemy in enemies: enemy.home = enemy.global_position
	restore_history()
	enemies[0].build_navigation()
	enemies[1].share_navigation(enemies[0].navigation_region)

func standing_clear(body: Node3D) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	# GROUND.place puts bodies and route stances 0.08m above real support.
	# The capsule's bottom retains that gap rather than intersecting the floor.
	query.transform.origin = body.global_position + Vector3.UP * 0.90
	query.collision_mask = 1
	query.exclude = [world.player.get_rid()]
	if body is CollisionObject3D: query.exclude.append(body.get_rid())
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func combat_allowed() -> bool:
	return grounded and state.current_map == state.MAP02 and state.cp02_claimed and state.roadblock_defeated() and state.lives > 0 and not state.recovery_pending and world.pause_owners.is_empty() and not world.training.player_locked() and not protected_player()

func protected_player() -> bool:
	var cp: Vector2 = world.checkpoint_xz()
	return Vector2(world.player.global_position.x, world.player.global_position.z).distance_to(cp) < 5.0

func attack_slot_available(requester: CharacterBody3D) -> bool:
	if not combat_allowed(): return false
	var count := 0
	for enemy in enemies:
		if enemy != requester and enemy.health > 0 and enemy.phase in ["telegraph", "attack"]: count += 1
	return count < 2

func interrupt() -> void:
	super()
	# Supplies are interactions, not pickups that settle during interrupted play.
	pickup_delay = maxf(pickup_delay, 0.75)

func can_save() -> bool:
	# The base's melee-only property assumption is invalid for the ranged unit.
	if enemies.size() != 2: return false
	var melee: CharacterBody3D = enemies[0]
	if melee.engaged or melee.returning or melee.melee.attacking or melee.phase in ["telegraph", "attack", "recovery", "hurt"]: return false
	return enemies[1].can_save()

func registry() -> Dictionary:
	if not combat_allowed(): return {}
	var result := {}
	for enemy in enemies:
		if enemy.health > 0: result[enemy] = enemy.hitbox
	return result

func settle_defeat(enemy: CharacterBody3D) -> void:
	if not enemies.has(enemy) or state.reward_history.has(enemy.stable_id): return
	var drop: Dictionary = preload("res://inventory/loot_adapter.gd").roll()
	if not state.settle_pressure(enemy.global_position, drop, enemy.stable_id): return
	death_remaining[enemy.stable_id] = 1.4
	world.training.feedback.reward(10)
	world.training.commit()
	if not drop.is_empty(): show_pickup(enemy.stable_id)
	world.training.tell("押送守卫已清除 · 胜利补给可领取；沿路调查押送线索" if state.pressure_defeated() else "一名押送守卫已击败 · 利用岩石遮挡箭线，退回灯台可整顿", 5)

func restore_history() -> void:
	death_remaining.clear()
	super()
	if grounded: rebuild_supplies()
	update_visibility()

func rebuild_supplies() -> void:
	for sprite in supplies.values():
		sprite.hide()
		sprite.queue_free()
	supplies.clear()
	for kind in ["branch", "victory"]:
		var hit: Dictionary = GROUND.support(world, branch_supply_xz if kind == "branch" else victory_supply_xz, [cover_body.get_rid()])
		if hit.is_empty():
			world.entry_failed.emit("押送路段补给缺少安全落脚点。")
			continue
		var sprite := Sprite3D.new()
		sprite.name = "RescueApproachSupply" if kind == "branch" else "PressureVictorySupply"
		sprite.texture = preload("res://assets/ui/icons/potion.png")
		sprite.pixel_size = 0.006
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.modulate = Color(1, 0.83, 0.38) if kind == "victory" else Color(0.7, 0.95, 0.8)
		add_child(sprite)
		sprite.global_position = hit.position + Vector3.UP * 0.75
		supplies[kind] = sprite
	update_supplies()

func update_supplies() -> void:
	for kind in supplies:
		supplies[kind].visible = state.meadow_branch_supply_available() if kind == "branch" else state.pressure_supply_available()

func nearby_supply() -> String:
	if not grounded or state.health <= 0 or state.recovery_pending or not world.pause_owners.is_empty() or world.training.player_locked(): return ""
	for kind in supplies:
		var sprite: Sprite3D = supplies[kind]
		if not sprite.visible or world.player.global_position.distance_to(sprite.global_position) > 2.0: continue
		var query := PhysicsRayQueryParameters3D.create(world.player.global_position + Vector3.UP, sprite.global_position, 1, [world.player.get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return kind
	return ""

func interaction_prompt() -> String:
	var kind := nearby_supply()
	if kind == "": return ""
	if not world.training.can_save(): return "补给仍保留 · 脱离交战后领取"
	return "[E] 领取先救人的前方补给" if kind == "branch" else "[E] 领取胜利补给 · 恢复20生命"

func interact() -> bool:
	var kind := nearby_supply()
	if kind == "": return false
	if not world.training.can_save():
		world.training.tell("补给仍保留 · 先利用岩石遮挡箭线、脱离交战")
		return true
	var grant: Dictionary = state.claim_meadow_branch_supply() if kind == "branch" else state.claim_pressure_supply()
	if grant.is_empty():
		world.training.tell("目前无需补充 · 补给仍留在这里")
		return true
	world.training.commit()
	world.training.feedback.sound(preload("res://assets/dialogue/sounds/Audio/pluck_002.ogg"), -22, 1.15)
	world.training.tell("前方补给已领取 · 生命 +%d，箭 +%d" % [grant.get("health", 0), grant.get("arrows", 0)] if kind == "branch" else "胜利补给已领取 · 生命 +%d" % grant.get("health", 0), 4)
	update_supplies()
	return true

func update_visibility() -> void:
	active = state.current_map == state.MAP02 and state.cp02_claimed and state.roadblock_defeated()
	for enemy in enemies:
		var defeated: bool = state.reward_history.has(enemy.stable_id)
		enemy.visible = active and (not defeated or death_remaining.get(enemy.stable_id, 0.0) > 0)
		enemy.collision_layer = 2 if active and not defeated else 0

func _physics_process(delta: float) -> void:
	if not grounded: return
	for id in death_remaining.keys(): death_remaining[id] = maxf(0, death_remaining[id] - delta)
	update_visibility()
	update_supplies()
	super(delta)

func _exit_tree() -> void:
	if navigation_map.is_valid(): NavigationServer3D.free_rid(navigation_map)

func _mcp_state() -> Dictionary:
	var result := super()
	var ready: bool = result.ready and is_instance_valid(world) and not world.is_queued_for_deletion()
	result.active = active
	result.complete = state.pressure_defeated() if ready else null
	result.remaining = state.pressure_remaining() if ready else null
	result.combat_allowed = combat_allowed() if ready else null
	result.protected_checkpoint = protected_player() if ready else null
	result.actor_count = enemies.size()
	result.branch_supply_available = state.meadow_branch_supply_available() if ready else null
	result.victory_supply_available = state.pressure_supply_available() if ready else null
	result.cover_position = cover.global_position if ready and is_instance_valid(cover) else null
	result.ranged = enemies[1]._mcp_state() if ready and enemies.size() > 1 else null
	return result
