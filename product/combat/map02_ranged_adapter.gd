extends "res://combat/channel_ranged_adapter.gd"
## Retained Ranger/KayKit draw, Snaiel ranged timeline and swept arrow contact.
## E02 adds lifecycle ownership; it does not introduce another damage authority.
const WITHDRAWAL_BURST := 0.9
const WITHDRAWAL_STAND := 0.7
const COVER_SEARCH_LIMIT := 6.0
const COVER_HOME_RADIUS := 4.0
var cover_search_active := false
var cover_search_attempted := false
var cover_search_elapsed := 0.0
var cover_search_plans := 0
var cover_destination := Vector3.ZERO
var cover_path := PackedVector3Array()
var cover_search_result := "idle"
var withdrawal_active := false
var withdrawal_elapsed := 0.0
var withdrawal_recovery_remaining := 0.0
# Raw geometry only: range, cooldown, navigation and attack-slot eligibility
# remain separate combat decisions. Sampling never ticks or plans an action.
var ranged_line_clear: Variant:
	get:
		if not is_inside_tree() or is_queued_for_deletion(): return null
		if not is_instance_valid(encounter) or encounter.is_queued_for_deletion() or not encounter.is_inside_tree(): return null
		var world: Node3D = encounter.world
		if not is_instance_valid(world) or world.is_queued_for_deletion() or not world.is_inside_tree(): return null
		var player: CharacterBody3D = world.player
		if not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree(): return null
		var space := get_world_3d()
		if space == null or space != player.get_world_3d() or space.direct_space_state == null: return null
		return line_clear(player.global_position)

func _ready() -> void:
	super()
	handler.eligibility = func(): return encounter.combat_allowed() and navigation_ready and health > 0

func interrupt_action() -> void:
	super()
	engaged = false
	returning = false
	lost_time = 0
	velocity = Vector3.ZERO
	withdrawal_active = false
	withdrawal_elapsed = 0
	withdrawal_recovery_remaining = 0
	_clear_cover_search()
	if health > 0: phase = "idle"

func reset_encounter() -> void:
	super()
	# Cooldowns and input requests belong to this disposable combat execution.
	action.cooldown = 0
	action.can_perform_action = true
	blackboard.set_value("perform_action", false)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(encounter) or not encounter.grounded: return
	if not encounter.combat_allowed():
		if engaged or returning or action.executing_action or not projectiles.is_empty(): interrupt_action()
		return
	if stable_id == "map02_e02_ranged": _update_cover_search(delta)
	withdrawal_recovery_remaining = maxf(0, withdrawal_recovery_remaining - delta)
	if withdrawal_active:
		withdrawal_elapsed = minf(WITHDRAWAL_BURST, withdrawal_elapsed + delta)
		if withdrawal_elapsed >= WITHDRAWAL_BURST:
			withdrawal_active = false
			withdrawal_recovery_remaining = WITHDRAWAL_STAND
	# Do not let an old blackboard request start an attack after another actor
	# acquired the encounter's attack slot during the preceding physics frame.
	if not action.executing_action and not encounter.attack_slot_available(self):
		blackboard.set_value("perform_action", false)
	super(delta)

func lost_sight_timeout() -> float:
	return COVER_SEARCH_LIMIT if stable_id == "map02_e02_ranged" and cover_search_active else super()

func _clear_cover_search() -> void:
	cover_search_active = false
	cover_search_attempted = false
	cover_search_elapsed = 0
	cover_search_plans = 0
	cover_destination = Vector3.ZERO
	cover_path.clear()
	cover_search_result = "idle"

func _update_cover_search(delta: float) -> void:
	if health <= 0 or not engaged or returning: return
	var target: Vector3 = encounter.world.player.global_position
	var distance := global_position.distance_to(target)
	if target.distance_to(home) > 12 or distance < 6 or distance > 12:
		_clear_cover_search()
		return
	if line_clear(target):
		if cover_search_active: cover_search_result = "reacquired"
		cover_search_active = false
		cover_search_attempted = false
		return
	if not cover_search_attempted:
		cover_search_attempted = true
		cover_search_elapsed = 0
		cover_search_plans = 1
		cover_path = _firing_path(target)
		cover_search_active = not cover_path.is_empty()
		cover_search_result = "searching" if cover_search_active else "unavailable"
		if cover_search_active: cover_destination = cover_path[-1]
	if cover_search_active:
		cover_search_elapsed += delta
		if cover_search_elapsed >= COVER_SEARCH_LIMIT:
			cover_search_active = false
			cover_search_result = "timed_out"

func _supported_stance(point: Vector3) -> Variant:
	var excluded: Array[RID] = [get_rid(), encounter.world.player.get_rid()]
	var support: Dictionary = encounter.world.ground_policy.support(encounter.world, Vector2(point.x, point.z), excluded)
	if support.is_empty(): return null
	var position: Vector3 = support.position + Vector3.UP * 0.08
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = position + Vector3.UP * 0.9
	query.collision_mask = 1
	query.exclude = excluded
	return position if get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty() else null

func _firing_path(target: Vector3) -> PackedVector3Array:
	# Inspect supported flank stances once per obstruction, never pursue the
	# player's occupied cover or replace the retained NavigationAgent movement.
	var best := PackedVector3Array()
	var best_length := maxf(0, COVER_SEARCH_LIMIT - cover_search_elapsed) * 1.5
	if not navigation_ready: return best
	var map := navigation_agent.get_navigation_map()
	for radius in [2.0, COVER_HOME_RADIUS]:
		for index in 8:
			var angle := TAU * float(index) / 8.0
			var stance: Variant = _supported_stance(home + Vector3(cos(angle), 0, sin(angle)) * radius)
			if stance == null: continue
			var candidate: Vector3 = stance
			var distance := candidate.distance_to(target)
			if candidate.distance_to(home) > COVER_HOME_RADIUS + 0.1 or distance < 6 or distance > 12: continue
			if not _firing_stance_clear(candidate, target): continue
			var path := NavigationServer3D.map_get_path(map, global_position, candidate, true, navigation_agent.navigation_layers)
			if path.size() < 2 or path[-1].distance_to(candidate) > 0.35: continue
			var length := 0.0
			var supported := true
			for segment in range(1, path.size()):
				var from := path[segment - 1]
				var to := path[segment]
				length += from.distance_to(to)
				for sample in range(1, maxi(1, int(ceil(from.distance_to(to) / 0.5))) + 1):
					var point := from.lerp(to, minf(1.0, float(sample) * 0.5 / maxf(0.01, from.distance_to(to))))
					var actual: Variant = _supported_stance(point)
					if actual == null or absf(actual.y - point.y) > 0.7 or point.distance_to(home) > COVER_HOME_RADIUS + 0.35:
						supported = false
						break
				if not supported: break
			if supported and length < best_length:
				best = path
				best_length = length
	return best

func _firing_stance_clear(candidate: Vector3, target: Vector3) -> bool:
	# Navigation arrival has a 0.35m tolerance. A ray grazing the rock at the
	# exact endpoint is insufficient: require clearance across that tolerance.
	for offset in [Vector3.ZERO, Vector3.LEFT * 0.4, Vector3.RIGHT * 0.4, Vector3.FORWARD * 0.4, Vector3.BACK * 0.4]:
		# Stance placement has an 0.08m gap; the body settles onto the floor.
		# Use the lower grounded eye line, with a small vertical safety margin.
		var query := PhysicsRayQueryParameters3D.create(candidate + offset + Vector3.UP * 1.18, target + Vector3.UP, 1, [get_rid(), encounter.world.player.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return false
	return true

func _move(destination: Vector3, stage: String) -> void:
	if stable_id == "map02_e02_ranged" and stage == "reposition" and cover_search_active:
		destination = cover_destination
		if global_position.distance_to(destination) < 0.4:
			# A player moving during the search may invalidate its firing line.
			# Allow one updated route within the SAME finite clock, then stop.
			if cover_search_plans < 2:
				cover_search_plans += 1
				cover_path = _firing_path(encounter.world.player.global_position)
				if not cover_path.is_empty():
					cover_destination = cover_path[-1]
					destination = cover_destination
				else:
					cover_search_active = false
			if cover_path.is_empty() or global_position.distance_to(destination) < 0.4:
				cover_search_active = false
				cover_search_result = "occluded_at_destination"
				return
	if stage != "retreat":
		withdrawal_active = false
		withdrawal_elapsed = 0
		super(destination, stage)
		return
	if withdrawal_recovery_remaining > 0:
		# A readable stationary opening after each bounded withdrawal; the
		# inherited update has already zeroed horizontal velocity this frame.
		phase = "withdrawal_recovery"
		return
	if not withdrawal_active:
		withdrawal_active = true
		withdrawal_elapsed = 0
	super(destination, stage)

func can_save() -> bool:
	if engaged or returning or phase in ["telegraph", "attack", "recovery", "hurt"] or action.executing_action: return false
	for projectile in projectiles:
		if is_instance_valid(projectile) and not projectile.settled: return false
	return true

func _mcp_state() -> Dictionary:
	var result := super()
	result.ranged_line_clear = ranged_line_clear
	result.withdrawal_active = withdrawal_active
	result.withdrawal_elapsed = withdrawal_elapsed
	result.withdrawal_recovery_remaining = withdrawal_recovery_remaining
	result.cover_search_active = cover_search_active
	result.cover_search_elapsed = cover_search_elapsed
	result.cover_search_plans = cover_search_plans
	result.cover_search_result = cover_search_result
	result.cover_destination = str(cover_destination)
	result.cover_path_points = cover_path.size()
	return result
