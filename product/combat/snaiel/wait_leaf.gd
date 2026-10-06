class_name SnaielWait
extends SnaielAction
## Adapted scripts/beehave/wait/wait.gd: pause-safe delta, interrupt resets wait.
var time = 0.45
var elapsed = 0.0

func before_run(_actor: Node, _blackboard: SnaielBlackboard) -> void:
	elapsed = 0

func tick(_actor: Node, blackboard: SnaielBlackboard) -> int:
	elapsed += blackboard.get_value("delta", 0.0)
	return SUCCESS if elapsed >= time else RUNNING

func interrupt(_actor: Node, _blackboard: SnaielBlackboard) -> void:
	elapsed = 0
