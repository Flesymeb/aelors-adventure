extends SceneTree

var failures: Array[String] = []
var contact_error := INF
var hold_contact_error := INF


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func mouse(button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func tick(player: CharacterBody3D, seconds: float) -> void:
	player.attack_timer = maxf(0.0, player.attack_timer - seconds)
	player._update_archery(seconds)


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func record_contact(player: CharacterBody3D) -> void:
	# Modifiers restore the base pose after rendering; measure inside their
	# processed signal, not from the unmodified pose after a process frame.
	var hand: Transform3D = player.skeleton.global_transform * player.skeleton.get_bone_global_pose(player.skeleton.find_bone("hand_r"))
	contact_error = (hand * Vector3(0, 0.065, 0)).distance_to(player.bow_draw_target.global_position)


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Mouse capture requires a window. Run: xvfb-run -a godot --path examples/emaceart-village-demo --script res://archery_smoke.gd")
		quit(2)
		return
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var ground := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(100, 0.1, 100)
	collision.shape = shape
	collision.position.y = -0.05
	ground.add_child(collision)
	stage.add_child(ground)
	var player := (load("res://Player.tscn") as PackedScene).instantiate() as CharacterBody3D
	stage.add_child(player)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for i in range(10):
		await physics_frame
	check(player.is_on_floor(), "Test player must be grounded")
	player.set_physics_process(false)
	player.request_weapon("bow")
	player._update_switch(0.8)
	check(player.weapon_mode == "bow", "Bow must equip")
	check(player.bow_pose != null, "Actual KayKit bow animation asset must load")
	if player.bow_pose == null:
		quit(1)
		return
	player.bow_ik.modification_processed.connect(record_contact.bind(player))

	mouse(MOUSE_BUTTON_RIGHT, true)
	await process_frame
	check(player.aim_requested, "RMB press must start aiming")
	tick(player, 0.1)
	check(player.camera.fov < 70.0 and player.camera.fov > 48.0, "Aim FOV must ease rather than snap")
	tick(player, 1.2)
	check(player.camera.fov < 49.0, "Held aim must converge to zoomed FOV")
	mouse(MOUSE_BUTTON_LEFT, true)
	await process_frame
	tick(player, 0.5)
	check(absf(player.bow_charge - 0.5) < 0.01, "Half draw must produce half charge")
	check(player.shots_fired == 0, "Holding draw must not shoot")
	tick(player, 0.6)
	var before_move := player.position
	key(KEY_A, true)
	player.set_physics_process(true)
	for i in range(15):
		await physics_frame
	player.set_physics_process(false)
	key(KEY_A, false)
	var facing: Vector3 = player.visual.global_basis.z.normalized()
	var camera_forward: Vector3 = -player.camera.global_basis.z
	camera_forward.y = 0.0
	check(player.position.distance_to(before_move) > 0.15, "Aimed player must be able to strafe")
	check(facing.dot(camera_forward.normalized()) > 0.95, "Aimed strafing must keep facing the target")
	await process_frame
	check(player.bow_state == "hold" and player.bow_charge == 1.0, "Full draw must enter hold")
	hold_contact_error = contact_error
	check(contact_error < 0.045, "Right palm must contact drawn string within 4.5 cm (got %.4f m)" % contact_error)
	mouse(MOUSE_BUTTON_LEFT, false)
	await process_frame
	check(player.shots_fired == 1, "LMB release must shoot exactly once")
	mouse(MOUSE_BUTTON_LEFT, false)
	await process_frame
	check(player.shots_fired == 1, "Duplicate release must not duplicate arrows")
	tick(player, 0.6)

	mouse(MOUSE_BUTTON_LEFT, true)
	await process_frame
	tick(player, 0.05)
	mouse(MOUSE_BUTTON_LEFT, false)
	await process_frame
	check(player.shots_fired == 1 and player.bow_state == "ready", "Too-short draw must cancel")
	mouse(MOUSE_BUTTON_LEFT, true)
	await process_frame
	tick(player, 0.5)
	mouse(MOUSE_BUTTON_RIGHT, false)
	await process_frame
	mouse(MOUSE_BUTTON_LEFT, false)
	await process_frame
	check(not player.aim_requested and player.bow_charge == 0.0 and player.shots_fired == 1, "RMB cancellation must not shoot")
	tick(player, 1.2)
	check(player.camera.fov > 69.0, "Releasing aim must smoothly restore FOV")

	mouse(MOUSE_BUTTON_RIGHT, true)
	await process_frame
	mouse(MOUSE_BUTTON_LEFT, true)
	await process_frame
	tick(player, 0.5)
	player.request_weapon("sword")
	player._update_switch(0.8)
	mouse(MOUSE_BUTTON_LEFT, false)
	await process_frame
	check(player.weapon_mode == "sword" and not player.aim_requested and player.bow_charge == 0.0 and player.shots_fired == 1, "Weapon switching must cancel drawn arrow")
	player.request_weapon("bow")
	player._update_switch(0.8)
	player.set_aim(true)
	player.begin_bow_draw()
	tick(player, 0.5)
	player.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(not player.aim_requested and player.bow_charge == 0.0, "Window focus loss must clear draw")
	player.set_aim(true)
	player.begin_bow_draw()
	tick(player, 0.5)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	Input.flush_buffered_events()
	await process_frame
	check(not player.aim_requested and player.bow_charge == 0.0, "Esc must cancel draw")
	player.respawn()
	check(player.bow_state == "idle" and player.bow_charge == 0.0, "Respawn must clear bow state")

	var target := Vector3(15, 3, 0)
	var direction: Vector3 = player._ballistic_direction(Vector3.ZERO, target, 25.0)
	var time := 15.0 / (direction.x * 25.0)
	var impact := direction * 25.0 * time + Vector3.DOWN * 0.5 * 3.0 * time * time
	check(impact.distance_to(target) < 0.01, "Ballistic launch direction must account for gravity")
	var wall := StaticBody3D.new()
	var wall_collision := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(1, 2, 0.1)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	stage.add_child(wall)
	wall.position = Vector3(5, 1, 0.3)
	await physics_frame
	var arrow := Node3D.new()
	arrow.set_script(load("res://arrow_projectile.gd"))
	stage.add_child(arrow)
	arrow.launch(Vector3(5, 1, 0), Vector3.BACK, player.get_rid(), 30.0)
	check(arrow.stuck, "An arrow already overlapping a close wall must be blocked")
	check(arrow.global_position.z + 0.646 <= 0.251, "Blocked arrow tip must stop at the wall")
	player.set_aim(true)
	player.begin_bow_draw()
	tick(player, 0.3)
	key(KEY_SPACE, true)
	player._physics_process(1.0 / 60.0)
	key(KEY_SPACE, false)
	check(not player.aim_requested and player.bow_charge == 0.0, "Jumping must cancel unshot draw")
	# Camera changes must not interfere with the active draw or shot count.
	player.position = Vector3(0, 0.02, 0)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	for i in range(12):
		await physics_frame
	player.set_physics_process(false)
	key(KEY_E, true)
	key(KEY_E, false)
	tick(player, 1.2)
	check(player.shoulder_side == -1.0 and player.arm.position.x < -0.29, "E must switch to the left shoulder")
	player.set_aim(true)
	player.begin_bow_draw()
	tick(player, 0.5)
	key(KEY_V, true)
	key(KEY_V, false)
	tick(player, 0.6)
	tick(player, 0.6)
	await physics_frame
	check(player.first_person and player.arm.spring_length == 0.0, "V must reach an eye-level first-person camera")
	check(absf(player.arm.position.y - 1.65) < 0.005, "First-person camera must sit at eye height")
	check(player.head_mesh != null and player.head_mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "First person must hide the hood while keeping its shadow")
	check(player.character_model.visible and player.bow_holder.visible, "First person must retain the body and held bow")
	check(player.bow_charge == 1.0 and player.bow_state == "hold", "Changing perspective must preserve draw")
	var shots_before: int = player.shots_fired
	mouse(MOUSE_BUTTON_LEFT, false)
	await process_frame
	check(player.shots_fired == shots_before + 1, "First-person release must shoot once")
	mouse(MOUSE_BUTTON_RIGHT, false)
	key(KEY_V, true)
	key(KEY_V, false)
	tick(player, 1.2)
	await physics_frame
	check(not player.first_person and player.arm.spring_length > 3.7, "V must restore third-person distance")
	check(player.head_mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Third person must restore the hood")
	check(player.arm.position.x < -0.29, "Third person must remember the selected shoulder")
	key(KEY_E, true)
	key(KEY_E, false)
	tick(player, 1.2)
	check(player.arm.position.x > 0.29, "E must restore the right shoulder")
	print("ARCHERY_SMOKE checks_complete failures=", failures.size(), " hold_contact_error_m=", hold_contact_error, " shots=", player.shots_fired)
	quit(0 if failures.is_empty() else 1)
