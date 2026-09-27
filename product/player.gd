extends CharacterBody3D

@export var walk_speed: float = 4.8
@export var sprint_speed: float = 7.8
@export var acceleration: float = 18.0
@export var turn_speed: float = 10.0
@export var mouse_sensitivity: float = 0.0025
@export var jump_speed: float = 7.2

@onready var visual: Node3D = $Visual
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm

var shoulder: float = 1.0
var gravity: float = 19.6

func _ready() -> void:
	_pose_idle()
	_make_face()
	visual.rotation.y = PI
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _pose_idle() -> void:
	var skeleton: Skeleton3D = $Visual/Ranger/Armature/Skeleton3D
	for bone_name in ["upperarm_l", "upperarm_r"]:
		var index := skeleton.find_bone(bone_name)
		if index >= 0:
			skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.RIGHT, -1.2))

func _make_face() -> void:
	# The ranger hood has an open dark cavity. Keep the inset face behind its rim.
	var face := MeshInstance3D.new()
	face.name = "InsetFace"
	var head := SphereMesh.new()
	head.radius = 0.075
	head.height = 0.14
	face.mesh = head
	face.position = Vector3(0.0, 1.66, 0.015)
	face.scale.z = 0.13
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.39, 0.28, 0.21)
	skin.roughness = 0.95
	face.material_override = skin
	visual.add_child(face)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		eye.name = "InsetEyeL" if side < 0.0 else "InsetEyeR"
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.007
		eye_mesh.height = 0.012
		eye.mesh = eye_mesh
		eye.position = Vector3(side * 0.032, 1.68, 0.027)
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.065, 0.05, 0.04)
		eye.material_override = dark
		visual.add_child(eye)

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
	var movement_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_velocity := direction * movement_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_speed
		else:
			velocity.y = -0.25
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	var air_pitch := -0.14 if not is_on_floor() else 0.0
	visual.rotation.x = lerpf(visual.rotation.x, air_pitch, minf(1.0, 10.0 * delta))
	if direction.length_squared() > 0.001:
		var target_angle := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, minf(1.0, turn_speed * delta))
	spring_arm.position.x = move_toward(spring_arm.position.x, shoulder * 0.55, 3.5 * delta)
