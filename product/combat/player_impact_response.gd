extends RefCounted
## Product adapter over retained Snaiel secondary movement. This object never
## moves a body; player_controller feeds its velocity to the traversal owner.
const SECONDARY := preload("res://combat/snaiel/secondary_movement.gd")
const MAX_DISTANCE := 0.8
const MOVE_SECONDS := 0.24
const RESTRICTION_SECONDS := 0.56
const RETRIGGER_SECONDS := 0.5
var remaining := 0.0
var guard_remaining := 0.0
var travel_remaining := 0.0
var traveled := 0.0
var secondary: SnaielSecondaryMovement
var contact: Dictionary = {}

func active() -> bool:
	return remaining > 0.0

func begin(resolved: Dictionary, origin: Vector3, player_position: Vector3) -> bool:
	if active() or guard_remaining > 0.0: return false
	if not resolved.get("heavy_impact_requested", false) or not resolved.get("accepted", false): return false
	if resolved.get("outcome", "") != "hurt" or resolved.get("hp_loss", 0.0) <= 0.0 or resolved.get("hp_after", 0.0) <= 0.0: return false
	if resolved.get("simulated", false) or resolved.get("source_id", 0) == 0 or not resolved.has("attack_instance"): return false
	var away := player_position - origin
	away.y = 0.0
	if away.is_zero_approx():
		away = resolved.get("attack_direction", Vector3.ZERO)
		away.y = 0.0
	if away.is_zero_approx(): return false
	contact = resolved.duplicate(true)
	remaining = RESTRICTION_SECONDS
	travel_remaining = MAX_DISTANCE
	traveled = 0.0
	secondary = SECONDARY.create(MAX_DISTANCE / MOVE_SECONDS, MOVE_SECONDS, 0.0, away.normalized())
	return true

func advance(delta: float) -> bool:
	if not active():
		guard_remaining = maxf(0.0, guard_remaining - delta)
		return false
	remaining = maxf(0.0, remaining - delta)
	if active(): return false
	secondary = null
	travel_remaining = 0.0
	guard_remaining = RETRIGGER_SECONDS
	return true

func requested_velocity(player: CharacterBody3D, delta: float) -> Vector3:
	if not active() or secondary == null or secondary.time <= 0.0 or delta <= 0.0: return Vector3.ZERO
	var seconds := minf(delta, secondary.time)
	secondary.time = maxf(0.0, secondary.time - delta)
	var motion := secondary.direction * minf(travel_remaining, secondary.speed * seconds)
	if motion.is_zero_approx(): return Vector3.ZERO
	# A capsule must retain supported ground ahead, rather than merely having
	# its centre stop at the last ray-hit point of a cliff edge.
	var ahead := player.global_position + motion + secondary.direction * 0.32
	var support := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.35, ahead + Vector3.DOWN * 0.3, player.collision_mask, [player.get_rid()])
	var floor_hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(support)
	if floor_hit.is_empty() or floor_hit.normal.dot(Vector3.UP) < cos(player.floor_max_angle):
		secondary.time = 0.0
		return Vector3.ZERO
	var collision := KinematicCollision3D.new()
	if player.test_move(player.global_transform, motion, collision):
		motion = secondary.direction * maxf(0.0, collision.get_travel().dot(secondary.direction) - 0.01)
		secondary.time = 0.0
	return motion / delta

func record_motion(before: Vector3, after: Vector3) -> void:
	var distance := Vector2(after.x - before.x, after.z - before.z).length()
	traveled += distance
	travel_remaining = maxf(0.0, travel_remaining - distance)

func cancel() -> void:
	remaining = 0.0
	guard_remaining = 0.0
	travel_remaining = 0.0
	secondary = null
	contact.clear()

func observation() -> Dictionary:
	return {"active": active(), "restriction_left": remaining, "guard_left": guard_remaining, "traveled": traveled, "distance_left": travel_remaining, "contact": contact.duplicate(true)}
