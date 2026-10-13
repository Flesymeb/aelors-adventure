extends "res://combat/snaiel/scripts/entities/enemy.gd"
## Native caster rig, retained Snaiel behavior/health/posed melee ownership.
@export var actor_source: PackedScene
var encounter: Node3D
var stable_id := "veyne"
var display_name := "维恩 · 裂隙祭坛"
const BODY_HEIGHT := 4.2
const BODY_RADIUS := 1.0
const VISUAL_CLEARANCE := 1.8
const MELEE_REACH := 1.9
var cast_action: Node
var beam_effect: Node3D
var attack_kind := ""
var attacks_started := 0
var casts_started := 0
var melee_started := 0
var next_cast := true
var pressure_phase := false
var pressure_changes := 0
var dragon_actions: Node3D
var telegraph: MeshInstance3D

func _ready() -> void:
	target = encounter.world.player
	enabled_policy = func(): return encounter.combat_allowed() and navigation_ready and not encounter.state.veyne_defeated
	ground_query = func(point: Vector3):
		if not encounter.ARENA.contains(Vector2(point.x,point.z)): return {}
		if not encounter.world.ground_policy.creature_clear(encounter.world,Vector2(point.x,point.z),VISUAL_CLEARANCE,BODY_HEIGHT,[get_rid(),target.get_rid()]): return {}
		return encounter.world.ground_policy.support(encounter.world,Vector2(point.x,point.z),[get_rid(),target.get_rid()])
	contact_policy = func(damage_source,point): return encounter.world.training.player_hitbox.contact(damage_source,point)
	result_listener = encounter.world.training.resolved_enemy_contact
	attack_cue = func(): encounter.play_effect("melee")
	var old: Node = $Model
	remove_child(old); old.free()
	var native: Node3D = actor_source.instantiate()
	native.name = "Model"
	add_child(native)
	super()
	# The imported skin's unposed AABB differs from its neutral skeleton pose.
	# Remove inherited humanoid normalization and fit the actual skinned pose.
	model.scale = Vector3.ONE
	model.position = Vector3.ZERO
	character.anim_tree.active = false
	animator.play("veyne/Idle")
	animator.advance(0)
	var posed: AABB = character.posed_bounds(model)
	var factor := BODY_HEIGHT/maxf(posed.size.y,0.01)
	model.scale = Vector3.ONE*factor
	model.position = Vector3(-posed.get_center().x,-posed.position.y,0)*factor
	character.anim_tree.active = true
	character.play("Idle",1,true)
	model_height = BODY_HEIGHT
	set_meta("ground_radius",VISUAL_CLEARANCE)
	set_meta("ground_height",BODY_HEIGHT)
	collision_layer = 3
	$Collision.shape = $Collision.shape.duplicate()
	$Collision.shape.height = BODY_HEIGHT
	$Collision.shape.radius = BODY_RADIUS
	$Collision.position.y = BODY_HEIGHT/2
	navigation_agent.radius = BODY_RADIUS
	health_component.max_health = 420
	health_component.health = 420
	var strategy := SnaielMeleeAttack.new()
	strategy.attack_name = &"Punch"
	strategy.damage_attributes.health = 20
	strategy.anticipation = 0.85
	strategy.strike_delay = 0.15
	strategy.contact_time = 0.3
	strategy.recovery = 1.05
	melee_events.stop_attacking()
	melee_events.timeline.free()
	melee_events.configure([strategy])
	cast_action = preload("res://combat/snaiel/veyne_cast_action.gd").new()
	add_child(cast_action)
	cast_action.configure()
	beam_effect = preload("res://combat/snaiel/veyne_beam_effect.gd").new()
	add_child(beam_effect)
	beam_effect.configure(self)
	cast_action.stage_changed.connect(_cast_stage)
	cast_action.action_effect.connect(func(): beam_effect.effect(cast_action.instance); encounter.play_effect("beam"))
	cast_action.end_effect.connect(beam_effect.end)
	cast_action.animation_finished.connect(_attack_finished)
	telegraph = preload("res://assets/bosses/veyne_effects.tscn").instantiate()
	telegraph.material_override = telegraph.material_override.duplicate()
	telegraph.material_override.set_shader_parameter("radial",1.0)
	telegraph.material_override.set_shader_parameter("warning_color",Color(1,0.65,0.15,0.85))
	telegraph.scale = Vector3(MELEE_REACH*2,MELEE_REACH*2,1)
	add_child(telegraph)
	telegraph.position.y = 0.04
	telegraph.hide()
	dragon_actions = preload("res://combat/veyne_dragon_actions.gd").new()
	dragon_actions.name = "DragonActions"
	add_child(dragon_actions)
	dragon_actions.configure(self)
	dead.connect(encounter.settle_defeat)

func _physics_process(delta: float) -> void:
	navigation_check_clock -= delta
	if navigation_check_clock <= 0 and home != Vector3.ZERO:
		_refresh_navigation(); navigation_check_clock = 0.2
	if not encounter.combat_allowed() or not navigation_ready or health <= 0: return
	if dragon_actions.kind != "":
		dragon_actions.tick(delta)
		return
	dragon_actions.effects.tick(delta)
	if cast_action and cast_action.executing_action:
		velocity = Vector3.ZERO
		if beam_effect.warning.visible: beam_effect.warning.material_override.set_shader_parameter("progress",minf(1,cast_action.timeline.current_animation_position/cast_action.ANTICIPATION))
		beam_effect.sample_contact()
		return
	# Retain the behavior tree, but qualify perception against the new room.
	var delta_to_target := target.global_position-global_position
	var distance := delta_to_target.length()
	delta_to_target.y = 0
	var perceives: bool = encounter.ARENA.contains(Vector2(target.global_position.x,target.global_position.z)) and line_clear(target.global_position)
	blackboard.set_value("target",target)
	blackboard.set_value("target_dist",distance)
	blackboard.set_value("target_dir",delta_to_target.normalized())
	blackboard.set_value("perceives_player",perceives)
	blackboard.set_value("attacking",melee.attacking)
	blackboard.set_value("patrol_dist",global_position.distance_to(patrol_point))
	velocity.x = 0; velocity.z = 0
	navigation_clock -= delta
	behavior.tick(delta)
	if not is_on_floor(): velocity.y -= 20*delta
	else: velocity.y = 0
	move_and_slide()
	_sample_contact()
	if phase == "telegraph" and attack_kind == "melee": telegraph.material_override.set_shader_parameter("progress",minf(1,clock/0.85))

func tick_attack(board: SnaielBlackboard) -> int:
	if melee.attacking or cast_action.executing_action or dragon_actions.kind != "": return SnaielBehaviorNode.RUNNING
	if not engaged or not board.get_value("perceives_player"): return SnaielBehaviorNode.FAILURE
	var distance: float = board.get_value("target_dist")
	if distance > 12.0: return SnaielBehaviorNode.FAILURE
	var selected: String = ["fire_breath","charge","dive","beam","melee"][attacks_started % 5]
	if selected == "melee" and distance > MELEE_REACH: return SnaielBehaviorNode.FAILURE
	if selected in ["fire_breath","charge","dive"]:
		if dragon_actions.begin(selected):
			attack_kind = selected; attacks_started += 1
			return SnaielBehaviorNode.RUNNING
		return SnaielBehaviorNode.FAILURE
	locked_direction = board.get_value("target_dir")
	attack_origin = global_position
	model.rotation.y = atan2(locked_direction.x,locked_direction.z)
	attacks_started += 1
	if selected == "beam":
		attack_kind = "beam"
		casts_started += 1
		next_cast = false
		beam_effect.prepare(character.casting_position(),character.casting_position().direction_to(target.global_position+Vector3.UP))
		cast_action.perform_action()
	else:
		attack_kind = "melee"
		melee_started += 1
		next_cast = true
		telegraph.show()
		melee.attack(0,true,false)
	return SnaielBehaviorNode.RUNNING

func _cast_stage(stage: String) -> void:
	match stage:
		"anticipation":
			phase = "telegraph"
			character.play("Cast",0.5/cast_action.ANTICIPATION,true)
		"active":
			phase = "attack"
			character.set_speed(1.0)
		"recovery": phase = "recovery"

func on_attack_stage(stage: String) -> void:
	super(stage)
	if stage == "anticipation": character.set_speed(0.38/0.85)
	if stage == "recovery" and telegraph: telegraph.hide()

func _sample_contact() -> void:
	if attack_kind != "melee": return
	# Retained sphere/sweep follows the native posed hand, with solid LOS.
	super()

func _attack_finished() -> void:
	attack_kind = ""
	if telegraph: telegraph.hide()
	if beam_effect: beam_effect.end()
	super()

func interrupt_action() -> void:
	super()
	if dragon_actions: dragon_actions.interrupt()
	if cast_action: cast_action.interrupt_action()
	if beam_effect: beam_effect.end()
	if telegraph: telegraph.hide()
	attack_kind = ""

func on_hurt(result: Dictionary) -> void:
	super(result)
	if result.outcome != "defeat": enter_pressure_if_needed()

func enter_pressure_if_needed() -> bool:
	if pressure_phase or health <= 0 or health > health_component.max_health*0.5: return false
	pressure_phase = true
	pressure_changes += 1
	encounter.begin_second_phase()
	return true

func reset_encounter() -> void:
	next_cast = true
	pressure_phase = false
	pressure_changes = 0
	reset_unit(encounter.state.veyne_defeated,false)
	if not encounter.state.veyne_defeated: collision_layer = 3
	if not is_instance_valid(navigation_region): build_navigation()

func _mcp_state() -> Dictionary:
	var result := super()
	result.merge({"boss":true,"dragon":dragon_actions._mcp_state() if dragon_actions else {},"attack_kind":attack_kind,"pressure_phase":pressure_phase,"pressure_changes":pressure_changes,"attacks_started":attacks_started,"casts_started":casts_started,"melee_started":melee_started,"cast_stage":cast_action.stage if cast_action else "","cast_time":cast_action.timeline.current_animation_position if cast_action and cast_action.executing_action else 0,"beam_active":beam_effect.active if beam_effect else false,"beam_contacts":beam_effect.contacts if beam_effect else 0,"beam_direction":beam_effect.direction if beam_effect else Vector3.ZERO})
	return result
