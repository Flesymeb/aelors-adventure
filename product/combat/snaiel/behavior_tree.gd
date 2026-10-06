class_name SnaielBehaviorTree
extends Node
## Beehave tree lifecycle adapted to explicit physics ticks and dependency injection.
var actor: Node
var blackboard: SnaielBlackboard
var enabled = true
var root_node: SnaielBehaviorNode
var last_status = SnaielBehaviorNode.SUCCESS

func tick(delta: float) -> void:
	if not enabled: return
	blackboard.set_value("delta", delta)
	last_status = root_node.tick(actor, blackboard)
	if last_status != SnaielBehaviorNode.RUNNING: root_node.after_run(actor, blackboard)

func interrupt() -> void:
	if root_node: root_node.interrupt(actor, blackboard)

func _mcp_state() -> Dictionary:
	return {"enabled": enabled, "status": last_status, "attacking": blackboard.get_value("attacking", false), "got_hit": blackboard.get_value("got_hit", false)}
