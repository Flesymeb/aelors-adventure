extends Node
## Scoped adaptation of Snaiel idle_animations.
var character: Node
func set_idle() -> void:
	character.play("Idle")
