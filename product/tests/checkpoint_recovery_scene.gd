extends Node
var test_results: Dictionary = {}
func _ready() -> void:
	test_results = await preload("res://tests/checkpoint_recovery_regression.gd").run(self)
func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture":true,"results":test_results}
