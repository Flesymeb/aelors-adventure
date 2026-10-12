extends Node
## Opt-in component checks. Manual physics calls and synthetic terrain are
## diagnostics, never ordinary-input, authored-route or earned-save acceptance.
var checks: Dictionary = {}
var completed := false
var player: CharacterBody3D
const DT := 1.0 / 60.0

func _ready() -> void:
	run.call_deferred()

func box(center: Vector3, size: Vector3, tilt: float = 0.0) -> void:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	body.position = center
	body.rotation.x = tilt

func tick(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		player._physics_process(DT)

func held(action: String, value: bool) -> void:
	if value: Input.action_press("r02_" + action)
	else: Input.action_release("r02_" + action)

func reset_at(point: Vector3) -> void:
	for action in ["forward", "back", "left", "right", "sprint", "jump"]:
		held(action, false)
	player.traversal.reset()
	player.position = point
	player.velocity = Vector3.ZERO
	player.arm.rotation.y = 0.0
	player.blocked_keys.clear()
	await tick(8)

func planar_travel(before: Vector3) -> float:
	return Vector2(player.position.x - before.x, player.position.z - before.z).length()

func stopped() -> bool:
	return Vector2(player.velocity.x, player.velocity.z).is_zero_approx()

func run() -> void:
	box(Vector3(32, -0.1, 32), Vector3(64, 0.2, 64))
	box(Vector3(28, 1.0, 18), Vector3(5, 2, 0.1))
	box(Vector3(40, 0.5, 32), Vector3(6, 0.3, 8), 0.15)
	box(Vector3(48, 0.125, 30), Vector3(4, 0.25, 1))
	player = (load("res://Player.tscn") as PackedScene).instantiate()
	# Synthetic floor is at zero, outside the production map's height range.
	player.minimum_world_height = -40.0
	add_child(player)
	player.set_physics_process(false)
	await reset_at(Vector3(16, 0.02, 32))
	checks.initial_support = player.is_on_floor()
	for sprint in [false, true]:
		await reset_at(Vector3(16, 0.02, 32))
		held("forward", true)
		held("sprint", sprint)
		await tick(40)
		var label := "sprint" if sprint else "walk"
		checks[label + "_steady"] = player.velocity.length() > (9.0 if sprint else 4.9)
		held("forward", false)
		held("sprint", false)
		var before := player.position
		await tick()
		checks[label + "_one_update_stop"] = stopped() and planar_travel(before) < 0.00001 and player.is_on_floor()
		checks[label + "_idle"] = player.current_animation == "Idle" and player.animation_player.speed_scale == 1.0
		held("back", true)
		await tick(20)
		checks[label + "_repress_reverse"] = player.position.z > before.z + 0.1 and player.velocity.z > 0.0
		held("back", false)
		await tick()
	await reset_at(Vector3(16, 0.02, 32))
	player.arm.rotation.y = PI / 2.0
	held("forward", true)
	await tick(12)
	checks.camera_relative = player.velocity.x < -1.0 and absf(player.velocity.z) < 0.1
	checks.acceleration_cadence = player.animation_player.speed_scale > 0.0 and player.animation_player.speed_scale < 1.0
	await reset_at(Vector3(28, 0.02, 20))
	held("forward", true)
	await tick(60)
	var wall_before := player.position
	await tick()
	checks.blocked_idle = planar_travel(wall_before) < 0.0001 and player.current_animation == "Idle"
	await reset_at(Vector3(40, 1.4, 32))
	held("forward", true)
	await tick(10)
	held("forward", false)
	var slope_before := player.position
	await tick()
	checks.slope_stop = stopped() and planar_travel(slope_before) < 0.0001 and player.is_on_floor()
	await reset_at(Vector3(48, 0.02, 32))
	held("forward", true)
	await tick(25)
	held("forward", false)
	var step_before := player.position
	await tick()
	checks.step_stop = stopped() and planar_travel(step_before) < 0.0001 and (player.is_on_floor() or player.traversal.step_grace > 0.0)
	await reset_at(Vector3(16, 0.02, 32))
	held("forward", true)
	await tick(20)
	held("jump", true)
	await tick()
	held("jump", false)
	held("forward", false)
	var air_velocity := player.velocity
	await tick()
	checks.airborne_release = not player.is_on_floor() and absf(player.velocity.z) > 4.0 and is_equal_approx(absf(air_velocity.z) - absf(player.velocity.z), 6.0 * DT) and player.velocity.y < air_velocity.y
	await tick(80)
	checks.jump_recovers = player.is_on_floor()
	for evade in ["roll", "dodge"]:
		await reset_at(Vector3(16, 0.02, 32))
		player.traversal.moving_direction = Vector3.RIGHT
		var started: bool = player.traversal.evade(evade)
		var before := player.position
		await tick(8)
		checks[evade + "_neutral_keeps_impulse"] = started and player.traversal.action == evade and planar_travel(before) > 0.1
		checks[evade + "_playback_speed"] = player.animation_player.speed_scale == 1.0
		await tick(60)
		checks[evade + "_recovers"] = player.traversal.action == "" and stopped() and player.is_on_floor()
	await reset_at(Vector3(16, 0.02, 32))
	held("forward", true)
	await tick(20)
	player.set_controls_open(true)
	held("forward", false)
	var release := InputEventKey.new()
	release.keycode = player.effective_bindings["forward"]
	release.pressed = false
	player.track_modal_input(release)
	player.set_controls_open(false)
	var modal_before := player.position
	await tick()
	checks.modal_release_stops = stopped() and planar_travel(modal_before) < 0.0001
	held("forward", true)
	await tick(10)
	checks.modal_fresh_press = planar_travel(modal_before) > 0.1
	for action in ["forward", "back", "left", "right", "sprint", "jump"]: held(action, false)
	player.queue_free()
	completed = true

func _mcp_state() -> Dictionary:
	return {"completed": completed, "checks": checks, "scope": "component diagnostics only"}
