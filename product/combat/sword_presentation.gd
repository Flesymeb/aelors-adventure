extends Node3D
## One weapon-bound presentation. Snaiel remains the attack/contact authority.
const STREAK := preload("res://combat/cats/mesh_streak.gd")
var training: Node
var streak: MeshInstance3D
var blade_edge: MeshInstance3D

func configure(owner_training: Node) -> void:
	training = owner_training
	streak = STREAK.new()
	streak.name = "BladeTrail"
	streak.origin_node = training.player.sword_holder
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/sword_trail.gdshader")
	streak.material_override = material
	add_child(streak)
	# Sword_Bronze's authored +Y blade ends at .924 + its .05 grip offset.
	# A narrow light edge follows the same hand socket, never a player-origin arc.
	blade_edge = MeshInstance3D.new()
	blade_edge.name = "BladeLightEdge"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.005
	cylinder.height = 0.66
	cylinder.radial_segments = 6
	blade_edge.mesh = cylinder
	blade_edge.position = Vector3(0.005, 0.63, 0)
	var edge_material := StandardMaterial3D.new()
	edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_material.albedo_color = Color(1.0, 0.92, 0.69)
	blade_edge.material_override = edge_material
	blade_edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blade_edge.visible = false
	training.player.sword_holder.add_child(blade_edge)

func attack_stage(stage: String) -> void:
	if not streak: return
	if stage == "anticipation": clear_presentation()
	elif stage == "contact": streak.set_emitting(not training.state.reduced_motion)
	elif stage == "recovery": streak.set_emitting(false)

func clear_presentation() -> void:
	if streak: streak.clear_streak()
	if blade_edge: blade_edge.visible = false

func _process(delta: float) -> void:
	if not training or not streak: return
	var equipped: bool = training.player.sword_holder.is_visible_in_tree()
	if not equipped or training.phase in ["idle", "death", "landing_recovery", "air_recovery"]:
		clear_presentation()
		return
	# Reduced Motion preserves the brief essential blade edge, without a ribbon.
	if training.state.reduced_motion: streak.clear_streak()
	streak.maximum_edges = 7 if training.state.graphics_quality == "low" else 14
	streak.sample(delta)
	blade_edge.visible = training.phase == "contact"

func _exit_tree() -> void:
	if is_instance_valid(blade_edge): blade_edge.queue_free()
