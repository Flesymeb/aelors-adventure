extends "res://combat/snaiel/scripts/entities/enemy.gd"
## Retained Snaiel health, contact-instance, navigation and rig owners.
## Warden selects two actions; physics alone owns body translation.
const HEAVY_REACH := 1.95
const WAVE_RADIUS := 1.8
@export var actor_source: PackedScene
var encounter: Node3D
var stable_id := "warden"
var display_name := "锁印看守"
var next_wave := false
var attack_kind := ""
var wave_source: SnaielDamageSource
var attacks_started := 0
var heavy_started := 0
var waves_started := 0
var wave_clock := 0.0
var wave_settled := false
var telegraph: MeshInstance3D
var warning_material: ShaderMaterial

func _ready() -> void:
	target = encounter.world.player
	enabled_policy = func(): return encounter.combat_allowed() and navigation_ready and not encounter.state.warden_defeated
	ground_query = func(point: Vector3):
		if point.x < 1.25 or point.x > 6.25 or point.z > -8.5 or point.z < -14.6: return {}
		return encounter.world.ground_policy.support(encounter.world,Vector2(point.x,point.z),[get_rid(),target.get_rid()])
	contact_policy = func(damage_source,point): return encounter.world.training.player_hitbox.contact(damage_source,point)
	result_listener = encounter.world.training.resolved_enemy_contact
	attack_cue = func(): encounter.play_effect("heavy")
	var old_model: Node = $Model
	remove_child(old_model)
	old_model.free()
	var presentation: Node3D = preload("res://actors/npc_presentation.tscn").instantiate()
	presentation.name = "Model"
	presentation.model_scene = actor_source
	presentation.appearance = preload("res://assets/bosses/warden_appearance.tres")
	presentation.configure_equipment(true,false,"sword")
	add_child(presentation)
	super()
	# Complete Ranger head/eyes, paired authored pauldrons and native sword mount.
	source.reparent(presentation.sword_holder,false)
	source.position = Vector3(0,0.55,0)
	melee.weapons = {&"fist":melee.get_path_to(source)}
	# Mature proportions; imported rig lengths and rest transforms remain intact.
	model.scale = Vector3.ONE * 1.05
	model.position = Vector3.ZERO
	model_height = 1.92
	collision_layer = 3
	$Collision.shape = $Collision.shape.duplicate()
	$Collision.shape.height = 1.92
	$Collision.position.y = 0.96
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
	dead.connect(encounter.settle_defeat)

func _physics_process(delta: float) -> void:
	if not encounter.combat_allowed(): return
	if attack_kind == "wave" and health > 0:
		_refresh_navigation()
		velocity = Vector3.ZERO
		wave_clock += delta
		warning_material.set_shader_parameter("progress",minf(1,wave_clock/1.3))
		if wave_clock >= 1.3 and not wave_settled:
			wave_settled = true
			phase = "attack"
			character.play("Punch",1.4,true)
			encounter.play_effect("shockwave")
			wave_source.instance += 1
			wave_source.can_damage = true
			wave_source.set_meta("attack_origin",global_position)
			wave_source.set_meta("attack_direction",(target.global_position-global_position).normalized())
			if wave_contains(target.global_position) and line_clear(target.global_position): contact_policy.call(wave_source,target.global_position+Vector3.UP)
			wave_source.can_damage = false
			telegraph.hide()
		if wave_clock >= 1.48: phase = "recovery"
		if wave_clock >= 2.65:
			attack_kind = ""
			phase = "idle"
			character.play("Idle",1,true)
		return
	super(delta)
	# Heavy contact is sampled only by the retained posed hand; the sector is
	# an upper bound, never a body-centered substitute hit scan.
	if phase == "telegraph": warning_material.set_shader_parameter("progress",minf(1,clock/1.15))

func tick_attack(board: SnaielBlackboard) -> int:
	if melee.attacking: return SnaielBehaviorNode.RUNNING
	if not engaged or not board.get_value("perceives_player") or board.get_value("target_dist") > (WAVE_RADIUS if next_wave else 1.15): return SnaielBehaviorNode.FAILURE
	attacks_started += 1
	locked_direction = board.get_value("target_dir")
	attack_origin = global_position
	model.rotation.y = atan2(locked_direction.x,locked_direction.z)
	telegraph.rotation.y = model.rotation.y
	telegraph.mesh.size = Vector2.ONE * 2 * (WAVE_RADIUS if next_wave else HEAVY_REACH)
	telegraph.show()
	if next_wave:
		waves_started += 1
		attack_kind = "wave"
		wave_clock = 0
		wave_settled = false
		phase = "telegraph"
		character.play("Punch",0.12,true)
		warning_material.set_shader_parameter("sector",0.0)
		warning_material.set_shader_parameter("warning_color",Color(0.8,0.2,1,0.85))
	else:
		heavy_started += 1
		attack_kind = "heavy"
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
	if stage == "recovery": telegraph.hide()

func _sample_contact() -> void:
	if attack_kind != "heavy": return
	var delta_to: Vector3 = target.global_position-global_position
	delta_to.y = 0
	if delta_to.length() > HEAVY_REACH or locked_direction.dot(delta_to.normalized()) < 0.5: return
	super()

func _attack_finished() -> void:
	attack_kind = ""
	if telegraph: telegraph.hide()
	super()

func interrupt_action() -> void:
	super()
	attack_kind = ""
	wave_clock = 0
	if wave_source: wave_source.can_damage = false
	if telegraph: telegraph.hide()

func reset_encounter() -> void:
	next_wave = false
	reset_unit(encounter.state.warden_defeated,false)
	if not encounter.state.warden_defeated: collision_layer = 3
	if not is_instance_valid(navigation_region): build_navigation()

func _mcp_state() -> Dictionary:
	var result := super()
	result.merge({"boss":true,"attack_kind":attack_kind,"attacks_started":attacks_started,"heavy_started":heavy_started,"waves_started":waves_started,"wave_clock":wave_clock,"wave_radius":WAVE_RADIUS,"heavy_reach":HEAVY_REACH,"warning_visible":telegraph.visible if telegraph else false})
	return result
