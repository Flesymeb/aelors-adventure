extends Node3D

const BOW_MESH := preload("res://Weapons/Bow_Golden.obj")
const ARROW_MESH := preload("res://Weapons/Arrow.obj")
const STRING_TOP := Vector3(0.2105, 0.534, 0.0)
const STRING_BOTTOM := Vector3(0.2105, -0.534, 0.0)
const REST_NOCK := Vector3(0.2105, 0.0, 0.0)

var upper_string: MeshInstance3D
var lower_string: MeshInstance3D
var held_arrow: MeshInstance3D


func _ready() -> void:
	var mesh := ArrayMesh.new()
	for i in range(BOW_MESH.get_surface_count()):
		var material := BOW_MESH.surface_get_material(i)
		# Remove the static string, rather than drawing a second string over it.
		if material and material.resource_name == "White":
			continue
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, BOW_MESH.surface_get_arrays(i))
		mesh.surface_set_material(mesh.get_surface_count() - 1, material)
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.scale = Vector3.ONE * 0.21
	body.position.x = -0.0063
	add_child(body)
	upper_string = _make_string()
	lower_string = _make_string()
	held_arrow = MeshInstance3D.new()
	held_arrow.mesh = ARROW_MESH
	held_arrow.scale = Vector3.ONE * 0.24
	held_arrow.visible = false
	add_child(held_arrow)
	set_draw(false, REST_NOCK, Vector3(0, 0, -1))


func _make_string() -> MeshInstance3D:
	var segment := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.002
	cylinder.bottom_radius = 0.002
	cylinder.height = 1.0
	cylinder.radial_segments = 6
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.83, 0.80, 0.65)
	cylinder.material = material
	segment.mesh = cylinder
	add_child(segment)
	return segment


func _set_segment(segment: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var direction := end - start
	segment.position = (start + end) * 0.5
	segment.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	segment.scale = Vector3(1.0, direction.length(), 1.0)


func set_draw(arrow_visible: bool, nock: Vector3, arrow_direction: Vector3) -> void:
	_set_segment(upper_string, STRING_TOP, nock)
	_set_segment(lower_string, STRING_BOTTOM, nock)
	held_arrow.visible = arrow_visible
	held_arrow.position = nock
	held_arrow.basis = Basis.looking_at(-arrow_direction.normalized(), Vector3.UP).scaled(Vector3.ONE * 0.24)
