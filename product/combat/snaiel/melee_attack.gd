class_name SnaielMeleeAttack
extends Resource
## Snaiel attack strategy adapted to existing clips and physics-owned movement.
@export var attack_name: StringName
@export var damage_attributes: SnaielDamageAttributes = SnaielDamageAttributes.new()
@export var secondary_movement: SnaielSecondaryMovement = SnaielSecondaryMovement.new()
@export var anticipation = 0.2
@export var contact_time = 0.15
@export var recovery = 0.35
@export var strike_delay = 0.0
