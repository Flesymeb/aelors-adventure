extends "res://ui/game_entry_router.gd"
## Opt-in ordinary-input smoke with disposable disk persistence across restarts.
func create_adventure_state() -> Node:
	DirAccess.make_dir_recursive_absolute("user://developer_recovery_checks")
	return preload("res://tests/entry_lifecycle_test.gd").RecoveryDiskState.new()
