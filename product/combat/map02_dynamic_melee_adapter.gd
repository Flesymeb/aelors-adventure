extends "res://combat/snaiel/scripts/entities/enemy.gd"
## Retained tunic rig, retargeted clips, Beehave movement and hand contact.
var encounter: Node3D
var stable_id := ""
var activated := false
var archetype := "melee"
var display_name := "草甸游荡近战者"

func _ready() -> void:
	preload("res://ranger_head_assembly.gd").assemble($Model.find_child("Skeleton3D", true, false))
	target = encounter.world.player
	enabled_policy = func(): return activated and navigation_ready and encounter.combat_allowed() and health > 0
	ground_query = func(point: Vector3): return encounter.support_point(Vector2(point.x, point.z), [get_rid(), target.get_rid()], false)
	contact_policy = func(damage_source, point): return encounter.world.training.player_hitbox.contact(damage_source, point)
	result_listener = func(result):
		encounter.record_unit(self)
		encounter.world.training.resolved_enemy_contact(result)
	attack_cue = encounter.world.training.feedback_swing
	acquired_cue = func(): encounter.world.training.tell("草甸游荡近战者 · 抬手后出拳；可沿原路退回灯台", 4)
	dead.connect(func(): encounter.settle_defeat(self))
	super()
	health_component.max_health = 42.0
	health_component.health = 42.0
	var strategy := SnaielMeleeAttack.new()
	strategy.attack_name = &"Punch"
	strategy.damage_attributes.health = 12.0
	strategy.anticipation = 0.65
	strategy.strike_delay = 0.22
	strategy.contact_time = 0.20
	strategy.recovery = 0.70
	melee_events.stop_attacking()
	melee_events.timeline.free()
	melee_events.configure([strategy])
	collision_layer = 0
	hitbox.enabled = false
	visible = false

func navigation_sample_clear(point: Vector3) -> bool:
	return encounter.clear_volume(point, [get_rid(), target.get_rid()], 1)

func tick_attack(board: SnaielBlackboard) -> int:
	if not melee.attacking and not encounter.attack_slot_available(self): return SnaielBehaviorNode.FAILURE
	return super(board)

func restore_record(record: Dictionary) -> void:
	home = record.home
	reset_unit(false, false)
	health_component.health = record.hp
	global_position = record.position
	activated = true
	hitbox.enabled = true
	visible = true
	collision_layer = 2

func can_save() -> bool:
	return not engaged and not returning and not melee.attacking and hurt_remaining <= 0 and phase not in ["anticipation", "attack", "recovery", "hurt"]

func interrupt_action() -> void:
	super()
	engaged = false
	returning = false
	velocity = Vector3.ZERO
	hurt_remaining = 0
	lost_time = 0
	if health > 0:
		phase = "idle"
		character.play("Idle", 1, true)
	if is_instance_valid(navigation_agent): navigation_agent.target_position = global_position

func _mcp_state() -> Dictionary:
	var result := super()
	result.id = stable_id
	result.archetype = archetype
	result.activated = activated
	return result
