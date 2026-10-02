extends CharacterBody3D
## Candidate-owned R02 controller. Physics owns translation; AnimationPlayer owns state pose.

const SPEED := 4.8
const DASH_SPEED := 12.0
const JUMP_VELOCITY := 6.6
const GRAVITY := 18.0
const ROLL_TIME := 0.62
const DASH_TIME := 0.22

var state := "idle"
var action_time := 0.0
var shoulder := 1
var equipment_mode := "unarmed"
var facing := Vector3(0, 0, 1)
var visual: Node3D
var body_mesh: MeshInstance3D
var cape: MeshInstance3D
var arm_l: MeshInstance3D
var arm_r: MeshInstance3D
var hand_item: MeshInstance3D
var back_item: MeshInstance3D
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var anim: AnimationPlayer
var hud_state: Label

func _ready() -> void:
	_build_actor()
	_build_camera()
	_build_animations()
	hud_state = get_node_or_null("../HUD/State")
	_update_hud()

func _build_actor() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	var collider := CollisionShape3D.new()
	collider.name = "Collision"
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	visual = Node3D.new()
	visual.name = "Aelor_AnimatedActor"
	add_child(visual)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#315447")
	mat.roughness = 0.78
	body_mesh = MeshInstance3D.new()
	var torso := CapsuleMesh.new()
	torso.radius = 0.48
	torso.height = 1.22
	body_mesh.mesh = torso
	body_mesh.material_override = mat
	body_mesh.position.y = 1.02
	visual.add_child(body_mesh)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.34
	head_mesh.height = 0.68
	head.mesh = head_mesh
	var head_mat: StandardMaterial3D = mat.duplicate()
	head_mat.albedo_color = Color("#b97956")
	head.material_override = head_mat
	head.position.y = 1.95
	visual.add_child(head)
	cape = MeshInstance3D.new()
	var cape_mesh := BoxMesh.new()
	cape_mesh.size = Vector3(0.9, 1.4, 0.14)
	cape.mesh = cape_mesh
	cape.material_override = mat
	cape.position = Vector3(0, 1.05, 0.38)
	visual.add_child(cape)
	arm_l = _limb(Vector3(-0.58, 1.05, 0), mat)
	arm_r = _limb(Vector3(0.58, 1.05, 0), mat)
	visual.add_child(arm_l)
	visual.add_child(arm_r)
	var boot_mat := StandardMaterial3D.new()
	boot_mat.albedo_color = Color("#272b35")
	for x in [-0.23, 0.23]:
		var leg := _limb(Vector3(x, 0.34, 0), boot_mat)
		leg.scale = Vector3(0.8, 1.15, 0.8)
		visual.add_child(leg)
	hand_item = _equipment(Color("#d6a84f"), Vector3(0.82, 0.88, -0.15))
	back_item = _equipment(Color("#b87943"), Vector3(-0.26, 1.15, 0.5))
	hand_item.visible = false
	back_item.visible = false
	visual.add_child(hand_item)
	visual.add_child(back_item)

func _limb(pos: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.13
	mesh.height = 0.85
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	return n

func _equipment(color: Color, pos: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.1, 1.0, 0.1)
	n.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	n.material_override = m
	n.position = pos
	return n

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.75, 0)
	add_child(camera_pivot)
	spring_arm = SpringArm3D.new()
	spring_arm.name = "CameraCollisionSpringArm"
	spring_arm.spring_length = 6.0
	spring_arm.margin = 0.25
	spring_arm.collision_mask = 1
	spring_arm.rotation_degrees = Vector3(-12, 0, 0)
	camera_pivot.add_child(spring_arm)
	camera = Camera3D.new()
	camera.name = "ThirdPersonCamera"
	camera.current = true
	camera.fov = 62.0
	spring_arm.add_child(camera)
	_update_shoulder()

func _build_animations() -> void:
	anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer_StateDriver"
	var lib := AnimationLibrary.new()
	for clip in ["Idle", "Locomotion", "Jump", "Dash", "EvadeRoll"]:
		var a := Animation.new()
		a.length = 0.8 if clip == "Idle" else (ROLL_TIME if clip == "EvadeRoll" else 0.45)
		a.loop_mode = Animation.LOOP_LINEAR if clip in ["Idle", "Locomotion"] else Animation.LOOP_NONE
		var track := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(track, NodePath("../Aelor_AnimatedActor:rotation"))
		a.track_insert_key(track, 0.0, Vector3.ZERO)
		a.track_insert_key(track, a.length * 0.5, Vector3(0, 0, 0.035 if clip == "Locomotion" else 0.0))
		a.track_insert_key(track, a.length, Vector3.ZERO)
		lib.add_animation(clip, a)
	anim.add_animation_library("", lib)
	add_child(anim)
	anim.play("Idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor() and state not in ["dash", "evade"]:
		velocity.y = JUMP_VELOCITY
		state = "jump"
		action_time = 0.0
	if Input.is_action_just_pressed("dash") and state not in ["dash", "evade"]:
		state = "dash"
		action_time = DASH_TIME
	if Input.is_action_just_pressed("roll") and is_on_floor() and state not in ["dash", "evade"]:
		state = "evade"
		action_time = ROLL_TIME
	if Input.is_action_just_pressed("shoulder_switch"):
		shoulder *= -1
		_update_shoulder()
	if Input.is_action_just_pressed("equipment_fixture"):
		equipment_mode = "hand" if equipment_mode == "unarmed" else ("back" if equipment_mode == "hand" else "unarmed")
		_update_equipment()
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_vec.x, 0, input_vec.y)
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		facing = direction
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), minf(delta * 12.0, 1.0))
	if state == "dash":
		velocity.x = facing.x * DASH_SPEED
		velocity.z = facing.z * DASH_SPEED
		action_time -= delta
	elif state == "evade":
		velocity.x = facing.x * 7.0
		velocity.z = facing.z * 7.0
		action_time -= delta
	else:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, SPEED * 8.0 * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, SPEED * 8.0 * delta)
	move_and_slide()
	if state in ["dash", "evade"] and action_time <= 0:
		state = "idle"
	if not is_on_floor() and state not in ["dash", "evade"]:
		state = "jump"
	elif state == "jump" and is_on_floor():
		state = "locomotion" if direction.length_squared() > 0.01 else "idle"
	elif state not in ["dash", "evade", "jump"]:
		state = "locomotion" if direction.length_squared() > 0.01 else "idle"
	_play_state()
	_update_hud()

func _play_state() -> void:
	var clip: String = {"idle":"Idle", "locomotion":"Locomotion", "jump":"Jump", "dash":"Dash", "evade":"EvadeRoll"}.get(state, "Idle")
	if anim.current_animation != clip:
		anim.play(clip)

func _update_shoulder() -> void:
	if spring_arm:
		spring_arm.position.x = 1.15 * shoulder

func _update_equipment() -> void:
	hand_item.visible = equipment_mode == "hand"
	back_item.visible = equipment_mode == "back"

func _update_hud() -> void:
	if hud_state:
		hud_state.text = "%s  •  %s SHOULDER  •  EQUIP:%s" % [state.to_upper(), "L" if shoulder < 0 else "R", equipment_mode.to_upper()]
