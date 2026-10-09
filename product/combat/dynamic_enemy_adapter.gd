extends "res://combat/snaiel/scripts/entities/enemy.gd"
## The retained combat unit owns movement, HP, pose and legal contact.
var encounter: Node3D
var stable_id := ""
var activated := false
var display_name := "游荡兽人"

func _ready() -> void:
	target = encounter.world.player
	enabled_policy = func(): return activated and navigation_ready and encounter.combat_allowed() and health > 0
	ground_query = func(point: Vector3): return preload("res://forest_ground.gd").support(encounter.world, Vector2(point.x, point.z), [get_rid(), target.get_rid()])
	contact_policy = func(damage_source, point): return encounter.world.training.player_hitbox.contact(damage_source, point)
	result_listener = func(result):
		encounter.record_unit(self)
		encounter.world.training.resolved_enemy_contact(result)
	attack_cue = encounter.world.training.feedback_swing
	acquired_cue = func(): encounter.world.training.tell("游荡兽人 · 抬手后出拳；可退回村庄", 4)
	dead.connect(func(): encounter.settle_defeat(self))
	super()
	# PRD CH01 melee starting values; the teaching unit keeps its 24 HP / 6 hit.
	health_component.max_health = 42.0
	health_component.health = 42.0
	var strategy := SnaielMeleeAttack.new()
	strategy.attack_name = &"Punch"
	strategy.damage_attributes.health = 12.0
	strategy.anticipation = 0.65
	strategy.strike_delay = 0.22
	strategy.contact_time = 0.20
	strategy.recovery = 0.70
	# Base _ready installs the teaching timeline. Replace it before activation,
	# retaining one event clock and the existing component signal connections.
	melee_events.stop_attacking()
	melee_events.timeline.free()
	melee_events.configure([strategy])
	collision_layer = 0
	visible = false

func restore_record(record: Dictionary) -> void:
	home = record.home
	reset_unit(false, false)
	health_component.health = record.hp
	global_position = record.position
	activated = true
	visible = true
	collision_layer = 2
