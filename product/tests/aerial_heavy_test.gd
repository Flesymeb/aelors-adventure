extends Node
## Opt-in component qualification only. Never attached to normal startup;
## no inventory, world progression, preferences or persistent saves are changed.
var observations: Dictionary = {}

func _ready() -> void:
	observations = run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture": true, "observations": observations}

static func run(holder: Node) -> Dictionary:
	var attacks: Array[SnaielMeleeAttack] = [preload("res://sword_training.gd").aerial_strategy()]
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
		"single_settlement": contact_hp == 76.0 and recovery.hp == 76.0 and recovery.contacts == 1,
		"one_contact_window": contact.damage_window and not recovery.damage_window,
		"interruption_closes_window": not cancelled.damage_window and not cancelled.attacking and cancelled.hp == 76.0,
		"new_instance_can_settle": repeated.instance == 2 and repeated.contacts == 2 and repeated.hp == 52.0},
		"scope": "actual Snaiel event/contact owners; airborne input, collision obstruction, rig motion and landing require ordinary runtime checks"}
	melee.interrupt_attack()
	source.entity.free()
	recipient.entity.free()
	recipient.free()
	melee.free()
	events.free()
	return result
