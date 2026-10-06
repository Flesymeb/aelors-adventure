class_name SnaielHitbox
extends Area3D
## Adapted Snaiel HitboxComponent: one source instance per receiving entity.
## Physics sweep/ray adapters supply real contacts; demo Globals/dizzy removed.
signal damage_source_hit(source: SnaielDamageSource)
signal resolved(result: Dictionary)
var entity: Node3D
var enabled = true
var policy: Callable
var _successful_hits: Dictionary = {}
var last_result: Dictionary = {}

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false

func contact(source: SnaielDamageSource, point: Vector3) -> Dictionary:
	if not enabled or not source.can_damage or source.entity == entity: return {}
	var id = source.get_instance_id()
	if _successful_hits.get(id, {}).get("instance", -1) == source.instance: return {}
	if not policy.is_valid(): return {}
	var result: Dictionary = policy.call(source, point)
	if not result.get("accepted", false): return result
	for key in _successful_hits.keys():
		if _successful_hits[key].ref.get_ref() == null: _successful_hits.erase(key)
	_successful_hits[id] = {"instance": source.instance, "ref": weakref(source)}
	result.merge({"source_id": id, "attack_instance": source.instance, "receiver": str(entity.get_path()), "point": point})
	last_result = result
	damage_source_hit.emit(source)
	resolved.emit(result)
	source.hit_considered()
	return result

func reset_contacts() -> void:
	_successful_hits.clear()
	last_result.clear()

func _mcp_state() -> Dictionary:
	return {"enabled": enabled, "last_contact": last_result, "source_instances": _successful_hits.size()}
