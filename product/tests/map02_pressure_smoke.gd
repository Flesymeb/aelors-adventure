extends Node
## Explicit isolated launch target. Never referenced by ordinary startup.
## The fixture intercepts saves; prepared E01 history is supplemental only.
func _ready() -> void:
	# Match production bus setup without loading or saving user preferences.
	var audio_defaults := preload("res://dialogue_state.gd").new()
	audio_defaults.apply_global_audio()
	audio_defaults.free()
	preload("res://tests/map02_pressure_test.gd").attach_diagnostic(self)
