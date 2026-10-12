extends Node
## Opt-in component qualification only. Never attached to normal startup;
## no inventory, world progression, preferences or persistent saves are changed.
var observations: Dictionary = {}

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
	training.free()
	melee.interrupt_attack()
	source.entity.free()
	recipient.entity.free()
	recipient.free()
	melee.free()
	events.free()
	return result
