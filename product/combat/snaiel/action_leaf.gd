# Adapted from addons/beehave/nodes/leaves/action.gd; see LICENSES.txt.
class_name SnaielAction extends SnaielLeaf

## Actions are leaf nodes that define a task to be performed by an actor.
## Their execution can be long running, potentially being called across multiple
## frame executions. In this case, the node should return `RUNNING` until the
## action is completed.

func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"SnaielAction")
	return classes

# Dependency-injected product action; tree retains Beehave RUNNING semantics.
var method: StringName
func tick(actor: Node, blackboard: SnaielBlackboard) -> int:
	return actor.call(method, blackboard)
