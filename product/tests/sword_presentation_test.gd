extends Node
## Disposable geometry/lifecycle check; never attached to the shipped entry.
var observations: Dictionary = {}

class PresentationState extends Node:
	var reduced_motion := false
	var graphics_quality := "high"

class PresentationPlayer extends Node3D:
	var sword_holder: Node3D

class PresentationTraining extends Node3D:
	var player: Node3D
	var state: Node
	var combo := 0
	var phase := "contact"

func _ready() -> void:
	observations = run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture": true, "observations": observations}

static func run(holder: Node) -> Dictionary:
	var blade := Node3D.new()
	holder.add_child(blade)
	var trail := preload("res://combat/cats/mesh_streak.gd").new()
	trail.origin_node = blade
	holder.add_child(trail)
	trail.set_emitting(true)
	trail.sample(0.0)
	blade.position.x = 0.15
	trail.sample(0.016)
	var points_follow_blade: bool = trail.mesh_array.size() == 2 and trail.mesh_array.back().top.is_equal_approx(blade.to_global(trail.streak_top))
	var mesh_follows_blade: bool = trail.mesh != null and trail.mesh.get_surface_count() == 1
	var count: int = trail.mesh_array.size()
	trail.sample(0.0)
	var frozen_pose_no_duplicates: bool = trail.mesh_array.size() == count
	trail.set_emitting(false)
	trail.sample(0.12)
	var recovery_expires: bool = trail.mesh == null and trail.mesh_array.is_empty()
	trail.set_emitting(true)
	trail.sample(0.0)
	blade.position.x += 0.1
	trail.sample(0.016)
	trail.clear_streak()
	trail.sample(0.0)
	var interruption_clears: bool = not trail.emitting and trail.mesh == null and trail.mesh_array.is_empty()
	trail.set_emitting(true)
	for index in 40:
		blade.position.x += 0.02
		trail.sample(0.001)
	var bounded_edges: bool = trail.mesh_array.size() <= trail.maximum_edges
	blade.position.x += 10.0
	trail.sample(0.001)
	var teleport_no_bridge: bool = trail.mesh_array.size() == 1 and trail.mesh == null
	var result := {"checks": {"world_blade_endpoints": points_follow_blade, "ribbon_mesh": mesh_follows_blade,
		"frozen_pose_no_duplicates": frozen_pose_no_duplicates, "recovery_expires": recovery_expires,
		"interruption_clears": interruption_clears, "bounded_edges": bounded_edges, "teleport_no_bridge": teleport_no_bridge},
		"scope": "geometry and lifecycle only; ordinary clips, contact identity, low-quality appearance and normal-speed readability require native observation"}
	result.checks.merge(_material_checks(holder))
	trail.free()
	blade.free()
	return result

static func _material_checks(holder: Node) -> Dictionary:
	var training := PresentationTraining.new()
	training.player = PresentationPlayer.new()
	training.state = PresentationState.new()
	training.add_child(training.player)
	training.add_child(training.state)
	training.player.sword_holder = Node3D.new()
	training.player.add_child(training.player.sword_holder)
	var sword := (load("res://Weapons/Sword_Bronze.gltf") as PackedScene).instantiate()
	preload("res://actors/mesh_qualification.gd").qualify_tree(sword, true)
	training.player.sword_holder.add_child(sword)
	var mesh: MeshInstance3D = sword.find_children("*", "MeshInstance3D", true, false)[0]
	var authored: StandardMaterial3D = mesh.mesh.surface_get_material(0)
	var original_override := authored.duplicate() as StandardMaterial3D
	mesh.set_surface_override_material(0, original_override)
	var original_next_pass := original_override.next_pass
	holder.add_child(training)
	var presentation := preload("res://combat/sword_presentation.gd").new()
	training.add_child(presentation)
	presentation.configure(training)
	var no_replacement_geometry: bool = training.player.sword_holder.get_child_count() == 1 and presentation.blade_bindings.size() == 1
	presentation.attack_stage("contact")
	var active := mesh.get_surface_override_material(0) as StandardMaterial3D
	var material_isolated: bool = active != original_override and active.next_pass is ShaderMaterial and original_override.next_pass == original_next_pass
	var textures_preserved: bool = active.albedo_texture == authored.albedo_texture and active.normal_texture == authored.normal_texture and active.roughness_texture == authored.roughness_texture and active.normal_enabled == authored.normal_enabled
	var first_strength: float = presentation.trail_material.get_shader_parameter("stage_strength")
	training.combo = 2
	presentation.attack_stage("contact")
	var third_strength: float = presentation.trail_material.get_shader_parameter("stage_strength")
	training.combo = 4
	presentation.attack_stage("contact")
	var finisher_strength: float = presentation.trail_material.get_shader_parameter("stage_strength")
	var stage_emphasis: bool = first_strength < third_strength and third_strength < finisher_strength and presentation.stage_profile(0).tint != presentation.stage_profile(1).tint
	presentation.attack_stage("recovery")
	var recovery_restores: bool = mesh.get_surface_override_material(0) == original_override and not presentation.streak.emitting
	training.state.reduced_motion = true
	training.state.graphics_quality = "low"
	presentation.attack_stage("contact")
	presentation._process(0.016)
	var reduced_motion: bool = not presentation.streak.emitting and presentation.streak.mesh == null and presentation.emphasis_active and presentation.streak.maximum_edges == 7
	training.player.sword_holder.visible = false
	presentation._process(0.016)
	var stow_clears: bool = mesh.get_surface_override_material(0) == original_override and presentation.streak.mesh_array.is_empty()
	training.player.sword_holder.visible = true
	presentation.attack_stage("contact")
	presentation.clear_presentation()
	var interruption_restores: bool = mesh.get_surface_override_material(0) == original_override and not presentation.emphasis_active
	presentation.attack_stage("contact")
	presentation.free()
	var exit_restores: bool = mesh.get_surface_override_material(0) == original_override and original_override.next_pass == original_next_pass
	training.free()
	return {"actual_blade_no_cylinder": no_replacement_geometry, "per_instance_material_isolation": material_isolated,
		"trim_normal_textures_preserved": textures_preserved, "strong_stage_emphasis": stage_emphasis,
		"recovery_restores_material": recovery_restores, "reduced_motion_low_quality": reduced_motion,
		"stow_clears_material_history": stow_clears, "interruption_restores_material": interruption_restores,
		"exit_restores_material": exit_restores}
