class_name ShortSwitch
extends SwitchComponent
## Adapted from the selected Nodragem unit. Permanent clue activation is explicit,
## distinct from investigation, and cannot be toggled off by repeated input.
@export var permanent := true

func on_interaction(requested: bool) -> void:
	if not requested or (permanent and is_activated): return
	is_activated = true if permanent else not is_activated
	update_animation()

func update_animation() -> void:
	var animator = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animator:
		var clip = "on_state" if is_activated else "off_state"
		if animator.has_animation(clip): animator.play(clip)
