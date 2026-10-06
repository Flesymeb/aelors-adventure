extends Node3D

signal first_contact(hit: Dictionary)
signal missed
var settled := false

const ARROW_MESH := preload("res://Weapons/Arrow.obj")
const SPEED := 22.0
const GRAVITY := 3.0
const ARROW_LENGTH := 0.646
const MAX_AGE := 3.0

var velocity := Vector3.ZERO
var shooter_rid: RID
var age := 0.0
var stuck := false


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = ARROW_MESH
	mesh.scale = Vector3.ONE * 0.24
	add_child(mesh)


func launch(origin: Vector3, direction: Vector3, shooter: RID, launch_speed: float = SPEED, safety_origin := Vector3.INF) -> void:
	global_position = origin
	velocity = direction * launch_speed
	shooter_rid = shooter
	_face_velocity()
	# An arrow can already overlap a nearby wall before its tail starts moving.
	var hit := _trace(safety_origin if safety_origin.is_finite() else origin, origin + direction * ARROW_LENGTH)
	if hit:
		_settle(hit, direction)


func _physics_process(delta: float) -> void:
	age += delta
	if age >= MAX_AGE:
		if not settled:
			settled = true
			missed.emit()
		queue_free()
		return
	if stuck:
		return
	var next := global_position + velocity * delta
	var direction := velocity.normalized()
	var hit := _trace(global_position + direction * ARROW_LENGTH, next + direction * ARROW_LENGTH)
	if hit:
		_settle(hit, direction)
	else:
		global_position = next
		velocity += Vector3.DOWN * GRAVITY * delta
		_face_velocity()


func _trace(start: Vector3, end: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [shooter_rid]
	query.collision_mask = 3
	query.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(query)


func _settle(hit: Dictionary, direction: Vector3) -> void:
	if settled: return
	settled = true
	_stick(hit.position, direction)
	first_contact.emit(hit)

func _stick(point: Vector3, direction: Vector3) -> void:
	global_position = point - direction * ARROW_LENGTH
	stuck = true
	age = MAX_AGE - 1.1


func _face_velocity() -> void:
	if velocity.length_squared() > 0.0001:
		global_basis = Basis.looking_at(-velocity.normalized(), Vector3.UP)
