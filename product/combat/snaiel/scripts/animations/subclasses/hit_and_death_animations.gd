extends Node
## Scoped adaptation of Snaiel hit_and_death_animations.
var character: Node
func hit() -> void:
	character.play("HitReact", 1.0, true)
func death() -> void:
	character.play("Death", 1.0, true)
