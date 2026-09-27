extends Node3D

## MAP02 spatial slice: safe farm entrance -> muddy road -> cover clearing -> return lane.
## This scene is directly launchable for route evaluation; chapter entry remains gated work.

const SOIL := Color(0.27, 0.23, 0.16)
const MEADOW := Color(0.27, 0.38, 0.23)
const TRACK := Color(0.39, 0.31, 0.21)
const HAY := Color(0.62, 0.48, 0.24)
const BARK := Color(0.27, 0.21, 0.15)
const STONE := Color(0.34, 0.39, 0.38)

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.name = "MeadowAtmosphere"
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color(0.48, 0.62, 0.65)
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.67, 0.73, 0.67)
	sky.ambient_light_energy = 0.8
	world.environment = sky
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "AfternoonSun"
	sun.rotation = Vector3(-0.8, -0.42, 0)
	sun.light_color = Color(1.0, 0.88, 0.7)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)
	_block("MeadowGround", Vector3(46, 0.5, 54), Vector3(0, -0.25, -17), MEADOW)
	_block("MainMuddyTrack", Vector3(4.8, 0.025, 36), Vector3(0, 0.018, -14), TRACK, false)
	_block("ReturnLane", Vector3(3.2, 0.025, 27), Vector3(-8.1, 0.019, -11), TRACK, false)
	_block("ClearingFloor", Vector3(17, 0.028, 12), Vector3(0, 0.02, -29), SOIL, false)
	_block("SouthBoundary", Vector3(46, 2.8, 0.8), Vector3(0, 1.4, 10.4), STONE)
	_block("NorthBoundary", Vector3(46, 2.8, 0.8), Vector3(0, 1.4, -44.4), STONE)
	_block("WestBoundary", Vector3(0.8, 2.8, 54), Vector3(-23.4, 1.4, -17), STONE)
	_block("EastBoundary", Vector3(0.8, 2.8, 54), Vector3(23.4, 1.4, -17), STONE)
	# Furrows frame the safe farm entrance. None crosses the primary road.
	for side in [-1.0, 1.0]:
		for i in range(5):
			_block("Furrow_%s_%s" % [str(side), str(i)], Vector3(0.65, 0.13, 15), Vector3(side * (5.0 + i * 1.35), 0.07, -2.5), SOIL, false)
		for z in [4.0, 0.0, -4.0, -8.0]:
			_grass(Vector3(side * 6.4, 0, z), "Crop_%s_%s" % [str(side), str(z)])
	# Rocks and bales create actual sightline cover with 2 m lanes around them.
	for i in range(3):
		_hay(Vector3(5.8 + i * 1.4, 0, -22.5 - i * 1.7), "EastHay%02d" % i, i)
		_rock(Vector3(-5.0 - i * 1.55, 0, -25.0 - i * 1.5), "WestRock%02d" % i, i)
	_hay(Vector3(2.3, 0, -32.8), "ClearingHay", 1)
	_rock(Vector3(-2.8, 0, -33.4), "ClearingRock", 2)
	# Two staggered tree lines distinguish the meadow from MAP01 village roofs.
	for i in range(8):
		_tree(Vector3(13.5 + float(i % 2) * 2.5, 0, 5.0 - i * 6.0), "EastTree%02d" % i, i)
		_tree(Vector3(-15.0 - float(i % 2) * 1.5, 0, 4.0 - i * 6.0), "WestTree%02d" % i, i + 1)
	# A fork back to the farm lets the player recover without a teleport.
	_block("ReturnConnector", Vector3(8.7, 0.025, 3.2), Vector3(-4.5, 0.021, -19), TRACK, false)
	_block("EntryConnector", Vector3(8.7, 0.025, 3.2), Vector3(-4.5, 0.021, 3), TRACK, false)
	var ui := CanvasLayer.new()
	ui.name = "RouteUI"
	add_child(ui)
	var label := Label.new()
	label.name = "RouteHint"
	label.text = "FOREST MEADOW  •  Follow the muddy road to the cover clearing; return by the west lane\nWASD Move   Shift Sprint   Space Jump   Tab Shoulder   Esc Cursor"
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 18)
	ui.add_child(label)

func _block(name_: String, size: Vector3, at: Vector3, color: Color, solid: bool = true) -> void:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.name = name_
	body.position = at
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	mesh.material_override = material
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	add_child(body)

func _grass(at: Vector3, name_: String) -> void:
	_block(name_, Vector3(0.18, 0.65, 0.18), at + Vector3(0, 0.33, 0), Color(0.44, 0.51, 0.27), false)

func _hay(at: Vector3, name_: String, variant: int) -> void:
	var size := Vector3(1.5 + 0.2 * variant, 1.45, 1.5 - 0.12 * variant)
	_block(name_, size, at + Vector3(0, size.y * 0.5, 0), HAY.lightened(0.05 * variant))
	_block(name_ + "Strap", Vector3(size.x + 0.02, 0.08, size.z + 0.02), at + Vector3(0, size.y * 0.59, 0), BARK, false)

func _rock(at: Vector3, name_: String, variant: int) -> void:
	var size := Vector3(1.4 + 0.35 * variant, 1.45 + 0.15 * variant, 1.6 - 0.1 * variant)
	_block(name_, size, at + Vector3(0, size.y * 0.5, 0), STONE.darkened(0.07 * variant))

func _tree(at: Vector3, name_: String, variant: int) -> void:
	var height := 3.0 + float(variant % 3) * 0.55
	_block(name_ + "Trunk", Vector3(0.58, height, 0.58), at + Vector3(0, height * 0.5, 0), BARK)
	var crown := MeshInstance3D.new()
	crown.name = name_ + "Crown"
	var shape := SphereMesh.new()
	shape.radius = 1.65 + float(variant % 3) * 0.13
	shape.height = 3.0 + float(variant % 2) * 0.45
	crown.mesh = shape
	crown.position = at + Vector3(0, height + 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.17 + 0.02 * (variant % 3), 0.30 + 0.015 * (variant % 2), 0.20)
	mat.roughness = 0.95
	crown.material_override = mat
	add_child(crown)
