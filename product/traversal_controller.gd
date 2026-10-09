extends Node

const MOTION_ASSET := "res://Characters/KayKitAnimations/Rig_Medium_MovementAdvanced.glb"
const MOTION_POSE := preload("res://movement_pose_modifier.gd")
const STEP_HEIGHT := 0.32
const SPEEDS := {"standing": 5.0, "crouch": 2.2, "prone": 1.15}

var player: CharacterBody3D
var posture := "standing"
var action := ""
var action_time := 0.0
var action_duration := 0.0
var cooldown := 0.0
var action_direction := Vector3.ZERO
var moving_direction := Vector3.ZERO
var sprinting := false
var clock := 0.0
var takeoff_timer := 0.0
var landing_timer := 0.0
var air_time := 0.0
var camera_step_offset := 0.0
var motion_pose: SkeletonModifier3D
var collision: CollisionShape3D
var step_count := 0
var floor_recovery_count := 0
var step_grace := 0.0
var last_step: Dictionary = {}
var feedback := ""
var feedback_time := 0.0
var standing_shape: CapsuleShape3D
var crouch_shape: CapsuleShape3D
var prone_shape: CapsuleShape3D

func _ready() -> void:
	collision = player.get_node("Collision")
	standing_shape = collision.shape.duplicate()
	crouch_shape = CapsuleShape3D.new()
	crouch_shape.radius = 0.32
	crouch_shape.height = 1.15
	prone_shape = CapsuleShape3D.new()
	prone_shape.radius = 0.36
	prone_shape.height = 1.75
	collision.shape = standing_shape
	player.floor_max_angle = deg_to_rad(46.0)
	player.floor_snap_length = 0.35
	player.floor_constant_speed = true
	player.safe_margin = 0.002
	if player.skeleton and ResourceLoader.exists(MOTION_ASSET):
		var source := (load(MOTION_ASSET) as PackedScene).instantiate() as Node3D
		source.visible = false
		player.add_child(source)
		motion_pose = SkeletonModifier3D.new()
		motion_pose.set_script(MOTION_POSE)
		player.skeleton.add_child(motion_pose)
		motion_pose.configure(source.find_child("Skeleton3D", true, false), source.get_node("AnimationPlayer"))
	_strip_roll_translation()
	_loop_locomotion()

func _strip_roll_translation() -> void:
	if not player.animation_player or not player.animation_player.has_animation("Roll"):
		return
	# Duplicate just this animation: preserve authored vertical motion and lock
	# lateral/forward root motion so the animated body follows its collision.
	var library: AnimationLibrary = player.animation_player.get_animation_library("")
	var roll: Animation = player.animation_player.get_animation("Roll").duplicate(true)
	var index: int = player.skeleton.find_bone("pelvis")
	var parent: int = player.skeleton.get_bone_parent(index)
	var basis: Basis = player.skeleton.get_bone_global_rest(parent).basis
	for track in range(roll.get_track_count()):
		if roll.track_get_type(track) != Animation.TYPE_POSITION_3D or not str(roll.track_get_path(track)).ends_with(":pelvis"):
			continue
		var anchor: Vector3 = basis * roll.track_get_key_value(track, 0)
		for key_index in range(roll.track_get_key_count(track)):
			var value: Vector3 = basis * roll.track_get_key_value(track, key_index)
			roll.track_set_key_value(track, key_index, basis.inverse() * Vector3(anchor.x, value.y, anchor.z))
	library = library.duplicate()
	library.remove_animation("Roll")
	library.add_animation("Roll", roll)
	player.animation_player.remove_animation_library("")
	player.animation_player.add_animation_library("", library)

func _loop_locomotion() -> void:
	if not player.animation_player:
		return
	var library: AnimationLibrary = player.animation_player.get_animation_library("")
	for clip in ["Idle", "Sword_Idle", "Walk", "Jog_Fwd", "Sprint", "Crouch_Fwd", "Crouch_Idle", "Jump"]:
		if not library.has_animation(clip):
			continue
		var animation := library.get_animation(clip).duplicate() as Animation
		animation.loop_mode = Animation.LOOP_LINEAR
		library.remove_animation(clip)
		library.add_animation(clip, animation)

func request_posture(next: String) -> bool:
	if player.combat and player.combat.player_locked(): return false
	if action != "" or not player.is_on_floor() or player.switch_timer > 0.0 or player.attack_timer > 0.0:
		return false
	var desired := "standing" if posture == next else next
	if desired not in SPEEDS:
		return false
	if (desired == "prone" and motion_pose == null) or (desired == "crouch" and player.animation_player == null):
		return false
	var shape := standing_shape if desired == "standing" else (crouch_shape if desired == "crouch" else prone_shape)
	var transform := _shape_transform(desired)
	if not _shape_clear(shape, transform):
		feedback = "Not enough room"
		feedback_time = 1.5
		return false
	player.cancel_aim()
	posture = desired
	collision.shape = shape
	collision.transform = transform
	player._set_weapon_visibility()
	player.current_animation = ""
	return true

func _shape_transform(value: String) -> Transform3D:
	if value == "prone":
		return Transform3D(Basis(Vector3.UP, player.visual.rotation.y) * Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.36, 0))
	return Transform3D(Basis.IDENTITY, Vector3(0, 0.9 if value == "standing" else 0.575, 0))

func _shape_clear(shape: Shape3D, local: Transform3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = player.global_transform * local
	query.transform.origin.y += 0.008  # Ignore contact with the supporting floor.
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	query.margin = 0.002
	return player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func evade(kind: String) -> bool:
	if kind not in ["roll", "dodge"] or posture != "standing" or action != "" or cooldown > 0.0 or not player.is_on_floor() or player.switch_timer > 0.0 :
		return false
	if kind == "dodge" and motion_pose == null:
		return false
	if kind == "roll" and (player.animation_player == null or not player.animation_player.has_animation("Roll")):
		return false
	if player.combat:
		if player.combat.player_locked(): return false
		player.combat.interrupt("dodge")
	player.cancel_aim()
	action = kind
	action_duration = 0.72 if kind == "roll" else 0.4
	action_time = 0.0
	action_direction = moving_direction if moving_direction.length_squared() > 0.01 else (-player.visual.global_basis.z if kind == "dodge" else player.visual.global_basis.z)
	action_direction.y = 0
	action_direction = action_direction.normalized()
	if kind == "roll":
		collision.shape = crouch_shape
		collision.transform = _shape_transform("crouch")
		player.visual.rotation.y = atan2(action_direction.x, action_direction.z)
		player.current_animation = ""
		player._play_animation("Roll", player.animation_player.get_animation("Roll").length / action_duration)
	return true

func advance(delta: float, direction: Vector3) -> float:
	clock += delta
	takeoff_timer = maxf(0, takeoff_timer - delta)
	landing_timer = maxf(0, landing_timer - delta)
	step_grace = maxf(0.0, step_grace - delta)
	player.floor_snap_length = 0.0 if step_grace > 0.0 else 0.35
	camera_step_offset = lerpf(camera_step_offset, 0.0, 1.0 - exp(-12.0 * delta))
	feedback_time = maxf(0, feedback_time - delta)
	cooldown = maxf(0, cooldown - delta)
	moving_direction = direction
	sprinting = action == "" and posture == "standing" and not player.aim_requested and direction.length_squared() > 0.01 and player.control_held("sprint")
	if action != "":
		action_time += delta
		if action_time >= action_duration or not player.is_on_floor():
			action = ""
			# Both evade types share a one-second start-to-start interval.
			# Preserve the remaining interval after normal motion or an early
			# airborne cancellation rather than allowing alternating spam.
			cooldown = maxf(0.0, 1.0 - action_time)
			if collision.shape == crouch_shape:
				posture = "standing" if _shape_clear(standing_shape, _shape_transform("standing")) else "crouch"
				collision.shape = standing_shape if posture == "standing" else crouch_shape
				collision.transform = _shape_transform(posture)
			player.current_animation = ""
	_update_pose(direction.length_squared() > 0.01)
	if player.aim_requested:
		return 2.2
	return 9.5 if sprinting else SPEEDS[posture]

func sync_prone_facing() -> void:
	if posture != "prone":
		return
	# Test the rendered heading before rotating a long collision into a wall.
	var desired := _shape_transform("prone")
	if _shape_clear(prone_shape, desired):
		collision.transform = desired
	else:
		var old_forward := collision.basis.y.normalized()
		player.visual.rotation.y = atan2(old_forward.x, old_forward.z)

func _update_pose(moving: bool) -> void:
	if not motion_pose:
		return
	motion_pose.breathing_weight = 1.0 if not moving and posture != "prone" and action == "" and not player.aim_requested and player.attack_timer <= 0.0 and player.switch_timer <= 0.0 else 0.0
	motion_pose.pose_weight = 1.0 if posture == "prone" or action == "dodge" else 0.0
	motion_pose.lower_body_weight = motion_pose.pose_weight
	motion_pose.pitch = 0.0
	if action == "dodge":
		var forward: Vector3 = player.visual.global_basis.z
		var right: Vector3 = -player.visual.global_basis.x  # +Z actor: its right is -X.
		var front := action_direction.dot(forward)
		var side := action_direction.dot(right)
		motion_pose.clip = ("Dodge_Forward" if front >= 0 else "Dodge_Backward") if absf(front) >= absf(side) else ("Dodge_Right" if side >= 0 else "Dodge_Left")
		motion_pose.clip_time = minf(0.399, action_time)
	else:
		motion_pose.clip = "Crawling"
		motion_pose.clip_time = fmod(clock * 1.15, 1.0666) if moving else 0.5

func action_velocity() -> Vector3:
	var progress := clampf(action_time / action_duration, 0, 1)
	var speed := (7.5 if action == "roll" else 6.5) * (0.35 + 0.65 * sin(PI * progress))
	return action_direction * speed

func move_with_steps(delta: float) -> void:
	var horizontal := Vector3(player.velocity.x, 0, player.velocity.z) * delta
	if (player.is_on_floor() or step_grace > 0.0) and player.velocity.y <= 0 and horizontal.length_squared() > 0.000001 and action == "" and posture != "prone":
		_try_step(horizontal)
	var before := player.global_position
	player.move_and_slide()
	# Terrain seams can report a walkable floor repeatedly at zero travel even
	# when the requested horizontal capsule sweep is clear. Retry that same
	# motion only; walls, penetration and unsupported destinations cannot qualify.
	if horizontal.length_squared() < 0.000001 or player.global_position.distance_squared_to(before) > 0.00000001 or not player.is_on_floor() or player.velocity.y > 0:
		return
	if player.get_slide_collision_count() == 0: return
	for i in player.get_slide_collision_count():
		var contact := player.get_slide_collision(i)
		if contact.get_normal().dot(Vector3.UP) < cos(player.floor_max_angle): return
	var volume := PhysicsShapeQueryParameters3D.new()
	volume.shape = collision.shape
	volume.transform = collision.global_transform
	volume.collision_mask = player.collision_mask
	volume.exclude = [player.get_rid()]
	if not player.get_world_3d().direct_space_state.intersect_shape(volume, 1).is_empty(): return
	var support := _support_observation(before + horizontal)
	if support.is_empty() or support.normal.dot(Vector3.UP) < cos(player.floor_max_angle) or absf(support.position.y - before.y) > STEP_HEIGHT: return
	if player.test_move(player.global_transform, horizontal): return
	player.move_and_collide(horizontal)
	if player.global_position.distance_squared_to(before) > 0.00000001: floor_recovery_count += 1

func _try_step(horizontal: Vector3) -> bool:
	var obstruction := KinematicCollision3D.new()
	if not player.test_move(player.global_transform, horizontal, obstruction):
		return false
	# Capsule contacts at a ledge corner have a diagonal normal. Determine the
	# actual tread normal from a short ray instead of treating it as a slope.
	# A wall contact removes horizontal velocity each frame. At that small
	# acceleration distance the ray can hit the sloped riser before its tread.
	# Keep a short minimum lookahead; the same distance is swept for clearance.
	var probe_distance := standing_shape.radius + maxf(horizontal.length(), 0.05) + 0.04
	var probe: Vector3 = player.global_position + horizontal.normalized() * probe_distance
	var query := PhysicsRayQueryParameters3D.create(probe + Vector3.UP * (STEP_HEIGHT + 0.04), probe + Vector3.DOWN * 0.04)
	query.exclude = [player.get_rid()]
	query.collision_mask = player.collision_mask
	var landing: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if landing.is_empty() or landing.normal.dot(Vector3.UP) < cos(player.floor_max_angle):
		return false
	var height: float = landing.position.y - player.global_position.y
	if height <= 0.01 or height > STEP_HEIGHT:
		return false
	var rise := Vector3.UP * (height + 0.003)
	var raised: Transform3D = player.global_transform
	if player.test_move(raised, rise):
		return false
	raised.origin += rise
	if player.test_move(raised, horizontal.normalized() * probe_distance):
		return false
	# Only lift vertically; horizontal movement is still swept by move_and_slide.
	# Brief support grace prevents floor-snap pulling the capsule off the corner
	# before its centre reaches the tread. It is never granted at a drop-off.
	last_step = {"from":player.global_position,"tread":landing.position,"normal":landing.normal,"height":height,"collider":str(landing.collider.get_path()) if landing.collider is Node else ""}
	player.global_position += rise
	last_step["raised_position"] = player.global_position
	player.velocity.y = 0.0
	step_grace = 0.14
	player.floor_snap_length = 0.0
	camera_step_offset -= height
	step_count += 1
	return true

func _support_observation(point: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0, point + Vector3.DOWN * 2.0)
	query.exclude = [player.get_rid()]
	query.collision_mask = player.collision_mask
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return {}
	return {"position":hit.position,"normal":hit.normal,"collider":str(hit.collider.get_path()) if hit.collider is Node else ""}

func observation() -> Dictionary:
	# Called only by read-only runtime inspection; never drives the player or UI.
	var heading: Vector3 = moving_direction if moving_direction.length_squared() > 0.01 else player.visual.global_basis.z
	heading.y = 0.0
	return {"grounded":player.is_on_floor(),"floor_normal":player.get_floor_normal() if player.is_on_floor() else Vector3.ZERO,"posture":posture,"action":action,"step_count":step_count,"floor_recovery_count":floor_recovery_count,"step_height_limit":STEP_HEIGHT,"step_grace":step_grace,"support":_support_observation(player.global_position),"ahead_support":_support_observation(player.global_position + heading.normalized() * 0.5),"last_step":last_step}

func eye_height() -> float:
	return 1.65 if posture == "standing" else (1.0 if posture == "crouch" else 0.62)

func reset() -> void:
	last_step.clear()
	action = ""
	cooldown = 0.0
	takeoff_timer = 0.0
	landing_timer = 0.0
	air_time = 0.0
	camera_step_offset = 0.0
	step_grace = 0.0
	player.floor_snap_length = 0.35
	posture = "standing"
	collision.shape = standing_shape
	collision.transform = _shape_transform("standing")
	if motion_pose:
		motion_pose.pose_weight = 0.0
		motion_pose.lower_body_weight = 0.0
