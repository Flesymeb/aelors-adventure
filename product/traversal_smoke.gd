extends SceneTree

var failures: Array[String] = []
var hip_height := INF
var palm_height := INF
var support_heights := {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func box(parent: Node, center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = center
	return body

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func frames(p: CharacterBody3D, count: int) -> void:
	for i in range(count):
		await physics_frame
		p._physics_process(1.0 / 60.0)

func record_prone(p: CharacterBody3D) -> void:
	if p.traversal.posture != "prone":
		return
	hip_height = (p.skeleton.global_transform * p.skeleton.get_bone_global_pose(p.skeleton.find_bone("pelvis"))).origin.y - p.global_position.y
	for bone in ["pelvis", "hand_l", "hand_r", "calf_l", "calf_r", "foot_l", "foot_r", "Head"]:
		support_heights[bone] = (p.skeleton.global_transform * p.skeleton.get_bone_global_pose(p.skeleton.find_bone(bone))).origin.y - p.global_position.y
	palm_height = (p.skeleton.global_transform * p.skeleton.get_bone_global_pose(p.skeleton.find_bone("hand_l"))).origin.y - p.global_position.y

func run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	box(stage, Vector3(0, -0.1, 0), Vector3(60, 0.2, 60))
	box(stage, Vector3(0, 0.125, -2), Vector3(3, 0.25, 1))
	box(stage, Vector3(0, 0.325, -4), Vector3(3, 0.65, 1))
	box(stage, Vector3(6, 1.4, 0), Vector3(3, 0.2, 3))
	box(stage, Vector3(-6, 0.125, -2), Vector3(3, 0.25, 1))
	box(stage, Vector3(-6, 2.1, -2), Vector3(3, 0.2, 3))
	box(stage, Vector3(12, 1, -1), Vector3(3, 2, 0.1))
	var p := (load("res://Player.tscn") as PackedScene).instantiate() as CharacterBody3D
	stage.add_child(p)
	p.set_physics_process(false)
	await frames(p, 10)
	var t: Node = p.traversal
	check(p.is_on_floor(), "Player must start grounded")
	check(p.animation_player.get_animation("Sword_Idle").loop_mode == Animation.LOOP_LINEAR, "Combat idle must keep looping instead of freezing")
	key(KEY_W, true)
	await frames(p, 30)
	check(p.position.y > 0.23 and p.position.z < -1.7, "Walking must automatically climb the 25 cm step")
	await frames(p, 50)
	print("STEPS count=", t.step_count, " position=", p.position)
	check(p.position.z > -3.3 and p.position.y < 0.4, "A 65 cm obstacle must not be treated as a step")
	key(KEY_W, false)
	p.position = Vector3(-6, 0.02, 0)
	p.velocity = Vector3.ZERO
	await frames(p, 5)
	key(KEY_W, true)
	await frames(p, 35)
	key(KEY_W, false)
	check(p.position.y < 0.22 and p.position.z > -1.5, "Stepping must not lift the standing capsule through a low ceiling")
	p.position = Vector3(4, 0.02, 0)
	p.velocity = Vector3.ZERO
	await frames(p, 5)
	key(KEY_C, true)
	key(KEY_C, false)
	check(t.posture == "crouch" and (p.get_node("Collision").shape as CapsuleShape3D).height < 1.2, "C must crouch and lower the collision")
	p.position = Vector3(6, 0.02, 0)
	await frames(p, 5)
	check(not t.request_posture("crouch") and t.posture == "crouch", "Standing beneath a low ceiling must be blocked")
	key(KEY_Z, true)
	key(KEY_Z, false)
	check(t.posture == "prone", "Z must enter prone under the ceiling")
	check(not t.request_posture("prone") and t.posture == "prone", "Prone must not stand through a ceiling")
	t.motion_pose.modification_processed.connect(record_prone.bind(p))
	await frames(p, 25)
	print("CRAWL_HEIGHTS ", support_heights)
	check(hip_height < 0.75 and palm_height < 0.4, "Prone must use a lowered crawl pose (hip %.3f palm %.3f)" % [hip_height, palm_height])
	var start := p.position
	key(KEY_W, true)
	await frames(p, 20)
	key(KEY_W, false)
	check(p.position.distance_to(start) > 0.12 and p.current_animation == "Idle", "Prone must crawl via the motion modifier")
	p.position = Vector3(9, 0.02, 0)
	p.velocity = Vector3.ZERO
	await frames(p, 5)
	check(t.request_posture("prone") and t.posture == "standing", "Standing must work after leaving the ceiling")
	p.position = Vector3(12, 0.02, 0)
	p.velocity = Vector3.ZERO
	p.visual.rotation.y = PI
	await frames(p, 5)
	t.moving_direction = Vector3.ZERO
	key(KEY_F, true)
	key(KEY_F, false)
	check(t.action == "roll", "F must start roll")
	check(not t.evade("roll"), "Rolling must not restart repeatedly")
	await frames(p, 52)
	check(p.position.z > -0.64 and t.action == "", "Roll must stop at a thin wall and recover")
	await frames(p, 30)
	p.position = Vector3(16, 0.02, 0)
	p.velocity = Vector3.ZERO
	await frames(p, 5)
	if t.posture != "standing": t.request_posture(t.posture)
	t.moving_direction = Vector3.RIGHT
	check(t.evade("dodge"), "Dodge must start after cooldown")
	start = p.position
	await frames(p, 8)
	check(t.motion_pose.clip == "Dodge_Right", "Right movement must select the right dodge animation")
	await frames(p, 25)
	check(p.position.x > start.x + 0.6 and t.action == "", "Dodge must move in the requested direction and recover")
	key(KEY_W, true)
	key(KEY_SHIFT, true)
	await frames(p, 40)
	check(t.sprinting and p.current_animation == "Sprint" and Vector2(p.velocity.x, p.velocity.z).length() > 9.0, "Shift movement must use the sprint clip and sprint speed")
	key(KEY_SHIFT, false)
	key(KEY_W, false)
	await frames(p, 25)
	key(KEY_SPACE, true)
	await frames(p, 1)
	key(KEY_SPACE, false)
	check(p.current_animation == "Jump_Start", "Jump must automatically play takeoff")
	await frames(p, 16)
	check(p.current_animation == "Jump", "Airborne state must automatically play the air loop")
	var saw_landing := false
	for i in range(60):
		await frames(p, 1)
		if p.current_animation == "Jump_Land": saw_landing = true
	check(saw_landing and p.is_on_floor(), "Landing must automatically play the landing clip")
	t.request_posture("prone")
	p.respawn()
	check(t.posture == "standing" and t.action == "" and p.get_node("Collision").shape == t.standing_shape, "Respawn must restore movement and collision state")
	print("TRAVERSAL_SMOKE failures=", failures.size(), " steps=", t.step_count, " prone_hip=", hip_height, " prone_palm=", palm_height)
	quit(0 if failures.is_empty() else 1)
