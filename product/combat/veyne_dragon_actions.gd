extends Node3D
## Creature actions share the Snaiel resolved-contact owner; physics owns travel.
var entity: CharacterBody3D
var source: SnaielDamageSource
var effects: Node3D
var warning: MeshInstance3D
var breath: MeshInstance3D
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
	warning = preload("res://assets/bosses/veyne_effects.tscn").instantiate()
	warning.material_override = warning.material_override.duplicate()
	add_child(warning)
	breath = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 1.5
	cone.bottom_radius = 0.15
	cone.height = 1
	cone.radial_segments = 12
	breath.mesh = cone
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/fire_breath.gdshader")
	mat.set_shader_parameter("flame_height",1.0)
	mat.set_shader_parameter("flame_height_offset",-0.5)
	mat.set_shader_parameter("outline_enabled",false)
	breath.material_override = mat
	breath.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(breath)
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
	serial += 1
	source.instance = serial
	source.set_meta("attack_origin",start)
	source.set_meta("attack_direction",direction)
	entity.model.rotation.y = atan2(direction.x,direction.z)
	entity.phase = "telegraph"
	warning.material_override.set_shader_parameter("warning_color",Color(1,0.3,0.04,0.85))
	warning.material_override.set_shader_parameter("radial",1.0 if kind == "dive" else 0.0)
	warning.global_position = landing+Vector3.UP*0.05 if kind == "dive" else start+direction*4+Vector3.UP*0.05
	warning.rotation.y = atan2(direction.x,direction.z)
	warning.scale = Vector3(6,6,1) if kind == "dive" else Vector3(3.2,8,1)
	warning.show()
	entity.character.play("Cast" if kind == "fire_breath" else ("Takeoff" if kind == "dive" else "Reveal"),1,true)
	entity.encounter.play_effect("beam" if kind == "fire_breath" else "melee")
	return true

func tick(delta: float) -> void:
	effects.tick(delta)
	if kind == "": return
	if not entity.encounter.combat_allowed(): return
	elapsed += delta
	warning.material_override.set_shader_parameter("progress",minf(1.0,elapsed/float(WINDUP[kind])))
	if kind == "dive": tick_dive(delta); return
	if stage == "warning" and elapsed >= WINDUP[kind]:
		stage = "active"; elapsed = 0
		entity.phase = "attack"
		source.can_damage = true
		entity.character.play("Cast" if kind == "fire_breath" else "Charge",1,true)
		if kind == "fire_breath": breath.show()
	if stage == "active":
		if kind == "fire_breath": sample_breath()
		else:
			var old := entity.global_position
			if not travel(direction*8.0*delta): stopped_by_wall = true; recover()
			if stage == "active": sample_charge(old,entity.global_position)
		if elapsed >= ACTIVE[kind]: recover()
	elif stage == "recovery" and elapsed >= RECOVERY[kind]: finish()

func sample_breath() -> Dictionary:
	var mouth: Vector3 = entity.character.casting_position()
	var endpoint := mouth+direction*8.0+Vector3.DOWN*maxf(0.0,mouth.y-floor_y-1.0)
	var wall := wall_between(mouth,endpoint)
	if not wall.is_empty(): endpoint = wall.position
	var axis := mouth.direction_to(endpoint)
	var tangent := axis.cross(Vector3.RIGHT).normalized()
	if tangent.length_squared() < 0.1: tangent = axis.cross(Vector3.FORWARD).normalized()
	breath.global_basis = Basis(tangent,axis,tangent.cross(axis).normalized())
	breath.global_position = (mouth+endpoint)*0.5
	breath.scale.y = maxf(0.01,mouth.distance_to(endpoint))
	breath.material_override.set_shader_parameter("effect_time",0.0 if entity.encounter.state.reduced_motion else elapsed)
	breath.material_override.set_shader_parameter("reduced_motion",entity.encounter.state.reduced_motion or entity.encounter.state.graphics_quality == "low")
	var target_point: Vector3 = entity.target.global_position+Vector3.UP
	var along: float = (target_point-mouth).dot(axis)
	if along <= 0 or along > mouth.distance_to(endpoint): return {}
	var lateral: float = (target_point-(mouth+axis*along)).length()
	if lateral > 0.4+along*0.18 or not wall_between(mouth,target_point).is_empty(): return {}
	return contact(target_point,"fire")

func sample_charge(previous: Vector3, current: Vector3) -> Dictionary:
	var target_point: Vector3 = entity.target.global_position+Vector3.UP
	var closest := Geometry3D.get_closest_point_to_segment(target_point,previous+Vector3.UP,current+Vector3.UP)
	if target_point.distance_to(closest)>entity.BODY_RADIUS+0.4 or not wall_between(closest,target_point).is_empty(): return {}
	return contact(target_point,"charge")

func tick_dive(delta: float) -> void:
	if stage == "warning":
		travel(Vector3.UP*4.0*delta,true)
		if elapsed >= 0.9: stage = "flight"; elapsed = 0; entity.character.play("Flight",1,true)
	elif stage == "flight":
		var destination := landing+Vector3.UP*5.0
		travel((destination-entity.global_position)*minf(1.0,delta*2.5),true)
		if elapsed >= 1.2:
			stage = "active"; elapsed = 0; entity.phase = "attack"
			entity.character.play("Dive",1,true)
	elif stage == "active":
		var remaining := landing-entity.global_position
		if not travel(remaining*minf(1.0,delta/maxf(0.05,0.7-elapsed)),true): stopped_by_wall = true; recover(); return
		if elapsed >= 0.7 or entity.global_position.distance_to(landing)<0.15:
			source.can_damage = true
			var point: Vector3 = entity.target.global_position+Vector3.UP
			if Vector2(point.x,point.z).distance_to(Vector2(landing.x,landing.z))<=3.0 and absf(entity.target.global_position.y-landing.y)<1.5 and wall_between(landing+Vector3.UP,point).is_empty(): contact(point,"dive")
			recover()
	elif stage == "recovery" and elapsed >= RECOVERY[kind]: finish()

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
		effects.contact(point,"fire" if element == "fire" else "lightning",str(result.get("outcome","")),float(result.get("hp_loss",0)))
		entity.encounter.play_effect("rift")
	return result

func recover() -> void:
	source.can_damage = false
	breath.hide(); warning.hide()
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
	if effects: effects.clear_transients()
	if entity: ground_after_flight()
	kind = ""; stage = "idle"; elapsed = 0

func _mcp_state() -> Dictionary:
	return {"kind":kind,"stage":stage,"time":elapsed,"landing":landing,"direction":direction,"contacts":contacts,"stopped_by_wall":stopped_by_wall,"source_active":source.can_damage if source else false,"effects":effects.snapshot() if effects else {}}
