extends "res://element_abilities.gd"
## MAP02 retains combat abilities without presenting the CH01 teaching targets.

func ground() -> void:
	for target in targets:
		target.hide()
		target.collision_layer = 0
	grounded = false

func eligible_target(target) -> bool:
	if is_instance_valid(target) and target is StaticBody3D and target in targets:
		return false
	return super(target)
