extends Node
## Opt-in native physics diagnostic. Private World3D, no story/save mutation.
const ACTIONS = preload("res://combat/veyne_dragon_actions.gd")
var observations: Dictionary = {}

class Ground extends RefCounted:
	static func support(world: Node3D, xz: Vector2, excludes: Array = []) -> Dictionary:
		var query := PhysicsRayQueryParameters3D.create(Vector3(xz.x,6,xz.y),Vector3(xz.x,-2,xz.y),1)
		var exclusions: Array[RID] = []
		exclusions.assign(excludes)
		query.exclude = exclusions
		var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
		return hit if not hit.is_empty() and hit.collider.has_meta("floor") else {}

class World extends Node3D:
	var ground_policy = Ground
class Settings extends RefCounted:
	var graphics_quality := "normal"
	var reduced_motion := false
class Encounter extends Node:
	var world: Node3D
	var state = Settings.new()
	var allowed := true
	func combat_allowed() -> bool: return allowed
	func play_effect(_cue: String) -> void: pass
class Character extends RefCounted:
	var clip := ""
	func play(value: String, _speed := 1.0, _reset := false) -> void: clip = value
class Effect extends Node3D:
	func tick(_delta: float) -> void: pass
	func clear_transients() -> void: pass
	func snapshot() -> Dictionary: return {}
	func contact(_point, _element, _outcome, _loss) -> void: pass
class Actor extends CharacterBody3D:
	const BODY_RADIUS := 1.0
	var target: CharacterBody3D
	var encounter: Node
	var model := Node3D.new()
	var character := Character.new()
	var ground_query: Callable
	var contact_policy: Callable
	var phase := ""
	var finishes := 0
	func _attack_finished() -> void: finishes += 1

func _ready() -> void:
	observations = await run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture":true,"observations":observations}

static func box(parent: Node3D, size: Vector3, point: Vector3, floor_box := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(shape)
	parent.add_child(body)
	body.position = point
	if floor_box: body.set_meta("floor",true)
	return body

static func run(parent: Node) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(64,64)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	parent.add_child(viewport)
	var world := World.new()
	viewport.add_child(world)
	var floor_body := box(world,Vector3(40,1,40),Vector3(0,-0.5,0),true)
	var actor := Actor.new()
	world.add_child(actor)
	actor.position.y = 0.08
	actor.add_child(actor.model)
	var shape := CollisionShape3D.new()
	shape.name = "Collision"
	shape.shape = CapsuleShape3D.new()
	shape.shape.radius = 1.0
	shape.shape.height = 4.2
	shape.position.y = 2.1
	actor.add_child(shape)
	var target := CharacterBody3D.new()
	target.collision_layer = 2
	world.add_child(target)
	target.position = Vector3(0,0.08,6)
	actor.target = target
	var encounter := Encounter.new()
	encounter.world = world
	world.add_child(encounter)
	actor.encounter = encounter
	actor.ground_query = func(point: Vector3): return Ground.support(world,Vector2(point.x,point.z),[actor.get_rid(),target.get_rid()])
	var settled := {"count":0}
	actor.contact_policy = func(source, _point):
		if not source.can_damage: return {}
		settled.count += 1
		return {"accepted":true,"outcome":"hit","hp_loss":24.0}
	var action = ACTIONS.new()
	actor.add_child(action)
	action.entity = actor
	action.effects = Effect.new()
	action.add_child(action.effects)
	action.source = SnaielDamageSource.new()
	action.source.entity = actor
	action.add_child(action.source)
	action.warning = preload("res://assets/bosses/veyne_effects.tscn").instantiate()
	action.warning.material_override = action.warning.material_override.duplicate()
	action.warning.top_level = true
	action.add_child(action.warning)
	action.breath = MeshInstance3D.new()
	action.breath_core = MeshInstance3D.new()
	action.add_child(action.breath); action.add_child(action.breath_core)
	action.start = actor.position
	action.direction = Vector3.BACK
	await parent.get_tree().physics_frame
	await parent.get_tree().process_frame
	var checks := {}
	var detail := {}
	var open: Dictionary = action.charge_profile(actor.position,9.2)
	checks.open_full_distance = is_equal_approx(open.distance,9.2) and not open.blocked
	action.charge_length = open.distance
	action.charge_endpoint = open.position
	action.update_charge_warning()
	var bounds: AABB = action.warning.mesh.get_aabb()
	checks.warning_complete_lane = absf(bounds.position.z+1.4)<0.01 and absf(bounds.end.z-10.6)<0.01 and absf(bounds.size.x-2.8)<0.01
	action.kind = "charge"; action.stage = "active"; action.source.can_damage = true
	for index in 69:
		await parent.get_tree().physics_frame
		action.tick(1.0/60.0)
	detail.open = {"prediction":open,"actual":actor.position,"stage":action.stage,"time":action.elapsed,"contacts":settled.count,"travelled":action.charge_distance}
	detail.after_open = action.charge_profile(actor.position,0.2)
	checks.open_motion_matches_prediction = actor.position.distance_to(open.position)<0.01 and action.stage == "recovery"
	checks.one_swept_contact = settled.count == 1
	action.tick(1.59)
	checks.recovery_stays_exposed = action.stage == "recovery" and not action.source.can_damage
	action.tick(0.02)
	checks.recovery_finishes_once = actor.finishes == 1 and action.kind == ""
	actor.position = Vector3(0,0.08,0)
	var wall := box(world,Vector3(8,6,0.5),Vector3(0,3,5))
	await parent.get_tree().physics_frame
	await parent.get_tree().process_frame
	var cover: Dictionary = action.charge_profile(actor.position,9.2)
	detail.cover = cover
	checks.cover_truncates_body = cover.blocked and cover.distance > 3.6 and cover.distance < 3.8
	action.charge_length = cover.distance; action.charge_endpoint = cover.position
	action.start = actor.position; action.charge_distance = 0.0; action.charge_contact_settled = false
	action.charge_blocked = cover.blocked; action.elapsed = 0.0
	action.kind = "charge"; action.stage = "active"; action.source.can_damage = true
	for index in 70:
		if action.stage == "active":
			await parent.get_tree().physics_frame
			action.tick(1.0/60.0)
	checks.cover_actual_matches_prediction = actor.position.distance_to(cover.position)<0.015 and action.stage == "recovery"
	checks.cover_no_false_contact = settled.count == 1
	actor.position = Vector3(0,0.08,5)
	await parent.get_tree().physics_frame
	checks.initial_overlap_stops = action.charge_profile(actor.position,9.2).distance == 0.0
	wall.free()
	floor_body.free()
	# Two authored-floor analogues with a 1 cm triangle seam. A wide capsule
	# remains supported; this must not be confused with the real edge below.
	box(world,Vector3(40,1,23),Vector3(0,-0.5,-8.505),true)
	box(world,Vector3(40,1,17),Vector3(0,-0.5,11.505),true)
	actor.position = Vector3(0,0.08,0)
	await parent.get_tree().physics_frame
	await parent.get_tree().process_frame
	var seam: Dictionary = action.charge_profile(actor.position,9.2)
	checks.narrow_floor_seam_is_supported = not seam.blocked and is_equal_approx(seam.distance,9.2)
	actor.position = Vector3(0,0.08,18)
	await parent.get_tree().physics_frame
	var edge: Dictionary = action.charge_profile(actor.position,9.2)
	checks.unsupported_floor_stops_body = edge.blocked and edge.position.z <= 19.001
	action.kind = "charge"; action.stage = "active"; action.elapsed = 0.4
	encounter.allowed = false
	var before := actor.position
	action.tick(0.5)
	checks.pause_freezes_sequence = action.elapsed == 0.4 and actor.position == before
	action.interrupt()
	checks.interrupt_clears = action.kind == "" and action.stage == "idle" and not action.source.can_damage and not action.warning.visible
	viewport.free()
	return {"checks":checks,"detail":detail,"scope":"isolated native supported sweep/contact diagnostic; ordinary Boss entry, shipped cameras and earned counterplay remain independent"}
