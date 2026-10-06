# Adapted from addons/beehave/nodes/composites/composite.gd; see LICENSES.txt.
class_name SnaielComposite extends SnaielBehaviorNode

## A SnaielComposite node controls the flow of execution of its children in a specific manner.

var running_child: SnaielBehaviorNode = null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super._get_configuration_warnings()

	if get_children().filter(func(x): return x is SnaielBehaviorNode).size() < 2:
		warnings.append("Any composite node should have at least two children. Otherwise it is not useful.")

	return warnings


func interrupt(actor: Node, blackboard: SnaielBlackboard) -> void:
	if running_child != null:
		running_child.interrupt(actor, blackboard)
		running_child = null


func after_run(actor: Node, blackboard: SnaielBlackboard) -> void:
	running_child = null


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"SnaielComposite")
	return classes
