extends Node3D
## Explicit scene-only source qualification; no adventure, preferences or saves.
@onready var village: Node3D = $AuthoredForest
func _ready() -> void:
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 12, 28)
	camera.rotation_degrees = Vector3(-10, 180, 0)
	camera.current = true
