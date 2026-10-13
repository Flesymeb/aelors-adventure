extends RefCounted
## Opt-in disposable simulation checks; no player saves or ordinary-entry proof.
class Settings extends Node:
	var reduced_motion := false
	var graphics_quality := "normal"
class EffectWorld extends Node3D:
	var dialogue_state: Settings
	var pause_owners := {}

static func lifecycle_checks(parent: Node) -> Dictionary:
	var checks := {}
	var world := EffectWorld.new()
	parent.add_child(world)
	world.dialogue_state = Settings.new()
	world.add_child(world.dialogue_state)
	var effects = preload("res://combat/skill_effects.gd").new()
	world.add_child(effects)
	effects.configure(world)
	var socket := Node3D.new()
	world.add_child(socket)
	socket.position = Vector3(3, 2, 1)
	var warning: int = effects.warning("lightning", socket.global_position, socket)
	socket.position.x += 2
	effects.tick(0.1)
	checks.warning_follows_live_socket = effects.records[0].node.global_position.is_equal_approx(socket.global_position)
	checks.warning_has_no_damage_owner = effects.get_children().all(func(child): return not child is CollisionObject3D)
	var before: Dictionary = effects.snapshot()
	world.pause_owners["menu"] = true
	effects.tick(0.5)
	checks.pause_suspends_visual_time = effects.snapshot() == before
	world.pause_owners.clear()
	effects.finish(warning, 0.18)
	effects.tick(0.2)
	checks.interruption_decays_warning = effects.records.is_empty()
	var beam: int = effects.line(Vector3.ZERO, Vector3(0, 0, -4), "lightning", 0.22)
	checks.active_binds_exact_endpoints = beam > 0 and effects.records[0].node.global_position.is_equal_approx(Vector3(0, 0, -2)) and effects.records[0].node.get_child(0).mesh.size.y == 4.0
	effects.tick(0.12)
	checks.active_decays = effects.records[0].stage == "decay"
	effects.tick(0.12)
	checks.travel_lifetime_bounded = effects.records.is_empty()
	effects.contact(Vector3.ONE, "fire", "obstruction", 0.0)
	checks.obstruction_not_hit = effects.records[0].stage == "obstruction" and effects.records[0].node.name == "SkillBlocked"
	effects.clear_transients()
	effects.contact(Vector3.ONE, "fire", "hit", 18.0)
	checks.resolved_hit_cue = effects.records[0].stage == "contact" and effects.records[0].node.name == "SkillContact"
	var projectile: MeshInstance3D = effects.projectile("fire", Vector3.UP)
	effects.tick(2.0)
	checks.physics_owns_projectile_lifetime = is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and effects.records.size() == 1 and not effects.records[0].managed
	world.dialogue_state.reduced_motion = true
	world.dialogue_state.graphics_quality = "low"
	effects.line(Vector3.ZERO, Vector3.UP * 4, "lightning")
	var material: ShaderMaterial = effects.records.back().material
	checks.low_quality_preserves_telegraph = material.get_shader_parameter("Octave_Count") == 1 and material.get_shader_parameter("reduced_motion") == true
	effects.tick(0.1)
	checks.reduced_motion_clock_stable = material.get_shader_parameter("effect_time") == 0.0
	var observation: Dictionary = effects.snapshot()
	checks.observation_read_only = effects.snapshot() == observation
	effects.clear_transients()
	checks.recovery_clears_all = effects.records.is_empty() and projectile.is_queued_for_deletion()
	checks.lightning_source_not_autonomous = not preload("res://assets/shaders/3d_lightning.gdshader").code.contains("TIME")
	checks.fire_source_not_autonomous = not preload("res://assets/shaders/fire_breath.gdshader").code.contains("TIME")
	world.free()
	return checks
