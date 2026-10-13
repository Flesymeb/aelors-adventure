extends CharacterBody3D
signal dead
var encounter: Node3D
var stable_id := "channel_ranged"
var display_name := "柱群弓守"
var home := Vector3.ZERO
var engaged := false
var phase := "idle"
var returning := false
var hurt_remaining := 0.0
var lost_time := 0.0
var attack_origin := Vector3.ZERO
var locked_direction := Vector3.ZERO
var presentation: Node3D
var action: Node
var projectiles: Array[Node3D] = []
var shots_fired := 0
var cover_contacts := 0
var player_contacts := 0
var last_projectile_result: Dictionary = {}
var navigation_region: NavigationRegion3D
var navigation_ready := false
# Read-only scalar projections retain the real ranged timeline as their owner.
# A detached/unready actor has no timeline to observe.
var ranged_executing: Variant:
	get: return action.executing_action if is_instance_valid(action) and not action.is_queued_for_deletion() else null
var ranged_can_perform: Variant:
	get: return action.can_perform_action if is_instance_valid(action) and not action.is_queued_for_deletion() else null
var ranged_cooldown_remaining: Variant:
	get: return action.cooldown if is_instance_valid(action) and not action.is_queued_for_deletion() else null
var ranged_stage: Variant:
	get: return action.stage if is_instance_valid(action) and not action.is_queued_for_deletion() else null
var hurt_pose: Variant:
	get: return presentation.current_animation if is_instance_valid(presentation) and not presentation.is_queued_for_deletion() else null
var health: float:
	get: return health_component.health if health_component else 36.0
@onready var health_component: SnaielHealth = $HealthComponent
@onready var hitbox: SnaielHitbox = $HitboxComponent
@onready var blackboard: SnaielBlackboard = $Blackboard
@onready var handler: SnaielHitHandler = $HitInteractionHandler
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent

func _ready() -> void:
	presentation = preload("res://actors/npc_presentation.tscn").instantiate()
	presentation.name = "ArcherPresentation"
	presentation.model_scene = preload("res://assets/guards/ranged_guard.glb")
	var appearance = preload("res://actors/npc_appearance.gd").new()
	appearance.cloth_color = Color(0.46,0.22,0.18)
	appearance.quiver = true
	presentation.appearance = appearance
	presentation.configure_equipment(false,true,"bow")
	add_child(presentation)
	presentation._set_weapon_visibility()
	action = preload("res://combat/snaiel/ranged_action.gd").new()
	action.name = "RangedAction"
	action.blackboard = blackboard
	add_child(action)
	action.stage_changed.connect(_stage)
	action.action_effect.connect(_shoot)
	hitbox.entity = self
	hitbox.policy = handler.handle_interaction
	hitbox.resolved.connect(encounter.world.training.resolved_enemy_contact)
	handler.blackboard = blackboard
	handler.health_component = health_component
	handler.eligibility = func(): return encounter.combat_allowed() and health > 0
	handler.reaction = _hurt
	health_component.zero_health.connect(_death)
	dead.connect(func(): encounter.settle_defeat(self))

func share_navigation(region: NavigationRegion3D) -> void:
	navigation_region = region
	navigation_agent.set_navigation_map(region.get_navigation_map())

func reset_encounter() -> void:
	interrupt_action()
	var defeated: bool = encounter.state.reward_history.has(stable_id)
	health_component.health = 0.0 if defeated else 36.0
	hitbox.enabled = not defeated
	hitbox.reset_contacts()
	phase = "death" if defeated else "idle"
	engaged = false
	returning = false
	lost_time = 0
	global_position = home
	velocity = Vector3.ZERO
	presentation.current_animation = ""
	presentation._play_animation("Death01" if defeated else "Idle")
	if defeated:
		var clip = presentation.animation_player.get_animation("Death01")
		presentation.animation_player.seek(clip.length,true)
		presentation.animation_player.pause()

func interrupt_action() -> void:
	if action: action.interrupt_action()
	if presentation: presentation.reset_archery()
	for projectile in projectiles:
		if is_instance_valid(projectile): projectile.queue_free()
	projectiles.clear()
	hurt_remaining = 0

func line_clear(destination: Vector3) -> bool:
	var excluded: Array[RID] = [get_rid(),encounter.world.player.get_rid()]
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.3,destination + Vector3.UP,1,excluded)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(delta: float) -> void:
	if not encounter.grounded or home == Vector3.ZERO: return
	navigation_ready = is_instance_valid(navigation_region) and NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) > 0
	if health <= 0 or not encounter.combat_allowed(): return
	var target: CharacterBody3D = encounter.world.player
	var distance := global_position.distance_to(target.global_position)
	var in_arena := target.global_position.distance_to(home) <= 12
	var sees := in_arena and distance <= 12 and line_clear(target.global_position)
	lost_time = 0 if sees else lost_time + delta
	if sees: engaged = true; returning = false
	elif engaged and (lost_time > lost_sight_timeout() or not in_arena):
		engaged = false
		returning = true
		action.interrupt_action()
	velocity.x = 0
	velocity.z = 0
	if hurt_remaining > 0:
		hurt_remaining = maxf(0,hurt_remaining-delta)
		phase = "hurt"
		if hurt_remaining <= 0:
			phase = "idle"
			blackboard.set_value("got_hit",false)
			presentation.current_animation = ""
			presentation._play_animation("Idle")
	elif returning:
		_move(home,"return")
		if global_position.distance_to(home) < 0.5:
			returning = false
			health_component.health = 36
			phase = "idle"
	elif engaged:
		var direction := target.global_position - global_position
		direction.y = 0
		# Face while drawing; the arrow snapshots a single direction on release.
		presentation.rotation.y = atan2(direction.x,direction.z)
		if distance >= 6 and distance <= 12 and sees:
			if not action.executing_action and encounter.attack_slot_available(self): blackboard.set_value("perform_action",true)
		elif not action.executing_action:
			var destination := target.global_position + direction.normalized() * -7 if distance < 6 else target.global_position
			# Bounded withdrawal; no endless pursuit outside the encounter.
			destination = home + (destination-home).limit_length(4)
			_move(destination,"retreat" if distance < 6 else "reposition")
	action.tick(delta, hurt_remaining <= 0 and engaged and sees and distance >= 5.5 and distance <= 12)
	presentation._update_archery(delta)
	if phase not in ["hurt","telegraph","attack","recovery"]:
		presentation._play_animation("Walk" if Vector2(velocity.x,velocity.z).length() > 0.1 else "Idle")
	if not is_on_floor(): velocity.y -= 20 * delta
	else: velocity.y = 0
	move_and_slide()

func lost_sight_timeout() -> float:
	# Encounters may retain a bounded search; shared CH01 behavior stays intact.
	return 1.1

func _move(destination: Vector3, stage: String) -> void:
	if not navigation_ready: return
	navigation_agent.target_position = destination
	var next := navigation_agent.get_next_path_position()
	var direction := next-global_position
	direction.y = 0
	if direction.length() < 0.05: return
	direction = direction.normalized()
	var excluded: Array[RID] = [get_rid(),encounter.world.player.get_rid()]
	var hit: Dictionary = encounter.world.ground_policy.support(encounter.world,Vector2(global_position.x+direction.x*0.5,global_position.z+direction.z*0.5),excluded)
	if hit.is_empty() or absf(hit.position.y-global_position.y) > 0.7: return
	velocity.x = direction.x * 1.5
	velocity.z = direction.z * 1.5
	presentation.rotation.y = atan2(direction.x,direction.z)
	phase = stage

func _stage(stage: String) -> void:
	if health <= 0: return
	phase = stage
	if stage == "telegraph":
		presentation.aim_requested = true
		presentation.aim_blend = 1
		presentation.bow_state = "draw"
		presentation.bow_charge = 0
		presentation.bow_clock = 0
		encounter.world.training.feedback.sound(preload("res://assets/dialogue/sounds/Audio/pluck_002.ogg"),-23,0.8)
	elif stage == "attack":
		presentation.release_charge = presentation.bow_charge
		presentation.bow_state = "release"
		presentation.bow_clock = 0
	elif stage == "idle": presentation.reset_archery()

func _shoot(occurrence: int) -> void:
	if health <= 0 or not encounter.combat_allowed(): return
	var origin: Vector3 = presentation.bow_draw_target.global_position
	var target: Vector3 = encounter.world.player.global_position + Vector3.UP
	var flight := origin.distance_to(target) / 16.0
	locked_direction = origin.direction_to(target + Vector3.UP * 1.5 * flight * flight)
	attack_origin = global_position
	var projectile = preload("res://combat/guard_projectile.gd").new()
	projectile.shooter = self
	projectile.occurrence = occurrence
	encounter.add_child(projectile)
	projectiles.append(projectile)
	projectile.tree_exiting.connect(func(): projectiles.erase(projectile))
	projectile.launch(origin,locked_direction,get_rid(),16,global_position + Vector3.UP*1.3)
	shots_fired += 1
	encounter.world.training.feedback.swing()

func on_hurt(result: Dictionary) -> void:
	# Elemental contact defers the registered reaction until after its immunity
	# decision. Use that same callback; damage and defeat stay with Snaiel.
	if handler.reaction.is_valid(): handler.reaction.call(result)

func _hurt(result: Dictionary) -> void:
	if result.outcome == "defeat": return
	interrupt_action()
	engaged = true
	hurt_remaining = 0.45
	phase = "hurt"
	presentation.current_animation = ""
	presentation._play_animation("Hit_Chest")

func on_parried() -> void:
	_hurt({"outcome":"hit"})

func _death() -> void:
	interrupt_action()
	phase = "death"
	engaged = false
	hitbox.enabled = false
	collision_layer = 0
	velocity = Vector3.ZERO
	presentation.current_animation = ""
	presentation._play_animation("Death01")
	dead.emit()

func _mcp_state() -> Dictionary:
	var action_available := is_instance_valid(action) and not action.is_queued_for_deletion()
	var pose_available := is_instance_valid(presentation) and not presentation.is_queued_for_deletion()
	return {"id":stable_id,"health":health,"max_health":36,"phase":phase,"engaged":engaged,"navigation_ready":navigation_ready,"shots_fired":shots_fired,"cover_contacts":cover_contacts,"player_contacts":player_contacts,"last_projectile_result":last_projectile_result,"pose":presentation._mcp_state() if pose_available else null,"action_instance":action.instance if action_available else null,"action_time":action.elapsed if action_available else null,"home":str(home),
		"hurt_remaining":hurt_remaining,"hurt_pose":hurt_pose,"ranged_executing":ranged_executing,"ranged_can_perform":ranged_can_perform,"ranged_cooldown_remaining":ranged_cooldown_remaining,"ranged_stage":ranged_stage}

func receive_contact(damage_source: SnaielDamageSource, point: Vector3) -> Dictionary:
	return hitbox.contact(damage_source, point)
