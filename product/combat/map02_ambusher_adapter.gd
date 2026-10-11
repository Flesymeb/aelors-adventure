extends "res://combat/map02_enemy_adapter.gd"
## Retained Snaiel health, EnemyActions, posed fist and animation ownership.
var rush_obstructed := false

func _ready() -> void:
	super()
	health_component.max_health = 36.0
	health_component.health = 36.0
	enabled_policy = func(): return encounter.combat_allowed() and navigation_ready and not encounter.state.reward_history.has(stable_id)
	acquired_cue = Callable()
	var strategy := SnaielMeleeAttack.new()
	strategy.attack_name = &"Punch"
	strategy.damage_attributes.health = 14.0
	strategy.anticipation = 0.6
	strategy.strike_delay = 0.18
	strategy.contact_time = 0.26
	strategy.recovery = 0.8
	melee_events.stop_attacking()
	melee_events.timeline.free()
	melee_events.configure([strategy])
	# Identity/HP are provided by the ordinary combat HUD after revelation.
	for label in find_children("*", "Label3D", true, false): label.hide()

func tick_attack(board: SnaielBlackboard) -> int:
	if melee.attacking:
		if melee_events.stage in ["strike", "contact"] and not rush_obstructed:
			var support: Dictionary = ground_query.call(global_position + locked_direction * 0.5)
			var collision := KinematicCollision3D.new()
			var blocked := test_move(global_transform, locked_direction * 0.12, collision)
			# Horizontal testing also reports the authored slope under our feet.
			# Slide on walkable ground; only walls/steep faces cancel the rush.
			var wall := blocked and collision.get_collider() != target and collision.get_normal().y < cos(floor_max_angle)
			if support.is_empty() or absf(support.position.y - global_position.y) > 0.7 or wall:
				rush_obstructed = true
			else:
				velocity.x = locked_direction.x * 5.0
				velocity.z = locked_direction.z * 5.0
		return SnaielBehaviorNode.RUNNING
	if not engaged or not board.get_value("perceives_player", false) or board.get_value("target_dist", 100.0) > 3.1 or not encounter.attack_slot_available(self): return SnaielBehaviorNode.FAILURE
	rush_obstructed = false
	attack_origin = global_position
	locked_direction = board.get_value("target_dir", Vector3.ZERO)
	model.rotation.y = atan2(locked_direction.x, locked_direction.z)
	melee.attack(0, true, false)
	return SnaielBehaviorNode.RUNNING

func on_attack_stage(stage: String) -> void:
	# Telegraph may face the player; the strike locks its direction once.
	if stage == "strike":
		locked_direction = global_position.direction_to(target.global_position)
		locked_direction.y = 0
		locked_direction = locked_direction.normalized()
		model.rotation.y = atan2(locked_direction.x, locked_direction.z)
	if stage == "anticipation": encounter.telegraph(self)
	super(stage)

func _sample_contact() -> void:
	if rush_obstructed:
		previous_fist = source.global_position
		return
	super()

func _mcp_state() -> Dictionary:
	if not is_node_ready(): return {"ready":false,"phase":null,"revealed":null}
	var result := super()
	result.revealed = encounter.state.e03_revealed
	result.recognition_remaining = encounter.recognition_remaining
	result.locked_direction = locked_direction
	result.rush_obstructed = rush_obstructed
	result.stable_id = stable_id
	return result
