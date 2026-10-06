# Adapted from scripts/resources/damage_attributes.gd; see LICENSES.txt.
class_name SnaielDamageAttributes
extends Resource


## Receiving entity damage on health on hit
@export var health: float = 10.0

## Receiving entity instability on hit
@export var hit_instability: float = 20.0
## Receiving entity instability on block
@export var block_instability: float = 20.0
## Receiving entity instability on parry
@export var parry_instability: float = 5.0

## This entity got parried
@export var got_parried_instability: float = 30.0

@export var knockback: SnaielSecondaryMovement = \
	SnaielSecondaryMovement.new()


static func create(
	_health: float,
	_hit_instability: float,
	_block_instability: float,
	_parry_instability: float,
	_knockback: SnaielSecondaryMovement
) -> SnaielDamageAttributes:
	var instance = SnaielDamageAttributes.new()
	instance.health = _health
	instance.hit_instability = _hit_instability
	instance.block_instability = _block_instability
	instance.parry_instability = _parry_instability
	instance.knockback = _knockback
	return instance
