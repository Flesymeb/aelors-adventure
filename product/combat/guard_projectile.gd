extends "res://arrow_projectile.gd"
## Retained tip sweep wins over Snaiel's unswept Area-body projectile.
var shooter: CharacterBody3D
var occurrence := 0
var source: SnaielDamageSource

func _ready() -> void:
	super()
	source = SnaielDamageSource.new()
	source.entity = shooter
	source.instance = occurrence
	source.can_damage = true
	source.damage_attributes.health = 10
	source.set_meta("attack_origin",shooter.attack_origin)
	source.set_meta("attack_direction",shooter.locked_direction)
	source.set_meta("ranged_contact",true)
	source.parried.connect(shooter.on_parried)
	add_child(source)
	first_contact.connect(_contact)

func _contact(hit: Dictionary) -> void:
	if not is_instance_valid(shooter) or not shooter.encounter.combat_allowed(): return
	var result: Dictionary
	if hit.collider == shooter.encounter.world.player:
		result = shooter.encounter.world.training.player_hitbox.contact(source,hit.position)
		if result.get("accepted",false): shooter.player_contacts += 1
	else:
		result = {"accepted":false,"outcome":"cover","hp_loss":0.0}
		shooter.cover_contacts += 1
		shooter.encounter.world.training.feedback.impact(hit.position,"",0,"obstruction")
	shooter.last_projectile_result = {"outcome":result.get("outcome","rejected"),"hp_loss":result.get("hp_loss",0.0),"attack_instance":occurrence,"collider":str(hit.collider.get_path()),"point":str(hit.position)}
	source.can_damage = false
