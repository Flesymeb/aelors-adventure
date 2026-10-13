extends "res://combat/map02_ambusher_adapter.gd"
## E03's rig, rush timeline and posed contact, with CH02 instance-only facts.
var activated := false
var archetype := "ambusher"
var revealed := false
var recognition_remaining := 0.0
var variant := 0
var warning_seen := false

func _ready() -> void:
	passive_healing = false
	super()
	enabled_policy = func(): return activated and revealed and recognition_remaining <= 0 and navigation_ready and encounter.combat_allowed() and health > 0
	ground_query = func(point: Vector3): return encounter.support_point(Vector2(point.x, point.z), [get_rid(), target.get_rid()], false)
	result_listener = func(result):
		encounter.record_unit(self)
		encounter.world.training.resolved_enemy_contact(result)
	collision_layer = 0
	hitbox.enabled = false
	visible = false

func navigation_sample_clear(point: Vector3) -> bool:
	return encounter.clear_volume(point, [get_rid(), target.get_rid()], 1)

func restore_record(record: Dictionary) -> void:
	home = record.home
	reset_unit(false, false)
	health_component.health = record.hp
	global_position = record.position
	variant = record.variant
	revealed = record.revealed
	activated = true
	# Saved action intent never resumes; restored revelation remains instance-owned.
	recognition_remaining = 0.8 if revealed else 0.0
	rush_obstructed = false
	warning_seen = false
	update_visibility()

func update_visibility() -> void:
	visible = activated
	collision_layer = 2 if activated and revealed and health > 0 else 0
	hitbox.enabled = activated and revealed and health > 0
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.transparency = 0.0 if revealed else 0.90

func reveal() -> bool:
	if not activated or revealed or health <= 0: return false
	revealed = true
	recognition_remaining = 0.8
	interrupt_action()
	update_visibility()
	encounter.record_unit(self)
	return true

func _physics_process(delta: float) -> void:
	if activated and encounter.combat_allowed():
		recognition_remaining = maxf(0, recognition_remaining - delta)
		if not revealed and not warning_seen and target.global_position.distance_to(home) < 10:
			warning_seen = true
			encounter.world.training.tell("岔路草丛传来低语 · 可绕行，或用 [3] 旧灯 [F] 显形（7 米）", 6)
			encounter.world.training.feedback.sound(preload("res://assets/training/soft_impact.ogg"), -24, 0.45)
	super(delta)

func can_save() -> bool:
	return not engaged and not returning and not melee.attacking and hurt_remaining <= 0 and recognition_remaining <= 0 and phase not in ["anticipation", "attack", "recovery", "hurt"]

func interrupt_action() -> void:
	super()
	engaged = false
	returning = false
	velocity = Vector3.ZERO
	hurt_remaining = 0
	lost_time = 0
	rush_obstructed = false
	if health > 0:
		phase = "idle"
		character.play("Idle", 1, true)
	if is_instance_valid(navigation_agent): navigation_agent.target_position = global_position

func _mcp_state() -> Dictionary:
	# Avoid the fixed adapter's global E03 observation entirely.
	var result := _binding_observation()
	result.merge({"ready":is_node_ready(), "id":stable_id, "archetype":archetype, "activated":activated, "revealed":revealed, "variant":variant, "recognition_remaining":recognition_remaining, "phase":phase, "hp":health, "position":global_position, "engaged":engaged, "navigation_ready":navigation_ready, "locked_direction":locked_direction, "rush_obstructed":rush_obstructed, "warning_seen":warning_seen, "attacking":melee.attacking if is_instance_valid(melee) else false})
	return result
