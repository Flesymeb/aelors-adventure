# Adapted from addons/beehave/nodes/beehave_node.gd; see LICENSES.txt.
class_name SnaielBehaviorNode extends Node

## A node in the behavior tree. Every node must return `SUCCESS`, `FAILURE` or
## `RUNNING` when ticked.

enum { SUCCESS, FAILURE, RUNNING }


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if get_children().any(func(x): return not (x is SnaielBehaviorNode)):
		warnings.append("All children of this node should inherit from SnaielBehaviorNode class.")

	return warnings


## Executes this node and returns a status code.
## This method must be overwritten.
func tick(actor: Node, blackboard: SnaielBlackboard) -> int:
	return SUCCESS


## Called when this node needs to be interrupted before it can return FAILURE or SUCCESS.
func interrupt(actor: Node, blackboard: SnaielBlackboard) -> void:
	pass


## Called before the first time it ticks by the parent.
func before_run(actor: Node, blackboard: SnaielBlackboard) -> void:
	pass


## Called after the last time it ticks and returns
## [code]SUCCESS[/code] or [code]FAILURE[/code].
func after_run(actor: Node, blackboard: SnaielBlackboard) -> void:
	pass


func get_class_name() -> Array[StringName]:
	return [&"SnaielBehaviorNode"]


func can_send_message(blackboard: SnaielBlackboard) -> bool:
	return blackboard.get_value("can_send_message", false)
