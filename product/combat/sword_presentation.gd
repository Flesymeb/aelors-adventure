extends Node3D
## One weapon-bound presentation. Snaiel remains the attack/contact authority.
const STREAK := preload("res://combat/cats/mesh_streak.gd")
const TRAIL_SHADER := preload("res://assets/shaders/sword_trail.gdshader")
var training: Node
var streak: MeshInstance3D
var blade_bindings: Array[Dictionary] = []
var trail_material: ShaderMaterial
var emphasis_active := false

func configure(owner_training: Node) -> void:
	training = owner_training
	streak = STREAK.new()
	streak.name = "BladeTrail"
	streak.origin_node = training.player.sword_holder
	trail_material = ShaderMaterial.new()
	trail_material.shader = TRAIL_SHADER
	streak.material_override = trail_material
	add_child(streak)
	# Emphasize the actual repaired sword surfaces, retaining their authored
	# textured/normal-mapped base pass. Neither shared resources nor the stowed
	# instance receive an override, and no substitute edge geometry is created.
	for instance in training.player.sword_holder.find_children("*", "MeshInstance3D", true, false):
		if instance.mesh == null: continue
		for surface in instance.mesh.get_surface_count():
			var source: Material = instance.get_active_material(surface)
			if source == null: continue
			var local: Material = source.duplicate()
			var overlay := ShaderMaterial.new()
			overlay.shader = TRAIL_SHADER
			overlay.set_shader_parameter("blade_overlay", true)
			overlay.next_pass = source.next_pass
			local.next_pass = overlay
			blade_bindings.append({"instance": instance, "surface": surface,
				"original": instance.get_surface_override_material(surface),
				"material": local, "overlay": overlay})

func attack_stage(stage: String) -> void:
	if not streak: return
	if stage == "anticipation":
		clear_presentation()
	elif stage == "contact":
		_apply_stage_profile()
		_set_blade_emphasis(true)
		streak.set_emitting(not training.state.reduced_motion)
	elif stage == "recovery":
		streak.set_emitting(false)
		_set_blade_emphasis(false)

func _apply_stage_profile() -> void:
	# Existing A/B/C, aerial and legal finisher timelines retain their motion
	# and timing. Direction comes only from the blade's real sampled endpoints.
	var profile := stage_profile(int(training.combo))
	trail_material.set_shader_parameter("stage_tint", profile.tint)
	trail_material.set_shader_parameter("stage_strength", profile.strength)
	streak.lifetime = profile.lifetime
	for binding in blade_bindings:
		binding.overlay.set_shader_parameter("stage_tint", profile.tint)
		binding.overlay.set_shader_parameter("stage_strength", profile.strength)

static func stage_profile(combo: int) -> Dictionary:
	match combo:
		1: return {"tint": Vector3(0.79, 0.86, 0.74), "strength": 0.8, "lifetime": 0.095}
		2: return {"tint": Vector3(1.0, 0.83, 0.49), "strength": 1.15, "lifetime": 0.12}
		3: return {"tint": Vector3(0.90, 0.88, 0.67), "strength": 1.05, "lifetime": 0.11}
		4: return {"tint": Vector3(1.0, 0.87, 0.56), "strength": 1.4, "lifetime": 0.135}
		_: return {"tint": Vector3(0.94, 0.88, 0.68), "strength": 0.72, "lifetime": 0.09}

func _set_blade_emphasis(active: bool) -> void:
	if emphasis_active == active: return
	for binding in blade_bindings:
		if is_instance_valid(binding.instance):
			binding.instance.set_surface_override_material(binding.surface, binding.material if active else binding.original)
	emphasis_active = active

func clear_presentation() -> void:
	if streak: streak.clear_streak()
	_set_blade_emphasis(false)

func _process(delta: float) -> void:
	if not training or not streak: return
	var equipped: bool = training.player.sword_holder.is_visible_in_tree()
	if not equipped or training.phase in ["idle", "death", "landing_recovery", "air_recovery"]:
		clear_presentation()
		return
	# Reduced Motion preserves the brief essential blade emphasis, without a
	# ribbon. Low quality only limits history; neither option changes combat.
	if training.state.reduced_motion: streak.clear_streak()
	streak.maximum_edges = 7 if training.state.graphics_quality == "low" else 14
	streak.sample(delta)
	_set_blade_emphasis(training.phase == "contact")

func _exit_tree() -> void:
	clear_presentation()
