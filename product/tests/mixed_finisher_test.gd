extends Node
## Opt-in component qualification only. Never attached to normal startup;
## no inventory, world progression, preferences or persistent saves are changed.
var observations: Dictionary = {}
const CONTACT := preload("res://tests/player_contact_feedback_test.gd")

class FollowupWorld extends CONTACT.ContactWorld:
	var pause_owners := {}

class FollowupPlayer extends "res://player_controller.gd":
	func _ready() -> void: pass
	# Exercise the real mapped-key and held-edge dispatch, without installing
	# global InputMap entries or reading/writing user control preferences.
	func _control_pressed(event: InputEvent, action: String) -> bool:
		return not controls_open and not blocked_keys.has(effective_bindings[action]) and event is InputEventKey and event.pressed and event.keycode == effective_bindings[action]

class FollowupTraining extends "res://sword_training.gd":
	var eligible := true
	func finisher_eligible() -> bool:
		# Native floor support is outside this component fixture's qualification.
		return eligible and not player_locked() and not player.controls_open
	func commit() -> bool: return true
	func tell(_message: String, _seconds = 2.6, _event_id := "") -> void: pass

func _ready() -> void:
	observations = run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture": true, "observations": observations}

static func run(holder: Node) -> Dictionary:
	var attacks: Array[SnaielMeleeAttack] = [preload("res://sword_training.gd").finisher_strategy()]
	var events := SnaielMeleeAnimations.new()
	events.process_mode = Node.PROCESS_MODE_DISABLED
	holder.add_child(events)
	events.configure(attacks)
	var melee := SnaielMelee.new()
	melee.melee_animations = events
	var source := SnaielDamageSource.new()
	source.name = "SwordDamageSource"
	source.entity = CharacterBody3D.new()
	holder.add_child(source.entity)
	melee.add_child(source)
	melee.weapons = {&"sword": NodePath("SwordDamageSource")}
	holder.add_child(melee)
	melee.configure()
	var recipient := SnaielHitbox.new()
	recipient.entity = Node3D.new()
	holder.add_child(recipient.entity)
	holder.add_child(recipient)
	var damage := {"hp": 100.0, "contacts": 0}
	recipient.policy = func(hit_source, _point):
		var before: float = damage.hp
		damage.hp = maxf(0.0, damage.hp - hit_source.damage_attributes.health)
		damage.contacts += 1
		return {"accepted": true, "outcome": "hit", "hp_before": before, "hp_after": damage.hp, "hp_loss": before - damage.hp}
	melee.attack(0)
	events.timeline.advance(0.0)
	var initial := {"instance": source.instance, "damage_window": source.can_damage, "stage": events.stage}
	recipient.contact(source, Vector3.ZERO)
	var anticipation_hp: float = damage.hp
	events.timeline.advance(attacks[0].anticipation + 0.01)
	var contact := {"instance": source.instance, "damage_window": source.can_damage, "stage": events.stage}
	recipient.contact(source, Vector3.ZERO)
	recipient.contact(source, Vector3.ZERO)
	var contact_hp: float = damage.hp
	events.timeline.advance(attacks[0].contact_time + 0.01)
	recipient.contact(source, Vector3.ZERO)
	var recovery := {"damage_window": source.can_damage, "hp": damage.hp, "contacts": damage.contacts}
	melee.interrupt_attack()
	events.timeline.advance(1.0)
	var cancelled := {"damage_window": source.can_damage, "attacking": events.attacking, "hp": damage.hp}
	# A new segment can hit the same target; the prior instance cannot re-settle.
	melee.attack(0)
	events.timeline.advance(0.0)
	events.timeline.advance(attacks[0].anticipation + 0.01)
	recipient.contact(source, Vector3.ZERO)
	var repeated := {"instance": source.instance, "hp": damage.hp, "contacts": damage.contacts}
	var result := {"initial": initial, "contact": contact, "recovery": recovery, "cancelled": cancelled, "next_instance": repeated,
		"checks": {"anticipation_has_no_contact": anticipation_hp == 100.0 and not initial.damage_window,
		"single_settlement": contact_hp == 72.0 and recovery.hp == 72.0 and recovery.contacts == 1,
		"one_contact_window": contact.damage_window and not recovery.damage_window,
		"interruption_closes_window": not cancelled.damage_window and not cancelled.attacking and cancelled.hp == 72.0,
		"new_instance_can_settle": repeated.instance == 2 and repeated.contacts == 2 and repeated.hp == 44.0},
		"scope": "actual Snaiel event/contact owners; grounding, held input, collision obstruction and rig motion require ordinary runtime checks"}
	# Exercise production link admission around both light recovery windows.
	var training = preload("res://sword_training.gd").new()
	training.sword_events = events
	events.attacks = [SnaielMeleeAttack.new(), SnaielMeleeAttack.new(), SnaielMeleeAttack.new(), preload("res://sword_training.gd").aerial_strategy(), attacks[0]]
	training.phase = "recovery"
	var admission := {}
	for link in [0, 1]:
		training.combo = link
		training.clock = 0.149
		admission["light_%d_early_rejected" % link] = not training.can_link_finisher()
		training.clock = 0.151
		admission["light_%d_window_admitted" % link] = training.can_link_finisher()
		training.clock = 0.351
		admission["light_%d_expired_rejected" % link] = not training.can_link_finisher()
	training.clock = 0.2
	for link in [2, 3, 4]:
		training.combo = link
		admission["invalid_link_%d" % link] = not training.can_link_finisher()
	training.combo = 0
	for stage in ["idle", "anticipation", "contact", "death"]:
		training.phase = stage
		admission[stage + "_rejected"] = not training.can_link_finisher()
	training.phase = "recovery"
	training.buffered = true
	admission.light_buffer_excludes_heavy = not training.can_link_finisher()
	training.buffered = false
	training.finisher_buffered = true
	admission.repeated_heavy_rejected = not training.can_link_finisher()
	training.clear_attack_buffers()
	admission.clear_discards_both = not training.buffered and not training.finisher_buffered
	# Exercise the actual modal adapter with a pending buffer and current move.
	# Detached actor: no _ready, inventory setup or user preference/save writes.
	var modal_player = preload("res://player_controller.gd").new()
	modal_player.combat = training
	training.player = modal_player
	training.finisher_buffered = true
	var stage_before: String = training.phase
	var clock_before: float = training.clock
	modal_player.set_controls_open(true)
	admission.modal_open_clears = not training.finisher_buffered and not training.buffered
	training.finisher_buffered = true
	modal_player.set_controls_open(false)
	admission.modal_close_clears = not training.finisher_buffered and not training.buffered
	admission.modal_preserves_current_move = training.phase == stage_before and training.clock == clock_before
	modal_player.free()
	result.admission = admission
	# Cancellation before the contact event must remain closed after advancing.
	events.attacks = attacks
	melee.attack(0)
	events.timeline.advance(0.0)
	melee.interrupt_attack()
	events.timeline.advance(2.0)
	recipient.contact(source, Vector3.ZERO)
	result.checks.cancel_before_contact = damage.hp == 44.0 and not source.can_damage and not events.attacking
	result.checks.stronger_longer_recovery = attacks[0].damage_attributes.health > 15.0 and attacks[0].recovery > 0.35
	result.parry_followup = parry_followup_checks(holder)
	training.free()
	melee.interrupt_attack()
	source.entity.free()
	recipient.entity.free()
	recipient.free()
	melee.free()
	events.free()
	return result

static func heavy_event(player: Node, pressed: bool, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = player.effective_bindings.heavy
	event.pressed = pressed
	event.echo = echo
	return event

static func parry_followup_checks(holder: Node) -> Dictionary:
	var world := FollowupWorld.new()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	holder.add_child(world)
	var training := FollowupTraining.new()
	world.add_child(training)
	training.world = world
	var state = preload("res://dialogue_state.gd").new()
	# Detached real state: never loads, saves or grants ordinary progression.
	state.sword_owned = true
	state.reduced_motion = false
	training.state = state
	var player := FollowupPlayer.new()
	training.player = player
	player.combat = training
	player.weapon_mode = "sword"
	player.effective_bindings.heavy = KEY_Y
	player.visual = Node3D.new()
	player.visual.name = "Visual"
	player.add_child(player.visual)
	player.arm = SpringArm3D.new()
	player.arm.name = "CameraArm"
	player.add_child(player.arm)
	player.camera = Camera3D.new()
	player.camera.name = "Camera"
	player.arm.add_child(player.camera)
	world.add_child(player)
	player.animation_player = AnimationPlayer.new()
	player.add_child(player.animation_player)
	var library := AnimationLibrary.new()
	var clip := Animation.new()
	clip.length = 1.0
	library.add_animation("Grounded_Finisher", clip)
	library.add_animation("Aerial_Heavy", clip.duplicate())
	player.animation_player.add_animation_library("sword", library)
	player.traversal = preload("res://traversal_controller.gd").new()
	training.feedback = CONTACT.ContactFeedback.new()
	world.add_child(training.feedback)
	var enemy := CONTACT.ContactEnemy.new()
	world.add_child(enemy)
	training.monster = enemy
	var events := SnaielMeleeAnimations.new()
	world.add_child(events)
	var attacks: Array[SnaielMeleeAttack] = [SnaielMeleeAttack.new(), SnaielMeleeAttack.new(), SnaielMeleeAttack.new(), training.aerial_strategy(), training.finisher_strategy()]
	events.configure(attacks)
	training.sword_events = events
	var melee := SnaielMelee.new()
	melee.melee_animations = events
	world.add_child(melee)
	var source := SnaielDamageSource.new()
	source.name = "SwordDamageSource"
	source.entity = player
	melee.add_child(source)
	melee.weapons = {&"sword": NodePath("SwordDamageSource")}
	melee.configure()
	training.sword_melee = melee
	training.sword_source = source
	training.player_hitbox = SnaielHitbox.new()
	world.add_child(training.player_hitbox)
	var checks := {}
	training.blocking = true
	training.parry_window = 0.1
	var outcome: String = training.receive_attack(Vector3(0, 0, 1), Vector3(0, 0, -1), 12.0)
	checks.real_parry_grants_exact_window = outcome == "parry" and is_equal_approx(training.parry_followup_remaining, 0.6)
	checks.guard_must_release = not training.can_parry_finisher()
	training.advance_parry_followup(0.2)
	training.parry_window = 0.1
	training.receive_attack(Vector3(0, 0, 1), Vector3(0, 0, -1), 12.0)
	checks.repeated_parry_does_not_extend_window = is_equal_approx(training.parry_followup_remaining, 0.4)
	var previous_mouse_mode := Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player._input(heavy_event(player, true))
	training.set_block(false)
	player._input(heavy_event(player, true))
	checks.held_heavy_cannot_dispatch_on_guard_release = training.phase == "idle" and source.instance == 0 and training.parry_followup_remaining > 0.0
	player._input(heavy_event(player, false))
	player._input(heavy_event(player, true))
	checks.fresh_mapped_heavy_starts_retained_finisher_once = training.combo == training.FINISHER_INDEX and training.phase == "anticipation" and source.instance == 1 and training.parry_followup_remaining == 0.0 and source.damage_attributes.health == 28.0
	checks.early_counterattack_preserves_existing_stop_on_both_clocks = is_equal_approx(training.hit_stop, 0.055) and player.animation_player.speed_scale == 0 and events.timeline.speed_scale == 0
	player._input(heavy_event(player, true, true))
	player._input(heavy_event(player, true))
	checks.duplicate_and_echo_do_not_restart = source.instance == 1
	training.interrupt("hurt")
	# The real start_swing turned the rig toward its camera. Restore the
	# contact fixture's +Z attacker facing before testing defense negatives.
	player.visual.rotation = Vector3.ZERO
	training.parry_followup_remaining = 0.6
	training.advance_parry_followup(0.599)
	checks.window_exists_before_expiry = training.can_parry_finisher()
	training.advance_parry_followup(0.002)
	player._input(heavy_event(player, false))
	player._input(heavy_event(player, true))
	checks.expired_fresh_input_has_no_delayed_attack = training.parry_followup_remaining == 0.0 and source.instance == 1 and training.phase == "idle"
	training.blocking = true
	training.parry_window = 0.1
	outcome = training.receive_attack(Vector3(0, 0, 1), Vector3(0, 0, -1), 12.0, true)
	checks.simulated_parry_grants_nothing = outcome == "parry" and training.parry_followup_remaining == 0.0
	training.parry_window = 0.1
	training.receive_attack(Vector3(0, 0, 1), Vector3(0, 0, -1), 12.0, false, false, false)
	checks.unblockable_grants_nothing = training.parry_followup_remaining == 0.0
	training.eligible = false
	training.parry_window = 0.1
	outcome = training.receive_attack(Vector3(0, 0, 1), Vector3(0, 0, -1), 12.0)
	checks.ineligible_parry_grants_nothing = outcome == "parry" and training.parry_followup_remaining == 0.0
	training.eligible = true
	training.parry_window = 0
	outcome = training.receive_attack(Vector3(0, 0, 1), Vector3(0, 0, -1), 12.0)
	checks.late_block_grants_nothing = outcome == "block" and training.parry_followup_remaining == 0.0
	training.blocking = false
	for reason in ["hurt", "death", "switch", "load", "travel", "exit", "dodge", "focus"]:
		training.parry_followup_remaining = 0.6
		training.interrupt(reason)
		checks[reason + "_discards_followup"] = training.parry_followup_remaining == 0.0
	training.parry_followup_remaining = 0.6
	world.pause_owners.controls = true
	player.set_controls_open(true)
	checks.pause_preserves_gameplay_window = training.parry_followup_remaining == 0.6 and not training.can_parry_finisher()
	world.pause_owners.clear()
	player.set_controls_open(false)
	checks.resume_does_not_dispatch = source.instance == 1 and training.parry_followup_remaining == 0.6
	world.pause_owners.dialogue = true
	player.set_controls_open(true)
	checks.dialogue_modal_discards_window = training.parry_followup_remaining == 0.0
	world.pause_owners.clear()
	player.set_controls_open(false)
	training.parry_followup_remaining = 0.6
	training.combo = 0
	training.phase = "idle"
	player.traversal.air_time = 0.1
	training.request_attack()
	checks.first_accepted_aerial_consumes_window = training.aerial_active and source.instance == 2 and training.parry_followup_remaining == 0.0
	checks.remapped_counterattack_guidance = training.repractice_guidance().contains("[Y]") and player.CONTROL_LABELS.heavy.contains("parry")
	Input.mouse_mode = previous_mouse_mode
	player.traversal.free()
	world.free()
	state.free()
	return {"checks": checks, "scope": "isolated production contact, event owner and mapped edge dispatch; native grounding, ordinary timing, obstruction, heard feedback and Continue remain independent runtime checks"}
