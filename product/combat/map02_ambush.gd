extends "res://combat/map02_roadblock.gd"
## Two fixed identities, one retained terrain/nav region, shared reward authority.
const MODELS := [preload("res://assets/ambush/ambusher_a.gltf"), preload("res://assets/ambush/ambusher_b.gltf")]
var recognition_remaining := 0.0
var warning_seen := false
var reveal_count := 0
var pulse_count := 0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	navigation_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(navigation_map, true)
	for i in 2:
		var actor: CharacterBody3D = preload("res://combat/snaiel/scenes/entities/enemies/HybridEnemy.tscn").instantiate()
		actor.set_script(preload("res://combat/map02_ambusher_adapter.gd"))
		var old: Node = actor.get_node("Model")
		actor.remove_child(old)
		old.free()
		var model: Node3D = MODELS[i].instantiate()
		model.name = "Model"
		actor.add_child(model)
		actor.name = "AmbusherA" if i == 0 else "AmbusherB"
		actor.stable_id = state.AMBUSH_IDS[i]
		actor.display_name = "伏击者 · 赤角" if i == 0 else "伏击者 · 铁颚"
		actor.encounter = self
		add_child(actor)
		actor.navigation_agent.set_navigation_map(navigation_map)
		actor.hide()
		actor.collision_layer = 0
		enemies.append(actor)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world) or world.is_queued_for_deletion(): return
		grounded = true
		for i in 2: grounded = MEADOW_GROUND.place(world, enemies[i], MEADOW_GROUND.AMBUSH_ANCHORS[i]) and grounded
		if grounded: break
	if not grounded:
		world.entry_failed.emit("林缘魔痕缺少安全落脚点。")
		return
	for actor in enemies: actor.home = actor.global_position
	restore_history()
	enemies[0].build_navigation()
	enemies[1].share_navigation(enemies[0].navigation_region)
	enemies[1]._choose_patrol_point()

func approach_allowed() -> bool:
	return grounded and state.current_map == state.MAP02 and state.mf01_acquired and state.health > 0 and not state.recovery_pending and world.pause_owners.is_empty() and not world.training.player_locked()

func combat_allowed() -> bool:
	return approach_allowed() and state.e03_revealed and recognition_remaining <= 0 and not protected_player()

func reveal(origin: Vector3) -> int:
	if not approach_allowed(): return 0
	pulse_count += 1
	var reached := false
	for actor in enemies:
		if state.reward_history.has(actor.stable_id): continue
		if actor.global_position.distance_to(origin) <= 7.0:
			var query := PhysicsRayQueryParameters3D.create(origin + Vector3.UP, actor.global_position + Vector3.UP, 1, [world.player.get_rid()])
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): reached = true
	if not reached: return 0
	if state.e03_revealed: return 1
	state.e03_revealed = true
	reveal_count += 1
	recognition_remaining = 0.8
	update_visibility()
	for actor in enemies:
		if actor.health > 0: world.training.feedback.spark(actor.global_position + Vector3.UP, Color(0.4,0.85,1))
	world.training.feedback.sound(preload("res://assets/dialogue/sounds/Audio/confirmation_001.ogg"), -19, 0.75)
	world.training.tell("灯光驱散了遮掩 · 两名伏击者！看清抬手，再闪避或格挡突进", 5)
	world.training.commit()
	return 2

func telegraph(actor: CharacterBody3D) -> void:
	world.training.feedback.spark(actor.global_position + Vector3.UP * 1.5, Color(1,0.62,0.25))

func settle_defeat(actor: CharacterBody3D) -> void:
	if not enemies.has(actor) or state.reward_history.has(actor.stable_id): return
	var drop: Dictionary = preload("res://inventory/loot_adapter.gd").roll()
	if not state.settle_ambush(actor.global_position, drop, actor.stable_id): return
	death_remaining[actor.stable_id] = 1.4
	world.training.feedback.reward(10)
	world.training.commit()
	if not drop.is_empty(): show_pickup(actor.stable_id)
	world.training.tell("E03 伏击已清除 · 押送队留下的魔痕仍通往深林，四位村民尚待救援" if state.ambush_defeated() else "一名伏击者已击败 · 留意另一名的突进；可退回灯台",5)

func show_pickup(id: String) -> void:
	var history: Dictionary = state.reward_history[id]
	var sprite := Sprite3D.new()
	sprite.texture = load(state.inventory.PROTOSET.data[history.drop.id].image)
	sprite.pixel_size = 0.006
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.modulate = Color(1,0.82,0.3)
	add_child(sprite)
	var anchor: Vector2 = Vector2(history.position.x, history.position.z)
	if not MEADOW_GROUND.place(world, sprite, anchor) and not MEADOW_GROUND.place(world, sprite, MEADOW_GROUND.AMBUSH_ANCHORS[state.AMBUSH_IDS.find(id)]):
		world.entry_failed.emit("伏击掉落缺少安全落脚点。")
		sprite.queue_free()
		return
	sprite.global_position += Vector3.UP * 0.62
	pickups[id] = sprite

func restore_history() -> void:
	if not grounded: return
	# A completed ambush is durable history. Clearing revelation after death
	# made E04 disappear; dead E03 actors could no longer be revealed again.
	if state.ambush_defeated(): state.e03_revealed = true
	recognition_remaining = 0.8 if state.e03_revealed and not state.ambush_defeated() else 0.0
	warning_seen = false
	super()

func update_visibility() -> void:
	for actor in enemies:
		var defeated: bool = state.reward_history.has(actor.stable_id)
		actor.visible = (state.mf01_acquired and not defeated) or death_remaining.get(actor.stable_id, 0.0) > 0
		actor.collision_layer = 2 if state.e03_revealed and not defeated else 0
		actor.hitbox.enabled = state.e03_revealed and not defeated
		for mesh in actor.model.find_children("*", "MeshInstance3D", true, false):
			mesh.transparency = 0.0 if state.e03_revealed or defeated else 0.90

func _physics_process(delta: float) -> void:
	if not grounded: return
	if approach_allowed():
		recognition_remaining = maxf(0, recognition_remaining - delta)
		if not warning_seen and not state.e03_revealed and world.player.global_position.distance_to(enemies[0].home) < 10:
			warning_seen = true
			world.training.tell("林缘有拖行的魔痕，暗处传来低语 · [3] 旧灯，再按 [F] 显形（范围 7 米）", 6)
			world.training.feedback.sound(preload("res://assets/training/soft_impact.ogg"), -24, 0.45)
	var pending := pickups.keys()
	super(delta)
	# Collection still belongs to the inherited inventory/save authority.
	# Emit an amount only after its accepted, once-only settlement.
	for id in pending:
		if pickups.has(id) or not state.reward_history[id].collected: continue
		var drop: Dictionary = state.reward_history[id].drop
		var item := "疗伤药" if drop.id == "healing" else "命火"
		var size := get_viewport().get_visible_rect().size
		world.training.feedback.add_cue("+%d %s" % [drop.quantity,item], Vector2(size.x * 0.48,size.y * 0.48), Color(1,0.8,0.24),1.6)

func _mcp_state() -> Dictionary:
	var result := super()
	var ready: bool = result.ready
	result.revealed = state.e03_revealed if ready else null
	result.recognition_remaining = recognition_remaining if ready else null
	result.complete = state.ambush_defeated() if ready else null
	result.remaining = state.ambush_remaining() if ready else null
	result.warning_seen = warning_seen
	result.reveal_count = reveal_count
	result.pulse_count = pulse_count
	return result
