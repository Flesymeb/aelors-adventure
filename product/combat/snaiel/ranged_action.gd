extends Node
## Adapted NonMeleeComponent/EnemyNonMeleeComponent boundary (Snaiel MIT).
## One legal occurrence, interrupted execution, blackboard request and release.
## The product supplies bow pose and swept projectile instead of template magic.
signal stage_changed(stage: String)
signal action_effect(instance: int)
var blackboard: SnaielBlackboard
var executing_action := false
var can_perform_action := true
var instance := 0
var elapsed := 0.0
var cooldown := 0.0
var stage := "idle"
const ANTICIPATION := 0.8
const RECOVERY := 0.55
const INTERVAL := 2.0

func perform_action() -> bool:
	if not can_perform_action or executing_action: return false
	instance += 1
	executing_action = true
	can_perform_action = false
	elapsed = 0
	cooldown = INTERVAL
	stage = "telegraph"
	stage_changed.emit(stage)
	return true

func tick(delta: float, eligible: bool) -> void:
	cooldown = maxf(0, cooldown - delta)
	if not executing_action:
		can_perform_action = cooldown <= 0
		if eligible and blackboard.get_value("perform_action", false):
			blackboard.set_value("perform_action", false)
			perform_action()
	else:
		if not eligible:
			interrupt_action()
			return
		elapsed += delta
		if stage == "telegraph" and elapsed >= ANTICIPATION:
			stage = "attack"
			stage_changed.emit(stage)
			action_effect.emit(instance)
		elif stage == "attack" and elapsed >= ANTICIPATION + 0.12:
			stage = "recovery"
			stage_changed.emit(stage)
		elif elapsed >= ANTICIPATION + RECOVERY:
			executing_action = false
			can_perform_action = cooldown <= 0
			stage = "idle"
			stage_changed.emit(stage)
	blackboard.set_value("executing_action", executing_action)

func interrupt_action() -> void:
	executing_action = false
	can_perform_action = cooldown <= 0
	elapsed = 0
	stage = "idle"
	if blackboard:
		blackboard.set_value("perform_action", false)
		blackboard.set_value("executing_action", false)
	stage_changed.emit(stage)
