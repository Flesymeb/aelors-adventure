extends RefCounted
## Component checks on explicit memory-only fixtures; not ordinary earning/QA.
const CIRCUIT = preload("res://tests/map03_barrier_test.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const STATE = preload("res://dialogue_state.gd")

class SurroundWorld extends Node3D:
	var dialogue_state: Node

static func component_checks(parent: Node) -> Dictionary:
	# Disposable resource/geometry prototype only; no save/progression facts.
	var actions = preload("res://combat/veyne_dragon_actions.gd")
	var rings: Array = []
	for row in 5:
		var ring: Array[Vector3] = []
		for segment in 12:
			var angle := TAU*float(segment)/12.0
			var along := float(row)*2.0
			ring.append(Vector3(cos(angle)*actions.breath_radius(along),along,sin(angle)*actions.breath_radius(along)))
		rings.append(ring)
	var mesh: ArrayMesh = actions.volume_mesh(rings,8.0)
	var arrays: Array = mesh.surface_get_arrays(0)
	var checks := breath_presentation_checks()
	checks.closed_volume_triangle_count = arrays[Mesh.ARRAY_VERTEX].size() == (4*12*2+24)*3
	checks.volume_has_normals_uv = arrays[Mesh.ARRAY_NORMAL].size() == arrays[Mesh.ARRAY_VERTEX].size() and arrays[Mesh.ARRAY_TEX_UV].size() == arrays[Mesh.ARRAY_VERTEX].size()
	checks.volume_stays_in_hazard_extent = mesh.get_aabb().position.y >= -0.001 and mesh.get_aabb().end.y <= 8.001
	checks.shell_stays_in_hazard_radius = true
	for vertex in arrays[Mesh.ARRAY_VERTEX]:
		checks.shell_stays_in_hazard_radius = checks.shell_stays_in_hazard_radius and Vector2(vertex.x,vertex.z).length() <= actions.breath_radius(vertex.y)+0.001
	var volume: MeshInstance3D = preload("res://assets/bosses/veyne_breath.tscn").instantiate()
	checks.volume_default_hidden = not volume.visible and not volume.get_node("BreathCore").visible
	checks.native_noise_bound = volume.material_override.get_shader_parameter("sample_noise") is NoiseTexture3D
	checks.core_distinct = volume.get_node("BreathCore").material_override.get_shader_parameter("core_layer") == true
	checks.material_isolation = volume.material_override != volume.get_node("BreathCore").material_override
	volume.free()
	var world := SurroundWorld.new()
	world.dialogue_state = STATE.new()
	world.add_child(world.dialogue_state)
	var environment_root := Node3D.new()
	world.add_child(environment_root)
	var environment_node := WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	environment_root.add_child(environment_node)
	var arena: Node3D = preload("res://world/veyne_arena.gd").new()
	environment_root.add_child(arena)
	var surround: Node3D = preload("res://world/veyne_surround.tscn").instantiate()
	arena.add_child(surround)
	# A private World3D prevents the disposable environment from taking over
	# the shipped scene's sky/light state during this component check.
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(64,64)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	parent.add_child(viewport)
	viewport.add_child(world)
	surround.bind(arena)
	checks.surround_module_count = surround.modules.size() == 9
	checks.surround_no_new_collision = surround.find_children("*","CollisionObject3D",true,false).is_empty()
	var variants := {}
	checks.surround_authored_textures = true
	checks.surround_all_transforms_finite = true
	checks.surround_all_bounds_finite = true
	checks.surround_all_placements_bounded = true
	checks.surround_authored_spans_match = true
	for module in surround.modules:
		var variant: String = module.get_meta("surround_variant")
		variants[variant] = int(variants.get(variant,0))+1
		var pose: Transform3D = module.global_transform
		var box: AABB = pose*module.mesh.get_aabb()
		var corner: Vector3 = module.get_meta("surround_corner")
		var extent: Vector3 = module.get_meta("surround_extent")
		checks.surround_all_transforms_finite = checks.surround_all_transforms_finite and pose.origin.is_finite() and pose.basis.x.is_finite() and pose.basis.y.is_finite() and pose.basis.z.is_finite()
		checks.surround_all_bounds_finite = checks.surround_all_bounds_finite and box.position.is_finite() and box.size.is_finite()
		checks.surround_all_placements_bounded = checks.surround_all_placements_bounded and pose.origin.length() < 1000.0
		for axis in 3:
			checks.surround_all_placements_bounded = checks.surround_all_placements_bounded and box.position[axis] >= corner[axis]-0.01 and box.end[axis] <= corner[axis]+extent[axis]+0.01
		if variant == "foundation":
			checks.surround_authored_spans_match = checks.surround_authored_spans_match and absf(maxf(box.size.x,box.size.z)-24.0) < 0.01 and absf(box.size.y-13.0) < 0.01
		elif variant == "lower_court":
			checks.surround_authored_spans_match = checks.surround_authored_spans_match and absf(box.size.x-80.0) < 0.01 and absf(box.size.z-80.0) < 0.01 and box.size.y < 0.01
		for surface in module.mesh.get_surface_count():
			var material = module.get_active_material(surface)
			checks.surround_authored_textures = checks.surround_authored_textures and material is BaseMaterial3D and material.albedo_texture != null
	checks.surround_multiple_variants = variants.size() == 3 and variants.values().max() <= 9*0.75
	checks.sky_bound = environment_node.environment.sky.sky_material.shader == preload("res://assets/shaders/veyne_night.gdshader")
	checks.sky_bounded_radiance = environment_node.environment.sky.radiance_size == Sky.RADIANCE_SIZE_32 and environment_node.environment.sky.process_mode == Sky.PROCESS_MODE_INCREMENTAL
	checks.pause_inherited = surround.process_mode == Node.PROCESS_MODE_INHERIT
	viewport.free()
	return checks

static func breath_presentation_checks() -> Dictionary:
	var actions = preload("res://combat/veyne_dragon_actions.gd")
	var mouth := Vector3(0,2,0)
	var endpoint := Vector3(0,1,8)
	var axis := mouth.direction_to(endpoint)
	var near := mouth+axis*2.0
	var far := mouth+axis*7.0
	return {
		"near_width_preserved":is_equal_approx(actions.breath_radius(2),0.76),
		"far_width_expands":is_equal_approx(actions.breath_radius(7),1.66),
		"near_lateral_escape":not actions.inside_breath(mouth,endpoint,near+Vector3.RIGHT),
		"far_lane_inside":actions.inside_breath(mouth,endpoint,far+Vector3.RIGHT),
		"far_lateral_escape":not actions.inside_breath(mouth,endpoint,far+Vector3.RIGHT*2),
		"behind_mouth_miss":not actions.inside_breath(mouth,endpoint,mouth-axis),
		"obstruction_endpoint_limits_contact":not actions.inside_breath(mouth,mouth+axis*3,far),
		"zero_length_safe":not actions.inside_breath(mouth,mouth,mouth)
	}

static func camera_projection_checks() -> Dictionary:
	var controller = preload("res://player_controller.gd")
	var checks := {}
	var pivot := Vector3(2,5,-20)
	for fov in [48.0,70.0,78.0]:
		for aspect in [16.0/9.0,4.0/3.0]:
			var basis := Basis.from_euler(Vector3(-0.2,0.7,0))
			var points: Array[Vector3] = []
			for x in [-6.0,6.0]:
				for y in [-4.0,7.0]:
					for z in [-5.0,5.0]: points.append(pivot + basis * Vector3(x,y,z))
			var distance: float = controller.subject_camera_distance(points,pivot,basis,fov,aspect)
			var fits := true
			for point in points:
				var local := basis.inverse() * (point-pivot)
				var depth := distance-local.z
				fits = fits and depth > 0.1 and absf(local.y)/depth < tan(deg_to_rad(fov)*0.5)*0.78 and absf(local.x)/depth < tan(deg_to_rad(fov)*0.5)*aspect*0.78
			checks[str(fov)+":"+str(aspect)+"_all_subjects_fit"] = fits
	# A clear arm and fitted subject box do not prove the player is visible.
	# Test depth and a posed local volume independently of stone collision.
	var volume := AABB(Vector3(-1,-1,-1),Vector3(2,2,2))
	var posed := Transform3D(Basis(Vector3.UP,0.45),Vector3(3,2,4))
	var occluders: Array = [{"bounds":volume,"inverse_pose":posed.affine_inverse()}]
	checks.foreground_actor_obscures = controller.subject_camera_occluded(posed*Vector3(0,0,5),posed*Vector3(0,0,-5),occluders)
	checks.actor_behind_player_does_not_obscure = not controller.subject_camera_occluded(posed*Vector3(0,0,5),posed*Vector3(0,0,2),occluders)
	checks.lateral_view_clears_actor = not controller.subject_camera_occluded(posed*Vector3(3,0,5),posed*Vector3(3,0,-5),occluders)
	var origin_volume: Array = [{"bounds":AABB(Vector3.ZERO,Vector3.ONE),"inverse_pose":Transform3D.IDENTITY}]
	checks.zero_vector_contact_still_obscures = controller.subject_camera_occluded(Vector3(-2,0,0),Vector3(2,0,0),origin_volume)
	var projected: Array[Vector3] = [Vector3(-1,-1,-4),Vector3(1,1,-4)]
	checks.compressed_view_can_still_fit = controller.subject_camera_points_fit(projected,Vector3.ZERO,Basis.IDENTITY,70.0,16.0/9.0)
	checks.cropped_subject_rejected = not controller.subject_camera_points_fit(projected,Vector3(0,0,-3),Basis.IDENTITY,70.0,16.0/9.0)
	checks.subject_behind_camera_rejected = not controller.subject_camera_points_fit(projected,Vector3(0,0,-5),Basis.IDENTITY,70.0,16.0/9.0)
	var user_look := Vector3(-0.2,0.7,0)
	var corrected := Basis.from_euler(Vector3(-1.1,1.6,0))
	checks.evasion_retains_user_yaw = controller.movement_camera_basis(corrected,true,user_look).is_equal_approx(Basis(Vector3.UP,user_look.y))
	checks.ordinary_movement_retains_camera = controller.movement_camera_basis(corrected,false,user_look).is_equal_approx(corrected)
	return checks

static func camera_owner_checks(world: Node3D, move := "dive") -> Dictionary:
	var boss: Node = world.veyne_encounter
	if not boss.combat_allowed(): return {"ready":false}
	var p: Node3D = world.player
	var old_rotation: Vector3 = p.arm.rotation
	var old_distance: float = p.free_camera_distance
	var old_shoulder: float = p.shoulder_side
	var preferences: Dictionary = world.dialogue_state.preference_snapshot()
	var old_player: Vector3 = p.global_position
	var old_actor: Vector3 = boss.actor.global_position
	boss.actor.interrupt_action()
	# Component setup on existing authored support, separate from ordinary
	# stair/evasion evidence. A stair-edge target has no valid dive landing.
	world.ground_policy.place(world,p,Vector2(-4,-22))
	world.ground_policy.place(world,boss.actor,Vector2(-4,-25))
	var started: bool = boss.actor.dragon_actions.begin(move)
	p._update_archery(0.016)
	p.arm.notification(Node.NOTIFICATION_INTERNAL_PHYSICS_PROCESS)
	var checks := {"started":started,"player_owns_framing":p.encounter_camera_active,"child_rotation_neutral":p.camera.rotation.is_zero_approx(),"mouse_orientation_preserved":p.encounter_camera_look.is_equal_approx(old_rotation),"native_collision_active":p.arm.collision_mask!=0 and p.arm.get_hit_length()<=p.arm.spring_length,"distance_preference_preserved":p.free_camera_distance==old_distance,"shoulder_preserved":p.shoulder_side==old_shoulder,"preferences_preserved":preferences==world.dialogue_state.preference_snapshot()}
	checks.corrective_orbit_keeps_controls = p.movement_camera_basis(p.camera.global_basis,p.encounter_camera_active,p.encounter_camera_look).is_equal_approx(Basis(Vector3.UP,old_rotation.y))
	if move == "charge":
		var action: Node3D = boss.actor.dragon_actions
		var danger: Array[Vector3] = boss.flight_camera_danger_targets()
		checks.committed_lane_has_depth_and_escape = danger.size() == 9 and danger[0].distance_to(danger[-1]) > action.charge_length
		for side in [-1.0,1.0]:
			p.shoulder_side = side
			p.shoulder_blend = side
			p._update_archery(0.016)
			var viewport_size: Vector2 = p.get_viewport().get_visible_rect().size
			var aspect: float = viewport_size.x/viewport_size.y
			checks[str(side)+"_charge_subjects_fit"] = p.subject_camera_points_fit(boss.flight_camera_subjects(),p.camera.global_position,p.camera.global_basis,p.camera.fov,aspect)
			checks[str(side)+"_charge_player_unobscured"] = true
			for height in [0.2,1.0,1.8]:
				var target: Vector3 = p.global_position+Vector3.UP*height
				checks[str(side)+"_charge_player_unobscured"] = checks[str(side)+"_charge_player_unobscured"] and not p.subject_camera_occluded(p.camera.global_position,target,boss.flight_camera_occluders())
		p.shoulder_side = old_shoulder
		p.shoulder_blend = old_shoulder
	boss.actor.dragon_actions.tick(0.5)
	p._update_archery(0.016)
	checks.tracked_body_does_not_collapse_sweep = p.arm.get_hit_length() >= p.arm.spring_length-0.01 and p.encounter_camera_exclusion==boss.actor.get_rid()
	p.aim_requested = true
	p._update_archery(0.016)
	checks.explicit_aim_retained = not p.encounter_camera_active
	p.aim_requested = false
	p.aim_blend = 0
	p._update_archery(0.016)
	boss.actor.interrupt_action()
	p._update_archery(0.016)
	checks.interruption_releases = not p.encounter_camera_active and p.camera.rotation.is_zero_approx() and is_equal_approx(p.arm.spring_length,p.smooth_camera_distance)
	checks.look_restored = p.arm.rotation.is_equal_approx(old_rotation)
	checks.tracked_body_filter_released = not p.encounter_camera_exclusion.is_valid()
	p.prepare_restored_camera(old_rotation.y)
	checks.restored_camera_neutral = not p.encounter_camera_active and p.camera.rotation.is_zero_approx() and is_equal_approx(p.arm.rotation.y,old_rotation.y)
	p.global_position = old_player
	boss.actor.global_position = old_actor
	return checks

static func state_checks() -> Dictionary:
	var state: Node = CIRCUIT.prepared()
	var checks := {"before_ln02_rejected":not state.defeat_veyne() and not state.take_veyne_key()}
	state.reveal_ln02(); state.cut_ln02_supply("north"); state.cut_ln02_supply("south"); state.purify_ln02()
	var old: Dictionary = state.training_snapshot().duplicate(true)
	checks.independent_of_warden = state.defeat_veyne() and not state.warden_defeated
	checks.once_only_defeat = not state.defeat_veyne()
	checks.victory_not_key = not state.veyne_release_key
	checks.key_once_only = state.take_veyne_key() and not state.take_veyne_key()
	var config: ConfigFile = HISTORY.history(state)
	checks.save_valid = state.config_unavailable_reason(config)==""
	var restored: Node = STATE.new()
	restored.restore_config(config)
	checks.new_facts_restored = restored.veyne_defeated and restored.veyne_release_key and not restored.warden_defeated
	config.erase_section_key("post_bow","veyne_defeated")
	config.erase_section_key("post_bow","veyne_release_key")
	checks.old_save_compatible = state.config_unavailable_reason(config)==""
	restored.restore_config(config)
	checks.old_save_defaults = not restored.veyne_defeated and not restored.veyne_release_key
	config.set_value("post_bow","veyne_release_key",true)
	checks.key_without_defeat_rejected = state.config_unavailable_reason(config)!=""
	config.set_value("post_bow","veyne_release_key",false)
	config.set_value("post_bow","veyne_defeated",true)
	config.set_value("post_bow","ln02_purified",false)
	checks.defeat_without_ln02_rejected = state.config_unavailable_reason(config)!=""
	state.restore_adventure(old)
	checks.rollback_clears_new_facts = not state.veyne_defeated and not state.veyne_release_key
	state.defeat_warden(); state.inspect_warden_device()
	checks.warden_first_allowed = state.defeat_veyne() and state.warden_defeated and state.warden_lock_released and state.emergency_release_tool
	restored.free(); state.free()
	return checks

static func binding_checks(actor: Node) -> Dictionary:
	var checks := {}
	checks.rig_present = actor.character.skeleton.get_bone_count()>10
	checks.skinned_mesh_present = actor.model.find_children("*","MeshInstance3D",true,false).any(func(mesh): return mesh.skin!=null)
	checks.contact_socket_present = actor.character.skeleton.find_bone(actor.character.contact_socket.bone_name)>=0
	for alias in ["Idle","Walk","Punch","HitReact","Death","Cast","Reveal","Charge","Takeoff","Flight","Dive","Land"]:
		checks[alias+"_bound"] = actor.animator.has_animation(alias) or actor.animator.has_animation("veyne/"+alias)
	return checks

static func transaction_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.veyne_encounter
	if not boss.combat_allowed(): return {"ready":false,"reason":"prepared active fight required"}
	var snapshot: Dictionary = world.dialogue_state.adventure_snapshot()
	var source := SnaielDamageSource.new()
	source.entity = world.player
	source.can_damage = true
	source.damage_attributes.health = 500
	source.instance = 900
	world.dialogue_state.fail_save_after = 0
	var result: Dictionary = boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	var checks := {"lethal_contact":result.get("outcome","")=="defeat","failed_save_rolls_back":not world.dialogue_state.veyne_defeated and boss.victory_pending,"damage_closed":not boss.actor.source.can_damage and not boss.actor.beam_effect.active}
	checks.failed_save_no_defeat_beat = not boss.defeat_scene.active
	boss.settle_defeat()
	checks.commit_once = world.dialogue_state.veyne_defeated and boss.victory_commits==1 and not boss.victory_pending
	checks.new_commit_beat = boss.defeat_scene.active
	boss.settle_defeat()
	checks.repeat_settlement_no_restart = boss.defeat_scene.consumed_commit == 1 and boss.victory_commits == 1
	checks.key_separate = not world.dialogue_state.veyne_release_key
	checks.wave_cleared = boss.reinforcements.units.is_empty()
	checks.key_blocked_during_beat = boss.device.interaction_prompt() == ""
	boss.defeat_scene.finish()
	checks.key_approach_supported = world.ground_policy.place(world,world.player,boss.ARENA.KEY+Vector2(0,1.6))
	checks.key_prompt_available = boss.device.interaction_prompt()!=""
	world.dialogue_state.fail_save_after = 0
	boss.device.interact()
	checks.key_failed_save_rolls_back = not world.dialogue_state.veyne_release_key
	boss.device.interact()
	checks.key_commit_once = world.dialogue_state.veyne_release_key and boss.device.inspections==1
	boss.device.interact()
	checks.key_no_repeat = boss.device.inspections==1
	var committed: ConfigFile = world.dialogue_state.histories[0]
	checks.committed_valid = world.dialogue_state.config_unavailable_reason(committed)==""
	world.dialogue_state.restore_config(committed)
	boss.restore_history()
	checks.restore_defeat_key = boss.actor.health==0 and world.dialogue_state.veyne_release_key and not boss.music.playing
	world.dialogue_state.restore_adventure(snapshot)
	boss.restore_history()
	source.free()
	return checks

static func phase_checks(world: Node3D, suppression_expected := false) -> Dictionary:
	var boss: Node = world.veyne_encounter
	if not boss.combat_allowed(): return {"ready":false}
	var source := SnaielDamageSource.new()
	source.entity = world.player
	source.can_damage = true
	source.damage_attributes.health = 210
	source.instance = 800
	boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	var checks := {"threshold_no_heal":boss.actor.health==210 and boss.phase=="phase_transition" and boss.phase_starts==1,"damage_suspended":not boss.combat_allowed()}
	source.instance += 1
	var result: Dictionary = boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	checks.transition_contact_rejected = not result.get("accepted",false) and boss.actor.health==210
	boss.finish_presentation()
	if suppression_expected:
		checks.explicit_node_suppresses_wave = world.dialogue_state.veyne_node_closed and boss.reinforcements.wave_count==0 and boss.reinforcements.units.is_empty()
	else:
		checks.one_two_melee_wave = boss.reinforcements.wave_count==1 and boss.reinforcements.units.size()==2
	boss.begin_second_phase()
	checks.phase_once = boss.phase_starts==1 and boss.actor.health==210 and boss.reinforcements.wave_count==(0 if suppression_expected else 1)
	boss.spawn_rifts()
	checks.rifts_warn_before_active = boss.rifts.size()==2 and not boss.rifts[0].source.can_damage
	var saved_warden: bool = world.dialogue_state.warden_defeated
	world.training.last_hp_loss = world.dialogue_state.health
	world.dialogue_state.health = 0
	var lives: int = world.dialogue_state.lives
	world.training.settle_death()
	checks.life_once = world.dialogue_state.lives==lives-1
	world.training.settle_death()
	checks.life_not_repeat = world.dialogue_state.lives==lives-1
	world.training.recover_at_checkpoint()
	checks.retry_reset = boss.actor.health==420 and not boss.actor.pressure_phase and boss.phase=="waiting" and boss.reinforcements.wave_count==0 and boss.reinforcements.units.is_empty() and boss.rifts.is_empty() and not boss.actor.beam_effect.active
	checks.node_closure_preserved = not suppression_expected or world.dialogue_state.veyne_node_closed
	checks.warden_preserved = world.dialogue_state.warden_defeated==saved_warden
	checks.cp03_position = Vector2(world.player.global_position.x,world.player.global_position.z).distance_to(world.checkpoint_xz())<0.1
	checks.ownership_released = world.pause_owners.is_empty() and world.player.camera.current and not boss.music.playing
	source.free()
	return checks

static func beam_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.veyne_encounter
	if not boss.combat_allowed(): return {"ready":false}
	var effect: Node = boss.actor.beam_effect
	var hp: float = world.dialogue_state.health
	var old_pos: Vector3 = world.player.global_position
	boss.actor.interrupt_action()
	world.training.protection = 0; world.training.hurt_time = 0
	world.training.parry_window = 0.25; world.training.blocking = true
	world.player.visual.rotation.y = PI
	world.ground_policy.place(world,world.player,Vector2(-4,-20))
	await world.get_tree().create_timer(0.1,false,true).timeout
	var mouth: Vector3 = boss.actor.character.casting_position()
	var lane_point: Vector3 = world.player.global_position+Vector3.UP
	effect.prepare(mouth,mouth.direction_to(lane_point))
	effect.effect(700)
	var hit: Dictionary = effect.sample_contact()
	var checks := {"physical_hit":hit.get("accepted",false) and hit.get("outcome","")=="hurt" and world.dialogue_state.health<hp,"beam_not_parried":hit.get("outcome","")!="parry" and effect.active}
	var after: float = world.dialogue_state.health
	effect.sample_contact()
	checks.single_instance = world.dialogue_state.health==after
	effect.end()
	world.training.blocking = false; world.training.parry_window = 0
	world.dialogue_state.health = hp; world.training.hurt_time = 0; world.training.protection = 0
	world.ground_policy.place(world,world.player,Vector2(-7,-20))
	await world.get_tree().create_timer(0.1,false,true).timeout
	effect.prepare(mouth,mouth.direction_to(lane_point)); effect.effect(701)
	checks.lateral_miss = effect.sample_contact().is_empty() and world.dialogue_state.health==hp
	effect.end()
	world.ground_policy.place(world,world.player,Vector2(-4,-20))
	var wall := StaticBody3D.new()
	world.add_child(wall)
	wall.global_position = mouth.lerp(lane_point,0.5)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(4,4,0.3)
	shape.shape = box; wall.add_child(shape)
	await world.get_tree().create_timer(0.1,false,true).timeout
	effect.prepare(mouth,mouth.direction_to(lane_point)); effect.effect(702)
	checks.solid_obstruction = effect.blocked and effect.clipped_length<6.0 and effect.sample_contact().is_empty() and world.dialogue_state.health==hp
	effect.end(); wall.queue_free()
	world.player.global_position = old_pos
	world.player.visual.rotation.y = 0
	world.training.hurt_time = 0; world.training.phase = "idle"
	return checks

static func rift_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.veyne_encounter
	if not boss.combat_allowed() or not boss.actor.pressure_phase: return {"ready":false}
	world.training.protection = 0
	world.training.hurt_time = 0
	world.training.blocking = false
	var hp: float = world.dialogue_state.health
	boss.spawn_rifts()
	boss.update_rifts(0.8)
	var checks := {"warning_no_damage":world.dialogue_state.health==hp}
	boss.update_rifts(0.5)
	checks.active_inside_damage = world.dialogue_state.health==hp-12 and boss.rift_contacts>0
	var after: float = world.dialogue_state.health
	boss.update_rifts(0.01)
	checks.once_per_rift = world.dialogue_state.health==after
	boss.clear_rifts()
	checks.cleanup_closes_danger = boss.rifts.is_empty()
	return checks

static func dragon_case(world: Node3D, scenario: String) -> Dictionary:
	# Real physics frames and real contact owners, isolated from durable saves.
	var boss: Node = world.veyne_encounter
	var actor: CharacterBody3D = boss.actor
	var action: Node3D = actor.dragon_actions
	var physics_enabled := actor.is_physics_processing()
	actor.set_physics_process(false)
	actor.interrupt_action()
	world.training.phase = "idle"
	world.training.hurt_time = 0
	world.training.protection = 0
	world.dialogue_state.health = 100
	world.ground_policy.place(world,actor,Vector2(-4,-27))
	world.ground_policy.place(world,world.player,Vector2(-4,-21))
	var start: Vector3 = actor.global_position
	var obstacle: StaticBody3D
	if scenario.ends_with("wall") or scenario == "initial_overlap":
		obstacle = StaticBody3D.new()
		world.add_child(obstacle)
		obstacle.global_position = start+Vector3(0,3,3 if scenario != "initial_overlap" else 0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(6,6,0.5)
		shape.shape = box
		obstacle.add_child(shape)
		await world.get_tree().physics_frame
	var move := "fire_breath" if scenario.begins_with("fire") else ("dive" if scenario.begins_with("dive") or scenario == "interruption" else "charge")
	var accepted: bool = action.begin(move)
	var checks := {"started":accepted,"warning_no_damage":false,"recovery":false,"flight_clip_advanced":false}
	var before_contacts: int = action.contacts
	var warning_position: Vector3 = action.warning.global_position
	if move == "fire_breath":
		# Complete cover can remove every reachable chest-height sample. An
		# intentionally empty footprint must not be mistaken for a rectangle.
		var covered_empty: bool = scenario.ends_with("wall") and action.warning.mesh == null and action.warning_triangles == 0 and not action.wall_between(actor.character.casting_position(),world.player.global_position+Vector3.UP).is_empty()
		checks.warning_uses_contact_footprint = action.warning.material_override.get_shader_parameter("footprint") == true and (action.warning.mesh is ArrayMesh or covered_empty)
		checks.warning_world_owned = action.warning.top_level and action.warning.global_transform.is_equal_approx(Transform3D.IDENTITY)
		checks.warning_shape_not_rectangle = action.warning_triangles > 2 or covered_empty
	if move == "dive":
		checks.warning_world_owned = action.warning.top_level
		checks.warning_matches_landing = warning_position.is_equal_approx(action.landing+Vector3.UP*0.05) and action.warning.scale.x==6.0 and action.warning.scale.y==6.0
		checks.warning_stationary_in_flight = true
		checks.warning_visible_until_impact = true
	if scenario == "initial_overlap":
		checks.initial_overlap_rejected = not action.travel(Vector3.BACK*0.2) and actor.global_position.is_equal_approx(start)
		checks.warning_no_damage = world.dialogue_state.health==100 and not action.source.can_damage
	else:
		for frame in 370:
			await world.get_tree().physics_frame
			action.tick(1.0/60.0)
			if move == "dive" and action.stage in ["warning","flight","active"]:
				checks.warning_stationary_in_flight = checks.warning_stationary_in_flight and action.warning.global_position.is_equal_approx(warning_position)
				checks.warning_visible_until_impact = checks.warning_visible_until_impact and action.warning.visible
			if frame == 15: checks.warning_no_damage = world.dialogue_state.health == 100 and not action.source.can_damage
			if frame == 30 and scenario.ends_with("evade"):
				world.ground_policy.place(world,world.player,Vector2(1,-21))
			if action.stage == "flight" and actor.character.current_position()>0.1:
				checks.flight_clip_advanced = actor.character.current_clip()=="veyne/Flight" and actor.global_position.y-start.y>2.0
			if scenario == "interruption" and action.stage == "flight":
				var source := SnaielDamageSource.new()
				source.entity = world.player; source.can_damage = true; source.damage_attributes.health = 6; source.instance = 980
				var hit: Dictionary = actor.receive_contact(source,actor.global_position+Vector3.UP)
				checks.hurt_interrupts = hit.get("accepted",false) and action.kind=="" and not action.source.can_damage and not action.warning.visible and not action.breath.visible and action.effects.records.is_empty()
				source.free(); break
			if move == "fire_breath" and action.stage == "active":
				checks.core_envelope_share_geometry = action.breath.mesh == action.breath_core.mesh and action.breath_core.visible and action.breath_core.material_override.get_shader_parameter("core_layer") == true
				checks.local_mouth_origin = action.breath.global_position.is_equal_approx(actor.character.casting_position())
			if action.stage == "recovery":
				checks.recovery = not action.source.can_damage and not action.warning.visible and not action.breath.visible
				break
	checks.hp = world.dialogue_state.health
	checks.contacts = action.contacts-before_contacts
	checks.displacement = actor.global_position.distance_to(start)
	if scenario.ends_with("hit"):
		checks.real_single_hit = checks.hp==76 and checks.contacts==1
	elif scenario.ends_with("evade") or scenario.ends_with("wall"):
		checks.no_false_hit = checks.hp==100 and checks.contacts==0
	if scenario.begins_with("charge"):
		checks.real_travel = checks.displacement>(0.1 if scenario.ends_with("wall") else 1.0)
	if scenario.ends_with("wall"):
		checks.solid_blocks = action.stopped_by_wall if move == "charge" else not action.wall_between(actor.character.casting_position(),world.player.global_position+Vector3.UP).is_empty()
	if scenario.begins_with("dive"):
		var support: Dictionary = world.ground_policy.support(world,Vector2(actor.global_position.x,actor.global_position.z),[actor.get_rid()])
		checks.grounded_landing = not support.is_empty() and absf(actor.global_position.y-support.position.y-0.08)<0.15
	var elapsed: float = action.elapsed
	var position: Vector3 = actor.global_position
	var warning_transform: Transform3D = action.warning.global_transform
	var warning_progress = action.warning.material_override.get_shader_parameter("progress")
	world._set_pause_owner("dragon_case",true)
	action.tick(0.5)
	checks.pause_preserves_stage = action.elapsed==elapsed and actor.global_position==position
	checks.pause_preserves_warning = action.warning.global_transform==warning_transform and action.warning.material_override.get_shader_parameter("progress")==warning_progress
	var before_menu: Dictionary = action._mcp_state()
	boss.set_menu_paused(true)
	checks.menu_preserves_attack_instance = action._mcp_state()==before_menu
	boss.set_menu_paused(false)
	world._set_pause_owner("dragon_case",false)
	actor.interrupt_action()
	checks.interruption_cleanup = action.kind=="" and not action.source.can_damage and action.effects.records.is_empty() and not action.breath_core.visible
	if obstacle: obstacle.queue_free()
	world.dialogue_state.health = 100
	world.training.hurt_time = 0; world.training.protection = 0; world.training.phase = "idle"
	world.ground_policy.place(world,actor,Vector2(-4,-25))
	actor.set_physics_process(physics_enabled)
	return checks

static func arena_checks(world: Node3D) -> Dictionary:
	var arena: Node3D = world.get_node("TombEnvironment/VeyneArena")
	var checks := {"contaminated_shell_retired":not arena.has_node("RitualRuin"),"route_supported":true,"perimeter_supported":true,"perimeter_textured":true,"perimeter_normals_uv":true}
	var excludes: Array[RID] = []
	for body in world.find_children("*","CollisionObject3D",true,false):
		if not world.village.is_ancestor_of(body): excludes.append(body.get_rid())
	# Stair treads, entrance, both escape lanes, landing/key, and adjacent LN02.
	for point in [Vector2(-4,-11),Vector2(-4,-15),Vector2(-4,-17.3),Vector2(-10,-23),Vector2(2,-23),Vector2(-4,-30),Vector2(-4,-33),Vector2(-4,-5)]:
		checks.route_supported = checks.route_supported and not world.ground_policy.support(world,point,excludes).is_empty()
	var walls := 0
	for mesh in arena.get_children():
		if not mesh is MeshInstance3D or not str(mesh.name).begins_with("RitualStoneWall"): continue
		walls += 1
		checks.perimeter_supported = checks.perimeter_supported and mesh.has_meta("arena_collision_bound")
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			checks.perimeter_normals_uv = checks.perimeter_normals_uv and arrays[Mesh.ARRAY_NORMAL]!=null and not arrays[Mesh.ARRAY_NORMAL].is_empty() and arrays[Mesh.ARRAY_TEX_UV]!=null and not arrays[Mesh.ARRAY_TEX_UV].is_empty()
			var material = mesh.get_active_material(surface)
			checks.perimeter_textured = checks.perimeter_textured and material is StandardMaterial3D and material.albedo_texture!=null and material.normal_texture!=null and material.roughness>0.8
	checks.connected_wall_modules = walls==14
	return checks
