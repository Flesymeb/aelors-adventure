extends Node3D

## A small, continuous MAP01 route: safe square -> river bridge -> training marker.
## The bank opening leaves the bridge as the solid crossing at player scale.

const GRASS := Color(0.25, 0.34, 0.27)
const PATH := Color(0.43, 0.37, 0.27)
const STONE := Color(0.37, 0.39, 0.38)
const WOOD := Color(0.32, 0.22, 0.15)
const ROOF := Color(0.28, 0.29, 0.35)

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.name = "VillageAtmosphere"
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color(0.29, 0.40, 0.47)
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.60, 0.67, 0.72)
	sky.ambient_light_energy = 0.72
	world.environment = sky
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "DawnSun"
	sun.rotation = Vector3(-0.65, 0.55, 0.0)
	sun.light_color = Color(1.0, 0.79, 0.59)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)
	_block("VillageBank", Vector3(48, 0.4, 29), Vector3(0, -0.2, 1.5), GRASS)
	_block("TrainingBank", Vector3(48, 0.4, 15), Vector3(0, -0.2, -28.5), GRASS)
	_block("RiverBed", Vector3(48, 0.3, 8), Vector3(0, -0.75, -17), Color(0.12, 0.21, 0.26), false)
	_block("RiverWater", Vector3(48, 0.03, 8), Vector3(0, -0.48, -17), Color(0.19, 0.42, 0.49), false)
	_block("SquarePath", Vector3(5.2, 0.025, 20), Vector3(0, 0.015, -3), PATH, false)
	_block("NorthPath", Vector3(5.2, 0.025, 13), Vector3(0, 0.015, -28), PATH, false)
	_block("BridgeDeck", Vector3(4.4, 0.36, 8.5), Vector3(0, -0.18, -17), WOOD)
	for i in range(9):
		_block("BridgePlank%02d" % i, Vector3(4.3, 0.035, 0.82), Vector3(0, 0.025, -20.7 + i * 0.92), Color(0.36 + (i % 2) * 0.035, 0.26, 0.17), false)
	for side in [-1.0, 1.0]:
		_block("BridgeRail_%s" % str(side), Vector3(0.22, 0.85, 8.5), Vector3(side * 2.25, 0.55, -17), WOOD)
		for z in [-20.8, -17.0, -13.2]:
			_block("RailPost_%s_%s" % [str(side), str(z)], Vector3(0.34, 1.3, 0.34), Vector3(side * 2.25, 0.65, z), WOOD)
	_block("SouthBoundary", Vector3(48, 2.6, 0.8), Vector3(0, 1.3, 16.4), STONE)
	_block("NorthBoundary", Vector3(48, 2.6, 0.8), Vector3(0, 1.3, -36.4), STONE)
	_block("WestBoundary", Vector3(0.8, 2.6, 53), Vector3(-24.4, 1.3, -10), STONE)
	_block("EastBoundary", Vector3(0.8, 2.6, 53), Vector3(24.4, 1.3, -10), STONE)
	for z in [5.0, -5.0, -27.0]:
		_house(Vector3(-7.5, 0, z), "WestHouse_%s" % str(z))
	for z in [1.0, -8.0, -28.0]:
		_house(Vector3(7.5, 0, z), "EastHouse_%s" % str(z))
	for z in [2.0, -10.0, -24.0]:
		_lamp(Vector3(3.5, 0, z), "EastLamp_%s" % str(z))
		_lamp(Vector3(-3.5, 0, z), "WestLamp_%s" % str(z))
	for x in [-17.0, -14.0, 14.0, 17.0]:
		_tree(Vector3(x, 0, -3.0 if x < 0 else -27.0), "Tree_%s" % str(x))
	# A tall three-stone training landmark is visible after the crossing.
	for x in [-1.35, 0.0, 1.35]:
		_block("TrainingStone_%s" % str(x), Vector3(0.82, 3.2, 0.82), Vector3(x, 1.6, -32), STONE)
	_block("TrainingLintel", Vector3(4.1, 0.65, 0.95), Vector3(0, 3.5, -32), STONE)
	var ui := CanvasLayer.new()
	ui.name = "RouteUI"
	add_child(ui)
	var label := Label.new()
	label.name = "RouteHint"
	label.text = "RIVER VILLAGE  •  Follow the path to the bridge and training stones\nWASD Move   Mouse Look   Space Jump   Tab Shoulder   Esc Cursor"
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 18)
	ui.add_child(label)

func _block(name_: String, size: Vector3, at: Vector3, color: Color, solid: bool = true) -> void:
	var parent: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.name = name_
	parent.position = at
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.93
	mesh.material_override = material
	parent.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		parent.add_child(collision)
	add_child(parent)

func _house(at: Vector3, name_: String) -> void:
	_block(name_ + "Walls", Vector3(4.4, 3.0, 4.4), at + Vector3(0, 1.5, 0), Color(0.51, 0.45, 0.34))
	for side in [-1.0, 1.0]:
		var panel := MeshInstance3D.new()
		panel.name = name_ + "Roof" + str(side)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(3.1, 0.24, 5.1)
		panel.mesh = mesh
		panel.position = at + Vector3(side * 1.15, 3.55, 0)
		panel.rotation.z = side * 0.38
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ROOF
		panel.material_override = mat
		add_child(panel)
	_block(name_ + "Door", Vector3(0.9, 1.9, 0.06), at + Vector3(0, 0.95, 2.24), WOOD, false)

func _lamp(at: Vector3, name_: String) -> void:
	_block(name_ + "Post", Vector3(0.15, 2.8, 0.15), at + Vector3(0, 1.4, 0), WOOD)
	_block(name_ + "Glow", Vector3(0.36, 0.4, 0.36), at + Vector3(0, 2.75, 0), Color(1.0, 0.64, 0.24), false)
	var light := OmniLight3D.new()
	light.name = name_ + "Light"
	light.position = at + Vector3(0, 2.7, 0)
	light.light_color = Color(1.0, 0.68, 0.33)
	light.light_energy = 0.65
	light.omni_range = 6.0
	add_child(light)

func _tree(at: Vector3, name_: String) -> void:
	_block(name_ + "Trunk", Vector3(0.55, 2.5, 0.55), at + Vector3(0, 1.25, 0), WOOD)
	var crown := MeshInstance3D.new()
	crown.name = name_ + "Crown"
	var sphere := SphereMesh.new()
	sphere.radius = 1.55
	sphere.height = 2.8
	crown.mesh = sphere
	crown.position = at + Vector3(0, 3.45, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.29, 0.23)
	crown.material_override = mat
	add_child(crown)
