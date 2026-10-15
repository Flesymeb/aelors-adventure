extends MeshInstance3D
## Adapted from Cat Prisbrey's MeshStreak (Unlicense); see LICENSES.txt.
## Keep the source's paired world-space blade edges and triangle-strip ribbon.
## Product events own emission; no equipment polling or asynchronous toggles.
var origin_node: Node3D
var streak_bottom := Vector3(0, 0.28, 0)
var streak_top := Vector3(0, 0.97, 0)
var emitting := false
var lifetime := 0.11
var maximum_edges := 14
var mesh_array: Array[Dictionary] = []

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_emitting(value: bool) -> void:
	if value and not emitting: clear_streak()
	emitting = value

func clear_streak() -> void:
	emitting = false
	mesh_array.clear()
	mesh = null

func sample(delta: float) -> void:
	for blade_edge in mesh_array: blade_edge.age += delta
	while not mesh_array.is_empty() and mesh_array[0].age >= lifetime:
		mesh_array.pop_front()
	if emitting and is_instance_valid(origin_node):
		create_edge()
	mesh_update()

func create_edge() -> void:
	var bottom: Vector3 = origin_node.to_global(streak_bottom)
	var top: Vector3 = origin_node.to_global(streak_top)
	# Frozen hit-stop and stationary poses must not accumulate degenerate quads.
	if not mesh_array.is_empty():
		var previous: Dictionary = mesh_array.back()
		if top.distance_squared_to(previous.top) + bottom.distance_squared_to(previous.bottom) < 0.000025: return
		# A teleport or restored pose must not draw a ribbon through the level.
		if top.distance_to(previous.top) > 2.0: mesh_array.clear()
	mesh_array.append({"top": top, "bottom": bottom, "age": 0.0})
	while mesh_array.size() > maximum_edges: mesh_array.pop_front()

func mesh_update() -> void:
	if mesh_array.size() < 2:
		mesh = null
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for blade_edge in mesh_array:
		var opacity := clampf(1.0 - float(blade_edge.age) / lifetime, 0.0, 1.0)
		surface.set_color(Color(1, 1, 1, opacity))
		surface.set_uv(Vector2(0, 1))
		surface.add_vertex(blade_edge.top)
		surface.set_color(Color(1, 1, 1, opacity))
		surface.set_uv(Vector2(0, 0))
		surface.add_vertex(blade_edge.bottom)
	mesh = surface.commit()
