extends Node3D

const LIFE := 1.1
const FLAKE_COUNT := 16

var seed_value := 1009
var age := 0.0
var flakes: Array[MeshInstance3D] = []
var velocities: Array[Vector3] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var flake_mesh := SphereMesh.new()
	flake_mesh.radius = 0.035
	flake_mesh.height = 0.07
	flake_mesh.radial_segments = 4
	flake_mesh.rings = 2
	var materials: Array[StandardMaterial3D] = []
	for tint in [Color(0.53, 0.68, 0.85), Color(0.76, 0.87, 0.97)]:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = tint
		materials.append(material)
	for i in range(FLAKE_COUNT):
		var flake := MeshInstance3D.new()
		flake.mesh = flake_mesh
		flake.material_override = materials[i % materials.size()]
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(0.02, 0.14)
		flake.position = Vector3(cos(angle) * radius, rng.randf_range(0.0, 0.04), sin(angle) * radius)
		flake.scale = Vector3.ONE * rng.randf_range(0.7, 1.35)
		add_child(flake)
		flakes.append(flake)
		var speed := rng.randf_range(0.55, 1.45)
		velocities.append(Vector3(cos(angle) * speed, rng.randf_range(0.9, 1.7), sin(angle) * speed))


func _process(delta: float) -> void:
	age += delta
	if age >= LIFE:
		queue_free()
		return
	for i in range(flakes.size()):
		velocities[i].y -= 2.3 * delta
		flakes[i].position += velocities[i] * delta
		flakes[i].scale *= maxf(0.0, 1.0 - delta * 1.4)
