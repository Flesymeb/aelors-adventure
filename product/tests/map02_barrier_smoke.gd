extends Node
## Explicit save-intercepted fixture; never referenced by ordinary startup.
func _ready() -> void:
	preload("res://tests/map02_barrier_test.gd").attach_diagnostic(self)
