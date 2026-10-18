extends RefCounted
## Opt-in resource/dispatch contract. Run against the delivered pack as well
## as source; this does not earn an encounter, save, reward or ordinary history.
const ACTIONS := "res://combat/snaiel/scenes/beehave/trees/EnemyActions.tscn"
const PATROL := "res://combat/snaiel/scenes/beehave/trees/Patrol.tscn"
const CALLBACKS := {
	"GotHit/WaitForHurt": &"tick_hurt",
	"Attack": &"tick_attack",
	"PursueOrReturn": &"tick_approach",
	"Patrol/Stationary/Wait": &"tick_patrol_wait",
	"Patrol/Move": &"tick_patrol_move",
}

class DecisionActor extends Node:
	var calls: Array[StringName] = []
	var action := &"tick_hurt"
	func dispatch(method: StringName) -> int:
		calls.append(method)
		return SnaielBehaviorNode.RUNNING if method == action else SnaielBehaviorNode.FAILURE
	func tick_hurt(_board: SnaielBlackboard) -> int: return dispatch(&"tick_hurt")
	func tick_attack(_board: SnaielBlackboard) -> int: return dispatch(&"tick_attack")
	func tick_approach(_board: SnaielBlackboard) -> int: return dispatch(&"tick_approach")
	func tick_patrol_wait(_board: SnaielBlackboard) -> int: return dispatch(&"tick_patrol_wait")
	func tick_patrol_move(_board: SnaielBlackboard) -> int: return dispatch(&"tick_patrol_move")

static func binding_checks() -> Dictionary:
	var checks := {}
	for path in [ACTIONS, PATROL]:
		var scene: PackedScene = load(path)
		var node := scene.instantiate()
		var expected: Dictionary = CALLBACKS if path == ACTIONS else {"Stationary/Wait": &"tick_patrol_wait", "Move": &"tick_patrol_move"}
		var prefix := "actions" if path == ACTIONS else "patrol"
		for relative in expected:
			var leaf: Node = node.get_node(relative)
			checks[prefix + ":" + relative + ":loaded"] = leaf.get("method") == expected[relative]
			var stored := false
			for property in leaf.get_property_list():
				if property.name == "method": stored = bool(property.usage & PROPERTY_USAGE_STORAGE)
			checks[prefix + ":" + relative + ":storage"] = stored
		# A real PackedScene packing step exposed the source-only false positive:
		# loaded callbacks existed, but vanished from the converted SceneState.
		var packed := PackedScene.new()
		checks[prefix + ":pack"] = packed.pack(node) == OK
		var restored := packed.instantiate()
		for relative in expected:
			checks[prefix + ":" + relative + ":roundtrip"] = restored.get_node(relative).get("method") == expected[relative]
		var condition := restored.get_node("GotHit/IsGotHitTrue" if path == ACTIONS else "Stationary/AtPoint")
		checks[prefix + ":comparison_control"] = condition.left_operand != "" and condition.right_operand != ""
		restored.free()
		node.free()
	return checks

static func decision_checks(parent: Node) -> Dictionary:
	# The actual serialized selector/sequence decides which callback to call.
	# The spy is only a unit contract, never reported as enemy gameplay.
	var actor := DecisionActor.new()
	parent.add_child(actor)
	var board := SnaielBlackboard.new()
	actor.add_child(board)
	var source: PackedScene = load(ACTIONS)
	var original := source.instantiate()
	var packed := PackedScene.new()
	packed.pack(original)
	original.free()
	var decisions: SnaielBehaviorNode = packed.instantiate()
	actor.add_child(decisions)
	var behavior := SnaielBehaviorTree.new()
	behavior.actor = actor
	behavior.blackboard = board
	behavior.root_node = decisions
	actor.add_child(behavior)
	var checks := {}
	for method in CALLBACKS.values():
		behavior.interrupt()
		actor.calls.clear()
		actor.action = method
		board.set_value("got_hit", method == &"tick_hurt")
		board.set_value("patrol_dist", 0.0 if method == &"tick_patrol_wait" else 1.0)
		behavior.tick(1.0 / 60.0)
		checks[str(method) + ":tree_dispatch"] = method in actor.calls and behavior.last_status == SnaielBehaviorNode.RUNNING
		# Interruption must allow a higher-priority action on the next tick.
		behavior.interrupt()
		actor.calls.clear()
		actor.action = &"tick_attack"
		board.set_value("got_hit", false)
		behavior.tick(1.0 / 60.0)
		checks[str(method) + ":interrupt_reselects"] = actor.calls == [&"tick_attack"]
	actor.free()
	return checks

static func actor_binding_checks() -> Dictionary:
	var checks := {}
	for path in ["res://TrainingMonster.tscn", "res://combat/Map02MeleeGuard.tscn", "res://assets/bosses/warden_actor.tscn", "res://assets/bosses/veyne_actor.tscn", "res://combat/snaiel/scenes/entities/BaseEnemy.tscn"]:
		var scene: PackedScene = load(path)
		var actor := scene.instantiate()
		var packed := PackedScene.new()
		checks[path + ":pack"] = packed.pack(actor) == OK
		var restored := packed.instantiate()
		for relative in CALLBACKS:
			var method: StringName = restored.get_node("EnemyActions/" + relative).get("method")
			checks[path + ":" + relative] = method == CALLBACKS[relative] and restored.has_method(method)
		restored.free()
		actor.free()
	return checks
