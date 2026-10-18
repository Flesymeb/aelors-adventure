extends RefCounted

class RevealRouter extends Node:
	var held := false
	var audio: Node
	func _confirmation_held() -> bool: return held

class RevealPauseMenu extends Control:
	var sub_menu: Control
	var confirmation: Control

static func ready_world_reveal_checks(holder: Node) -> Dictionary:
	# Isolated native canvas clock; never constructs a world or writes a save.
	# Router readiness/commit ordering is also exercised by ordinary entry smoke.
	var owner := RevealRouter.new()
	holder.add_child(owner)
	var opening := preload("res://tests/opening_motion_test.gd").QuietOpening.new()
	opening.router = owner
	var preferences := preload("res://tests/opening_motion_test.gd").Preferences.new()
	opening.state = preferences
	opening.add_child(preferences)
	holder.add_child(opening)
	var emissions := [0]
	opening.world_revealed.connect(func(): emissions[0] += 1)
	var checks := {}
	checks.merge(reveal_read_checks(opening, emissions, "before"))
	owner.held = true
	opening.begin_world_reveal()
	opening._process_world_reveal(1.0)
	checks.held_skip_cannot_start_reveal = opening.revealing and opening.reveal_elapsed == 0 and emissions[0] == 0
	checks.merge(reveal_read_checks(opening, emissions, "held"))
	owner.held = false
	opening._process_world_reveal(0.12)
	checks.actual_canvas_fades = opening.reveal_veil.color.a > 0 and opening.reveal_veil.color.a < 1 and emissions[0] == 0
	checks.merge(reveal_read_checks(opening, emissions, "during"))
	var before: float = opening.reveal_elapsed
	opening.pause_menu = RevealPauseMenu.new()
	opening.add_child(opening.pause_menu)
	opening._process_world_reveal(2.0)
	checks.pause_suspends_reveal = opening.reveal_elapsed == before and emissions[0] == 0
	checks.merge(reveal_read_checks(opening, emissions, "paused"))
	opening.pause_menu.free()
	opening.pause_menu = null
	owner.held = true
	opening._process_world_reveal(1.0)
	checks.held_attack_cannot_release_controls = opening.revealing and emissions[0] == 0
	owner.held = false
	opening._process_world_reveal(0.0)
	opening._process_world_reveal(1.0)
	checks.once_only_release = not opening.revealing and not opening.visible and emissions[0] == 1
	checks.merge(reveal_read_checks(opening, emissions, "after"))
	preferences.reduced_motion = true
	opening.pause_menu = RevealPauseMenu.new()
	opening.add_child(opening.pause_menu)
	opening.begin_world_reveal()
	checks.skip_from_pause_releases_old_menu = opening.pause_menu == null
	checks.reduced_motion_immediate = emissions[0] == 2 and not opening.revealing and not opening.visible
	checks.merge(reveal_read_checks(opening, emissions, "reduced_motion"))
	opening.shutdown()
	checks.shutdown_idempotent = not opening.revealing and opening.finished and emissions[0] == 2
	checks.merge(reveal_read_checks(opening, emissions, "shutdown"))
	opening.queue_free()
	checks.merge(reveal_read_checks(opening, emissions, "queued"))
	opening.free()
	owner.free()
	return {"checks": checks, "scope": "isolated actual canvas/pause/fresh-input clock; no earned history or ordinary entry acceptance"}

static func reveal_read_checks(opening: Node, emissions: Array, boundary: String) -> Dictionary:
	var snapshot := [opening.revealing, opening.reveal_elapsed, opening.inputs_armed,
		opening.finished, opening.visible, opening.state.reduced_motion,
		opening.get_tree().paused, emissions[0], opening.video_active]
	var opacity: Variant = opening.reveal_veil.color.a if is_instance_valid(opening.reveal_veil) else null
	var first: Dictionary = opening._mcp_state()
	for repeat in 4:
		if opening._mcp_state() != first: return {boundary + "_read_only": false}
	var available: bool = not opening.is_queued_for_deletion() and (not opening.finished or opening.revealing)
	return {boundary + "_read_only": snapshot == [opening.revealing, opening.reveal_elapsed,
		opening.inputs_armed, opening.finished, opening.visible, opening.state.reduced_motion,
		opening.get_tree().paused, emissions[0], opening.video_active],
		boundary + "_actual_scalars": first.revealing == (opening.revealing if available else null)
			and first.reveal_elapsed == (opening.reveal_elapsed if available else null)
			and first.veil_opacity == (opacity if available else null)}
## Explicit diagnostic only; never attached to the normal entry path.
class CameraReadinessPlayer extends "res://player_controller.gd":
	# Exercise the real restore helper without actor loading, controls files,
	# animation, traversal, combat, or any normal-startup callbacks.
	func _ready() -> void:
		arm.add_excluded_object(get_rid())
	var dialogue_preparations := 0
	var preparation_pause_states: Array[bool] = []
	func prepare_dialogue_camera(subject: CollisionObject3D = null) -> void:
		dialogue_preparations += 1
		preparation_pause_states.append(get_tree().paused)
		super.prepare_dialogue_camera(subject)

class CameraReadinessWorld extends "res://preview_controller.gd":
	# Retain the real pause owner without constructing a second product world.
	var camera_subject: CollisionObject3D
	func _ready() -> void:
		pass
	func _dialogue_camera_subject() -> CollisionObject3D:
		return camera_subject

static func paused_actor_pose_checks(parent: Node) -> Dictionary:
	# Actual retained rigs, synchronously initialized in a disposable world.
	# No gameplay frame, save/history setup, input dispatch or reward owner runs.
	var viewport := SubViewport.new()
	viewport.name = "PausedActorPoseReadiness"
	viewport.own_world_3d = true
	viewport.process_mode = Node.PROCESS_MODE_DISABLED
	var world := CameraReadinessWorld.new()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	viewport.add_child(world)
	parent.add_child(viewport)
	var player := preload("res://Player.tscn").instantiate()
	player.configure_equipment(false, false, "unarmed")
	world.player = player
	world.add_child(player)
	var coach := preload("res://Hers.tscn").instantiate()
	world.add_child(coach)
	world.camera_subject = coach
	var paused := parent.get_tree().paused
	var mouse_mode := Input.mouse_mode
	var physics_frame := Engine.get_physics_frames()
	var idle_frame := Engine.get_process_frames()
	var checks := {}
	var observations := {}
	checks.coach_initial_pose_evaluated = _pose_matches_clip(coach.actor)
	for mode in ["unarmed", "sword"]:
		player.velocity = Vector3.ZERO
		player.configure_equipment(mode == "sword", false, mode)
		var position: Vector3 = player.global_position
		player.velocity = Vector3(1, 2, 3)
		var before := _actor_pose_observation(player)
		world._prepare_restored_actor_pose()
		var assigned: String = player.animation_player.current_animation
		var animation_time: float = player.animation_player.current_animation_position
		world._set_pause_owner("dialogue", true)
		var after := _actor_pose_observation(player)
		observations[mode] = {"before": before, "after": after}
		checks[mode + "_pose_evaluated"] = _pose_matches_clip(player)
		checks[mode + "_restored_idle_selected"] = assigned == ("Sword_Idle" if mode == "sword" else "Idle")
		checks[mode + "_clip_and_time_retained"] = player.animation_player.current_animation == assigned and is_equal_approx(player.animation_player.current_animation_position, animation_time)
		checks[mode + "_possession_and_mounts"] = player.owns_sword == (mode == "sword") and player.sword_holder.visible == (mode == "sword") and not player.sword_back_holder.visible and not player.owns_bow and not player.bow_holder.visible and not player.bow_back_holder.visible
		checks[mode + "_paused_without_movement"] = parent.get_tree().paused and player.controls_open and player.global_position == position and player.velocity == Vector3(1, 2, 3)
		world._set_pause_owner("controls", true)
		world._set_pause_owner("controls", false)
		checks[mode + "_nested_pose_preserved"] = after == _actor_pose_observation(player) and parent.get_tree().paused
		# Entry promotion restores equipment a second time while the dialogue
		# still owns pause. Its floor cache must not leave a queued Jump blend.
		player.velocity = Vector3.ZERO
		player.configure_equipment(mode == "sword", false, mode)
		world._prepare_restored_actor_pose()
		checks[mode + "_entry_promotion_pose"] = _pose_matches_clip(player) and player.animation_player.current_animation == assigned and parent.get_tree().paused
		world._set_pause_owner("dialogue", false)
		checks[mode + "_controls_return"] = not parent.get_tree().paused and not player.controls_open
	checks.no_world_frame = Engine.get_physics_frames() == physics_frame and Engine.get_process_frames() == idle_frame
	parent.get_tree().paused = paused
	Input.mouse_mode = mouse_mode
	viewport.free()
	return {"scope": "isolated retained-rig zero-time pose initialization; no ordinary Continue, earned coaching or exported combat acceptance", "checks": checks, "observations": observations}

static func _pose_matches_clip(actor: Node3D) -> bool:
	var clip: Animation = actor.animation_player.get_animation(actor.animation_player.current_animation)
	var matched := 0
	for index in clip.get_track_count():
		if clip.track_get_type(index) != Animation.TYPE_ROTATION_3D: continue
		var path: NodePath = clip.track_get_path(index)
		var bone_name: String = path.get_subname(0) if path.get_subname_count() > 0 else ""
		if bone_name not in ["upperarm_l", "lowerarm_l", "upperarm_r", "lowerarm_r"]: continue
		var bone: int = actor.skeleton.find_bone(bone_name)
		if bone < 0 or not actor.skeleton.get_bone_pose_rotation(bone).is_equal_approx(clip.rotation_track_interpolate(index, actor.animation_player.current_animation_position)):
			return false
		matched += 1
	return matched == 4

static func _actor_pose_observation(actor: Node3D) -> Dictionary:
	var bones := {}
	for bone_name in ["upperarm_l", "lowerarm_l", "upperarm_r", "lowerarm_r"]:
		var rotation: Quaternion = actor.skeleton.get_bone_pose_rotation(actor.skeleton.find_bone(bone_name))
		bones[bone_name] = [rotation.x, rotation.y, rotation.z, rotation.w]
	return {"clip": actor.animation_player.current_animation, "time": actor.animation_player.current_animation_position, "bones": bones}

static func restored_camera_readiness_checks(parent: Node) -> Dictionary:
	# Synchronous, disposable native fixture. In particular, do not await/thaw a
	# frame to obtain a better pose: that would hide the ordering under test.
	var viewport := SubViewport.new()
	viewport.name = "RestoredCameraReadiness"
	viewport.own_world_3d = true
	viewport.process_mode = Node.PROCESS_MODE_DISABLED
	var player := CameraReadinessPlayer.new()
	player.name = "CameraReadinessPlayer"
	var visual := Node3D.new()
	visual.name = "Visual"
	player.add_child(visual)
	var arm := SpringArm3D.new()
	arm.name = "CameraArm"
	arm.collision_mask = 1
	player.add_child(arm)
	var camera := Camera3D.new()
	camera.name = "Camera"
	arm.add_child(camera)
	viewport.add_child(player)
	parent.add_child(viewport)
	var observations := {}
	var checks := {}
	var physics_frame := Engine.get_physics_frames()
	var idle_frame := Engine.get_process_frames()
	var paused := parent.get_tree().paused
	# Initial placement and an already-ready actor's same-map teleport have
	# distinct transform histories. Neither may depend on a gameplay tick.
	for boundary in ["initial_placement", "same_map_teleport"]:
		player.global_position = Vector3(4, 2, -8) if boundary == "initial_placement" else Vector3(-7, 5, 11)
		player.velocity = Vector3(1, 2, 3)
		player.attack_timer = 0.37
		player.switch_timer = 0.21
		var position := player.global_position
		var velocity := player.velocity
		player.prepare_restored_camera(0.7)
		var direct := restored_camera_observation(player)
		# If this differs from direct, a repeated native sweep can expose native
		# initialization readiness rather than a wrapper or dialogue transform.
		arm.notification(Node.NOTIFICATION_INTERNAL_PHYSICS_PROCESS)
		var repeated := restored_camera_observation(player)
		player.force_update_transform()
		arm.force_update_transform()
		arm.notification(Node.NOTIFICATION_INTERNAL_PHYSICS_PROCESS)
		var forced := restored_camera_observation(player)
		observations[boundary] = {"direct": direct, "repeated_native": repeated, "forced_transform": forced}
		checks[boundary + "_external_immediately"] = direct.camera_arm_distance > player.free_camera_distance - 0.02
		checks[boundary + "_native_length"] = is_equal_approx(direct.hit_length, player.free_camera_distance)
		checks[boundary + "_repeat_stable"] = direct == repeated
		checks[boundary + "_transform_stable"] = direct == forced
		checks[boundary + "_gameplay_unchanged"] = player.global_position == position and player.velocity == velocity and player.attack_timer == 0.37 and player.switch_timer == 0.21
	checks.no_gameplay_frame = Engine.get_physics_frames() == physics_frame and Engine.get_process_frames() == idle_frame
	checks.pause_preserved = parent.get_tree().paused == paused
	viewport.free()
	var dialogue: Dictionary = dialogue_camera_readiness_checks(parent)
	checks.merge(dialogue.checks)
	return {"scope": "isolated native camera readiness; no ordinary history or collision-scene acceptance", "checks": checks, "observations": observations, "dialogue": dialogue.observations}

static func dialogue_camera_readiness_checks(parent: Node) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.name = "DialogueCameraReadiness"
	viewport.own_world_3d = true
	viewport.process_mode = Node.PROCESS_MODE_DISABLED
	var world := CameraReadinessWorld.new()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	var player := CameraReadinessPlayer.new()
	player.name = "CameraReadinessPlayer"
	var visual := Node3D.new()
	visual.name = "Visual"
	player.add_child(visual)
	var arm := SpringArm3D.new()
	arm.name = "CameraArm"
	arm.collision_mask = 1
	arm.margin = 0.12
	player.add_child(arm)
	var camera := Camera3D.new()
	camera.name = "Camera"
	arm.add_child(camera)
	world.player = player
	world.add_child(player)
	var subject := StaticBody3D.new()
	subject.name = "DialogueSubject"
	world.camera_subject = subject
	world.add_child(subject)
	viewport.add_child(world)
	parent.add_child(viewport)
	var paused := parent.get_tree().paused
	var mouse_mode := Input.mouse_mode
	var physics_frame := Engine.get_physics_frames()
	var idle_frame := Engine.get_process_frames()
	var checks := {}
	var observations := {}
	# Both a settled first-person view and the ordinary V return's unfinished
	# perspective blend must leave the close camera before acquiring pause.
	for side in [-1.0, 1.0]:
		for boundary in ["first_person", "perspective_return"]:
			parent.get_tree().paused = false
			player.first_person = boundary == "first_person"
			player.perspective_blend = 1.0 if player.first_person else 0.6065
			player.aim_requested = true
			player.aim_blend = 0.8
			player.shoulder_side = side
			player.shoulder_blend = -side
			player.free_camera_distance = 5.15
			player.smooth_camera_distance = 2.4
			player.arm.rotation = Vector3(0.21, 0.7, 0)
			player.arm.spring_length = 0.0
			player.camera.position = Vector3.ZERO
			player.global_position = Vector3(4, 2, -8)
			player.velocity = Vector3(1, 2, 3)
			player.attack_timer = 0.37
			player.switch_timer = 0.21
			var preparations := player.dialogue_preparations
			world._set_pause_owner("dialogue", true)
			var direct := restored_camera_observation(player)
			var key := "%s_%s" % [str(side), boundary]
			observations[key] = direct
			checks[key + "_external_before_pause"] = not player.preparation_pause_states[-1] and direct.paused and direct.controls_open and direct.camera_arm_distance > 5.13
			checks[key + "_intent_retained"] = player.free_camera_distance == 5.15 and arm.rotation.is_equal_approx(Vector3(0.21, 0.7, 0)) and player.shoulder_side == side and player.shoulder_blend == side
			checks[key + "_transients_cleared"] = not player.first_person and player.perspective_blend == 0.0 and not player.aim_requested and player.aim_blend == 0.0
			checks[key + "_native_collision_retained"] = arm.collision_mask == 1 and is_equal_approx(arm.margin, 0.12) and is_equal_approx(direct.hit_length, 5.15)
			checks[key + "_only_subject_filter_owned"] = player.dialogue_camera_exclusion == subject.get_rid() and not player.encounter_camera_exclusion.is_valid()
			checks[key + "_gameplay_unchanged"] = player.global_position == Vector3(4, 2, -8) and player.velocity == Vector3(1, 2, 3) and player.attack_timer == 0.37 and player.switch_timer == 0.21
			world._set_pause_owner("controls", true)
			world._set_pause_owner("dialogue", true)
			world._set_pause_owner("controls", false)
			checks[key + "_nested_dialogue_retained"] = parent.get_tree().paused and player.controls_open and world.pause_owners.has("dialogue") and player.dialogue_preparations == preparations + 1 and restored_camera_observation(player) == direct
			checks[key + "_nested_subject_filter_retained"] = player.dialogue_camera_exclusion == subject.get_rid()
			world._set_pause_owner("dialogue", false)
			checks[key + "_control_return"] = not parent.get_tree().paused and not player.controls_open and world.pause_owners.is_empty() and arm.rotation.is_equal_approx(Vector3(0.21, 0.7, 0))
			checks[key + "_subject_filter_released"] = not player.dialogue_camera_exclusion.is_valid()
	checks.dialogue_no_gameplay_frame = Engine.get_physics_frames() == physics_frame and Engine.get_process_frames() == idle_frame
	parent.get_tree().paused = paused
	Input.mouse_mode = mouse_mode
	viewport.free()
	return {"checks": checks, "observations": observations}

static func dialogue_camera_obstruction_checks(parent: Node) -> Dictionary:
	# Opt-in native collision negative. One setup frame publishes the two
	# bodies; neither dialogue preparation nor release advances another frame.
	var viewport := SubViewport.new()
	viewport.name = "DialogueCameraObstruction"
	viewport.own_world_3d = true
	viewport.process_mode = Node.PROCESS_MODE_DISABLED
	var world := CameraReadinessWorld.new()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	var player := CameraReadinessPlayer.new()
	player.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	var visual := Node3D.new()
	visual.name = "Visual"
	player.add_child(visual)
	var arm := SpringArm3D.new()
	arm.name = "CameraArm"
	arm.collision_mask = 1
	arm.margin = 0.12
	player.add_child(arm)
	var camera := Camera3D.new()
	camera.name = "Camera"
	arm.add_child(camera)
	player.position = Vector3(0, 2, 0)
	player.free_camera_distance = 3.8
	var subject := StaticBody3D.new()
	subject.name = "Interlocutor"
	subject.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	subject.collision_layer = 1
	subject.position = Vector3(0.3, 3.45, 1.1)
	var subject_collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	subject_collision.shape = capsule
	subject.add_child(subject_collision)
	var wall := StaticBody3D.new()
	wall.name = "AuthoredWall"
	wall.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	wall.collision_layer = 1
	wall.position = Vector3(0, 3.45, 2.6)
	var wall_collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 0.2)
	wall_collision.shape = box
	wall.add_child(wall_collision)
	world.player = player
	world.camera_subject = subject
	world.add_child(player)
	world.add_child(subject)
	world.add_child(wall)
	viewport.add_child(world)
	parent.add_child(viewport)
	await parent.get_tree().physics_frame
	var paused := parent.get_tree().paused
	var mouse_mode := Input.mouse_mode
	var physics_frame := Engine.get_physics_frames()
	var idle_frame := Engine.get_process_frames()
	world._set_pause_owner("dialogue", true)
	var modal := restored_camera_observation(player)
	var query := PhysicsRayQueryParameters3D.create(arm.global_position, arm.global_position + Vector3(0, 0, 3.8), 1, [player.get_rid(), subject.get_rid()])
	var wall_hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	world._set_pause_owner("dialogue", false)
	var released := restored_camera_observation(player)
	var checks := {
		"modal_keeps_physical_wall": modal.hit_length > 2.0 and modal.hit_length < 2.8 and not wall_hit.is_empty() and wall_hit.collider == wall,
		"release_restores_interlocutor_collision": released.hit_length > 0.1 and released.hit_length < 1.2 and released.hit_length < modal.hit_length and not player.dialogue_camera_exclusion.is_valid(),
		"native_mask_margin_preserved": arm.collision_mask == 1 and is_equal_approx(arm.margin, 0.12),
		"modal_and_release_advance_no_frame": Engine.get_physics_frames() == physics_frame and Engine.get_process_frames() == idle_frame}
	parent.get_tree().paused = paused
	Input.mouse_mode = mouse_mode
	viewport.free()
	return {"scope": "isolated native wall/interlocutor collision; not ordinary scene acceptance", "checks": checks, "modal": modal, "released": released}

static func restored_camera_observation(player: Node3D) -> Dictionary:
	# Read-only; usable on an ordinary restored player before/after nested UI.
	var arm: SpringArm3D = player.arm
	var camera: Camera3D = player.camera
	return {"player_position": player.global_position, "arm_position": arm.global_position,
		"camera_position": camera.global_position, "camera_local_position": camera.position,
		"camera_arm_distance": camera.global_position.distance_to(arm.global_position),
		"requested_length": arm.spring_length, "hit_length": arm.get_hit_length(),
		"arm_rotation": arm.rotation, "camera_rotation": camera.rotation,
		"controls_open": player.controls_open, "paused": player.get_tree().paused}

class RecoveryDiskState extends "res://dialogue_state.gd":
	# Dedicated disposable namespace; never production saves or preferences.
	var fail_recovery_write := false
	func _ready() -> void:
		inventory = preload("res://inventory/product_inventory.gd").new()
		inventory.state = self
		add_child(inventory)
		inventory.restore()
	func opening_recovery_path() -> String:
		return "user://developer_recovery_checks/missing/intent.cfg" if fail_recovery_write else "user://developer_recovery_checks/intent.cfg"
	func _history_path(slot: int) -> String:
		return "user://developer_recovery_checks/slot_%d.cfg" % slot
	func save_preferences() -> Error:
		return OK

static func opening_recovery_disk_checks() -> Dictionary:
	# Opt-in test only. Exercise the real atomic producer and quiet reader using
	# disposable files, including a prior committed adventure and failed writes.
	var checks := {}
	DirAccess.make_dir_recursive_absolute("user://developer_recovery_checks")
	var state := RecoveryDiskState.new()
	for slot in [0, 1, 2]:
		DirAccess.remove_absolute(state._history_path(slot))
	state.clear_opening_recovery()
	checks.absent = not state.opening_recovery().pending and state.continue_unavailable_reason() != ""
	state.reset_adventure()
	state.opening_completed = true
	state.experience = 10
	checks.committed_write = state.save_progress(Vector3.ZERO, 0) == OK
	checks.manual_write = state.save_progress(Vector3.ZERO, 0, 1) == OK
	var committed := FileAccess.get_file_as_bytes(state._history_path(0))
	var manual := FileAccess.get_file_as_bytes(state._history_path(1))
	var preferences := state.preference_snapshot()
	checks.begin = state.begin_opening_recovery() == OK
	var boundary := state.opening_recovery()
	checks.pending = boundary.pending and boundary.id.length() == 32 and state.continue_unavailable_reason() == ""
	checks.preserves_committed = committed == FileAccess.get_file_as_bytes(state._history_path(0)) and manual == FileAccess.get_file_as_bytes(state._history_path(1))
	checks.no_grants_or_preferences = state.experience == 10 and state.preference_snapshot() == preferences
	var restarted := RecoveryDiskState.new()
	checks.cold_reader = restarted.opening_recovery() == boundary
	state.fail_recovery_write = true
	checks.failed_write = state.begin_opening_recovery() != OK
	state.fail_recovery_write = false
	checks.failed_write_preserves_boundary = state.opening_recovery() == boundary and committed == FileAccess.get_file_as_bytes(state._history_path(0))
	state.reset_adventure()
	checks.uncommitted_no_grants = not state.opening_completed and state.experience == 0 and not state.sword_owned and not state.bow_owned and not state.lamp_owned
	state.opening_completed = true
	state.opening_recovery_id = boundary.id
	checks.safe_commit = state.save_progress(Vector3.ZERO, 0) == OK
	checks.stale_intent_ignored = not restarted.opening_recovery().pending
	var legacy: ConfigFile = state.HISTORY_READER.read(state._history_path(0)).config
	legacy.erase_section("cinematic")
	checks.legacy_completed = state.restore_config(legacy).size() > 0 and state.opening_completed
	checks.legacy_no_replay = not state.slot_needs_opening(1)
	state.clear_opening_recovery()
	var damaged := FileAccess.open(state.opening_recovery_path(), FileAccess.WRITE)
	damaged.store_string("[presentation]\nid=\"broken\"\nversion=1\n")
	damaged.close()
	checks.corrupt_intent_safe = not state.opening_recovery().pending and state.opening_recovery().reason != "" and state.slot_unavailable_reason(0, true) == ""
	checks.replacement_retry = state.begin_opening_recovery() == OK and state.opening_recovery().pending
	state.clear_opening_recovery()
	for slot in [0, 1, 2]: DirAccess.remove_absolute(state._history_path(slot))
	state.free()
	restarted.free()
	return checks

static func settings_audio_lifecycle_checks() -> Dictionary:
	# Assign disposable dependencies while detached. Never enter the tree,
	# register buses, apply/load preferences, or start/pause/seek playback.
	var state: Node = preload("res://dialogue_state.gd").new()
	var host: Control = preload("res://ui/title_menu.gd").new()
	host.state = state
	var settings: Node = preload("res://ui/title_settings.gd").new()
	settings.host = host
	var audio: Node = preload("res://ui/menu_audio.gd").new()
	audio.state = state
	audio.music = AudioStreamPlayer.new()
	audio.voice = AudioStreamPlayer.new()
	var before := {"settings": boundary_comparison(settings), "audio": boundary_comparison(audio)}
	settings.queue_free()
	audio.queue_free()
	var pending := {"settings": boundary_comparison(settings), "audio": boundary_comparison(audio)}
	var checks: Dictionary = lifecycle_comparison_checks(before, pending)
	checks.settings_preferences_available = before.settings.before.preferences is Dictionary
	checks.settings_preferences_preserved = before.settings.direct_before.preferences == pending.settings.direct_after.preferences
	checks.settings_focus_unavailable = before.settings.before.focus_name == null and pending.settings.before.focus_name == null
	checks.audio_not_started = before.audio.before.music_playing == false and before.audio.before.playing == false
	checks.audio_preferences_preserved = before.audio.direct_before.preferences == pending.audio.direct_after.preferences
	checks.audio_registry_preserved = before.audio.direct_before.buses == pending.audio.direct_after.buses and before.audio.direct_before.bus_count == pending.audio.direct_after.bus_count
	var result := {"selection": "settings_audio", "pre_ready": before, "pending_teardown": pending, "checks": checks}
	audio.music.free()
	audio.voice.free()
	settings.free()
	audio.free()
	host.free()
	state.free()
	return result

static func opening_router_lifecycle_checks() -> Dictionary:
	# The real router/opening callbacks run against detached state. No startup,
	# rollback/history write, playback advancement or opening completion occurs.
	var state: Node = preload("res://dialogue_state.gd").new()
	var router: Node = preload("res://ui/game_entry_router.gd").new()
	var opening: Node = preload("res://ui/illustrated_opening.gd").new()
	router.state = state
	router.opening = opening
	opening.state = state
	opening.router = router
	var before := {"router": boundary_comparison(router), "opening": boundary_comparison(opening)}
	router.queue_free()
	opening.queue_free()
	var pending := {"router": boundary_comparison(router), "opening": boundary_comparison(opening)}
	var checks: Dictionary = lifecycle_comparison_checks(before, pending)
	checks.opening_timeline_preserved = before.opening.direct_before.elapsed == pending.opening.direct_after.elapsed and before.opening.direct_before.beat_elapsed == pending.opening.direct_after.beat_elapsed and before.opening.direct_before.beat_index == pending.opening.direct_after.beat_index
	checks.opening_unavailable = before.opening.before.beat == null and before.opening.before.image == null and pending.opening.before.beat == null
	checks.opening_streams_unavailable = before.opening.before.music_playing == null and pending.opening.before.music_playing == null
	checks.reveal_unavailable_at_teardown = pending.opening.before.revealing == null and pending.opening.before.reveal_elapsed == null and pending.opening.before.veil_opacity == null and pending.router.before.revealing == null and pending.router.before.reveal_elapsed == null and pending.router.before.veil_opacity == null
	checks.router_history_preserved = before.router.direct_before.history == pending.router.direct_after.history and before.router.direct_before.previous_history == pending.router.direct_after.previous_history and before.router.direct_before.confirmed_choices == pending.router.direct_after.confirmed_choices
	checks.router_preferences_preserved = before.router.direct_before.preferences == pending.router.direct_after.preferences
	checks.opening_history_preserved = before.opening.direct_before.history == pending.opening.direct_after.history and before.opening.direct_before.opening_completed == pending.opening.direct_after.opening_completed
	checks.router_not_initialized = before.router.direct_before.initialized == false and pending.router.direct_after.initialized == false
	var result := {"selection": "opening_router", "pre_ready": before, "pending_teardown": pending, "checks": checks}
	opening.free()
	router.free()
	state.free()
	return result

static func boundary_comparison(owner: Node) -> Dictionary:
	# Each boundary retains raw measurements independently from assertions.
	var direct_before: Dictionary = direct_owner_fields(owner)
	var before: Dictionary = owner._mcp_state()
	var after: Dictionary = owner._mcp_state()
	return {"direct_before": direct_before, "before": before, "after": after, "direct_after": direct_owner_fields(owner)}

static func lifecycle_comparison_checks(before: Dictionary, pending: Dictionary) -> Dictionary:
	var checks := {}
	for name in before:
		for boundary in ["pre_ready", "pending_teardown"]:
			var comparison: Dictionary = before[name] if boundary == "pre_ready" else pending[name]
			var key: String = str(name) + "_" + boundary
			checks[key + "_read_only"] = comparison.before == comparison.after
			checks[key + "_owner_preserved"] = stable_raw_fields(comparison.direct_before) == stable_raw_fields(comparison.direct_after)
			checks[key + "_unready"] = comparison.before.get("ready") == false and comparison.after.get("ready") == false
			checks[key + "_detached"] = comparison.direct_before.inside_tree == false and comparison.direct_after.inside_tree == false
			checks[key + "_queued_boundary"] = comparison.direct_before.queued_for_deletion == (boundary == "pending_teardown") and comparison.direct_after.queued_for_deletion == (boundary == "pending_teardown")
	return checks

static func stable_raw_fields(value: Variant) -> Variant:
	# Timestamps remain in raw output, but are not owner-state mutations.
	if value is Dictionary:
		var result := {}
		for key in value:
			if key != "sample_us": result[key] = stable_raw_fields(value[key])
		return result
	if value is Array:
		var result := []
		for item in value: result.append(stable_raw_fields(item))
		return result
	return value

static func run(_holder: Node) -> Dictionary:
	var world := preload("res://preview_controller.gd").new()
	var before: Dictionary = world._mcp_state()
	var unchanged: Dictionary = world._mcp_state()
	# Retain the actual object through the queued-deletion boundary. Disable
	# processing and avoid _ready: this test must not construct a second world.
	world.process_mode = Node.PROCESS_MODE_DISABLED
	world.queue_free()
	var pending: Dictionary = world._mcp_state()
	var checks := {"controls_absent": before.controls_ready == false and before.controls_visible == null and before.controls_submenu == null,
		"player_absent": before.player_ready == false and before.player_position == null,
		"read_only": before == unchanged,
		"pending_teardown": world.is_queued_for_deletion() and pending.ready == false and pending.controls_visible == null,
		"unavailable_state": before.preferences == null and before.objective == null and pending.tree_paused == null}
	var observers: Dictionary = observer_lifecycle_checks()
	checks.merge(observers.checks)
	var isha: Dictionary = isha_observer_checks()
	checks.merge(isha.checks)
	var departure: Dictionary = departure_lifecycle_checks()
	checks.merge(departure.checks)
	return {"checks": checks, "before": before, "pending_teardown": pending, "departure": departure, "isha": isha, "observers": observers.observations, "audio": observers.audio}


static func isha_observer_checks() -> Dictionary:
	# Detached real actor/player: no actor _ready, model import, world build,
	# conversation, progression or saves. Only this explicit fixture drives the
	# tiny clip; repeated observations must never assign, seek or start it.
	var actor: Node = preload("res://isha_npc.gd").new()
	var absent: Dictionary = actor._mcp_state()
	actor.idle_player = AnimationPlayer.new()
	actor.add_child(actor.idle_player)
	var initial: Dictionary = actor._mcp_state()
	var initial_repeated: Dictionary = actor._mcp_state()
	var library := AnimationLibrary.new()
	var clip := Animation.new()
	clip.length = 3.5
	clip.loop_mode = Animation.LOOP_LINEAR
	library.add_animation("Isha_Idle", clip)
	actor.idle_player.add_animation_library("", library)
	actor.idle_player.play("Isha_Idle")
	actor.idle_player.advance(0.625)
	var assigned: String = actor.idle_player.assigned_animation
	var playing: bool = actor.idle_player.is_playing()
	var initialized: Dictionary = actor._mcp_state()
	var initialized_repeated: Dictionary = actor._mcp_state()
	var playback_preserved: bool = actor.idle_player.assigned_animation == assigned and actor.idle_player.is_playing() == playing
	actor.idle_player.pause()
	var paused: Dictionary = actor._mcp_state()
	var paused_repeated: Dictionary = actor._mcp_state()
	var paused_preserved: bool = not actor.idle_player.is_playing() and actor.idle_player.assigned_animation == assigned
	actor.idle_player.stop()
	var stopped: Dictionary = actor._mcp_state()
	actor.idle_player.free()
	var freed: Dictionary = actor._mcp_state()
	actor.free()
	return {"checks": {
		"isha_absent_animation_unavailable": absent.idle_animation_ready == false and absent.idle_clip == null and absent.idle_position == null,
		"isha_unassigned_animation_unavailable": initial.idle_animation_ready == false and initial.idle_clip == null and initial.idle_position == null,
		"isha_unassigned_observation_read_only": initial == initial_repeated,
		"isha_initialized_idle_available": initialized.idle_animation_ready == true and initialized.idle_clip == "Isha_Idle" and is_equal_approx(initialized.idle_position, 0.625),
		"isha_initialized_playback_read_only": initialized == initialized_repeated and playback_preserved,
		"isha_paused_playback_read_only": paused == paused_repeated and paused_preserved,
		"isha_stopped_animation_unavailable": stopped.idle_animation_ready == false and stopped.idle_position == null,
		"isha_freed_animation_unavailable": freed.idle_animation_ready == false and freed.idle_clip == null and freed.idle_position == null},
		"absent": absent, "unassigned": initial, "initialized": initialized, "paused": paused, "stopped": stopped, "freed": freed}


static func departure_lifecycle_checks() -> Dictionary:
	# Actual callbacks, detached and disabled: no product startup/save/audio.
	var router: Node = preload("res://ui/game_entry_router.gd").new()
	var world: Node = preload("res://preview_controller.gd").new()
	var transition: Node = preload("res://ui/chapter_transition.gd").new()
	router.world = world
	router.source_world = world
	router.transition = transition
	router.destination_map = preload("res://world/map02_ground.gd").MAP02_ID
	router.route = "travel_story"
	var direct_before: Dictionary = transition._mcp_state()
	var world_before: Dictionary = world._mcp_state()
	var before: Dictionary = router._mcp_state()
	var unchanged: bool = before == router._mcp_state() and direct_before == transition._mcp_state() and world_before == world._mcp_state()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	transition.process_mode = Node.PROCESS_MODE_DISABLED
	world.queue_free()
	transition.queue_free()
	var direct_pending: Dictionary = transition._mcp_state()
	var world_pending: Dictionary = world._mcp_state()
	var pending: Dictionary = router._mcp_state()
	# Free immediately to exercise invalid handles, then leave the persistent
	# owner alive. Both before and pending callbacks use the real scripts.
	world.free()
	transition.free()
	var absent: Dictionary = router._mcp_state()
	var checks := {
		"departure_initial_projection": before.departure_phase == direct_before.phase and before.departure_transition_ready == false,
		"departure_actual_world_callback": before.departure_controls_present == world_before.controls_ready and before.departure_control_ready == false,
		"departure_read_only": unchanged and router.route == "travel_story",
		"departure_pending_direct_unready": direct_pending.ready == false and world_pending.ready == false,
		"departure_pending_null": pending.departure_phase == null and pending.departure_transition_ready == null and pending.departure_control_ready == null,
		"departure_invalid_handles_null": absent.departure_phase == null and absent.departure_world_ready == null and absent.departure_controls_present == null,
		"departure_owner_boundary_survives": absent.route == "travel_story" and absent.departure_destination == before.departure_destination and absent.departure_transition_present == false and absent.departure_source_present == false,
		"departure_no_state_assumption": before.departure_current_map == null and absent.departure_cp02_claimed == null and absent.departure_lives == null}
	router.free()
	return {"checks":checks,"before":before,"direct_before":direct_before,"world_before":world_before,"pending":pending,"direct_pending":direct_pending,"world_pending":world_pending,"absent":absent}

static func observer_lifecycle_checks() -> Dictionary:
	# These are real observation implementations with no _ready invocation,
	# world construction, playback or save writes in the isolated fixture.
	var checks := {}
	var observations := {}
	for path in ["ui/game_entry_router.gd", "ui/illustrated_opening.gd", "ui/chapter_transition.gd", "ui/title_settings.gd", "ui/menu_audio.gd", "world/map02_entry.gd", "world/chapter_pillar.gd"]:
		var observer: Node = load("res://" + path).new()
		var direct_before: Dictionary = direct_owner_fields(observer)
		var initial: Dictionary = observer._mcp_state()
		var repeated: Dictionary = observer._mcp_state()
		var direct_after: Dictionary = direct_owner_fields(observer)
		observer.process_mode = Node.PROCESS_MODE_DISABLED
		observer.queue_free()
		var pending: Dictionary = observer._mcp_state()
		observations[path] = {"direct_before": direct_before, "initial": initial, "repeated": repeated, "direct_after": direct_after, "pending": pending, "direct_pending": direct_owner_fields(observer)}
		checks[path + "_initial_shape"] = initial.has("ready") and initial.ready == false
		checks[path + "_read_only"] = initial == repeated
		checks[path + "_pending_teardown"] = observer.is_queued_for_deletion() and pending.ready == false
		if path == "ui/illustrated_opening.gd":
			checks.opening_skip_initial = initial.skip_hold == 0.0 and initial.pause_menu_present == false
			checks.opening_streams_unavailable = initial.music_playing == null and initial.music_paused == null and initial.ambience_paused == null and initial.cue_paused == null
		if path == "ui/menu_audio.gd":
			checks.menu_streams_unavailable = initial.music_position == null and initial.music_paused == null and initial.voice_paused == null
		if path == "ui/title_settings.gd":
			checks.settings_focus_unavailable = initial.focus_name == null and pending.focus_name == null
		if path == "world/chapter_pillar.gd":
			checks.pillar_unavailable = initial.active == null and initial.player_distance == null and initial.player_in_range == null and initial.interaction_eligible == null and pending.interaction_eligible == null
	var audio: Dictionary = detached_audio_checks()
	checks.merge(audio.checks)
	return {"checks": checks, "observations": observations, "audio": audio.observations}

static func detached_audio_checks() -> Dictionary:
	# Exercise real assigned dependencies and freed handles without entering the
	# tree, playing audio, invoking _ready, or loading/writing user preferences.
	# Standalone probes have no AdventureState _ready to register audio buses.
	# Godot exposes Master for an unregistered requested bus; measure that
	# boundary without creating buses. Live routing is checked separately below.
	var music_bus_index := AudioServer.get_bus_index("Music")
	var effects_bus_index := AudioServer.get_bus_index("Effects")
	var bus_count := AudioServer.bus_count
	var expected_music_bus := "Music" if music_bus_index >= 0 else "Master"
	var expected_voice_bus := "Effects" if effects_bus_index >= 0 else "Master"
	var observer: Node = preload("res://ui/menu_audio.gd").new()
	observer.state = preload("res://dialogue_state.gd").new()
	observer.music = AudioStreamPlayer.new()
	observer.music.bus = "Music"
	observer.voice = AudioStreamPlayer.new()
	observer.voice.bus = "Effects"
	var direct_before: Dictionary = direct_owner_fields(observer)
	var before: Dictionary = observer._mcp_state()
	var repeated: Dictionary = observer._mcp_state()
	var direct_after: Dictionary = direct_owner_fields(observer)
	observer.music.free()
	observer.voice.free()
	var freed_streams: Dictionary = observer._mcp_state()
	observer.state.free()
	var freed_state: Dictionary = observer._mcp_state()
	observer.free()
	return {"checks": {"detached_audio_read_only": before == repeated,
		"detached_audio_not_started": before.ready == false and before.music_playing == false and before.playing == false,
		"detached_audio_routes": before.music_bus == expected_music_bus and before.voice_bus == expected_voice_bus,
		"detached_audio_bus_registry_unchanged": AudioServer.bus_count == bus_count and AudioServer.get_bus_index("Music") == music_bus_index and AudioServer.get_bus_index("Effects") == effects_bus_index,
		"freed_streams_unavailable": freed_streams.ready == false and freed_streams.music_position == null and freed_streams.music_paused == null and freed_streams.voice_paused == null,
		"freed_audio_state_unavailable": freed_state.ready == false and freed_state.muted == null}, "observations": {"direct_before": direct_before, "before": before, "repeated": repeated, "direct_after": direct_after, "freed_streams": freed_streams, "freed_state": freed_state}}

static func live_read_checks(router: Node) -> Dictionary:
	# Opt-in check of the actual current entry boundary. Do not call the mutable
	# adventure_snapshot() helper or apply preferences while measuring reads.
	if not is_instance_valid(router):
		return {"ready": false, "reason": "entry unavailable", "checks": {}, "observations": {}}
	if not router.is_inside_tree() or not router.is_node_ready() or router.is_queued_for_deletion() or not is_instance_valid(router.state) or router.state.is_queued_for_deletion() or not is_instance_valid(router.audio) or router.audio.is_queued_for_deletion():
		return {"ready": false, "reason": "live entry/state/audio unavailable", "checks": {}, "observations": {"direct": direct_owner_fields(router)}}
	var state: Node = router.state
	var direct_before: Dictionary = direct_owner_fields(router)
	var preferences: Dictionary = state.preference_snapshot()
	var history: Dictionary = state.training_snapshot().duplicate(true)
	var choices: Array = state.confirmed_choices.duplicate(true)
	var route: String = router.route
	var tree_paused: bool = router.get_tree().paused
	var mouse_mode: int = Input.mouse_mode
	var focused: Control = router.get_viewport().gui_get_focus_owner()
	var observed: Dictionary = router._mcp_state()
	var departure_before: Dictionary = router._departure_observation()
	var departure_after: Dictionary = router._departure_observation()
	var audio_before: Dictionary = router.audio._mcp_state()
	var audio_after: Dictionary = router.audio._mcp_state()
	var observations := {"direct_before": direct_before, "router": observed, "departure_before": departure_before, "departure_after": departure_after, "audio_before": audio_before, "audio_after": audio_after, "settings": {}}
	var checks := {"router_ready_shape": observed.ready == true and observed.route == route,
		"audio_ready_shape": audio_before.ready == true and audio_before.music_bus == "Music" and audio_before.voice_bus == "Effects",
		"preferences_unchanged": state.preference_snapshot() == preferences,
		"history_unchanged": state.training_snapshot() == history and state.confirmed_choices == choices,
		"route_unchanged": router.route == route,
		"departure_read_only": departure_before == departure_after,
		"departure_nullable_shape": [null, true, false].has(departure_before.departure_transition_ready) and [null, true, false].has(departure_before.departure_control_ready),
		"playback_not_reset": audio_after.music_position >= audio_before.music_position and audio_after.music_playing == audio_before.music_playing,
		"audio_pause_unchanged": audio_after.music_paused == audio_before.music_paused and audio_after.voice_paused == audio_before.voice_paused and audio_after.last_cue == audio_before.last_cue}
	if is_instance_valid(router.opening):
		var opening: Node = router.opening
		var opening_direct_before: Dictionary = direct_owner_fields(opening)
		var before: Dictionary = opening._mcp_state()
		var after: Dictionary = opening._mcp_state()
		observations.opening = {"direct_before": opening_direct_before, "before": before, "after": after, "direct_after": direct_owner_fields(opening)}
		checks.router_opening_matches_leaf = observed.opening == before
		checks.opening_ready_shape = before.ready == true and before.beat is int and before.image is String
		checks.opening_clock_unchanged = before.elapsed == after.elapsed and before.beat_elapsed == after.beat_elapsed and before.finished == after.finished
		checks.opening_pause_unchanged = before.pause_owners == after.pause_owners and before.timeline_paused == after.timeline_paused
		checks.opening_skip_unchanged = before.skip_hold == after.skip_hold and before.inputs_armed == after.inputs_armed and before.pause_menu_present == after.pause_menu_present
		checks.opening_audio_unchanged = before.music_playing == after.music_playing and before.music_paused == after.music_paused and before.ambience_paused == after.ambience_paused and before.cue_paused == after.cue_paused
	for node in router.find_children("*", "Control", true, false):
		var script: Script = node.get_script()
		if script == null or script.resource_path != "res://ui/title_settings.gd": continue
		var settings_direct_before: Dictionary = direct_owner_fields(node)
		var before: Dictionary = node._mcp_state()
		var after: Dictionary = node._mcp_state()
		observations.settings[str(node.get_path())] = {"direct_before": settings_direct_before, "before": before, "after": after, "direct_after": direct_owner_fields(node)}
		checks.settings_ready_shape = before.ready == true and before.preferences is Dictionary and before.bindings is Dictionary
		checks.settings_read_only = before == after
	# Compare after every observer has run, including nested opening/settings.
	checks.preferences_unchanged = state.preference_snapshot() == preferences
	checks.history_unchanged = state.training_snapshot() == history and state.confirmed_choices == choices
	checks.route_unchanged = router.route == route
	checks.pause_input_ownership_preserved = router.get_tree().paused == tree_paused and Input.mouse_mode == mouse_mode and router.get_viewport().gui_get_focus_owner() == focused
	observations.direct_after = direct_owner_fields(router)
	return {"ready": true, "checks": checks, "route": route, "observations": observations}

static func direct_owner_fields(owner: Node) -> Dictionary:
	# Independent raw reads in the opted-in fixture: no observer methods, bus
	# application, timeline advancement, snapshot mutation, playback or file I/O.
	var result := {"sample_us": Time.get_ticks_usec(), "bus_count": AudioServer.bus_count, "buses": {}}
	for bus in ["Master", "Music", "Effects"]:
		var index := AudioServer.get_bus_index(bus)
		var data := {"index": index, "available": index >= 0, "volume_db": null, "muted": null, "bypassed": null, "send": null, "effects": null}
		if index >= 0:
			data.merge({"volume_db": AudioServer.get_bus_volume_db(index), "muted": AudioServer.is_bus_mute(index), "bypassed": AudioServer.is_bus_bypassing_effects(index), "send": str(AudioServer.get_bus_send(index)), "effects": []}, true)
			for effect_index in AudioServer.get_bus_effect_count(index):
				var effect := AudioServer.get_bus_effect(index, effect_index)
				data.effects.append({"name": effect.resource_name, "enabled": AudioServer.is_bus_effect_enabled(index, effect_index), "gain_db": effect.volume_db if effect is AudioEffectAmplify else null})
		result.buses[bus] = data
	if not is_instance_valid(owner): return result
	result.merge({"inside_tree": owner.is_inside_tree(), "node_ready": owner.is_node_ready(), "queued_for_deletion": owner.is_queued_for_deletion()})
	var script: Script = owner.get_script()
	var script_path: String = script.resource_path
	# The disposable adventure overrides persistence through a router subclass.
	# Walk actual inheritance rather than losing direct baselines for that owner.
	while script_path not in ["res://ui/game_entry_router.gd", "res://ui/title_settings.gd", "res://ui/menu_audio.gd", "res://ui/illustrated_opening.gd"] and script.get_base_script() != null:
		script = script.get_base_script()
		script_path = script.resource_path
	var state: Node
	if script_path == "res://ui/game_entry_router.gd":
		state = owner.state
		result.merge({"route": owner.route, "initialized": owner.initialized, "player_ready": owner.player_ready, "previous_history": owner.previous_history.duplicate(true), "tree_paused": owner.get_tree().paused if owner.is_inside_tree() else null})
		result.audio = direct_owner_fields(owner.audio) if is_instance_valid(owner.audio) else null
		result.opening = direct_owner_fields(owner.opening) if is_instance_valid(owner.opening) else null
	elif script_path == "res://ui/title_settings.gd":
		state = owner.host.state if is_instance_valid(owner.host) else null
		result.merge({"group": owner.group, "capturing": owner.capturing})
	elif script_path == "res://ui/menu_audio.gd" or script_path == "res://ui/illustrated_opening.gd":
		state = owner.state
		var channels := ["music", "voice"] if script_path == "res://ui/menu_audio.gd" else ["music", "ambience", "cue"]
		result.streams = {}
		for channel in channels:
			var player: AudioStreamPlayer = owner.get(channel)
			result.streams[channel] = {"bus": str(player.bus), "playing": player.playing, "paused": player.stream_paused, "position": player.get_playback_position(), "volume_db": player.volume_db} if is_instance_valid(player) and not player.is_queued_for_deletion() else null
		if script_path == "res://ui/menu_audio.gd": result.last_cue = owner.last_cue
		else:
			result.merge({"beat_index": owner.beat, "beat_elapsed": owner.elapsed, "elapsed": owner.total_elapsed, "finished": owner.finished, "inputs_armed": owner.inputs_armed, "skip_hold": owner.skip_hold, "pause_menu_present": is_instance_valid(owner.pause_menu) and not owner.pause_menu.is_queued_for_deletion()})
	result.merge({"state_available": is_instance_valid(state) and not state.is_queued_for_deletion(), "preferences": null, "preference_error": null, "history": null, "confirmed_choices": null, "opening_completed": null})
	if result.state_available:
		result.preferences = {}
		for key in state.PREFERENCE_DEFAULTS: result.preferences[key] = state.get(key)
		result.preference_error = state.preference_error
		result.history = {}
		for key in state.TRAINING_KEYS: result.history[key] = state.get(key)
		for key in state.POST_DEFAULTS: result.history[key] = state.get(key)
		result.history = result.history.duplicate(true)
		result.confirmed_choices = state.confirmed_choices.duplicate(true)
		result.opening_completed = state.opening_completed
	return result
