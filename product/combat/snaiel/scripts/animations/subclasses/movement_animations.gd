extends Node
## Scoped adaptation of Snaiel movement_animations.
var character: Node
func move(speed: float) -> void:
	character.play("Walk", clampf(speed / 1.25, 0.3, 1.3))
