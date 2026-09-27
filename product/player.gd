extends CharacterBody3D

@export var walk_speed: float = 4.8
@export var acceleration: float = 18.0
@export var turn_speed: float = 10.0
@export var mouse_sensitivity: float = 0.0025

@onready var visual: Node3D = $Visual
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm

var shoulder: float = 1.0
var gravity: float = 19.6

func _ready() -> void:
	call_deferred("_make_world")
	_pose_idle()
	visual.rotation.y = PI
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _pose_idle() -> void:
	var skeleton: Skeleton3D = $Visual/Ranger/Armature/Skeleton3D
	for bone_name in ["upperarm_l", "upperarm_r"]:
		var index := skeleton.find_bone(bone_name)
		if index >= 0:
			skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.RIGHT, -1.2))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoulder_switch"):
		shoulder = -shoulder
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.screen_relative.x * mouse_sensitivity
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - event.screen_relative.y * mouse_sensitivity, -0.85, 0.45)

func _physics_process(delta: float) -> void:
	var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := camera_pivot.global_basis * Vector3(axis.x, 0.0, axis.y)
	direction.y = 0.0
	direction = direction.normalized()
	var target_velocity := direction * walk_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	if is_on_floor():
		velocity.y = -0.25
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	if direction.length_squared() > 0.001:
		var target_angle := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, minf(1.0, turn_speed * delta))
	spring_arm.position.x = move_toward(spring_arm.position.x, shoulder * 0.55, 3.5 * delta)

func _make_world() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.22, 0.30, 0.35)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.63, 0.70, 0.75)
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	get_parent().add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation = Vector3(-0.8, 0.7, 0.0)
	sun.light_color = Color(1.0, 0.86, 0.66)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	get_parent().add_child(sun)
	_make_block("Ground", Vector3(20.0, 0.35, 20.0), Vector3(0.0, -0.175, 0.0), Color(0.29, 0.39, 0.32))
	_make_block("NorthWall", Vector3(20.0, 3.5, 0.7), Vector3(0.0, 1.75, -10.0), Color(0.31, 0.34, 0.38))
	_make_block("SouthWall", Vector3(20.0, 3.5, 0.7), Vector3(0.0, 1.75, 10.0), Color(0.31, 0.34, 0.38))
	_make_block("WestWall", Vector3(0.7, 3.5, 20.0), Vector3(-10.0, 1.75, 0.0), Color(0.31, 0.34, 0.38))
	_make_block("EastWall", Vector3(0.7, 3.5, 20.0), Vector3(10.0, 1.75, 0.0), Color(0.31, 0.34, 0.38))
	_make_block("Pillar", Vector3(1.4, 2.5, 1.4), Vector3(3.0, 1.25, -3.0), Color(0.45, 0.41, 0.34))
	var face := MeshInstance3D.new()
	face.name = "Face"
	var head := SphereMesh.new()
	head.radius = 0.14
	head.height = 0.27
	face.mesh = head
	face.position = Vector3(0.0, 1.59, 0.17)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.63, 0.44, 0.32)
	face.material_override = skin
	visual.add_child(face)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		eye.name = "EyeLeft" if side < 0.0 else "EyeRight"
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.016
		eye_mesh.height = 0.025
		eye.mesh = eye_mesh
		eye.position = Vector3(side * 0.055, 1.62, 0.304)
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.09, 0.085, 0.075)
		eye.material_override = dark
		visual.add_child(eye)
	var ui := CanvasLayer.new()
	ui.name = "UI"
	get_parent().add_child(ui)
	var label := Label.new()
	label.name = "Instructions"
	label.text = "WASD  Move     Mouse  Look     Tab  Switch shoulder     Esc  Cursor"
	label.position = Vector2(24.0, 20.0)
	label.add_theme_font_size_override("font_size", 18)
	ui.add_child(label)

func _make_block(block_name: String, size: Vector3, at: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = block_name
	body.position = at
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	get_parent().add_child(body)
