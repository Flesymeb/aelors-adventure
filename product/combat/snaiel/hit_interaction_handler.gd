class_name SnaielHitHandler
extends Node
## Adapted HitInteractionHandler; product policy precedes HP and reaction.
signal interaction
signal resolved(result: Dictionary)
var blackboard: SnaielBlackboard
var health_component: SnaielHealth
var eligibility: Callable
var reaction: Callable

func handle_interaction(source: SnaielDamageSource, _point: Vector3) -> Dictionary:
	if not health_component.is_alive() or not eligibility.call(): return {"accepted": false}
	var before = health_component.health
	var loss = health_component.incoming_damage(source)
	if loss <= 0: return {"accepted": false}
	var result = {"accepted": true, "outcome": "defeat" if not health_component.is_alive() else "hit", "hp_before": before, "hp_after": health_component.health, "hp_loss": loss}
	blackboard.set_value("got_hit", health_component.is_alive())
	interaction.emit()
	if reaction.is_valid(): reaction.call(result)
	resolved.emit(result)
	return result
