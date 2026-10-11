extends "res://combat/map02_enemy_adapter.gd"
## Retained Snaiel health, EnemyActions, posed fist and animation ownership.
var rush_obstructed := false

func _ready() -> void:
	super()
	health_component.max_health = 36.0
	health_component.health = 36.0
	enabled_policy = func(): return encounter.combat_allowed() and navigation_ready and not encounter.state.reward_history.has(stable_id)
	acquired_cue = Callable()
	var strategy := SnaielMeleeAttack.new()
	strategy.attack_name = &"Punch"
	strategy.damage_attributes.health = 14.0
	strategy.anticipation = 0.6
	strategy.strike_delay = 0.18
	strategy.contact_time = 0.26
	strategy.recovery = 0.8
	melee_events.stop_attacking()
	melee_events.timeline.free()
	melee_events.configure([strategy])
	# Identity/HP are provided by the ordinary combat HUD after revelation.
	for label in find_children("*", "Label3D", true, false): label.hide()

func tick_attack(board: SnaielBlackboard) -> int:
	if melee.attacking:
		if melee_events.stage in ["strike", "contact"] and not rush_obstructed:
			var support: Dictionary = ground_query.call(global_position + locked_direction * 0.5)
			var collision := KinematicCollision3D.new()
			var blocked := test_move(global_transform, locked_direction * 0.12, collision)
			# Horizontal testing also reports the authored slope under our feet.
			# Slide on walkable ground; only walls/steep faces cancel the rush.
			var wall := blocked and collision.get_collider() != target and collision.get_normal().y < cos(floor_max_angle)
			if support.is_empty() or absf(support.position.y - global_position.y) > 0.7 or wall:
				rush_obstructed = true
			else:
				velocity.x = locked_direction.x * 5.0
				velocity.z = locked_direction.z * 5.0
		return SnaielBehaviorNode.RUNNING
	if not engaged or not board.get_value("perceives_player", false) or board.get_value("target_dist", 100.0) > 3.1 or not encounter.attack_slot_available(self): return SnaielBehaviorNode.FAILURE
	rush_obstructed = false
	attack_origin = global_position
	locked_direction = board.get_value("target_dir", Vector3.ZERO)
	model.rotation.y = atan2(locked_direction.x, locked_direction.z)
	melee.attack(0, true, false)
	return SnaielBehaviorNode.RUNNING

func on_attack_stage(stage: String) -> void:
	# Telegraph may face the player; the strike locks its direction once.
	if stage == "strike":
		locked_direction = global_position.direction_to(target.global_position)
		locked_direction.y = 0
		locked_direction = locked_direction.normalized()
		model.rotation.y = atan2(locked_direction.x, locked_direction.z)
	if stage == "anticipation": encounter.telegraph(self)
	super(stage)

func _sample_contact() -> void:
	if rush_obstructed:
		previous_fist = source.global_position
		return
	super()

func _mcp_state() -> Dictionary:
	var bindings := _binding_observation()
	if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion():
		bindings.merge({"ready":false,"phase":null,"revealed":null})
		return bindings
	var result := super()
	result.revealed = encounter.state.e03_revealed
	result.recognition_remaining = encounter.recognition_remaining
	result.locked_direction = locked_direction
	result.rush_obstructed = rush_obstructed
	result.stable_id = stable_id
	result.merge(bindings)
	return result

func _binding_observation() -> Dictionary:
	# Read the instantiated replacement and configured recipients, not MODELS
	# constants or detached load results. Never configure or play from a probe.
	var result := {"binding_ready":false,"model_resource":null,"model_path":null,"skeleton_path":null,"bone_count":null,"skinned_mesh_count":null,"skin_bind_count":null,"skin_skeleton_path":null,"animation_player_path":null,"animation_root_path":null,"animation_driver_resource":null,"animation_tree_active":null,"active_clip":null,"active_clip_position":null,"contact_source_path":null,"contact_socket_path":null,"contact_bone":null,"contact_bone_index":null,"contact_attached":null}
	if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion(): return result
	if not is_instance_valid(model) or not is_instance_valid(character) or not is_instance_valid(animator) or not is_instance_valid(source): return result
	var rig: Skeleton3D = character.skeleton
	var socket: BoneAttachment3D = character.contact_socket
	if not is_instance_valid(rig) or not is_instance_valid(socket) or not is_instance_valid(character.anim_tree): return result
	result.binding_ready = true
	result.model_resource = model.scene_file_path
	result.model_path = str(model.get_path())
	result.skeleton_path = str(rig.get_path())
	result.bone_count = rig.get_bone_count()
	result.skinned_mesh_count = 0
	# Preserve absence rather than assuming a skin is assigned to this rig.
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.skin == null: continue
		result.skinned_mesh_count += 1
		if result.skin_bind_count == null:
			result.skin_bind_count = mesh.skin.get_bind_count()
			var skin_rig := mesh.get_node_or_null(mesh.skeleton)
			result.skin_skeleton_path = str(skin_rig.get_path()) if skin_rig else null
	result.animation_player_path = str(animator.get_path())
	var animation_root := animator.get_node_or_null(animator.root_node)
	result.animation_root_path = str(animation_root.get_path()) if animation_root else null
	result.animation_driver_resource = character.get_script().resource_path
	result.animation_tree_active = character.anim_tree.active
	result.active_clip = character.current_clip()
	result.active_clip_position = character.current_position()
	result.contact_source_path = str(source.get_path())
	result.contact_socket_path = str(socket.get_path())
	result.contact_bone = socket.bone_name
	result.contact_bone_index = rig.find_bone(socket.bone_name)
	result.contact_attached = source.get_parent() == socket and socket.get_parent() == rig
	return result
