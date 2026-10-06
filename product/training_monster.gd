extends CharacterBody3D
const MAX_HP = 24.0
const DAMAGE = 6.0
var training: Node3D
var model: Node3D
var animator: AnimationPlayer
var home = Vector3.ZERO
var health: float:
	get: return health_component.health if health_component else MAX_HP
var phase = "idle"
var clock: float:
	get: return melee_events.timeline.current_animation_position if melee_events and melee_events.attacking else 0.0
var engaged = false
var locked_direction = Vector3.ZERO
var attack_origin = Vector3.ZERO
var practice_replay = false
@onready var health_component: SnaielHealth = $HealthComponent
@onready var hitbox: SnaielHitbox = $HitboxComponent
@onready var blackboard: SnaielBlackboard = $Blackboard
@onready var melee_events: SnaielMeleeAnimations = $MeleeAnimations
@onready var melee: SnaielMelee = $MeleeComponent
@onready var source: SnaielDamageSource = $MeleeComponent/Fist
@onready var handler: SnaielHitHandler = $HitInteractionHandler
var behavior: SnaielBehaviorTree
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
	bind_combat()
	play("Idle")

func play(key: String, speed = 1.0) -> void:
	if animator.current_animation != key or not animator.is_playing(): animator.play(key, 0.1, speed)

func bind_combat() -> void:
	var strategy = SnaielMeleeAttack.new()
	strategy.attack_name = &"Punch"
	strategy.damage_attributes.health = DAMAGE
	strategy.anticipation = 0.9
	strategy.strike_delay = 0.15
	strategy.contact_time = 0.18
	strategy.recovery = 1.0
	melee_events.configure([strategy])
	melee.melee_animations = melee_events
	melee.weapons = {&"fist": NodePath("Fist")}
	source.entity = self
	source.parried.connect(on_parried)
	melee.configure()
	melee_events.stage_changed.connect(on_attack_stage)
	melee_events.attacking_finished.connect(func(): phase = "idle"; play("Idle"))
	hitbox.entity = self
	hitbox.policy = handler.handle_interaction
	hitbox.resolved.connect(training.resolved_enemy_contact)
	handler.blackboard = blackboard
	handler.health_component = health_component
	handler.eligibility = func(): return training.state.practice_hit and training.state.practice_defense and training.state.sword_owned and not training.player_locked() and (practice_replay or not training.state.encounter_defeated)
	handler.reaction = on_hurt
	health_component.zero_health.connect(on_death)
	behavior = SnaielBehaviorTree.new()
	behavior.name = "BehaviorTree"
	behavior.actor = self
	behavior.blackboard = blackboard
	var selector = SnaielSelector.new()
	selector.name = "EnemySelector"
	behavior.root_node = selector
	behavior.add_child(selector)
	# Snaiel BaseEnemy GotHit branch: condition -> wait -> clear fact.
	var hurt = SnaielSequence.new()
	hurt.name = "GotHit"
	var check = SnaielBlackboardCompare.new()
	check.left_operand = 'get_value("got_hit", false)'
	check.right_operand = 'true'
	hurt.add_child(check)
	var wait = SnaielWait.new()
	wait.time = 0.6
	hurt.add_child(wait)
	var clear = SnaielBlackboardSet.new()
	clear.key = '"got_hit"'
	clear.value = 'false'
	hurt.add_child(clear)
	selector.add_child(hurt)
	var attack = SnaielAction.new()
	attack.name = "MeleeAttack"
	attack.method = &"tick_attack"
	selector.add_child(attack)
	var approach = SnaielAction.new()
	approach.name = "Approach"
	approach.method = &"tick_approach"
	selector.add_child(approach)
	add_child(behavior)

func reset_encounter() -> void:
	practice_replay = false
	melee.interrupt_attack()
	behavior.interrupt()
	blackboard.set_value("got_hit", false)
	blackboard.set_value("attacking", false)
	health_component.enabled = true
	health_component.health = 0 if training.state.encounter_defeated else MAX_HP
	phase = "death" if health <= 0 else "idle"
	engaged = false
	velocity = Vector3.ZERO
	global_position = home
	flash_time = 0
	for material in materials: material.emission_enabled = false
	hitbox.reset_contacts()
	hitbox.enabled = health > 0
	behavior.enabled = health > 0
	collision_layer = 2 if health > 0 else 0
	visible = not training.state.remnant_collected
	if health <= 0:
		animator.play("Death")
		animator.seek(animator.get_animation("Death").length, true)
		animator.pause()
	else: play("Idle")

func begin_practice_replay() -> void:
	reset_encounter()
	practice_replay = true
	health_component.health = MAX_HP
	hitbox.enabled = true
	behavior.enabled = true
	collision_layer = 2
	visible = true
	phase = "idle"
	play("Idle")

func line_clear(destination: Vector3) -> bool:
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, destination + Vector3.UP, 1, [get_rid(), training.player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(delta: float) -> void:
	if not training or not training.grounded or health <= 0 or training.player_locked(): return
	flash_time = maxf(0, flash_time - delta)
	for material in materials:
		material.emission_enabled = flash_time > 0
		material.emission = Color(0.6, 0.2, 0.04)
	var target_player: CharacterBody3D = training.player
	var distance = global_position.distance_to(target_player.global_position)
	var ready: bool = training.state.practice_hit and training.state.practice_defense and training.state.sword_owned
	if not ready or target_player.global_position.distance_to(home) > 6.0 or global_position.distance_to(home) > 5.5:
		if engaged: reset_encounter()
		return
	if not engaged and distance < 5.0 and line_clear(target_player.global_position):
		engaged = true
		training.tell("◇ 训练怪 · 抬手后出拳；退回赫斯处可脱离", 4)
	if not engaged: return
	# Adapted enemy.gd target/blackboard wiring. Physics owns horizontal travel.
	var direction = target_player.global_position - global_position
	direction.y = 0
	blackboard.set_value("target", target_player)
	blackboard.set_value("target_dist", distance)
	blackboard.set_value("target_dir", direction.normalized())
	blackboard.set_value("attacking", melee.attacking)
	velocity.x = 0
	velocity.z = 0
	behavior.tick(delta)
	if source.can_damage:
		melee.sweep(self, attack_origin + Vector3.UP * 0.95, locked_direction, {target_player: training.player_hitbox}, 1)
	if not is_on_floor(): velocity.y -= 20 * delta
	else: velocity.y = 0
	move_and_slide()

func tick_attack(_board: SnaielBlackboard) -> int:
	if melee.attacking: return SnaielBehaviorNode.RUNNING
	if blackboard.get_value("target_dist") > 1.5 or not line_clear(training.player.global_position): return SnaielBehaviorNode.FAILURE
	if blackboard.get_value("got_hit", false): return SnaielBehaviorNode.FAILURE
	locked_direction = blackboard.get_value("target_dir")
	attack_origin = global_position
	model.rotation.y = atan2(locked_direction.x, locked_direction.z)
	melee.attack(0, true, false)
	return SnaielBehaviorNode.RUNNING

func tick_approach(_board: SnaielBlackboard) -> int:
	if blackboard.get_value("got_hit", false): return SnaielBehaviorNode.SUCCESS
	var direction: Vector3 = blackboard.get_value("target_dir")
	# No demo NavigationAgent/navmesh: this scoped arena steers only over real
	# Forest ground, with terrain slope/drop checks and move_and_slide collision.
	var probe = global_position + direction * 0.6
	var ray = PhysicsRayQueryParameters3D.create(probe + Vector3.UP * 0.8, probe - Vector3.UP, 1, [get_rid(), training.player.get_rid()])
	var ground = get_world_3d().direct_space_state.intersect_ray(ray)
	if ground.is_empty() or ground.normal.y < 0.65 or not line_clear(training.player.global_position):
		phase = "idle"
		play("Idle")
		return SnaielBehaviorNode.SUCCESS
	phase = "approach"
	model.rotation.y = atan2(direction.x, direction.z)
	velocity.x = direction.x * 1.25
	velocity.z = direction.z * 1.25
	play("Walk")
	return SnaielBehaviorNode.SUCCESS

func on_attack_stage(stage: String) -> void:
	match stage:
		"anticipation":
			phase = "telegraph"
			animator.play("Punch", 0.08, 0.22)
		"strike":
			phase = "attack"
			var anticipation_position = animator.current_animation_position
			animator.play("Punch", 0.05, 1.0)
			animator.seek(anticipation_position, true)
			training.feedback.swing()
		"recovery": phase = "recovery"

func on_parried() -> void:
	melee.interrupt_attack()
	behavior.interrupt()
	blackboard.set_value("got_hit", true)
	phase = "stagger"
	animator.play("HitReact", 0.05)

func on_hurt(result: Dictionary) -> void:
	melee.interrupt_attack()
	behavior.interrupt()
	velocity = Vector3.ZERO
	flash_time = 0.1 if result.outcome != "defeat" else 0.0
	if result.outcome != "defeat":
		engaged = true
		phase = "hurt"
		animator.play("HitReact", 0.05)

func on_death() -> void:
	melee.interrupt_attack()
	blackboard.set_value("attacking", false)
	behavior.interrupt()
	behavior.enabled = false
	hitbox.enabled = false
	phase = "death"
	engaged = false
	collision_layer = 0
	velocity = Vector3.ZERO
	for material in materials: material.emission_enabled = false
	animator.play("Death", 0.05)
	if not practice_replay: training.enemy_defeated()
	else: training.tell("复练结束 · 不重复发放初战奖励", 4)

func receive_contact(damage_source: SnaielDamageSource, point: Vector3) -> Dictionary:
	return hitbox.contact(damage_source, point)

func _mcp_state() -> Dictionary:
	return {"health": health, "max_health": health_component.max_health, "phase": phase, "phase_time": clock, "engaged": engaged, "home": home, "animation": animator.current_animation if animator else "", "animation_position": animator.current_animation_position if animator else 0, "source_height": model_height, "practice_replay": practice_replay, "attack_instance": source.instance, "damage_window": source.can_damage, "last_contact": hitbox.last_result, "behavior": behavior._mcp_state()}
