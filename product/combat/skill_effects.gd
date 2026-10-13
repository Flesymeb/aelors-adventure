extends Node3D
## Presentation only. Contacts and damage remain with the attack/result owners.
## tick() is driven by the owning simulation; shader clocks never use TIME.
const LIGHTNING = preload("res://assets/shaders/3d_lightning.gdshader")
const FIRE = preload("res://assets/shaders/fire_breath.gdshader")
const IMPACT = preload("res://assets/shaders/skill_impact.gdshader")
const MAX_EFFECTS := 40
var world: Node3D
var settings: Node
var records: Array[Dictionary] = []
var next_id := 0

func configure(owner_world: Node3D, settings_node: Node = null) -> void:
	world = owner_world
	settings = settings_node
	if settings == null:
		for property in owner_world.get_property_list():
			if property.name == "dialogue_state": settings = owner_world.get("dialogue_state"); break

func reduced_motion() -> bool:
	return is_instance_valid(settings) and bool(settings.get("reduced_motion"))

func low_quality() -> bool:
	return is_instance_valid(settings) and settings.get("graphics_quality") == "low"

func tint(element: String, outcome := "") -> Color:
	if outcome in ["obstruction", "block", "miss"]: return Color(0.55, 0.55, 0.6)
	return Color(0.38, 0.72, 1.0) if element == "lightning" else Color(1.0, 0.35, 0.06)

func _add_effect(node: Node3D, element: String, stage: String, duration: float, material: ShaderMaterial = null, managed := true) -> int:
	# Do not evict live projectile meshes: their lifetimes belong to physics.
	if records.size() >= MAX_EFFECTS:
		for record in records:
			if record.managed:
				record.node.queue_free()
				records.erase(record)
				break
	# Contact/travel positions are world-owned; the casting actor may move while
	# their explicitly driven clocks continue. Socket warnings follow in tick().
	node.top_level = true
	add_child(node)
	next_id += 1
	records.append({"id":next_id,"node":node,"element":element,"stage":stage,"elapsed":0.0,"duration":duration,"material":material,"managed":managed,"socket":null})
	return next_id

func _impact_material(element: String, outcome := "") -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = IMPACT
	material.set_shader_parameter("tint", tint(element, outcome))
	material.set_shader_parameter("opacity", 1.0)
	return material

func warning(element: String, origin: Vector3, socket: Node3D = null) -> int:
	var node := MeshInstance3D.new()
	node.name = "SkillWarning"
	var mesh := SphereMesh.new()
	mesh.radius = 0.13
	mesh.height = 0.26
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	var material := _impact_material(element)
	node.material_override = material
	var id := _add_effect(node, element, "warning", 0.0, material)
	node.global_position = origin
	records.back().socket = socket
	return id

func finish(id: int, duration := 0.18) -> void:
	for record in records:
		if record.id != id: continue
		record.stage = "decay"
		record.elapsed = 0.0
		record.duration = duration
		record.socket = null
		return

func remove(id: int) -> void:
	for record in records:
		if record.id != id: continue
		if is_instance_valid(record.node): record.node.queue_free()
		records.erase(record)
		return

func projectile(element: String, origin: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "SkillProjectile"
	var mesh := SphereMesh.new()
	mesh.radius = 0.14
	mesh.height = 0.28
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = FIRE
	material.set_shader_parameter("flame_height", 0.3)
	material.set_shader_parameter("flame_height_offset", -0.15)
	material.set_shader_parameter("outline_enabled", false)
	material.set_shader_parameter("reduced_motion", reduced_motion() or low_quality())
	material.set_shader_parameter("opacity", 1.0)
	node.material_override = material
	_add_effect(node, element, "active", 0.0, material, false)
	node.global_position = origin
	return node

func line(origin: Vector3, destination: Vector3, element: String, duration := 0.22) -> int:
	var length := origin.distance_to(destination)
	if length < 0.001: return -1
	var node := Node3D.new()
	node.name = "SkillTravel"
	var material := ShaderMaterial.new()
	material.shader = LIGHTNING if element == "lightning" else FIRE
	if element == "lightning":
		material.set_shader_parameter("Main_Color", tint(element))
		material.set_shader_parameter("Effect_Color", Color(0.4, 0.75, 1.0))
		material.set_shader_parameter("Octave_Count", 1 if low_quality() else 3)
		material.set_shader_parameter("Y_Size", maxf(1.0, length * 0.5))
	else:
		material.set_shader_parameter("flame_height", length)
		material.set_shader_parameter("flame_height_offset", -length * 0.5)
		material.set_shader_parameter("outline_enabled", false)
	material.set_shader_parameter("reduced_motion", reduced_motion() or low_quality())
	material.set_shader_parameter("opacity", 1.0)
	# Two crossed narrow strips provide a volumetric cue without particles or
	# screen textures. The ray/contact owner supplies the obstruction endpoint.
	for angle in [0.0, PI * 0.5]:
		var strip := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.48 if element == "lightning" else 0.6, length)
		strip.mesh = mesh
		strip.material_override = material
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		strip.rotation.y = angle
		node.add_child(strip)
	var id := _add_effect(node, element, "active", duration, material)
	records.back().line_geometry = true
	update_line(id, origin, destination)
	return id

func update_line(id: int, origin: Vector3, destination: Vector3) -> void:
	for record in records:
		if record.id != id or not record.get("line_geometry", false): continue
		var length := origin.distance_to(destination)
		record.node.visible = length >= 0.001
		if length < 0.001: return
		for strip in record.node.get_children(): strip.mesh.size.y = length
		if record.element == "lightning": record.material.set_shader_parameter("Y_Size", maxf(1.0, length * 0.5))
		else:
			record.material.set_shader_parameter("flame_height", length)
			record.material.set_shader_parameter("flame_height_offset", -length * 0.5)
		_place_line(record.node, origin, destination)
		return

func _place_line(node: Node3D, origin: Vector3, destination: Vector3) -> void:
	node.global_position = (origin + destination) * 0.5
	var axis := origin.direction_to(destination)
	var tangent := axis.cross(Vector3.FORWARD).normalized()
	if tangent.length_squared() < 0.1: tangent = axis.cross(Vector3.RIGHT).normalized()
	node.global_basis = Basis(tangent, axis, tangent.cross(axis).normalized())

func contact(point: Vector3, element: String, outcome: String, hp_loss: float) -> int:
	# Only a resolved result creates hit feedback. Misses/obstructions use a
	# smaller neutral ring and never imply damage to an enemy.
	var hit := hp_loss > 0.0 or outcome == "straw"
	var node := MeshInstance3D.new()
	node.name = "SkillContact" if hit else "SkillBlocked"
	var mesh := SphereMesh.new()
	mesh.radius = 0.27 if hit else 0.12
	mesh.height = mesh.radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	var material := _impact_material(element, "" if hit else "obstruction")
	node.material_override = material
	var id := _add_effect(node, element, "contact" if hit else "obstruction", 0.3 if hit else 0.16, material)
	node.global_position = point
	return id

func tick(delta: float) -> void:
	if is_instance_valid(world):
		var owners = world.get("pause_owners")
		if owners is Dictionary and not owners.is_empty(): return
	if is_inside_tree() and get_tree().paused: return
	for record in records.duplicate():
		if not is_instance_valid(record.node) or record.node.is_queued_for_deletion():
			records.erase(record)
			continue
		record.elapsed += delta
		if is_instance_valid(record.socket): record.node.global_position = record.socket.global_position
		var fade := 1.0
		if record.duration > 0:
			fade = clampf(1.0 - record.elapsed / record.duration, 0.0, 1.0)
			if record.stage == "active" and record.elapsed > record.duration * 0.45: record.stage = "decay"
			if record.elapsed >= record.duration:
				record.node.queue_free()
				records.erase(record)
				continue
		if record.material:
			record.material.set_shader_parameter("effect_time", 0.0 if reduced_motion() else record.elapsed)
			record.material.set_shader_parameter("opacity", fade)
		if record.stage in ["contact", "obstruction"] and not reduced_motion(): record.node.scale = Vector3.ONE * (1.0 + record.elapsed * 2.5)

func clear_transients() -> void:
	for record in records:
		if is_instance_valid(record.node): record.node.queue_free()
	records.clear()

func snapshot() -> Dictionary:
	var effects: Array[Dictionary] = []
	for record in records:
		if not is_instance_valid(record.node): continue
		effects.append({"id":record.id,"element":record.element,"stage":record.stage,"elapsed":record.elapsed,"duration":record.duration,"position":record.node.global_position,"managed":record.managed})
	return {"count":effects.size(),"effects":effects,"reduced_motion":reduced_motion(),"low_quality":low_quality()}
