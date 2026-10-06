# Adapted from addons/beehave/nodes/leaves/condition.gd; see LICENSES.txt.
class_name SnaielCondition extends SnaielLeaf

## Conditions are leaf nodes that either return SUCCESS or FAILURE depending on
## a single simple condition. They should never return `RUNNING`.

func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"SnaielCondition")
	return classes
