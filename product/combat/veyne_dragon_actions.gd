extends Node3D
## Creature actions share the Snaiel resolved-contact owner; physics owns travel.
var entity: CharacterBody3D
var source: SnaielDamageSource
var effects: Node3D
var landing_effect: Node3D
var warning: MeshInstance3D
var breath: MeshInstance3D
var breath_core: MeshInstance3D
var warning_quad: Mesh
var footprint_clock := 0.0
var breath_length := 0.0
var warning_triangles := 0
var kind := ""
var stage := "idle"
var elapsed := 0.0
var direction := Vector3.BACK
var start := Vector3.ZERO
var landing := Vector3.ZERO
var floor_y := 0.0
var contacts := 0
var stopped_by_wall := false
var serial := 0
var charge_endpoint := Vector3.ZERO
var charge_length := 0.0
var charge_distance := 0.0
var charge_blocked := false
var charge_contact_settled := false
const CHARGE_SPEED := 8.0
const CHARGE_SAMPLE := 0.2
const CHARGE_SKIN := 0.005
const BREATH_REACH := 8.0
const BREATH_BASE_RADIUS := 0.4
const BREATH_SPREAD := 0.18
const WINDUP := {"fire_breath":1.1,"charge":1.2,"dive":0.9}
const ACTIVE := {"fire_breath":1.1,"charge":1.15,"dive":0.7}
const RECOVERY := {"fire_breath":1.5,"charge":1.6,"dive":1.8}

func configure(owner: CharacterBody3D) -> void:
	entity = owner
	source = SnaielDamageSource.new()
	source.entity = entity
	source.damage_attributes.health = 24
	for key in ["unparryable","unblockable","ranged_contact"]: source.set_meta(key,true)
	add_child(source)
	effects = preload("res://combat/skill_effects.gd").new()
	add_child(effects)
	effects.configure(entity.encounter.world)
	landing_effect = preload("res://assets/bosses/veyne_landing_effect.tscn").instantiate()
	add_child(landing_effect)
	landing_effect.configure(entity.encounter.world, entity.encounter.state)
	warning = preload("res://assets/bosses/veyne_effects.tscn").instantiate()
	warning.material_override = warning.material_override.duplicate()
	warning_quad = warning.mesh
	# Attempt-owned lifetime, world-owned landing footprint.
	warning.top_level = true
	add_child(warning)
	breath = preload("res://assets/bosses/veyne_breath.tscn").instantiate()
	add_child(breath)
	breath_core = breath.get_node("BreathCore")
	# Sibling transforms retain the existing mouth-origin ownership contract.
	breath.remove_child(breath_core)
	add_child(breath_core)
	interrupt()

func begin(move: String) -> bool:
	if kind != "" or not entity.encounter.combat_allowed(): return false
	kind = move
	stage = "warning"
	elapsed = 0
	start = entity.global_position
	floor_y = start.y
	direction = entity.global_position.direction_to(entity.target.global_position)
	direction.y = 0
	direction = direction.normalized()
	landing = entity.target.global_position
	if kind == "dive": landing += direction*1.7
	var support: Dictionary = entity.ground_query.call(landing)
	if kind == "dive" and support.is_empty(): kind = ""; stage = "idle"; return false
	if not support.is_empty(): landing = support.position+Vector3.UP*0.08
	stopped_by_wall = false
	charge_distance = 0.0
	charge_contact_settled = false
	if kind == "charge":
		var profile := charge_profile(start,CHARGE_SPEED * float(ACTIVE.charge))
		charge_endpoint = profile.position
		charge_length = profile.distance
		charge_blocked = profile.blocked
	serial += 1
	source.instance = serial
	source.set_meta("attack_origin",start)
	source.set_meta("attack_direction",direction)
	source.set_meta("heavy_impact",kind == "dive")
	entity.model.rotation.y = atan2(direction.x,direction.z)
	entity.phase = "telegraph"
	warning.material_override.set_shader_parameter("warning_color",Color(1,0.3,0.04,0.85))
	warning.mesh = warning_quad
	warning.material_override.set_shader_parameter("footprint",kind == "fire_breath")
	warning.material_override.set_shader_parameter("radial",1.0 if kind == "dive" else 0.0)
	warning.global_position = landing+Vector3.UP*0.05 if kind == "dive" else start+direction*4+Vector3.UP*0.05
	warning.rotation = Vector3(-PI*0.5,atan2(direction.x,direction.z),0)
	warning.scale = Vector3(6,6,1) if kind == "dive" else Vector3(3.2,8,1)
	if kind == "fire_breath":
		update_breath_warning(breath_profile())
		footprint_clock = 0
	elif kind == "charge": update_charge_warning()
	warning.show()
	entity.character.play("Cast" if kind == "fire_breath" else ("Takeoff" if kind == "dive" else "Reveal"),1,true)
	entity.encounter.play_effect("beam" if kind == "fire_breath" else "melee")
	return true

func tick(delta: float) -> void:
	effects.tick(delta)
	if kind == "": return
	if not entity.encounter.combat_allowed(): return
	var previous_elapsed := elapsed
	elapsed += delta
	warning.material_override.set_shader_parameter("progress",minf(1.0,elapsed/float(WINDUP[kind])))
	if kind == "dive": tick_dive(delta); return
	if kind == "fire_breath" and stage in ["warning","active"]:
		footprint_clock -= delta
		if footprint_clock <= 0:
			update_breath_warning(breath_profile())
			footprint_clock = 0.1
	if stage == "warning" and elapsed >= WINDUP[kind]:
		if kind == "charge" and charge_length <= 0.001:
			stopped_by_wall = true; recover(); return
		stage = "active"; elapsed = 0
		entity.phase = "attack"
		source.can_damage = true
		entity.character.play("Cast" if kind == "fire_breath" else "Charge",1,true)
		if kind == "fire_breath": breath.show(); breath_core.show()
		# Charge wind-up owns this tick. Do not also spend a full motion tick;
		# retain the breath action's existing transition/contact timing.
		if kind == "charge": return
	if stage == "active":
		if kind == "fire_breath": sample_breath()
		else:
			var old := entity.global_position
			var active_delta := minf(delta,maxf(0.0,float(ACTIVE.charge)-previous_elapsed))
			var remaining := maxf(0.0,charge_length-charge_distance)
			var profile := charge_profile(old,minf(CHARGE_SPEED*active_delta,remaining))
			var motion: Vector3 = profile.position-old
			# The target never shortens the lane. Its contact belongs exclusively
			# to Snaiel, while native movement still stops at solid geometry.
			entity.add_collision_exception_with(entity.target)
			var collision := entity.move_and_collide(motion)
			entity.remove_collision_exception_with(entity.target)
			charge_distance += Vector2(entity.global_position.x-old.x,entity.global_position.z-old.z).length()
			# Include the final swept segment even when it ends at cover.
			sample_charge(old,entity.global_position)
			if kind != "charge": return
			if bool(profile.blocked) or collision != null or charge_distance >= charge_length-0.001:
				stopped_by_wall = bool(profile.blocked) or collision != null or charge_blocked
				if bool(profile.blocked) or collision != null:
					charge_length = charge_distance; charge_endpoint = entity.global_position
					update_charge_warning()
				recover()
		if stage == "active" and elapsed >= ACTIVE[kind]: recover()
	elif stage == "recovery" and elapsed >= RECOVERY[kind]: finish()

static func breath_radius(along: float) -> float:
	return BREATH_BASE_RADIUS + maxf(0.0,along) * BREATH_SPREAD

static func inside_breath(mouth: Vector3, endpoint: Vector3, point: Vector3) -> bool:
	var length := mouth.distance_to(endpoint)
	if length < 0.001: return false
	var axis := mouth.direction_to(endpoint)
	var along := (point-mouth).dot(axis)
	return along > 0 and along <= length and point.distance_to(mouth+axis*along) <= breath_radius(along)

func breath_profile() -> Dictionary:
	var mouth: Vector3 = entity.character.casting_position()
	var endpoint := mouth+direction*BREATH_REACH+Vector3.DOWN*maxf(0.0,mouth.y-floor_y-1.0)
	var wall := wall_between(mouth,endpoint)
	if not wall.is_empty(): endpoint = wall.position
	return {"mouth":mouth,"endpoint":endpoint,"axis":mouth.direction_to(endpoint),"length":mouth.distance_to(endpoint)}

func update_breath_warning(profile: Dictionary) -> void:
	# Sample the existing chest-height contact volume onto authored support.
	# Cover uses the very same mouth-to-contact ray as damage, including side
	# cover; the mesh never extends through the center obstruction endpoint.
	var rows := 12 if entity.encounter.state.graphics_quality == "low" else 20
	var columns := 4 if entity.encounter.state.graphics_quality == "low" else 8
	var side := Vector3(-direction.z,0,direction.x)
	var horizontal: float = Vector2(profile.endpoint.x-profile.mouth.x,profile.endpoint.z-profile.mouth.z).length()
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for row in rows+1:
		var fraction := float(row)/rows
		var center: Vector3 = profile.mouth+direction*horizontal*fraction
		var radius := breath_radius(float(profile.length)*fraction)
		for column in columns+1:
			var lateral := float(column)/columns*2.0-1.0
			var point := center+side*radius*lateral
			var support: Dictionary = entity.encounter.world.ground_policy.support(entity.encounter.world,Vector2(point.x,point.z),[entity.get_rid(),entity.target.get_rid()])
			var visible_point := false
			if not support.is_empty():
				point.y = support.position.y+0.055
				var chest := point+Vector3.UP*1.025
				visible_point = inside_breath(profile.mouth,profile.endpoint,chest) and wall_between(profile.mouth,chest).is_empty()
			else: point.y = floor_y+0.055
			vertices.append(point)
			colors.append(Color(1,1,1,1 if visible_point else 0))
			uvs.append(Vector2(float(column)/columns,fraction))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	warning_triangles = 0
	for row in rows:
		for column in columns:
			var a := row*(columns+1)+column
			var b := a+columns+1
			for triangle in [[a,b,a+1],[a+1,b,b+1]]:
				if colors[triangle[0]].a+colors[triangle[1]].a+colors[triangle[2]].a == 0: continue
				for index in triangle:
					tool.set_color(colors[index]); tool.set_uv(uvs[index]); tool.set_normal(Vector3.UP)
					tool.add_vertex(vertices[index])
				warning_triangles += 1
	warning.global_transform = Transform3D.IDENTITY
	warning.mesh = tool.commit() if warning_triangles else null

func update_breath_mesh(profile: Dictionary) -> void:
	var axis: Vector3 = profile.axis
	var tangent := axis.cross(Vector3.RIGHT).normalized()
	if tangent.length_squared() < 0.1: tangent = axis.cross(Vector3.FORWARD).normalized()
	var across := tangent.cross(axis).normalized()
	var segments := 8 if entity.encounter.state.graphics_quality == "low" else 12
	var rings: Array = []
	# A closed, subdivided container follows actual side-cover rays, not a
	# camera-facing quad. The shader never modifies this contact-owned extent.
	for row in 5:
		var along := float(profile.length)*float(row)/4.0
		var ring: Array[Vector3] = []
		for segment in segments:
			var angle := TAU*float(segment)/segments
			var point: Vector3 = profile.mouth+axis*along+(tangent*cos(angle)+across*sin(angle))*breath_radius(along)
			var wall := wall_between(profile.mouth,point)
			if not wall.is_empty(): point = wall.position
			ring.append(Vector3((point-profile.mouth).dot(tangent),(point-profile.mouth).dot(axis),(point-profile.mouth).dot(across)))
		rings.append(ring)
	breath.mesh = volume_mesh(rings,float(profile.length))
	breath_core.mesh = breath.mesh
	for node in [breath,breath_core]:
		node.global_transform = Transform3D(Basis(tangent,axis,across),profile.mouth)
		node.material_override.set_shader_parameter("flame_height",maxf(0.001,float(profile.length)))
		node.material_override.set_shader_parameter("effect_time",0.0 if entity.encounter.state.reduced_motion else elapsed)
		node.material_override.set_shader_parameter("reduced_motion",entity.encounter.state.reduced_motion)
		node.material_override.set_shader_parameter("layered_mode",entity.encounter.state.graphics_quality == "low" or RenderingServer.get_current_rendering_method() == "gl_compatibility")

static func volume_mesh(rings: Array, length: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = rings[0].size()
	for row in rings.size()-1:
		for segment in segments:
			var next := (segment+1)%segments
			var points: Array = [rings[row][segment],rings[row+1][segment],rings[row][next],rings[row+1][next]]
			for index in [0,1,2,2,1,3]:
				var point: Vector3 = points[index]
				tool.set_normal(Vector3(point.x,0,point.z).normalized())
				tool.set_uv(Vector2(float(segment)/segments,point.y/maxf(0.001,length)))
				tool.add_vertex(point)
	# End caps ensure front/high views see the same sampled volume.
	for end in 2:
		var ring: Array = rings[0 if end == 0 else rings.size()-1]
		var center := Vector3(0,length*end,0)
		for segment in segments:
			var next := (segment+1)%segments
			for point in [center,ring[next] if end == 0 else ring[segment],ring[segment] if end == 0 else ring[next]]:
				tool.set_normal(Vector3.DOWN if end == 0 else Vector3.UP)
				tool.set_uv(Vector2(point.x,point.z))
				tool.add_vertex(point)
	return tool.commit()

func sample_breath() -> Dictionary:
	var profile := breath_profile()
	breath_length = profile.length
	if breath_length < 0.01:
		breath.hide(); breath_core.hide(); return {}
	breath.show(); breath_core.show()
	update_breath_mesh(profile)
	var target_point: Vector3 = entity.target.global_position+Vector3.UP
	if not inside_breath(profile.mouth,profile.endpoint,target_point) or not wall_between(profile.mouth,target_point).is_empty(): return {}
	return contact(target_point,"fire")

func sample_charge(previous: Vector3, current: Vector3) -> Dictionary:
	if charge_contact_settled: return {}
	var target_point: Vector3 = entity.target.global_position+Vector3.UP
	var closest := Geometry3D.get_closest_point_to_segment(target_point,previous+Vector3.UP,current+Vector3.UP)
	if target_point.distance_to(closest)>entity.BODY_RADIUS+0.4 or not wall_between(closest,target_point).is_empty(): return {}
	var result := contact(target_point,"charge")
	if result.get("accepted",false): charge_contact_settled = true
	return result

func charge_support(point: Vector3, clearance := false) -> Dictionary:
	var exclusions := [entity.get_rid(),entity.target.get_rid()]
	var sample: Dictionary = entity.ground_query.call(point) if clearance else entity.encounter.world.ground_policy.support(entity.encounter.world,Vector2(point.x,point.z),exclusions)
	if not sample.is_empty(): return sample
	# Imported triangle seams can miss an exact ray despite continuous body
	# support. Require all four neighboring samples, never bridge an edge.
	var nearby := {}
	for offset in [Vector3(-0.02,0,-0.02),Vector3(-0.02,0,0.02),Vector3(0.02,0,-0.02),Vector3(0.02,0,0.02)]:
		var probe: Vector3 = point+offset
		var hit: Dictionary = entity.ground_query.call(probe) if clearance else entity.encounter.world.ground_policy.support(entity.encounter.world,Vector2(probe.x,probe.z),exclusions)
		if hit.is_empty() or (not nearby.is_empty() and absf(hit.position.y-nearby.position.y)>0.05): return {}
		nearby = hit
	nearby.position = Vector3(point.x,nearby.position.y,point.z)
	return nearby

func charge_profile(origin: Vector3, distance: float) -> Dictionary:
	# Prediction and execution use the same supported capsule sweep. Godot's
	# cast_motion ignores initial overlaps, so query those before every sweep.
	var point := origin
	var travelled := 0.0
	var stop_reason := ""
	var space := get_world_3d().direct_space_state
	var shape: CollisionShape3D = entity.get_node("Collision")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape.shape
	query.exclude = [entity.get_rid(),entity.target.get_rid()]
	query.collision_mask = 1
	query.margin = entity.safe_margin
	while travelled < distance-0.0001:
		query.transform = shape.global_transform
		query.transform.origin += point-entity.global_position
		query.motion = Vector3.ZERO
		if not space.intersect_shape(query,1).is_empty(): stop_reason = "overlap"; break
		var step := minf(CHARGE_SAMPLE,distance-travelled)
		var next := point+direction*step
		var support := charge_support(next,true)
		if support.is_empty() or absf(support.position.y+0.08-point.y)>0.65: stop_reason = "support"; break
		next.y = support.position.y+0.08
		var supported := true
		# Center support alone permits a wide creature to run over an edge.
		for offset in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
			var edge: Vector3 = next+offset*entity.BODY_RADIUS
			var floor_hit := charge_support(edge)
			if floor_hit.is_empty() or absf(floor_hit.position.y-support.position.y)>0.65:
				supported = false; break
		if not supported: stop_reason = "edge"; break
		query.motion = next-point
		var sweep := space.cast_motion(query)
		var fraction: float = sweep[0] if sweep.size()>0 else 0.0
		if fraction < 1.0:
			stop_reason = "solid"
			var safe := maxf(0.0,fraction-CHARGE_SKIN/maxf(query.motion.length(),CHARGE_SKIN))
			point += query.motion*safe
			travelled += step*safe
			break
		point = next
		travelled += step
	return {"position":point,"distance":travelled,"blocked":travelled<distance-0.001,"stop_reason":stop_reason}

func update_charge_warning() -> void:
	# A single supported world-space capsule describes the complete swept
	# contact lane, including body/target clearance and both end caps.
	var radius: float = entity.BODY_RADIUS+0.4
	var side := Vector3(-direction.z,0,direction.x)
	var rows := maxi(2,ceili((charge_length+radius*2)/0.3))
	var columns := 6 if entity.encounter.state.graphics_quality == "low" else 10
	var points := PackedVector3Array()
	var uvs := PackedVector2Array()
	var supported: Array[bool] = []
	for row in rows+1:
		var along := lerpf(-radius,charge_length+radius,float(row)/rows)
		var cap := maxf(0.0,maxf(-along,along-charge_length))
		var width := sqrt(maxf(0.0,radius*radius-cap*cap))
		for column in columns+1:
			var point := start+direction*along+side*width*(float(column)/columns*2-1)
			var support := charge_support(point)
			supported.append(not support.is_empty())
			point.y = support.position.y+0.055 if not support.is_empty() else floor_y+0.055
			points.append(point)
			uvs.append(Vector2(float(column)/columns,float(row)/rows))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	warning_triangles = 0
	for row in rows:
		for column in columns:
			var a := row*(columns+1)+column
			var b := a+columns+1
			for triangle in [[a,b,a+1],[a+1,b,b+1]]:
				if not supported[triangle[0]] or not supported[triangle[1]] or not supported[triangle[2]]: continue
				for index in triangle:
					tool.set_normal(Vector3.UP); tool.set_color(Color.WHITE); tool.set_uv(uvs[index]); tool.add_vertex(points[index])
				warning_triangles += 1
	warning.global_transform = Transform3D.IDENTITY
	warning.mesh = tool.commit() if warning_triangles else null
	warning.material_override.set_shader_parameter("footprint",true)

func tick_dive(delta: float) -> void:
	if stage == "warning":
		if not travel(Vector3.UP*4.0*delta,true): stopped_by_wall = true; recover(); return
		if elapsed >= 0.9: stage = "flight"; elapsed = 0; entity.character.play("Flight",1,true)
	elif stage == "flight":
		var destination := landing+Vector3.UP*5.0
		if not travel((destination-entity.global_position)*minf(1.0,delta*2.5),true): stopped_by_wall = true; recover(); return
		if elapsed >= 1.2:
			stage = "active"; elapsed = 0; entity.phase = "attack"
			entity.character.play("Dive",1,true)
	elif stage == "active":
		var remaining := landing-entity.global_position
		if not travel(remaining*minf(1.0,delta/maxf(0.05,0.7-elapsed)),true): stopped_by_wall = true; recover(); return
		if elapsed >= 0.7 or entity.global_position.distance_to(landing)<0.15:
			var support: Dictionary = entity.ground_query.call(entity.global_position)
			if not verified_arrival(entity.global_position, landing, support):
				stopped_by_wall = true; recover(); return
			entity.global_position = support.position + Vector3.UP * 0.08
			landing = entity.global_position
			source.set_meta("attack_origin",support.position)
			landing_effect.emit_once(support.position,support.get("normal",Vector3.UP),serial,null)
			source.can_damage = true
			var point: Vector3 = entity.target.global_position+Vector3.UP
			if Vector2(point.x,point.z).distance_to(Vector2(landing.x,landing.z))<=3.0 and absf(entity.target.global_position.y-landing.y)<1.5 and wall_between(landing+Vector3.UP,point).is_empty(): contact(point,"dive")
			# Heavy hurt clears the previous camera owner. Apply the grounded
			# impulse after settlement, only if death did not end the encounter.
			if landing_effect.active and entity.encounter.combat_allowed() and entity.target.has_method("start_camera_shake"):
				entity.target.start_camera_shake(landing_effect.distance_strength(entity.target.global_position.distance_to(support.position)),0.24)
			recover()
	elif stage == "recovery" and elapsed >= RECOVERY[kind]: finish()

static func verified_arrival(position: Vector3, committed: Vector3, support: Dictionary) -> bool:
	return not support.is_empty() and Vector2(position.x-committed.x,position.z-committed.z).length() <= 0.18 and absf(position.y - support.position.y - 0.08) <= 0.2

func travel(motion: Vector3, airborne := false) -> bool:
	var point := entity.global_position+motion
	if not entity.encounter.ARENA.contains(Vector2(point.x,point.z)): return false
	if not airborne:
		var support: Dictionary = entity.ground_query.call(point)
		if support.is_empty() or absf(support.position.y-entity.global_position.y)>0.65: return false
		motion.y = support.position.y+0.08-entity.global_position.y
	# cast_motion ignores initial overlap; test that independently before sweep.
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = entity.get_node("Collision").shape
	query.transform = entity.get_node("Collision").global_transform
	query.exclude = [entity.get_rid(),entity.target.get_rid()]
	query.collision_mask = 1
	var space := get_world_3d().direct_space_state
	if not space.intersect_shape(query,1).is_empty(): return false
	query.motion = motion
	var sweep := space.cast_motion(query)
	var fraction: float = sweep[0] if sweep.size()>0 else 0.0
	# Airborne collision ignores the target body, whose landing exposure is
	# resolved only at the actual grounded impact; stone still owns the sweep.
	if airborne: entity.add_collision_exception_with(entity.target)
	entity.move_and_collide(motion*maxf(0.0,fraction-0.001))
	if airborne: entity.remove_collision_exception_with(entity.target)
	return fraction>=0.999

func wall_between(origin: Vector3, endpoint: Vector3) -> Dictionary:
	if origin.distance_squared_to(endpoint)<0.0001: return {}
	var query := PhysicsRayQueryParameters3D.create(origin,endpoint,1,[entity.get_rid(),entity.target.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func contact(point: Vector3, element: String) -> Dictionary:
	var result: Dictionary = entity.contact_policy.call(source,point)
	if result.get("accepted",false):
		contacts += 1
		if element != "dive":
			effects.contact(point,"fire" if element == "fire" else "lightning",str(result.get("outcome","")),float(result.get("hp_loss",0)))
			entity.encounter.play_effect("rift")
	return result

func recover() -> void:
	source.can_damage = false
	breath.hide(); breath_core.hide(); warning.hide()
	stage = "recovery"; elapsed = 0; entity.phase = "recovery"
	ground_after_flight()
	entity.character.play("Land" if kind == "dive" else "Idle",1,true)

func ground_after_flight() -> void:
	if kind != "dive": return
	var point: Dictionary = entity.ground_query.call(entity.global_position)
	if not point.is_empty(): entity.global_position.y = point.position.y+0.08

func finish() -> void:
	kind = ""; stage = "idle"; elapsed = 0
	entity._attack_finished()

func interrupt() -> void:
	if source: source.can_damage = false
	if warning: warning.hide()
	if breath: breath.hide()
	if breath_core: breath_core.hide()
	if effects: effects.clear_transients()
	if landing_effect: landing_effect.clear()
	if entity: ground_after_flight()
	kind = ""; stage = "idle"; elapsed = 0
	charge_length = 0.0; charge_distance = 0.0; charge_contact_settled = false

func _mcp_state() -> Dictionary:
	return {"kind":kind,"stage":stage,"time":elapsed,"landing":landing,"direction":direction,"contacts":contacts,"charge_endpoint":charge_endpoint,"charge_length":charge_length,"charge_distance":charge_distance,"breath_length":breath_length,"warning_triangles":warning_triangles,"stopped_by_wall":stopped_by_wall,"source_active":source.can_damage if source else false,"effects":effects.snapshot() if effects else {},"ground_impact":landing_effect.snapshot() if landing_effect else {}}
