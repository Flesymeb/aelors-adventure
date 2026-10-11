extends "res://preview_controller.gd"
## Independent authored environment with the retained product controller.
var route_ready := false
var route_samples := 0
var pressure_route_samples := 0
var pressure_route_ready := false
var ambush_route_ready := false
var ambush_route_samples := 0
var line_route_ready := false
var line_route_samples := 0

func _ready() -> void:
	meadow_slice = true
	ground_policy = preload("res://world/map02_ground.gd")
	super()
	# CH01 teaching remains in the shared combat component, without its actors
	# being presented as new meadow objectives or an alternative progression path.
	for node in [isha, training.hers, training.target, training.monster, lamp_training.signpost, bow_training.ronen, bow_training.target, bow_training.obstruction]:
		node.hide()
		node.process_mode = Node.PROCESS_MODE_DISABLED
		for body in [node] + node.find_children("*", "CollisionObject3D", true, false):
			if body is CollisionObject3D: body.collision_layer = 0
	bow_training.pending_demo = false
	chapter_pillar = preload("res://world/ChapterPillar.tscn").instantiate()
	chapter_pillar.return_passage = true
	chapter_pillar.anchor = ground_policy.RETURN
	chapter_pillar.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(chapter_pillar)
	chapter_pillar.configure(self)

func create_lamp_training() -> Node3D:
	return preload("res://world/map02_lamp.gd").new()

func create_element_abilities() -> Node3D:
	return preload("res://world/map02_element_abilities.gd").new()

func create_environment() -> Node3D:
	var forest: Node3D = preload("res://assets/maps/map02/Main.tscn").instantiate()
	forest.set_script(preload("res://world/map02_environment.gd"))
	return forest

func initial_spawn_height(_spawn: Vector2) -> float:
	# Placement waits for actual collision support before enabling the body.
	return 15.0

func checkpoint_xz() -> Vector2:
	return preload("res://world/map02_ground.gd").ENTRY

func _add_village_buildings() -> void:
	pass

func _place_player() -> void:
	var ground = preload("res://world/map02_ground.gd")
	var xz: Vector2 = ground.entry_xz(restored_position.get("position", Vector3.ZERO), restored_position.get("map_id", ""))
	for attempt in 120:
		await get_tree().physics_frame
		if not ground.place(self, player, xz): xz = ground.ENTRY; continue
		if not training.grounded or not bow_training.grounded or not bridge_encounter.grounded or not chapter_pillar.grounded or not pressure_encounter.grounded or not route_clue.grounded or not ambush_encounter.grounded or not line_encounter.grounded or not line_record.grounded: continue
		# Qualify support and standing volume along the scoped approach, not an
		# invisible replacement floor. The retained collision remains authoritative.
		route_samples = 0
		var stance := Node3D.new()
		add_child(stance)
		for i in 14:
			var point: Vector2 = ground.ENTRY.lerp(ground.ROADBLOCK, float(i)/13.0)
			if ground.place(self, stance, point): route_samples += 1
		# Keep the approach check and qualify the short branch to each actor.
		for anchor in ground.ROADBLOCK_ANCHORS:
			for i in 3:
				if ground.place(self, stance, ground.ROADBLOCK.lerp(anchor, float(i)/2.0)): route_samples += 1
		# The cover blocks the central arrow lane. Qualify a walking flank,
		# then both actor homes and the return line on actual retained collision.
		pressure_route_samples = 0
		var points: Array[Vector2] = [ground.ROADBLOCK, ground.PRESSURE_APPROACH, ground.PRESSURE_FLANK[0], ground.PRESSURE_FLANK[1], ground.PRESSURE_ANCHORS[0], ground.PRESSURE_ANCHORS[1]]
		for i in points.size() - 1:
			for j in 5:
				if ground.place(self, stance, points[i].lerp(points[i+1], float(j)/4.0)) and pressure_encounter.standing_clear(stance): pressure_route_samples += 1
		pressure_route_ready = pressure_route_samples == 25
		var clue_route_samples := 0
		for i in 6:
			if ground.place(self, stance, ground.PRESSURE_FLANK[1].lerp(ground.RECORD_APPROACH, float(i)/5.0)) and pressure_encounter.standing_clear(stance): clue_route_samples += 1
		pressure_route_ready = pressure_route_ready and clue_route_samples == 6
		ambush_route_samples = 0
		var ambush_points: Array[Vector2] = [ground.RECORD_APPROACH, ground.AMBUSH_ROUTE_START, ground.AMBUSH_APPROACH, ground.AMBUSH_FLANK, ground.AMBUSH_ANCHORS[0], ground.AMBUSH_ANCHORS[1]]
		for i in ambush_points.size() - 1:
			for j in 6:
				if ground.place(self, stance, ambush_points[i].lerp(ambush_points[i+1], float(j)/5.0)) and pressure_encounter.standing_clear(stance): ambush_route_samples += 1
		ambush_route_ready = ambush_route_samples == 30
		line_route_samples = 0
		var line_points: Array[Vector2] = [ground.AMBUSH_FLANK, ground.LINE_APPROACH, ground.LINE_FLANK[0], ground.LINE_FLANK[1], ground.LINE_SUPPLY_APPROACH, ground.LINE_RECORD_APPROACH]
		for i in line_points.size() - 1:
			for j in 6:
				if ground.place(self, stance, line_points[i].lerp(line_points[i+1], float(j)/5.0)) and line_encounter.standing_clear(stance): line_route_samples += 1
		line_route_ready = line_route_samples == 30
		stance.queue_free()
		route_ready = route_samples == 20 and pressure_route_ready and ambush_route_ready and line_route_ready
		if not route_ready:
			entry_failed.emit("草甸道路无法安全通行。已保留上一处落脚点。")
			return
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		player.set_meta("spawn_position", player.global_position)
		player.prepare_restored_camera(float(restored_position.get("yaw", PI)))
		entry_ready.emit()
		return
	entry_failed.emit("草甸落脚点尚未准备好。已保留上一处落脚点。")

func _mcp_state() -> Dictionary:
	var result := super()
	result.map_id = preload("res://world/map02_ground.gd").MAP02_ID
	result.route_ready = route_ready
	result.route_samples = route_samples
	result.pressure_route_ready = pressure_route_ready
	result.pressure_route_samples = pressure_route_samples
	result.ambush_route_ready = ambush_route_ready
	result.ambush_route_samples = ambush_route_samples
	result.line_route_ready = line_route_ready
	result.line_route_samples = line_route_samples
	result.checkpoint = "CP02"
	return result
