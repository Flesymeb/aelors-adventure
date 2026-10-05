extends CharacterBody3D
const MAX_HP = 24.0
const DAMAGE = 6.0
var training: Node3D
var model: Node3D
var animator: AnimationPlayer
var home = Vector3.ZERO
var health = MAX_HP
var phase = "idle"
var clock = 0.0
var engaged = false
var locked_direction = Vector3.ZERO
var attack_origin = Vector3.ZERO
var model_height = 0.0
var flash_time = 0.0
var materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	model = $Model
	animator = model.get_node("AnimationPlayer")
	var bounds = AABB()
	var first = true
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = (model.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		for surface in mesh.mesh.get_surface_count():
			var source = mesh.get_active_material(surface) as StandardMaterial3D
			if source:
				var material = source.duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(surface, material)
				materials.append(material)
	model_height = bounds.size.y
	if model_height > 0:
		var factor = 1.72 / model_height
		model.scale *= factor
		model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor
	for key in ["Idle", "Walk", "Punch", "HitReact", "Death"]:
		if not animator.has_animation(key): push_error("Training Orc missing imported clip: " + key)
	for key in ["Idle", "Walk"]:
		var clip = animator.get_animation(key).duplicate() as Animation
		clip.loop_mode = Animation.LOOP_LINEAR
		var library = animator.get_animation_library("")
		library.remove_animation(key)
		library.add_animation(key, clip)
	play("Idle")

func play(key: String, speed = 1.0) -> void:
	if animator.current_animation != key or not animator.is_playing(): animator.play(key, 0.1, speed)

func reset_encounter() -> void:
	health = 0 if training.state.encounter_defeated else MAX_HP
	phase = "death" if health <= 0 else "idle"
	engaged = false
	clock = 0
	velocity = Vector3.ZERO
	global_position = home
	visible = not training.state.remnant_collected
	if health <= 0:
		animator.play("Death")
		animator.seek(animator.get_animation("Death").length, true)
		animator.pause()
	else: play("Idle")

func line_clear(destination: Vector3) -> bool:
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, destination + Vector3.UP, 1, [get_rid(), training.player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(delta: float) -> void:
	if not training or not training.grounded or health <= 0 or training.player_locked(): return
	flash_time = maxf(0, flash_time - delta)
	for material in materials:
		material.emission_enabled = flash_time > 0
		material.emission = Color(0.6, 0.2, 0.04)
	var player: CharacterBody3D = training.player
	var distance = global_position.distance_to(player.global_position)
	var player_in_arena: bool = player.global_position.distance_to(home) <= 6.0
	var ready: bool = training.state.practice_hit and training.state.practice_defense and training.state.sword_owned
	if not ready or not player_in_arena or global_position.distance_to(home) > 5.5:
		if engaged: reset_encounter()
		return
	if not engaged and distance < 5.0 and line_clear(player.global_position):
		engaged = true
		training.tell("◇ 训练怪 · 抬手后出拳；退回赫斯处可脱离", 4)
	if not engaged: return
	clock += delta
	var direction = player.global_position - global_position
	direction.y = 0
	if phase in ["idle", "approach"]:
		model.rotation.y = atan2(direction.x, direction.z)
		if distance > 1.5:
			phase = "approach"
			velocity.x = direction.normalized().x * 1.25
			velocity.z = direction.normalized().z * 1.25
			play("Walk")
		else:
			phase = "telegraph"
			clock = 0
			locked_direction = direction.normalized()
			attack_origin = global_position
			velocity.x = 0
			velocity.z = 0
			play("Punch", 0.22)
	elif phase == "telegraph":
		if clock >= 0.9:
			phase = "attack"
			clock = 0
			# Resume the actual imported punch at full speed, preserving its
			# anticipation pose instead of carrying the slow preview rate.
			var anticipation_position = animator.current_animation_position
			animator.play("Punch", 0.05, 1.0)
			animator.seek(anticipation_position, true)
	elif phase == "attack" and clock >= 0.2:
		var outcome = "miss"
		if line_clear(player.global_position): outcome = training.receive_attack(attack_origin, locked_direction, DAMAGE)
		phase = "stagger" if outcome == "parry" else "recovery"
		clock = 0
		if phase == "stagger": play("HitReact")
	elif phase == "stagger" and clock >= 0.6:
		phase = "recovery"
		clock = 0
	elif phase == "hurt" and clock >= 0.45:
		phase = "recovery"
		clock = 0
	elif phase == "recovery" and clock >= 1.0:
		phase = "idle"
		clock = 0
		play("Idle")
	if not is_on_floor(): velocity.y -= 20 * delta
	else: velocity.y = 0
	move_and_slide()

func receive_hit(amount: float) -> float:
	if health <= 0 or not training.state.practice_defense: return 0
	var loss = minf(health, amount)
	health -= loss
	engaged = true
	velocity = Vector3.ZERO
	clock = 0
	flash_time = 0.1
	if health <= 0:
		phase = "death"
		engaged = false
		animator.play("Death", 0.05)
		training.enemy_defeated()
	else:
		phase = "hurt"
		animator.play("HitReact", 0.05)
	return loss

func _mcp_state() -> Dictionary:
	return {"health": health, "max_health": MAX_HP, "phase": phase, "phase_time": clock, "engaged": engaged, "home": home, "animation": animator.current_animation if animator else "", "animation_position": animator.current_animation_position if animator else 0, "source_height": model_height}
