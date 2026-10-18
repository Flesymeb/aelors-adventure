extends "res://combat/snaiel/scripts/entities/enemy.gd"
## Retained Snaiel health, contact-instance, navigation and rig owners.
## Warden selects two actions; physics alone owns body translation.
const HEAVY_REACH := 1.95
const WAVE_RADIUS := 1.8
@export var actor_source: PackedScene
var encounter: Node3D
var stable_id := "warden"
var display_name := "锁印看守"
var next_wave := true
var pressure_phase := false
var pressure_changes := 0
const BODY_HEIGHT := 2.5
const BODY_RADIUS := 0.68
const VISUAL_CLEARANCE := 1.35
const BOULDER_RADIUS := 0.48
var attack_kind := ""
var wave_source: SnaielDamageSource
var attacks_started := 0
var heavy_started := 0
var waves_started := 0
var wave_clock := 0.0
var wave_settled := false
var telegraph: MeshInstance3D
var warning_material: ShaderMaterial
var heavy_presentation: Node3D

func _ready() -> void:
	target = encounter.world.player
	enabled_policy = func(): return encounter.combat_allowed() and navigation_ready and not encounter.state.warden_defeated
	ground_query = func(point: Vector3):
		if point.x < 1.25 or point.x > 6.25 or point.z > -8.5 or point.z < -14.6: return {}
		if not encounter.world.ground_policy.creature_clear(encounter.world,Vector2(point.x,point.z),VISUAL_CLEARANCE,BODY_HEIGHT,[get_rid(),target.get_rid()]): return {}
		return encounter.world.ground_policy.support(encounter.world,Vector2(point.x,point.z),[get_rid(),target.get_rid()])
	contact_policy = func(damage_source,point): return encounter.world.training.player_hitbox.contact(damage_source,point)
	result_listener = encounter.world.training.resolved_enemy_contact
	attack_cue = func():
		if is_instance_valid(heavy_presentation): heavy_presentation.play_swing(source.global_position)
	var old_model: Node = $Model
	remove_child(old_model)
	old_model.free()
	# Instance the complete native creature. Its AnimationPlayer, skeleton,
	# skin, materials and embedded image remain within the imported hierarchy.
	var presentation: Node3D = actor_source.instantiate()
	presentation.name = "Model"
	add_child(presentation)
	super()
	# BaseEnemy calibrates mesh bounds to 1.72m. Native skin inverse binds
	# already compensate the importer skeleton offset; its rest-mesh AABB
	# offset must not be applied a second time to the animated creature.
	var size_ratio := BODY_HEIGHT / 1.72
	model.scale *= size_ratio
	model.position = Vector3.ZERO
	model_height = BODY_HEIGHT
	set_meta("ground_radius",VISUAL_CLEARANCE)
	set_meta("ground_height",BODY_HEIGHT)
	collision_layer = 3
	$Collision.shape = $Collision.shape.duplicate()
	$Collision.shape.height = BODY_HEIGHT
	$Collision.shape.radius = BODY_RADIUS
	$Collision.position.y = BODY_HEIGHT * 0.5
	navigation_agent.radius = BODY_RADIUS
	health_component.max_health = 240
	health_component.health = 240
	var strategy := SnaielMeleeAttack.new()
	strategy.attack_name = &"Punch"
	strategy.damage_attributes.health = 24
	strategy.anticipation = 1.15
	strategy.strike_delay = 0.18
	strategy.contact_time = 0.24
	strategy.recovery = 1.25
	melee_events.stop_attacking()
	melee_events.timeline.free()
	melee_events.configure([strategy])
	wave_source = SnaielDamageSource.new()
	wave_source.name = "ShockwaveContact"
	wave_source.entity = self
	wave_source.damage_attributes.health = 18
	wave_source.set_meta("unparryable",true)
	wave_source.set_meta("unblockable",true)
	wave_source.set_meta("ranged_contact",true)
	add_child(wave_source)
	warning_material = ShaderMaterial.new()
	warning_material.shader = preload("res://assets/bosses/warden_telegraph.gdshader")
	telegraph = MeshInstance3D.new()
	telegraph.name = "ActualDangerArea"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * WAVE_RADIUS * 2
	telegraph.mesh = quad
	telegraph.rotation.x = -PI/2
	telegraph.material_override = warning_material
	telegraph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(telegraph)
	telegraph.position.y = 0.025
	telegraph.hide()
	heavy_presentation = preload("res://combat/warden_heavy_presentation.gd").new()
	heavy_presentation.name = "HeavyContactPresentation"
	add_child(heavy_presentation)
	heavy_presentation.configure(encounter.state)
	dead.connect(encounter.settle_defeat)

func _physics_process(delta: float) -> void:
	if not encounter.combat_allowed(): return
	enter_pressure_if_needed()
	if attack_kind == "wave" and health > 0:
		_refresh_navigation()
		velocity = Vector3.ZERO
		wave_clock += delta
		warning_material.set_shader_parameter("progress",minf(1,wave_clock/1.3))
		if wave_settled:
			warning_material.set_shader_parameter("release",clampf((wave_clock-1.3)/0.18,0.001,1.0))
		if wave_clock >= 1.3 and not wave_settled:
			wave_settled = true
			phase = "attack"
			character.set_speed(1.0)
			character.anim_player.speed_scale = 1.0 / 0.65
			encounter.play_effect("shockwave")
			wave_source.instance += 1
			wave_source.can_damage = true
			wave_source.set_meta("attack_origin",global_position)
			wave_source.set_meta("attack_direction",(target.global_position-global_position).normalized())
			if wave_contains(target.global_position) and line_clear(target.global_position): contact_policy.call(wave_source,target.global_position+Vector3.UP)
			wave_source.can_damage = false
			warning_material.set_shader_parameter("release",0.001)
		if wave_clock >= 1.48:
			phase = "recovery"
			telegraph.hide()
		if wave_clock >= 2.65:
			attack_kind = ""
			phase = "idle"
			character.play("Idle",1,true)
		return
	super(delta)
	# The retained enemy may abort directly on lost sight. That path stops the
	# melee unit without emitting attacking_finished; retire only our visuals.
	if attack_kind == "heavy" and not melee.attacking:
		attack_kind = ""
		telegraph.hide()
		heavy_presentation.clear()
	# Heavy contact is sampled only by the retained posed hand; the sector is
	# an upper bound, never a body-centered substitute hit scan.
	if phase == "telegraph": warning_material.set_shader_parameter("progress",minf(1,clock/1.15))

func tick_attack(board: SnaielBlackboard) -> int:
	if melee.attacking: return SnaielBehaviorNode.RUNNING
	if not engaged or not board.get_value("perceives_player") or board.get_value("target_dist") > (WAVE_RADIUS if next_wave else HEAVY_REACH): return SnaielBehaviorNode.FAILURE
	attacks_started += 1
	locked_direction = board.get_value("target_dir")
	attack_origin = global_position
	model.rotation.y = atan2(locked_direction.x,locked_direction.z)
	telegraph.rotation.y = model.rotation.y
	telegraph.mesh.size = Vector2.ONE * 2 * (WAVE_RADIUS if next_wave else HEAVY_REACH)
	warning_material.set_shader_parameter("progress",0.0)
	warning_material.set_shader_parameter("release",0.0)
	telegraph.show()
	if next_wave:
		waves_started += 1
		attack_kind = "wave"
		wave_clock = 0
		wave_settled = false
		phase = "telegraph"
		character.play("Wave",0.65,true)
		warning_material.set_shader_parameter("sector",0.0)
		warning_material.set_shader_parameter("warning_color",Color(0.8,0.2,1,0.85))
	else:
		heavy_started += 1
		attack_kind = "heavy"
		heavy_presentation.begin(heavy_started)
		warning_material.set_shader_parameter("sector",1.0)
		warning_material.set_shader_parameter("warning_color",Color(1,0.65,0.13,0.85))
		melee.attack(0,true,false)
	next_wave = not next_wave
	return SnaielBehaviorNode.RUNNING

func wave_contains(point: Vector3) -> bool:
	var center: Vector3 = global_position if is_inside_tree() else position
	return Vector2(point.x-center.x,point.z-center.z).length() <= WAVE_RADIUS and absf(point.y-center.y) <= 1.5

func on_attack_stage(stage: String) -> void:
	super(stage)
	# Native Attack1's boulder crosses the frontal lane at 1.48-1.72s.
	# Anticipation advances to its 1.30s wind-up, then strike runs at 1x.
	if stage == "anticipation": character.set_speed(1.30 / 1.15)
	if stage == "recovery": telegraph.hide()

func _sample_contact() -> void:
	if attack_kind != "heavy": return
	var point: Vector3 = source.global_position
	# Sample authored world collision with the same posed boulder volume, even
	# when the player escaped its sector. No timer or player result implies floor
	# contact. World feedback never calls the victim/damage policy.
	if source.can_damage: _sample_world_contact(point)
	var delta_to: Vector3 = target.global_position-global_position
	delta_to.y = 0
	if delta_to.length() > HEAVY_REACH or locked_direction.dot(delta_to.normalized()) < 0.5:
		previous_fist = point
		return
	if source.can_damage and contact_policy.is_valid():
		var shape := SphereShape3D.new()
		shape.radius = BOULDER_RADIUS
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform.origin = point
		query.collision_mask = target.collision_layer
		query.exclude = [get_rid()]
		for hit in get_world_3d().direct_space_state.intersect_shape(query,8):
			if hit.collider == target and line_clear(target.global_position): contact_policy.call(source,point)
		# Sweep the same posed boulder volume, rather than a body-centered sector.
		var motion: Vector3 = point - previous_fist
		if motion.length() > 0.01:
			query.transform.origin = previous_fist
			query.motion = motion
			var fractions := get_world_3d().direct_space_state.cast_motion(query)
			if fractions[0] < 1 and line_clear(target.global_position):
				query.motion = Vector3.ZERO
				query.transform.origin = previous_fist + motion * minf(1.0,fractions[1]+0.001)
				for hit in get_world_3d().direct_space_state.intersect_shape(query,8):
					if hit.collider == target: contact_policy.call(source,query.transform.origin)
	previous_fist = point

func _sample_world_contact(point: Vector3) -> void:
	if not is_instance_valid(heavy_presentation) or heavy_presentation.settled: return
	var shape := SphereShape3D.new()
	shape.radius = BOULDER_RADIUS
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = point
	query.collision_mask = 1
	query.exclude = [get_rid(),target.get_rid()]
	var space := get_world_3d().direct_space_state
	var hit := space.get_rest_info(query)
	if hit.is_empty():
		var motion: Vector3 = point-previous_fist
		if motion.length() <= 0.01: return
		query.transform.origin = previous_fist
		query.motion = motion
		var fractions := space.cast_motion(query)
		if fractions[0] >= 1: return
		# get_rest_info does not use motion. Resolve the swept contact pose and
		# require an actual surface normal/point before emitting anything.
		query.transform.origin = previous_fist+motion*minf(1.0,fractions[1]+0.001)
		query.motion = Vector3.ZERO
		hit = space.get_rest_info(query)
	if not hit.is_empty(): heavy_presentation.world_contact(hit,heavy_started)

func _attack_finished() -> void:
	attack_kind = ""
	if telegraph: telegraph.hide()
	if is_instance_valid(heavy_presentation): heavy_presentation.clear()
	super()

func interrupt_action() -> void:
	super()
	attack_kind = ""
	wave_clock = 0
	if wave_source: wave_source.can_damage = false
	if telegraph: telegraph.hide()
	if is_instance_valid(heavy_presentation): heavy_presentation.clear()

func enter_pressure_if_needed() -> bool:
	if pressure_phase or health <= 0 or health > health_component.max_health * 0.5: return false
	pressure_phase = true
	pressure_changes += 1
	next_wave = false
	encounter.enter_pressure_phase()
	return true

func on_hurt(result: Dictionary) -> void:
	super(result)
	enter_pressure_if_needed()

func reset_encounter() -> void:
	next_wave = true
	pressure_phase = false
	pressure_changes = 0
	reset_unit(encounter.state.warden_defeated,false)
	if not encounter.state.warden_defeated: collision_layer = 3
	if not is_instance_valid(navigation_region): build_navigation()

func _mcp_state() -> Dictionary:
	var result := super()
	result.merge({"boss":true,"creature_source":"res://assets/bosses/warden_actor.glb","pressure_phase":pressure_phase,"pressure_changes":pressure_changes,"next_wave":next_wave,"body_radius":BODY_RADIUS,"body_height":BODY_HEIGHT,"visual_clearance":VISUAL_CLEARANCE,"boulder_radius":BOULDER_RADIUS,"attack_kind":attack_kind,"attacks_started":attacks_started,"heavy_started":heavy_started,"waves_started":waves_started,"wave_clock":wave_clock,"wave_radius":WAVE_RADIUS,"heavy_reach":HEAVY_REACH,"warning_visible":telegraph.visible if telegraph else false})
	result["heavy_presentation"] = heavy_presentation.snapshot() if is_instance_valid(heavy_presentation) else {}
	return result
