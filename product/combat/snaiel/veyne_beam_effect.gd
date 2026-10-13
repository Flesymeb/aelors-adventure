extends Node3D
## Adapted Snaiel energy_beam.gd / NonMeleeActionEffect (MIT, LICENSES.txt).
## One directional beam instance, no projectile loop, no target-position typo,
## no parry callback. Both rendering and damage use the obstacle-clipped lane.
const LENGTH := 6.0
const HALF_WIDTH := 0.32
var entity: CharacterBody3D
var source: SnaielDamageSource
var origin := Vector3.ZERO
var direction := Vector3.FORWARD
var active := false
var warning: MeshInstance3D
var beam_id := -1
var clipped_length := LENGTH
var contacts := 0
var blocked := false

func configure(owner: CharacterBody3D) -> void:
	entity = owner
	source = SnaielDamageSource.new()
	source.entity = entity
	source.damage_attributes.health = 22
	for key in ["unparryable","unblockable","ranged_contact"]: source.set_meta(key,true)
	add_child(source)
	warning = preload("res://assets/bosses/veyne_effects.tscn").instantiate()
	warning.material_override = warning.material_override.duplicate()
	add_child(warning)
	end()

func prepare(point: Vector3, facing: Vector3) -> void:
	end()
	origin = point
	direction = facing.normalized()

	source.set_meta("attack_origin",origin-Vector3.UP)
	source.set_meta("attack_direction",direction)
	_refresh_length()
	warning.show()
	warning.material_override.set_shader_parameter("progress",0.0)

func effect(instance: int) -> void:
	source.instance = instance
	source.can_damage = true
	active = true
	warning.hide()
	_refresh_length()

func _refresh_length() -> void:
	if active: origin = entity.character.casting_position()
	var q := PhysicsRayQueryParameters3D.create(origin,origin+direction*LENGTH,1,[entity.get_rid(),entity.target.get_rid()])
	var wall := get_world_3d().direct_space_state.intersect_ray(q)
	clipped_length = LENGTH if wall.is_empty() else maxf(0.0,origin.distance_to(wall.position)-0.03)
	blocked = not wall.is_empty()
	var midpoint := origin+direction*clipped_length*0.5
	if active:
		# The retrieved lightning is the sole active visual. Its lifetime and
		# clipped endpoints belong to this action, including fully blocked lanes.
		if beam_id <= 0 and clipped_length >= 0.001:
			beam_id = entity.dragon_actions.effects.line(origin,origin+direction*clipped_length,"lightning",0.0)
		elif beam_id > 0:
			entity.dragon_actions.effects.update_line(beam_id,origin,origin+direction*clipped_length)
	warning.global_position = Vector3(midpoint.x,entity.global_position.y+0.04,midpoint.z)
	warning.rotation.y = atan2(direction.x,direction.z)
	warning.scale = Vector3(HALF_WIDTH*2,clipped_length,1)

func sample_contact() -> Dictionary:
	if not active or not source.can_damage: return {}
	_refresh_length()
	var shape := BoxShape3D.new()
	shape.size = Vector3(HALF_WIDTH*2,0.65,maxf(0.01,clipped_length))
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis.looking_at(-direction),origin+direction*clipped_length*0.5)
	q.collision_mask = entity.target.collision_layer
	q.exclude = [entity.get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(q,8):
		if hit.collider != entity.target: continue
		var wallq := PhysicsRayQueryParameters3D.create(origin,entity.target.global_position+Vector3.UP,1,[entity.get_rid(),entity.target.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(wallq).is_empty(): continue
		var result: Dictionary = entity.contact_policy.call(source,entity.target.global_position+Vector3.UP)
		if result.get("accepted",false):
			contacts += 1
			entity.dragon_actions.effects.contact(entity.target.global_position+Vector3.UP,"lightning",str(result.get("outcome","")),float(result.get("hp_loss",0)))
		return result
	return {}

func end() -> void:
	active = false
	if source: source.can_damage = false
	if beam_id > 0 and is_instance_valid(entity):
		entity.dragon_actions.effects.remove(beam_id)
	beam_id = -1
	if warning: warning.hide()
