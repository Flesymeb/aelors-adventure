extends "res://combat/channel_melee_adapter.gd"
## Same Snaiel movement, fist contact, health and animation owner.
const SEARCH_LIMIT := 4.0
const SEARCH_PROJECTION_LIMIT := 0.8
# This adapter is also used by E01/E03. Only PressureMelee opts in before ready.
var remembered_search_enabled := false
var last_visible_position := Vector3.ZERO
var search_memory_valid := false
var search_active := false
var search_attempted := false
var search_elapsed := 0.0
var search_plans := 0
var search_path := PackedVector3Array()
var search_result := "idle"

func _ready() -> void:
	var guard: Node3D = get_node("Model")
	# Only outfit-only human rigs need the Ranger head and cloth palette.
	# Complete monster atlas rigs already have faces and painted skin/armour.
	var ranger_source := "res://Characters/QuaterniusRanger/Male_Ranger.gltf"
	var outfit_only: bool = guard.scene_file_path in [ranger_source,"res://assets/guards/melee_guard.glb"]
	if outfit_only:
		var rig: Skeleton3D = guard.find_child("Skeleton3D", true, false)
		preload("res://ranger_head_assembly.gd").assemble(rig)
	if guard.scene_file_path == ranger_source:
		var dresser := preload("res://actors/npc_presentation.gd").new()
		dresser.character_model = guard
		dresser.appearance = preload("res://assets/guards/e02_melee_appearance.tres")
		dresser._apply_appearance()
		dresser.free()
	# The route has long sightlines. Retain engagement across small distance
	# fluctuations instead of oscillating between patrol and pursuit at 5m.
	acquisition_distance = 8.0
	pursuit_distance = 10.0
	leash_distance = 10.0
	navigation_radius_cells = 14
	super()
	if remembered_search_enabled:
		acquisition_distance = 5.0
		pursuit_distance = 5.0
		leash_distance = 6.0
		navigation_radius_cells = 8
	ground_query = func(point: Vector3):
		var excluded: Array[RID] = [get_rid(), target.get_rid()]
		# A remembered route belongs on terrain, not on top of its rock obstacle.
		if remembered_search_enabled and is_instance_valid(encounter.cover_body): excluded.append(encounter.cover_body.get_rid())
		return encounter.world.ground_policy.support(encounter.world, Vector2(point.x,point.z), excluded)
	enabled_policy = func(): return encounter.combat_allowed() and navigation_ready and not encounter.state.reward_history.has(stable_id)
	acquired_cue = func(): encounter.world.training.tell("路障近战者 · 抬手后出拳；格挡、闪避后反击，退回灯台可整顿", 4)

func navigation_sample_clear(point: Vector3) -> bool:
	if not remembered_search_enabled: return super(point)
	# The baseline's small mid-body sphere admitted low rock shoulders and
	# rock-top samples. Include full standing volume plus grid-edge clearance.
	var shape := CapsuleShape3D.new()
	shape.radius = 0.60
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = point + Vector3.UP * 0.98
	query.collision_mask = 1
	query.exclude = [get_rid(), target.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _physics_process(delta: float) -> void:
	if remembered_search_enabled and is_instance_valid(encounter) and encounter.grounded and not encounter.combat_allowed():
		# Ordinary pause stops this pausable node altogether, preserving the same
		# attempt. CP02 protection, death/recovery and locks cancel action intent.
		if engaged or returning or search_memory_valid or melee.attacking:
			interrupt_action()
			engaged = false
			returning = false
		return
	super(delta)
	# The shared owner refreshes navigation before its eligibility gate. If the
	# map becomes unavailable, that gate skips perception; still end the active
	# attempt rather than freezing its clock and retaining intent indefinitely.
	if remembered_search_enabled and search_active and not navigation_ready:
		_end_search("unavailable")

func interrupt_action() -> void:
	super()
	if not remembered_search_enabled: return
	search_active = false
	search_attempted = false
	search_memory_valid = false
	search_elapsed = 0
	search_plans = 0
	last_visible_position = Vector3.ZERO
	search_path.clear()
	search_result = "idle"
	velocity = Vector3.ZERO
	navigation_clock = 0
	if is_instance_valid(navigation_agent): navigation_agent.target_position = global_position

func update_perception(distance: float, perceives: bool, delta: float) -> void:
	if not remembered_search_enabled:
		super(distance, perceives, delta)
		return
	if perceives:
		var reacquired := search_active
		search_active = false
		search_attempted = false
		search_elapsed = 0
		search_path.clear()
		last_visible_position = target.global_position
		search_memory_valid = true
		if reacquired:
			search_result = "reacquired"
			navigation_clock = 0
		super(distance, perceives, delta)
		return
	lost_time += delta
	if not engaged or returning: return
	# Retain the encounter's existing leash, independently of search memory.
	if target.global_position.distance_to(home) > 6.0:
		_end_search("leash")
		return
	if not search_attempted:
		search_attempted = true
		search_plans = 1
		search_path = _remembered_path() if search_memory_valid else PackedVector3Array()
		if search_path.is_empty():
			_end_search("unavailable")
			return
		search_active = true
		search_result = "searching"
		navigation_agent.target_position = last_visible_position
		# The existing movement owner follows this single committed destination.
		# It must not periodically plan to the unseen target or refresh the path.
		navigation_clock = SEARCH_LIMIT + 1.0
	if search_active:
		search_elapsed = minf(SEARCH_LIMIT, search_elapsed + delta)
		if not navigation_ready:
			_end_search("unavailable")
		elif search_elapsed >= SEARCH_LIMIT:
			_end_search("timed_out")

func _end_search(reason: String) -> void:
	# Preserve raw terminal scalars while clearing all usable search intent.
	var elapsed := search_elapsed
	var plans := search_plans
	var reacting: bool = blackboard.get_value("got_hit", false)
	var reaction_phase: String = phase
	interrupt_action()
	# Hurt/parry already invalidates memory. Its next occluded tick may end the
	# unavailable search, but must retain the existing exposed reaction owner.
	if reacting:
		blackboard.set_value("got_hit", true)
		phase = reaction_phase
	search_elapsed = elapsed
	search_plans = plans
	search_result = reason
	engaged = false
	returning = true
	lost_time = 0

func _remembered_path() -> PackedVector3Array:
	if not navigation_ready: return PackedVector3Array()
	var path := NavigationServer3D.map_get_path(navigation_agent.get_navigation_map(), global_position, last_visible_position, true, navigation_agent.navigation_layers)
	# The 0.75m terrain grid removes cells beside the rock's standing volume.
	# Investigate within one cell of memory through the agent's safe projection;
	# do not reject a usable detour merely because the player stood at its edge.
	if path.size() < 2 or path[-1].distance_to(last_visible_position) > SEARCH_PROJECTION_LIMIT: return PackedVector3Array()
	# Validate actual ground and static clearance once, not only a mocked route
	# or another agent's synchronized map. Occupied cover cannot be a stance.
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [get_rid(), target.get_rid()]
	for segment in range(1, path.size()):
		var from := path[segment - 1]
		var to := path[segment]
		var samples := maxi(1, int(ceil(from.distance_to(to) / 0.5)))
		for sample in range(1, samples + 1):
			var point := from.lerp(to, float(sample) / samples)
			var support: Dictionary = ground_query.call(point)
			# The existing leash bounds the player relative to home. A supported
			# detour may pass slightly farther out within the existing nav region.
			if support.is_empty() or absf(support.position.y - point.y) > 0.7: return PackedVector3Array()
			query.transform.origin = support.position + Vector3.UP * 0.98
			if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(): return PackedVector3Array()
	return path

func tick_approach(board: SnaielBlackboard) -> int:
	if not remembered_search_enabled or returning or not engaged or board.get_value("perceives_player", false): return super(board)
	if not search_active: return SnaielBehaviorNode.FAILURE
	if global_position.distance_to(search_path[-1]) <= 0.35:
		phase = "search"
		character.execute("Idle", &"set_idle")
	else:
		_move_towards(last_visible_position, "search", 1.25)
	return SnaielBehaviorNode.SUCCESS

func _mcp_state() -> Dictionary:
	var result := super()
	result.remembered_search_enabled = remembered_search_enabled
	result.search_active = search_active
	result.search_attempted = search_attempted
	result.search_memory_valid = search_memory_valid
	result.search_elapsed = search_elapsed
	result.search_plans = search_plans
	result.search_result = search_result
	result.last_visible_position = str(last_visible_position)
	result.search_path_points = search_path.size()
	result.returning = returning
	result.lost_time = lost_time
	# Pair the search clock with the actual perception and hurt owners. Missing
	# dependencies remain unavailable; observation never advances their timers.
	result.perceives_player = blackboard.get_value("perceives_player", null) if is_instance_valid(blackboard) and not blackboard.is_queued_for_deletion() else null
	var training: Node = encounter.world.training if is_instance_valid(encounter) and not encounter.is_queued_for_deletion() and is_instance_valid(encounter.world) and not encounter.world.is_queued_for_deletion() else null
	result.player_hurt_time = training.hurt_time if is_instance_valid(training) and not training.is_queued_for_deletion() else null
	return result
