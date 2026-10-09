extends Node3D
## Product policy: acquisition, defense, checkpoint/reward history and presentation.
## Snaiel melee/hitboxes own attack windows, instances and contact settlement.
const DAMAGES = [12.0, 15.0, 20.0]
const CLIPS = ["sword/Sword_Regular_A", "sword/Sword_Regular_B", "sword/Sword_Regular_C"]
const GROUND = preload("res://forest_ground.gd")
const CP01 = GROUND.SPAWN
const PRACTICE_XZ = GROUND.PRACTICE
const HERS_XZ = GROUND.HERS
const ENCOUNTER_XZ = GROUND.ENCOUNTER
var world: Node3D
var player: CharacterBody3D
var state: Node
var hers: StaticBody3D
var target: StaticBody3D
var monster: CharacterBody3D
var hud: CanvasLayer
var feedback: CanvasLayer
var phase = "idle"
var clock = 0.0
var combo = 0
var buffered = false
var player_hitbox: SnaielHitbox
var target_hitbox: SnaielHitbox
var environment_hitbox: SnaielHitbox
var sword_source: SnaielDamageSource
var sword_melee: SnaielMelee
var sword_events: SnaielMeleeAnimations
var pickup_delay = 0.0
var blocking = false
var parry_window = 0.0
var parry_cooldown = 0.0
var block_age = 0.0
var late_window = 0.0
var hurt_time = 0.0
var death_time = 0.0
var protection = 0.0
var hit_stop = 0.0
var notice = ""
var notice_time = 0.0
# Counts guarded first grants in this live session; restoration is not a grant.
var sword_grants := 0
var sim_phase = "idle"
var sim_clock = 0.0
var sim_direction = Vector3.ZERO
var sim_origin = Vector3.ZERO
var remnant: Node3D
var grounded = false
var recovery_settled = false
var last_outcome = ""
var last_hp_loss = 0.0
var commit_retry = false
var commit_retry_timer = 0.0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	player = world.player
	state = world.dialogue_state
	player.combat = self
	hers = preload("res://Hers.tscn").instantiate()
	hers.name = "Hers"
	add_child(hers)
	target = StaticBody3D.new()
	target.name = "PracticeTarget"
	target.collision_layer = 2
	add_child(target)
	var bale = preload("res://Prefabs/Prop/Container/EA03_Prop_Container_Bale_01a_PRE.prefab.scn").instantiate()
	target.add_child(bale)
	bale.scale *= 3.0
	# Keep the authored bale mesh/material; one simple product contact collider.
	for body in bale.find_children("*", "CollisionObject3D", true, false):
		body.collision_layer = 0
		body.collision_mask = 0
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.08, 1.12, 1.8)
	collision.shape = shape
	collision.position.y = 0.6
	target.add_child(collision)
	bind_player_combat()
	monster = preload("res://TrainingMonster.tscn").instantiate()
	monster.name = "TrainingMonster"
	monster.training = self
	add_child(monster)
	hud = preload("res://combat_hud.gd").new()
	hud.training = self
	world.add_child(hud)
	feedback = preload("res://reward_feedback.gd").new()
	feedback.name = "RewardFeedback"
	feedback.training = self
	world.add_child(feedback)
	ground_module.call_deferred()

func bind_player_combat() -> void:
	sword_source = SnaielDamageSource.new()
	sword_source.name = "SwordDamageSource"
	sword_source.entity = player
	sword_events = SnaielMeleeAnimations.new()
	sword_events.name = "SwordEvents"
	add_child(sword_events)
	var strategies: Array[SnaielMeleeAttack] = []
	for index in DAMAGES.size():
		var strategy = SnaielMeleeAttack.new()
		strategy.attack_name = CLIPS[index]
		strategy.damage_attributes.health = DAMAGES[index]
		strategy.recovery = 0.5 if index == 2 else 0.35
		strategies.append(strategy)
	sword_events.configure(strategies)
	sword_melee = SnaielMelee.new()
	sword_melee.name = "SwordMelee"
	sword_melee.melee_animations = sword_events
	sword_melee.weapons = {&"sword": NodePath("SwordDamageSource")}
	sword_melee.add_child(sword_source)
	add_child(sword_melee)
	sword_melee.configure()
	sword_events.stage_changed.connect(sword_stage)
	sword_events.attacking_finished.connect(sword_finished)
	player_hitbox = SnaielHitbox.new()
	player_hitbox.name = "PlayerHitbox"
	player_hitbox.entity = player
	player_hitbox.policy = resolve_player_contact
	add_child(player_hitbox)
	target_hitbox = SnaielHitbox.new()
	target_hitbox.name = "PracticeHitbox"
	target_hitbox.entity = target
	target_hitbox.policy = resolve_practice_contact
	add_child(target_hitbox)
	environment_hitbox = SnaielHitbox.new()
	environment_hitbox.name = "EnvironmentHitbox"
	environment_hitbox.entity = self
	environment_hitbox.policy = func(_source, point):
		feedback.impact(point, "剑被挡住", 0, "obstruction")
		return {"accepted": true, "outcome": "obstruction", "hp_loss": 0.0}
	add_child(environment_hitbox)
	sword_melee.obstruction_hitbox = environment_hitbox

func sword_stage(stage: String) -> void:
	clock = 0
	if stage == "anticipation": phase = "anticipation"
	elif stage == "contact":
		phase = "contact"
		feedback.swing()
	elif stage == "recovery":
		phase = "recovery"
		player.current_animation = ""
		if combo < 2: player._play_animation("sword/Sword_Regular_%s_Rec" % ("A" if combo == 0 else "B"), 2.8)

func sword_finished() -> void:
	if buffered and combo < 2 and not player_locked():
		combo += 1
		start_swing()
	else:
		phase = "idle"
		player.current_animation = ""

func resolve_practice_contact(_source: SnaielDamageSource, point: Vector3) -> Dictionary:
	if not state.practice_hit:
		state.practice_hit = true
		commit()
	feedback.impact(point, "命中草靶", 0, "straw")
	tell("命中成立 · 回到赫斯身边按 E 练习防御")
	return {"accepted": true, "outcome": "practice", "hp_loss": 0.0}

func resolve_player_contact(source: SnaielDamageSource, _point: Vector3) -> Dictionary:
	var before: float = state.health
	var outcome = receive_attack(source.get_meta("attack_origin",source.entity.attack_origin), source.get_meta("attack_direction",source.entity.locked_direction), source.damage_attributes.health, false, source.get_meta("ranged_contact",false))
	if outcome == "parry": source.get_parried()
	return {"accepted": outcome in ["hurt", "block", "parry", "dodge", "protected"], "outcome": outcome, "hp_before": before, "hp_after": state.health, "hp_loss": before - state.health}

func resolved_enemy_contact(result: Dictionary) -> void:
	var defeated: bool = result.outcome == "defeat"
	feedback.impact(result.point, "击败" if defeated else "", result.hp_loss, "defeat" if defeated else "hit", result)
	if result.source_id == sword_source.get_instance_id() and combo == 2: stop_on_contact(0.045)

func ground_module() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		grounded = place_on_ground(hers, HERS_XZ) and place_on_ground(target, PRACTICE_XZ) and place_on_ground(monster, ENCOUNTER_XZ)
		if grounded: break
	if grounded:
		monster.home = monster.global_position
		# Home, terrain-derived navigation and the reset destination share one anchor.
		# Rebuild only a previously bound region; initial reset creates it otherwise.
		if is_instance_valid(monster.navigation_region): monster.build_navigation()
	if not grounded:
		push_error("Sword module placement lacks authored village ground")
	restore_history()

func place_on_ground(body: Node3D, xz: Vector2) -> bool:
	return GROUND.place(world, body, xz)

func restore_history() -> void:
	interrupt("load")
	death_time = 0
	recovery_settled = false
	last_outcome = ""
	last_hp_loss = 0
	commit_retry = false
	sim_phase = "idle"
	sim_clock = 0
	parry_cooldown = 0
	late_window = 0
	protection = 0
	notice_time = 0
	hers.idle()
	player.traversal.reset()
	player.owns_lamp = state.lamp_owned
	state.inventory.ensure_equipment()
	state.inventory.select_equipment(state.selected_equipment)
	player.configure_equipment(state.sword_owned, state.bow_owned, state.selected_equipment)
	monster.reset_encounter()
	player_hitbox.reset_contacts()
	target_hitbox.reset_contacts()
	environment_hitbox.reset_contacts()
	pickup_delay = 0.75
	if remnant: remnant.queue_free(); remnant = null
	if state.encounter_defeated and not state.remnant_collected: show_remnant()
	if state.lives <= 0:
		show_game_over()
	elif state.recovery_pending or state.health <= 0:
		death_time = 0.4
		recovery_settled = true
		phase = "death"
	else:
		phase = "idle"
	if world.lamp_training: world.lamp_training.restore_history()
	if world.bridge_encounter: world.bridge_encounter.restore_history()
	if world.channel_guards: world.channel_guards.restore_history()
	if world.dynamic_encounters: world.dynamic_encounters.restore_history()
	if feedback: feedback.clear_feedback()

func can_save() -> bool:
	return phase != "death" and not monster.engaged and sim_phase == "idle" and (world.bridge_encounter == null or world.bridge_encounter.can_save()) and (world.dynamic_encounters == null or world.dynamic_encounters.can_save()) and (world.channel_guards == null or world.channel_guards.can_save()) and (world.element_abilities == null or world.element_abilities.can_save()) and (world.lamp_training == null or world.lamp_training.reveal_remaining <= 0)

func commit() -> bool:
	state.selected_equipment = player.pending_weapon if player.switch_timer > 0 else player.weapon_mode
	state.sword_selected = state.selected_equipment == "sword"
	# Autosaves update history at the fixed CP01 anchor, never at the monster.
	var error: Error = state.save_progress(Vector3(CP01.x, 0, CP01.y), player.arm.rotation.y)
	commit_retry = error != OK
	if commit_retry:
		commit_retry_timer = 1.0
		tell("保存失败 · 保留当前进度，正在重试")
	return not commit_retry

func tell(message: String, seconds = 2.6, event_id := "") -> void:
	notice = message
	notice_time = seconds
	if world.gameplay_hud and not message.begins_with("命数") and not message.begins_with("保存"):
		world.gameplay_hud.notify(message, true, seconds, event_id)

func interaction_prompt() -> String:
	if state.lives <= 0: return ""
	if remnant and player.global_position.distance_to(remnant.global_position) < 2.0: return "◇ 靠近拾取经验残响 · +10 XP"
	if hers.can_interact(player): return "[E] 与赫斯交谈" if not state.sword_owned else ("[E] 复练训练怪 · 无额外奖励" if state.bow_owned and state.remnant_collected else "[E] 练习 / 重试振刀")
	return ""

func interact() -> bool:
	if hers.can_interact(player):
		if not state.q01_accepted:
			tell("赫斯：先去听伊莎的请求。")
		elif not state.sword_owned:
			world.open_hers_dialogue()
		elif state.bow_owned and state.remnant_collected:
			monster.begin_practice_replay()
			tell("赫斯：训练怪已就位，可用剑或弓复练；初战奖励不会重复。", 5)
		elif not state.practice_hit:
			hers.demonstrate()
			tell("赫斯：左键挥剑，击中右侧草靶；1 拔剑。")
		else:
			sim_phase = "prepare"
			sim_clock = 0.0
			tell("赫斯：看我抬手。右键挡，或 %s 闪避；临近接触再按右键可振刀。" % player.key_prompt("dodge"), 4)
		return true
	return false

func grant_sword() -> void:
	if not state.q01_accepted or state.sword_owned: return
	state.sword_owned = true
	sword_grants += 1
	state.hers_node = "H02"
	state.sword_selected = true
	state.selected_equipment = "sword"
	player.configure_equipment(true, state.bow_owned)
	player.request_weapon("sword")
	hers.demonstrate()
	commit()
	tell("取得巡路剑 · 1 拔剑 · 试击草靶", 5, "sword_acquired")

func player_locked() -> bool:
	return state.lives <= 0 or phase == "death" or hurt_time > 0

func motion_restricted() -> bool:
	return phase in ["anticipation", "contact", "recovery"] or blocking

func pose_owned() -> bool:
	return motion_restricted() or player_locked() or hit_stop > 0

func request_attack() -> void:
	if player.abilities and player.abilities.busy(): return
	if player_locked() or player.controls_open or player.switch_timer > 0 or not player.is_on_floor() or player.traversal.action != "" or player.traversal.posture != "standing": return
	if not state.sword_owned or player.weapon_mode != "sword": return
	if phase == "recovery" and clock >= recovery_duration() - 0.2 and combo < 2:
		buffered = true
		return
	if phase != "idle": return
	combo = 0
	start_swing()

func start_swing() -> void:
	protection = 0
	blocking = false
	parry_window = 0
	phase = "anticipation"
	clock = 0
	buffered = false
	if sword_melee: sword_melee.interrupt_attack()
	var facing = -player.camera.global_basis.z
	facing.y = 0
	player.visual.rotation.y = atan2(facing.x, facing.z)
	player.current_animation = ""
	# Imported clip contact is compressed to the product's 0.35s attack interval.
	var length: float = player.animation_player.get_animation(CLIPS[combo]).length
	player._play_animation(CLIPS[combo], length / 0.35)
	sword_source.global_position = player.global_position
	sword_melee.attack(combo, true, false)

func recovery_duration() -> float:
	return 0.5 if combo == 2 else 0.35

func interrupt(_reason: String) -> void:
	if world.element_abilities and _reason in ["death", "load", "recovery"]: world.element_abilities.clear_transients()
	if world.channel_guards and _reason in ["death", "load", "recovery"]: world.channel_guards.interrupt()
	if world.bridge_encounter and _reason in ["death", "load", "recovery"]: world.bridge_encounter.interrupt()
	if world.dynamic_encounters and _reason in ["death", "load", "recovery"]: world.dynamic_encounters.interrupt()
	player.reset_archery()
	if world.bow_training and _reason in ["death", "load", "recovery"]: world.bow_training.clear_transients()
	buffered = false
	blocking = false
	parry_window = 0
	if sword_melee: sword_melee.interrupt_attack()
	player.attack_timer = 0
	if phase != "death": phase = "idle"
	hurt_time = 0
	clock = 0
	hit_stop = 0
	if sword_events and sword_events.timeline: sword_events.timeline.speed_scale = 1
	if _reason in ["death", "load", "recovery"] and monster:
		monster.interrupt_action()
		player_hitbox.reset_contacts()
		if feedback: feedback.clear_feedback()
	if player.animation_player:
		player.animation_player.speed_scale = 1
		player.current_animation = ""

func set_block(pressed: bool) -> void:
	if pressed and player.abilities and player.abilities.busy(): return
	if not pressed:
		if blocking: player.current_animation = ""
		blocking = false
		parry_window = 0
		return
	if player_locked() or phase != "idle" or player.switch_timer > 0 or player.traversal.action != "" or player.traversal.posture != "standing" or player.weapon_mode != "sword": return
	if blocking: return
	if late_window > 0: tell("振刀偏晚 · 接触前按右键，松开后重试")
	blocking = true
	block_age = 0
	var facing = -player.camera.global_basis.z
	facing.y = 0
	player.visual.rotation.y = atan2(facing.x, facing.z)
	if parry_cooldown <= 0:
		parry_window = 0.16
		parry_cooldown = 0.5
	player.current_animation = ""
	player._play_animation("sword/Sword_Block")

func advance_player(delta: float) -> void:
	notice_time = maxf(0, notice_time - delta)
	parry_window = maxf(0, parry_window - delta)
	parry_cooldown = maxf(0, parry_cooldown - delta)
	late_window = maxf(0, late_window - delta)
	protection = maxf(0, protection - delta)
	if blocking: block_age += delta
	if commit_retry:
		# Retry the same snapshot, including settled lives, without reapplying
		# acquisition, damage or reward. Recovery waits for a successful write.
		commit_retry_timer -= delta
		if commit_retry_timer <= 0: commit()
	if phase == "death":
		death_time -= delta
		if death_time <= 0 and not commit_retry: recover_at_checkpoint()
		return
	if state.lives <= 0: return
	if hurt_time > 0:
		hurt_time = maxf(0, hurt_time - delta)
		return
	if hit_stop > 0:
		hit_stop = maxf(0, hit_stop - delta)
		if hit_stop <= 0:
			player.animation_player.speed_scale = 1
			sword_events.timeline.speed_scale = 1
		return
	if player.traversal.action != "" and phase != "idle": interrupt("dodge")
	if phase in ["anticipation", "contact", "recovery"]: clock += delta
	if sword_source.can_damage:
		sword_source.global_position = player.global_position
		var registry = {target: target_hitbox, monster: monster.hitbox}
		if world.bridge_encounter: registry.merge(world.bridge_encounter.registry())
		if world.channel_guards: registry.merge(world.channel_guards.registry())
		if world.dynamic_encounters: registry.merge(world.dynamic_encounters.registry())
		sword_melee.sweep(player, player.global_position + Vector3.UP * 0.95, player.visual.global_basis.z.normalized(), registry, 3)
	if blocking and player.animation_player.current_animation == "sword/Sword_Block":
		# Hold the completed guard pose; do not restart it every frame.
		if player.animation_player.current_animation_position >= 0.5: player.animation_player.pause()

func stop_on_contact(seconds: float) -> void:
	if state.reduced_motion: return
	hit_stop = maxf(hit_stop, seconds)
	player.animation_player.speed_scale = 0
	sword_events.timeline.speed_scale = 0

func receive_attack(origin: Vector3, direction: Vector3, amount: float, simulated = false, projectile_contact = false) -> String:
	last_hp_loss = 0
	if player_locked(): return "unavailable"
	if protection > 0: return "protected"
	var traversal: Node = player.traversal
	# Short dodge and longer roll have distinct damage windows. Their motion
	# can continue after immunity ends; sprint never enters either window.
	var evade_window_end: float = 0.20 if traversal.action == "dodge" else 0.27
	var dodging: bool = traversal.action in ["dodge", "roll"] and traversal.action_time >= 0.05 and traversal.action_time <= evade_window_end
	var toward: Vector3 = origin - player.global_position
	toward.y = 0
	var forward: Vector3 = player.visual.global_basis.z.normalized()
	var front: bool = toward.normalized().dot(forward) >= 0.5
	var on_line: bool = direction.dot((player.global_position - origin).normalized()) > 0.5
	# RangedContact is supplied only after the arrow's first physical tip sweep
	# resolves against this player. Melee retains its scoped proximity gate.
	var in_range: bool = projectile_contact or (player.global_position.distance_to(origin) < 2.15 and on_line)
	if dodging:
		if in_range or (simulated and player.global_position.distance_to(origin) < 3.5):
			last_outcome = "dodge"
		else: return "miss"
	elif not in_range: return "miss"
	elif blocking and front and parry_window > 0:
		last_outcome = "parry"
		parry_window = 0
		stop_on_contact(0.055)
		feedback.impact(player.global_position + Vector3.UP, "◇ 振刀", 0, "parry")
	elif blocking and front:
		last_outcome = "block"
		last_hp_loss = 0 if simulated else minf(state.health, amount * 0.3)
		feedback.impact(player.global_position + Vector3.UP, "◇ 格挡", last_hp_loss, "block")
	else:
		last_outcome = "hurt"
		last_hp_loss = 0 if simulated else minf(state.health, amount)
		if simulated:
			late_window = 0.3
			tell("未防住 · 练习不会扣血；抬手后挡或躲，可按 E 重试")
		else:
			interrupt("hurt")
			hurt_time = 0.45
			player._play_animation("Hit_Chest")
	state.health -= last_hp_loss
	if not simulated and last_outcome == "hurt" and state.health > 0:
		feedback.impact(player.global_position + Vector3.UP, "受击", last_hp_loss, "hurt")
	if simulated and last_outcome in ["block", "parry", "dodge"]:
		state.practice_defense = true
		if last_outcome == "parry": state.practice_parry = true
		commit()
		# Keep the timing result visible alongside the committed exercise.
		# A generic completion notice must not erase early/success feedback.
		var result_text = "振刀成功" if last_outcome == "parry" else ("格挡有效 · 振刀偏早" if last_outcome == "block" else "闪避有效")
		tell(result_text + " · 防御练习完成；可挑战训练怪，或松开右键按 E 重试", 4)
	if state.health <= 0: settle_death()
	return last_outcome

func lethal_fall() -> void:
	if phase != "death" and state.lives > 0:
		last_hp_loss = state.health
		last_outcome = "fall"
		state.health = 0
		settle_death()

func settle_death() -> void:
	if phase == "death" or state.lives <= 0: return
	interrupt("death")
	phase = "death"
	death_time = 1.8
	state.lives -= 1
	state.health = 0
	state.recovery_pending = true
	state.conversation_active = false
	recovery_settled = true
	player.velocity = Vector3.ZERO
	player._play_animation("Death01")
	# One terminal cue carries the same clamped loss as the lethal outcome.
	feedback.impact(player.global_position + Vector3.UP, "倒下", last_hp_loss, "death")
	commit()
	tell("命数 -1 · 剩余 %d · 返回河谷村庄灯台" % state.lives, 4)

func recover_at_checkpoint() -> void:
	if state.lives <= 0:
		show_game_over()
		return
	monster.reset_encounter()
	if world.bridge_encounter: world.bridge_encounter.restore_history()
	if world.channel_guards: world.channel_guards.restore_history()
	if world.dynamic_encounters: world.dynamic_encounters.restore_history()
	sim_phase = "idle"
	hers.idle()
	player.traversal.reset()
	# Recovery restores possession, selection and mounts together, including
	# interrupted switches or a sword stowed by the previous posture.
	player.owns_lamp = state.lamp_owned
	state.inventory.ensure_equipment()
	state.inventory.select_equipment(state.selected_equipment)
	player.configure_equipment(state.sword_owned, state.bow_owned, state.selected_equipment)
	if not place_on_ground(player, CP01):
		tell("检查点落地失败，请加载安全存档")
		return
	player.velocity = Vector3.ZERO
	state.health = 100
	state.recovery_pending = false
	phase = "idle"
	hurt_time = 0
	interrupt("recovery")
	player._update_animation(false)
	protection = 2
	feedback.clear_feedback()
	commit()

func show_game_over() -> void:
	phase = "death"
	world.show_failure()

func _physics_process(delta: float) -> void:
	if not grounded or player_locked() or world.pause_owners.size() > 0: return
	pickup_delay = maxf(0, pickup_delay - delta)
	if remnant and pickup_delay <= 0 and player.global_position.distance_to(remnant.global_position) < 1.65:
		var ray = PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 0.7, remnant.global_position + Vector3.UP * 0.7, 1, [player.get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): collect_remnant()
	if sim_phase == "idle": return
	sim_clock += delta
	if sim_phase == "prepare" and sim_clock >= 1.0:
		sim_phase = "telegraph"
		sim_clock = 0
		sim_origin = hers.global_position
		sim_direction = (player.global_position - sim_origin).normalized()
		hers.face_player(player)
		hers.telegraph()
		tell("◇ 模拟攻击 · 即将挥剑", 1.5)
	elif sim_phase == "telegraph" and sim_clock >= 1.1:
		hers.strike()
		sim_phase = "strike"
		sim_clock = 0
	elif sim_phase == "strike" and sim_clock >= 0.2:
		var ray = PhysicsRayQueryParameters3D.create(sim_origin + Vector3.UP, player.global_position + Vector3.UP, 1, [hers.get_rid(), player.get_rid()])
		var clear = get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
		var outcome = receive_attack(sim_origin, sim_direction, 6, true) if clear else "miss"
		if outcome == "miss": tell("攻击落空 · 请靠近赫斯读招，再按 E 重试")
		sim_phase = "recovery"
		sim_clock = 0
	elif sim_phase == "recovery" and sim_clock >= 0.9:
		sim_phase = "idle"
		hers.idle()

func enemy_defeated() -> void:
	if state.encounter_defeated: return
	state.encounter_defeated = true
	state.remnant_position = monster.global_position
	commit()
	show_remnant()
	pickup_delay = 0.75
	tell("训练怪已倒下 · 靠近金色残响自动拾取", 4)

func show_remnant() -> void:
	if remnant or state.remnant_collected: return
	remnant = Node3D.new()
	remnant.name = "ExperienceRemnant"
	add_child(remnant)
	var xz = Vector2(state.remnant_position.x, state.remnant_position.z)
	# A pre-layout unclaimed reward still belongs to the same encounter. Keep its
	# committed history, but display it within the revised reachable training yard.
	if xz.distance_to(ENCOUNTER_XZ) > 6.0: xz = ENCOUNTER_XZ
	if xz == Vector2.ZERO: xz = ENCOUNTER_XZ
	if not place_on_ground(remnant, xz) and not place_on_ground(remnant, ENCOUNTER_XZ):
		remnant.queue_free()
		remnant = null
		return
	var glow = CPUParticles3D.new()
	glow.amount = 14
	glow.lifetime = 1.4
	glow.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	glow.emission_sphere_radius = 0.2
	glow.direction = Vector3.UP
	glow.initial_velocity_min = 0.15
	glow.initial_velocity_max = 0.3
	glow.gravity = Vector3.ZERO
	glow.scale_amount_min = 0.03
	glow.scale_amount_max = 0.055
	glow.color = Color(1, 0.78, 0.18)
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1
	mesh.material = material
	glow.mesh = mesh
	glow.position.y = 0.65
	remnant.add_child(glow)
	var label = Label3D.new()
	label.text = "◇ 经验残响"
	label.font = preload("res://dialogue_theme.tres").default_font
	label.font_size = 44
	label.pixel_size = 0.005
	label.position.y = 1.25
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	remnant.add_child(label)

func collect_remnant() -> void:
	if state.remnant_collected or not state.encounter_defeated: return
	state.remnant_collected = true
	state.experience += 10
	if not commit():
		state.remnant_collected = false
		state.experience -= 10
		return
	if remnant: remnant.queue_free()
	remnant = null
	if not monster.practice_replay: monster.visible = false
	feedback.reward(10)
	tell("初战奖励已领取 · +10 XP；继续完成巡路剑教学", 4)

func player_snapshot() -> Dictionary:
	return {"phase": phase, "phase_time": clock, "combo": combo + 1, "buffered": buffered, "blocking": blocking, "parry_window": parry_window, "parry_cooldown": parry_cooldown, "health": state.health, "lives": state.lives, "last_outcome": last_outcome, "last_hp_loss": last_hp_loss, "protection": protection, "attack_instance": sword_source.instance if sword_source else 0, "damage_window": sword_source.can_damage if sword_source else false, "last_contact": player_hitbox.last_result if player_hitbox else {}}

func _mcp_state() -> Dictionary:
	# Scalar correlation only; reading this never grants or saves equipment.
	return {"sword_grants": sword_grants, "player": player_snapshot(), "history": state.training_snapshot(), "grounded": grounded, "simulation": sim_phase, "simulation_time": sim_clock, "hers_position": hers.global_position, "target_position": target.global_position, "monster": monster._mcp_state(), "remnant_visible": remnant != null, "notice": notice, "commit_retry": commit_retry}

func feedback_swing() -> void:
	if feedback: feedback.swing()
