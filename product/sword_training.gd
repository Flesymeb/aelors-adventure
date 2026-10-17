extends Node3D
## Product policy: acquisition, defense, checkpoint/reward history and presentation.
## Snaiel melee/hitboxes own attack windows, instances and contact settlement.
const HEAVY_RESPONSE := preload("res://combat/player_impact_response.gd")
var heavy_impact = HEAVY_RESPONSE.new()
const DAMAGES = [12.0, 15.0, 20.0]
const CLIPS = ["sword/Sword_Regular_A", "sword/Sword_Regular_B", "sword/Sword_Regular_C"]
const AERIAL_INDEX = 3
const AERIAL_DAMAGE = 24.0
const FINISHER_INDEX = 4
const FINISHER_DAMAGE = 28.0
const PARRY_FOLLOWUP_SECONDS = 0.6
var parry_followup_remaining := 0.0
var finisher_buffered = false
var finisher_animation_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
var aerial_active = false
var aerial_used = false
var aerial_landed = false
var aerial_recovery_left = 0.0
var aerial_animation_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
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
var sword_presentation: Node3D
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
# Latest actual animation-stop interval only. Opted in through the existing F9
# developer switch; never saved, displayed, or used by combat decisions.
var _stop_serial := 0
var _stop_trace: Dictionary = {}
var _stop_pause_started_us := 0
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
var repractice_guidance_time := 0.0

func _exit_tree() -> void:
	clear_parry_followup()
	clear_attack_buffers()

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
	strategies.append(aerial_strategy())
	strategies.append(finisher_strategy())
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
	sword_presentation = preload("res://combat/sword_presentation.gd").new()
	sword_presentation.name = "SwordPresentation"
	add_child(sword_presentation)
	sword_presentation.configure(self)
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

static func aerial_strategy() -> SnaielMeleeAttack:
	var aerial = SnaielMeleeAttack.new()
	aerial.attack_name = "sword/Aerial_Heavy"
	aerial.airborne = true
	aerial.damage_attributes.health = AERIAL_DAMAGE
	# Retained UAL2 overhead: source 2.1..3.45 at 2.4x, one down-cut.
	aerial.anticipation = 0.18
	aerial.contact_time = 0.13
	aerial.recovery = 1.35 / 2.4 - 0.31
	return aerial

static func finisher_strategy() -> SnaielMeleeAttack:
	var finisher = SnaielMeleeAttack.new()
	finisher.attack_name = "sword/Grounded_Finisher"
	finisher.damage_attributes.health = FINISHER_DAMAGE
	# First UAL2 heavy cut at source speed, then exposed end-pose recovery.
	finisher.anticipation = 0.4
	finisher.contact_time = 0.2
	finisher.recovery = 0.7
	return finisher

func clear_attack_buffers() -> void:
	buffered = false
	finisher_buffered = false

func clear_parry_followup() -> void:
	parry_followup_remaining = 0.0

func can_parry_finisher() -> bool:
	return parry_followup_remaining > 0.0 and phase == "idle" and not blocking and finisher_eligible()

func advance_parry_followup(delta: float) -> void:
	# The actor's gameplay clock is paused by the world owner. No wall timer or
	# pending heavy press can dispatch a follow-up when control returns.
	if parry_followup_remaining <= 0.0: return
	if not finisher_eligible() or phase != "idle":
		clear_parry_followup()
		return
	parry_followup_remaining = maxf(0.0, parry_followup_remaining - delta)

func can_link_finisher() -> bool:
	return phase == "recovery" and combo in [0, 1] and clock >= recovery_duration() - 0.2 and clock <= recovery_duration() and not buffered and not finisher_buffered

func finisher_eligible() -> bool:
	return not player_locked() and not player.controls_open and player.switch_timer <= 0 and player.traversal.action == "" and player.traversal.posture == "standing" and state.sword_owned and player.weapon_mode == "sword" and player.is_on_floor() and not aerial_active and not (player.abilities and player.abilities.busy())

func request_finisher() -> void:
	if not finisher_eligible(): return
	if not player.animation_player.has_animation(player.FINISHER_CLIP): return
	if can_parry_finisher():
		combo = FINISHER_INDEX
		start_swing()
		return
	if not can_link_finisher(): return
	clear_parry_followup()
	finisher_buffered = true

func sword_stage(stage: String) -> void:
	clock = 0
	if sword_presentation: sword_presentation.attack_stage(stage)
	if stage == "anticipation": phase = "anticipation"
	elif stage == "contact":
		phase = "contact"
		feedback.swing()
	elif stage == "recovery":
		phase = "recovery"
		if aerial_active: return
		player.current_animation = ""
		if combo < 2: player._play_animation("sword/Sword_Regular_%s_Rec" % ("A" if combo == 0 else "B"), 2.8)

func sword_finished() -> void:
	if sword_presentation: sword_presentation.clear_presentation()
	if combo == FINISHER_INDEX:
		player.animation_player.callback_mode_process = finisher_animation_process
	if aerial_active:
		phase = "air_recovery"
		return
	if finisher_buffered:
		var eligible = finisher_eligible()
		clear_attack_buffers()
		if eligible:
			combo = FINISHER_INDEX
			start_swing()
			return
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

func resolve_player_contact(source: SnaielDamageSource, point: Vector3) -> Dictionary:
	var before: float = state.health
	# The hitbox appends identity after this policy returns. Capture it now so
	# immediate defense/hurt/death cues describe this contact, not a later pose.
	var contact := {"point": point, "source_id": source.get_instance_id(), "attack_instance": source.instance, "receiver": str(player.get_path()), "hp_before": before, "simulated": false, "heavy_impact_requested": source.get_meta("heavy_impact", false), "impact_origin": source.get_meta("attack_origin", source.entity.attack_origin), "attack_direction": source.get_meta("attack_direction", source.entity.locked_direction)}
	var outcome = receive_attack(source.get_meta("attack_origin",source.entity.attack_origin), source.get_meta("attack_direction",source.entity.locked_direction), source.damage_attributes.health, false, source.get_meta("ranged_contact",false),not source.get_meta("unblockable",false),not source.get_meta("unparryable",false), contact)
	if outcome == "parry": source.get_parried()
	contact.merge({"accepted": outcome in ["hurt", "block", "parry", "dodge", "protected"], "outcome": outcome, "hp_after": state.health, "hp_loss": before - state.health}, true)
	return contact

func resolved_enemy_contact(result: Dictionary) -> void:
	var defeated: bool = result.outcome == "defeat"
	feedback.impact(result.point, "击败" if defeated else "", result.hp_loss, "defeat" if defeated else "hit", result)
	if result.source_id == sword_source.get_instance_id() and (combo == 2 or combo == FINISHER_INDEX or aerial_active): stop_on_contact(0.045, result)

func ground_module() -> void:
	if world.meadow_slice:
		grounded = true
		restore_history()
		return
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
	return world.ground_policy.place(world, body, xz)

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
	if not world.meadow_slice: monster.reset_encounter()
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
	if world.pressure_encounter: world.pressure_encounter.restore_history()
	if world.ambush_encounter: world.ambush_encounter.restore_history()
	if world.line_encounter: world.line_encounter.restore_history()
	if world.channel_guards: world.channel_guards.restore_history()
	if world.dynamic_encounters: world.dynamic_encounters.restore_history()
	if world.get("warden_encounter"): world.warden_encounter.restore_history()
	if world.get("veyne_encounter"): world.veyne_encounter.restore_history()
	if feedback: feedback.clear_feedback()

func can_save() -> bool:
	if world.get("veyne_encounter") and not world.veyne_encounter.can_save(): return false
	if world.get("warden_encounter") and not world.warden_encounter.can_save(): return false
	return phase != "death" and not monster.engaged and sim_phase == "idle" and (world.bridge_encounter == null or world.bridge_encounter.can_save()) and (world.dynamic_encounters == null or world.dynamic_encounters.can_save()) and (world.channel_guards == null or world.channel_guards.can_save()) and (world.pressure_encounter == null or world.pressure_encounter.can_save()) and (world.ambush_encounter == null or world.ambush_encounter.can_save()) and (world.line_encounter == null or world.line_encounter.can_save()) and (world.element_abilities == null or world.element_abilities.can_save()) and (world.lamp_training == null or world.lamp_training.reveal_remaining <= 0)

func commit() -> bool:
	state.selected_equipment = player.pending_weapon if player.switch_timer > 0 else player.weapon_mode
	state.sword_selected = state.selected_equipment == "sword"
	# Autosaves update history at the fixed CP01 anchor, never at the monster.
	var error: Error = state.save_progress(Vector3(world.checkpoint_xz().x, 0, world.checkpoint_xz().y), player.arm.rotation.y)
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
	if finisher_buffered: return "终结技已衔接 · 等待轻击收招"
	if parry_followup_remaining > 0.0 and phase == "idle" and finisher_eligible():
		if blocking: return "振刀反击 · 松开格挡后按 [%s] 终结" % player.key_prompt("heavy")
		return "[%s] 振刀反击终结 · 收招更长" % player.key_prompt("heavy")
	if finisher_eligible() and can_link_finisher(): return "[%s] 重击终结 · 更强一击，收招更长" % player.key_prompt("heavy")
	if remnant and player.global_position.distance_to(remnant.global_position) < 2.0: return "◇ 靠近拾取经验残响 · +10 XP"
	if hers.can_interact(player):
		if not state.sword_owned: return "[E] 与赫斯交谈"
		if monster.practice_replay: return "[E] 再次剑术复练 · 无额外奖励" if monster.health <= 0 else "复练进行中 · 退回赫斯处脱离"
		return "[E] 可选剑术复练 · 无额外奖励" if can_repractice() else "[E] 练习 / 重试振刀"
	if repractice_guidance_time > 0 and monster.practice_replay and monster.health > 0 and not monster.engaged and player.weapon_mode == "sword" and phase == "idle" and not player_locked(): return repractice_guidance()
	return ""

func can_repractice() -> bool:
	return state.sword_owned and state.encounter_defeated and state.remnant_collected and grounded and not player_locked() and sim_phase == "idle" and world.pause_owners.is_empty()

func repractice_guidance() -> String:
	return "复练 · 轻击收招末段 / 振刀松挡后 [%s] 终结；[%s] 闪避 · 无额外奖励" % [player.key_prompt("heavy"), player.key_prompt("dodge")]

func interact() -> bool:
	if hers.can_interact(player):
		if not state.q01_accepted:
			tell("赫斯：先去听伊莎的请求。")
		elif not state.sword_owned:
			world.open_hers_dialogue()
		elif monster.practice_replay:
			if monster.health <= 0:
				monster.end_practice_replay()
				start_repractice()
			else:
				tell("复练进行中 · 先退回赫斯处，等待训练怪返回", 2.6)
		elif can_repractice():
			start_repractice()
		elif not state.practice_hit:
			hers.demonstrate()
			tell("赫斯：左键挥剑，击中右侧草靶；1 拔剑。")
		else:
			sim_phase = "prepare"
			sim_clock = 0.0
			tell("赫斯：看我抬手。右键挡，或 %s 闪避；临近接触再按右键可振刀。" % player.key_prompt("dodge"), 4)
		return true
	return false

func start_repractice() -> void:
	if monster.begin_practice_replay():
		repractice_guidance_time = 5.0
		tell("可选剑术复练已开始 · 无额外奖励", 2.6, "sword_repractice")

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
	tell("取得巡路剑 · 1 拔剑 · 左键轻击后收招末段按 %s 重击终结" % player.key_prompt("heavy"), 5, "sword_acquired")

func player_locked() -> bool:
	return state.lives <= 0 or phase == "death" or hurt_time > 0 or heavy_impact.active()

func motion_restricted() -> bool:
	return phase in ["anticipation", "contact", "recovery", "air_recovery", "landing_recovery"] or blocking

func pose_owned() -> bool:
	return motion_restricted() or player_locked() or hit_stop > 0

func request_attack() -> void:
	if player.abilities and player.abilities.busy(): return
	if player_locked() or player.controls_open or player.switch_timer > 0 or player.traversal.action != "" or player.traversal.posture != "standing": return
	if not state.sword_owned or player.weapon_mode != "sword": return
	if not player.is_on_floor():
		if phase != "idle" or aerial_used or player.traversal.step_grace > 0.0 or player.traversal.air_time <= 0.0: return
		if not player.animation_player.has_animation(player.AERIAL_CLIP): return
		aerial_active = true
		aerial_used = true
		aerial_landed = false
		combo = AERIAL_INDEX
		start_swing()
		return
	if aerial_active: return
	if phase == "recovery" and clock >= recovery_duration() - 0.2 and combo < 2 and not finisher_buffered:
		clear_parry_followup()
		buffered = true
		return
	if phase != "idle": return
	combo = 0
	start_swing()

func start_swing() -> void:
	clear_parry_followup()
	protection = 0
	blocking = false
	parry_window = 0
	phase = "anticipation"
	clock = 0
	clear_attack_buffers()
	if sword_melee: sword_melee.interrupt_attack()
	var facing = -player.camera.global_basis.z
	facing.y = 0
	player.visual.rotation.y = atan2(facing.x, facing.z)
	player.current_animation = ""
	# Imported clip contact is compressed to the product's 0.35s attack interval.
	if aerial_active:
		aerial_animation_process = player.animation_player.callback_mode_process
		player.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
		player._play_animation(player.AERIAL_CLIP, player.AERIAL_PLAYBACK_SPEED)
		player.animation_player.advance(0.0)
	elif combo == FINISHER_INDEX:
		finisher_animation_process = player.animation_player.callback_mode_process
		player.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
		player._play_animation(player.FINISHER_CLIP, 1.0)
		player.animation_player.advance(0.0)
	else:
		var length: float = player.animation_player.get_animation(CLIPS[combo]).length
		player._play_animation(CLIPS[combo], length / 0.35)
	sword_source.global_position = player.global_position
	sword_melee.attack(combo, true, false)
	# A fresh counterattack may arrive during the existing brief parry stop.
	# Starting its clip must not resume only the rig ahead of contact events.
	if hit_stop > 0:
		player.animation_player.speed_scale = 0
		sword_events.timeline.speed_scale = 0

func recovery_duration() -> float:
	return sword_events.attacks[combo].recovery

func sword_landed() -> void:
	aerial_used = false
	if not aerial_active: return
	# Landing never starts a second segment. It closes even a late strike.
	sword_melee.interrupt_attack()
	player.animation_player.callback_mode_process = aerial_animation_process
	aerial_landed = true
	phase = "landing_recovery"
	clock = 0
	aerial_recovery_left = sword_events.attacks[AERIAL_INDEX].landing_recovery
	player.current_animation = ""
	player._play_animation("Jump_Land", 2.0)

func interrupt(_reason: String) -> void:
	clear_parry_followup()
	repractice_guidance_time = 0.0
	cancel_heavy_response()
	if sword_presentation: sword_presentation.clear_presentation()
	if world.get("veyne_encounter") and _reason in ["death","load","recovery"]: world.veyne_encounter.interrupt()
	if world.get("warden_encounter") and _reason in ["death","load","recovery"]: world.warden_encounter.interrupt()
	if world.element_abilities and _reason in ["death", "load", "recovery"]: world.element_abilities.clear_transients()
	if world.channel_guards and _reason in ["death", "load", "recovery"]: world.channel_guards.interrupt()
	if world.ambush_encounter and _reason in ["death", "load", "recovery"]: world.ambush_encounter.interrupt()
	if world.line_encounter and _reason in ["death", "load", "recovery"]: world.line_encounter.interrupt()
	if world.pressure_encounter and _reason in ["death", "load", "recovery"]: world.pressure_encounter.interrupt()
	if world.bridge_encounter and _reason in ["death", "load", "recovery"]: world.bridge_encounter.interrupt()
	if world.dynamic_encounters and _reason in ["death", "load", "recovery"]: world.dynamic_encounters.interrupt()
	player.reset_archery()
	if world.bow_training and _reason in ["death", "load", "recovery"]: world.bow_training.clear_transients()
	clear_attack_buffers()
	if combo == FINISHER_INDEX and player.animation_player:
		player.animation_player.callback_mode_process = finisher_animation_process
	if aerial_active and player.animation_player:
		player.animation_player.callback_mode_process = aerial_animation_process
	aerial_active = false
	aerial_landed = false
	aerial_recovery_left = 0
	# Hurt/switch/dodge cannot buy a second strike in the same airborne arc.
	if _reason in ["death", "load", "recovery"]: aerial_used = false
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
	if _reason in ["death", "load", "recovery", "travel", "exit"] and monster and monster.has_method("end_practice_replay"):
		monster.end_practice_replay()
	if player.animation_player:
		player.animation_player.speed_scale = 1
		player.current_animation = ""
	_observe_stop_end(_reason)

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

func cancel_heavy_response() -> void:
	if heavy_impact.active() and player.has_method("suppress_held_combat_actions"):
		player.suppress_held_combat_actions()
	heavy_impact.cancel()
	if player.has_method("clear_camera_impulse"): player.clear_camera_impulse()

func advance_player(delta: float) -> void:
	advance_parry_followup(delta)
	repractice_guidance_time = maxf(0.0, repractice_guidance_time - delta)
	if heavy_impact.advance(delta):
		clear_attack_buffers()
		if player.has_method("suppress_held_combat_actions"): player.suppress_held_combat_actions()
		player.current_animation = ""
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
		if not _stop_trace.is_empty() and _stop_trace.stop_exit_wall_us == 0:
			_stop_trace.stop_gameplay_seconds += delta
		hit_stop = maxf(0, hit_stop - delta)
		if hit_stop <= 0:
			player.animation_player.speed_scale = 1
			sword_events.timeline.speed_scale = 1
			_observe_stop_end("elapsed")
		return
	if player.traversal.action != "" and phase != "idle": interrupt("dodge")
	if aerial_active and phase == "landing_recovery":
		clock += delta
		aerial_recovery_left = maxf(0.0, aerial_recovery_left - delta)
		if aerial_recovery_left <= 0:
			aerial_active = false
			phase = "idle"
			player.current_animation = ""
		return
	if phase in ["anticipation", "contact", "recovery"]: clock += delta
	if sword_source.can_damage:
		sword_source.global_position = player.global_position
		var registry = {target: target_hitbox, monster: monster.hitbox}
		if world.bridge_encounter: registry.merge(world.bridge_encounter.registry())
		if world.pressure_encounter: registry.merge(world.pressure_encounter.registry())
		if world.ambush_encounter: registry.merge(world.ambush_encounter.registry())
		if world.line_encounter: registry.merge(world.line_encounter.registry())
		if world.channel_guards: registry.merge(world.channel_guards.registry())
		if world.dynamic_encounters: registry.merge(world.dynamic_encounters.registry())
		if world.get("warden_encounter"): registry.merge(world.warden_encounter.registry())
		if world.get("veyne_encounter"): registry.merge(world.veyne_encounter.registry())
		if aerial_active:
			# Contact follows the retained hand mount and blade's local +Y axis.
			# No body-centred aerial sphere or landing shockwave can award a hit.
			sword_melee.sweep(player, player.sword_holder.global_position, player.sword_holder.global_basis.y.normalized(), registry, 3, true)
		else:
			sword_melee.sweep(player, player.global_position + Vector3.UP * 0.95, player.visual.global_basis.z.normalized(), registry, 3)
	if blocking and player.animation_player.current_animation == "sword/Sword_Block":
		# Hold the completed guard pose; do not restart it every frame.
		if player.animation_player.current_animation_position >= 0.5: player.animation_player.pause()

func stop_on_contact(seconds: float, contact: Dictionary = {}) -> void:
	if state.reduced_motion: return
	var already_stopped: bool = player.animation_player.speed_scale == 0 and sword_events.timeline.speed_scale == 0
	hit_stop = maxf(hit_stop, seconds)
	player.animation_player.speed_scale = 0
	sword_events.timeline.speed_scale = 0
	if not _stop_observation_enabled(): return
	if not already_stopped:
		_stop_serial += 1
		_stop_pause_started_us = 0
		_stop_trace = {"stop_id": _stop_serial, "stop_entry_wall_us": Time.get_ticks_usec(),
			"stop_exit_wall_us": 0, "stop_paused_wall_us": 0, "stop_gameplay_seconds": 0.0,
			"stop_entry_animation_speed": player.animation_player.speed_scale,
			"stop_entry_timeline_speed": sword_events.timeline.speed_scale,
			"stop_exit_animation_speed": -1.0, "stop_exit_timeline_speed": -1.0,
			"stop_end_reason": "", "stop_source_id": contact.get("source_id", 0),
			"stop_attack_instance": contact.get("attack_instance", 0),
			"stop_receiver": contact.get("receiver", ""), "stop_outcome": contact.get("outcome", "parry"),
			"stop_simulated": contact.get("simulated", false), "stop_contacts": 0}
	# Multiple resolved contacts may share an interval. Retain its first identity
	# and the latest trigger, rather than inventing another speed transition.
	if not _stop_trace.is_empty() and _stop_trace.stop_exit_wall_us == 0:
		_stop_trace.stop_contacts += 1
		_stop_trace.stop_last_source_id = contact.get("source_id", 0)
		_stop_trace.stop_last_attack_instance = contact.get("attack_instance", 0)

func _stop_observation_enabled() -> bool:
	return is_instance_valid(world) and world.get("developer_ui") == true

func _observe_stop_end(reason: String) -> void:
	if _stop_trace.is_empty() or _stop_trace.stop_exit_wall_us != 0: return
	var now := Time.get_ticks_usec()
	if _stop_pause_started_us != 0:
		_stop_trace.stop_paused_wall_us += now - _stop_pause_started_us
		_stop_pause_started_us = 0
	_stop_trace.stop_exit_wall_us = now
	_stop_trace.stop_end_reason = reason
	_stop_trace.stop_exit_animation_speed = player.animation_player.speed_scale
	_stop_trace.stop_exit_timeline_speed = sword_events.timeline.speed_scale

func _notification(what: int) -> void:
	if _stop_trace.is_empty() or _stop_trace.stop_exit_wall_us != 0: return
	# Includes inspection freezes: wall time is explicitly not gameplay time.
	if what == NOTIFICATION_PAUSED and _stop_pause_started_us == 0:
		_stop_pause_started_us = Time.get_ticks_usec()
	elif what == NOTIFICATION_UNPAUSED and _stop_pause_started_us != 0:
		_stop_trace.stop_paused_wall_us += Time.get_ticks_usec() - _stop_pause_started_us
		_stop_pause_started_us = 0

func stop_observation() -> Dictionary:
	# Pure scalar projection: reads neither finish intervals nor sample clocks.
	if not _stop_observation_enabled(): return {"stop_observation_enabled": false}
	# Native watches resolve fields before driving input. Stable scalar defaults
	# let the very first contact be sampled; id/time 0 and speed -1 mean that
	# the corresponding edge has not been observed, never a successful result.
	var observation := {"stop_id": 0, "stop_entry_wall_us": 0, "stop_exit_wall_us": 0,
		"stop_paused_wall_us": 0, "stop_gameplay_seconds": 0.0, "stop_end_reason": "",
		"stop_source_id": 0, "stop_attack_instance": 0, "stop_receiver": "", "stop_outcome": "",
		"stop_simulated": false, "stop_contacts": 0, "stop_last_source_id": 0,
		"stop_last_attack_instance": 0, "stop_entry_animation_speed": -1.0,
		"stop_entry_timeline_speed": -1.0, "stop_exit_animation_speed": -1.0,
		"stop_exit_timeline_speed": -1.0}
	observation.merge(_stop_trace, true)
	observation.stop_observation_enabled = true
	observation.stop_remaining_seconds = hit_stop
	observation.stop_pause_started_wall_us = _stop_pause_started_us
	observation.stop_animation_speed = player.animation_player.speed_scale
	observation.stop_timeline_speed = sword_events.timeline.speed_scale
	return observation

func receive_attack(origin: Vector3, direction: Vector3, amount: float, simulated = false, projectile_contact = false, blockable = true, parryable = true, contact: Dictionary = {}) -> String:
	last_hp_loss = 0
	# Heavy stagger restricts controls, never incoming HP settlement. The hitbox
	# retains duplicate source/attack rejection while the guard rejects retrigger.
	if player_locked() and not heavy_impact.active(): return "unavailable"
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
	elif parryable and blocking and front and parry_window > 0:
		last_outcome = "parry"
		parry_window = 0
		# Only the accepted real defense result earns this choice. Coach timing
		# exercises and held defense never create or extend an opportunity.
		if not simulated and blockable and phase == "idle" and state.get("sword_owned") == true and player.get("weapon_mode") == "sword" and finisher_eligible() and parry_followup_remaining <= 0.0:
			parry_followup_remaining = PARRY_FOLLOWUP_SECONDS
		stop_on_contact(0.055, contact.merged({"outcome": "parry", "simulated": simulated}, true))
	elif blockable and blocking and front:
		last_outcome = "block"
		last_hp_loss = 0 if simulated else minf(state.health, amount * 0.3)
	else:
		last_outcome = "hurt"
		last_hp_loss = 0 if simulated else minf(state.health, amount)
		if simulated:
			late_window = 0.3
			tell("未防住 · 练习不会扣血；抬手后挡或躲，可按 E 重试")
	var before: float = state.health
	state.health -= last_hp_loss
	var resolved := contact.duplicate(true)
	resolved.merge({"accepted": last_outcome in ["hurt", "block", "parry", "dodge", "protected"], "outcome": last_outcome, "hp_before": before, "hp_after": state.health, "hp_loss": last_hp_loss, "simulated": simulated}, true)
	if not simulated and last_outcome == "hurt" and state.health > 0:
		var requested: bool = resolved.get("heavy_impact_requested", false)
		var guarded: bool = heavy_impact.active() or heavy_impact.guard_remaining > 0.0
		var can_stagger: bool = requested and not guarded and player.is_on_floor() and player.traversal.get("posture") == "standing"
		if can_stagger:
			interrupt("heavy_hurt")
			resolved["heavy_stagger_started"] = heavy_impact.begin(resolved, resolved.get("impact_origin", origin), player.global_position)
			if resolved.heavy_stagger_started:
				clear_attack_buffers()
				if player.has_method("suppress_held_combat_actions"): player.suppress_held_combat_actions()
				player._play_animation("Upright_Heavy_Hurt")
			else:
				# A source without a usable planar origin/direction still owns
				# the ordinary surviving hurt response rather than losing it.
				hurt_time = 0.45
				player._play_animation("Hit_Chest")
		elif not guarded:
			interrupt("hurt")
			hurt_time = 0.45
			player._play_animation("Hit_Chest")
	contact.merge({"heavy_stagger_started": resolved.get("heavy_stagger_started", false)}, true)
	# Only simulated training/direct fall callers lack physical contact geometry.
	var point: Vector3 = resolved.get("point", player.global_position + Vector3.UP)
	if last_outcome == "parry":
		feedback.impact(point, "◇ 振刀", 0, "parry", resolved)
	elif last_outcome == "block":
		feedback.impact(point, "◇ 格挡", last_hp_loss, "block", resolved)
	elif not simulated and last_outcome == "hurt" and state.health > 0:
		feedback.impact(point, "受击", last_hp_loss, "hurt", resolved)
	if simulated and last_outcome in ["block", "parry", "dodge"]:
		state.practice_defense = true
		if last_outcome == "parry": state.practice_parry = true
		commit()
		# Keep the timing result visible alongside the committed exercise.
		# A generic completion notice must not erase early/success feedback.
		var result_text = "振刀成功" if last_outcome == "parry" else ("格挡有效 · 振刀偏早" if last_outcome == "block" else "闪避有效")
		tell(result_text + " · 防御练习完成；可挑战训练怪，或松开右键按 E 重试", 4)
	if state.health <= 0: settle_death(resolved)
	return last_outcome

func lethal_fall() -> void:
	if phase != "death" and state.lives > 0:
		last_hp_loss = state.health
		last_outcome = "fall"
		state.health = 0
		settle_death()

func settle_death(contact: Dictionary = {}) -> void:
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
	feedback.impact(contact.get("point", player.global_position + Vector3.UP), "倒下", last_hp_loss, "death", contact)
	commit()
	tell("命数 -1 · 剩余 %d · 返回%s" % [state.lives,state.checkpoint_name()], 4)

func recover_at_checkpoint() -> void:
	if state.lives <= 0:
		show_game_over()
		return
	if not world.meadow_slice: monster.reset_encounter()
	if world.bridge_encounter: world.bridge_encounter.restore_history()
	if world.pressure_encounter: world.pressure_encounter.restore_history()
	if world.ambush_encounter: world.ambush_encounter.restore_history()
	if world.line_encounter: world.line_encounter.restore_history()
	if world.channel_guards: world.channel_guards.restore_history()
	if world.dynamic_encounters: world.dynamic_encounters.restore_history()
	if world.get("warden_encounter"): world.warden_encounter.restore_history()
	if world.get("veyne_encounter"): world.veyne_encounter.restore_history()
	sim_phase = "idle"
	hers.idle()
	player.traversal.reset()
	# Recovery restores possession, selection and mounts together, including
	# interrupted switches or a sword stowed by the previous posture.
	player.owns_lamp = state.lamp_owned
	state.inventory.ensure_equipment()
	state.inventory.select_equipment(state.selected_equipment)
	player.configure_equipment(state.sword_owned, state.bow_owned, state.selected_equipment)
	if not place_on_ground(player, world.checkpoint_xz()):
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
	return {"phase": phase, "phase_time": clock, "combo": combo + 1, "buffered": buffered, "finisher_buffered": finisher_buffered, "parry_followup_remaining": parry_followup_remaining, "finisher_active": combo == FINISHER_INDEX and phase != "idle", "aerial_active": aerial_active, "aerial_used": aerial_used, "aerial_landed": aerial_landed, "landing_recovery_left": aerial_recovery_left, "blocking": blocking, "parry_window": parry_window, "parry_cooldown": parry_cooldown, "health": state.health, "lives": state.lives, "last_outcome": last_outcome, "last_hp_loss": last_hp_loss, "protection": protection, "attack_instance": sword_source.instance if sword_source else 0, "damage_window": sword_source.can_damage if sword_source else false, "last_contact": player_hitbox.last_result if player_hitbox else {}, "heavy_impact": heavy_impact.observation()}

func _mcp_state() -> Dictionary:
	# Scalar correlation only; reading this never grants or saves equipment.
	var observation := {"sword_grants": sword_grants, "player": player_snapshot(), "history": state.training_snapshot(), "grounded": grounded, "simulation": sim_phase, "simulation_time": sim_clock, "hers_position": hers.global_position, "target_position": target.global_position, "monster": monster._mcp_state(), "remnant_visible": remnant != null, "notice": notice, "commit_retry": commit_retry}
	observation.merge(stop_observation())
	return observation

func feedback_swing() -> void:
	if feedback: feedback.swing()
