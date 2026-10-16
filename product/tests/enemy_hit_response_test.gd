extends Node
## Opt-in fixture: actual Snaiel health/handler/hitbox, two actors sharing
## authored materials, and the production local overlay. No save/progression.
var observations: Dictionary = {}

func _ready() -> void:
	observations = run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture": true, "observations": observations}

static func run(holder: Node) -> Dictionary:
	# Registered execution may enter with its harness freeze using tree pause.
	# Run this synchronous fixture with a known simulation state, exercise a
	# real pause below, then restore the exact entry state before returning.
	# No frames/input are advanced while this fixture temporarily unpauses.
	var tree := holder.get_tree()
	var entry_paused := tree.paused
	tree.paused = false
	var stage := Node3D.new()
	holder.add_child(stage)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.22, 0.38, 0.17)
	var prior_overlay := StandardMaterial3D.new()
	var victim := make_actor(material, prior_overlay)
	var neighbor := make_actor(material, prior_overlay)
	stage.add_child(victim)
	stage.add_child(neighbor)
	var mesh: MeshInstance3D = victim.get_child(0)
	var other_mesh: MeshInstance3D = neighbor.get_child(0)
	var response = preload("res://combat/enemy_hit_response.gd").new()
	victim.add_child(response)
	response.configure(victim)
	var other_response = preload("res://combat/enemy_hit_response.gd").new()
	neighbor.add_child(other_response)
	other_response.configure(neighbor)
	var health := SnaielHealth.new()
	victim.add_child(health)
	var blackboard := SnaielBlackboard.new()
	victim.add_child(blackboard)
	var handler := SnaielHitHandler.new()
	victim.add_child(handler)
	handler.health_component = health
	handler.blackboard = blackboard
	handler.eligibility = func(): return true
	var reactions := [0]
	handler.reaction = func(_result): reactions[0] += 1
	var hitbox := SnaielHitbox.new()
	victim.add_child(hitbox)
	hitbox.entity = victim
	hitbox.policy = handler.handle_interaction
	var attack := {"name": "sword/Sword_Regular_A"}
	var notices := [0]
	hitbox.resolved.connect(func(result):
		notices[0] += 1
		response.resolved(result, attack.name))
	var source := SnaielDamageSource.new()
	neighbor.add_child(source)
	source.can_damage = true
	source.damage_attributes.health = 12.0
	var checks := {}
	var result := hitbox.contact(source, Vector3(0.2, 1.0, 0.0))
	checks.accepted_contact_follows_hp_and_hurt = health.health == 88.0 and reactions[0] == 1 and notices[0] == 1 and response.response_kind == "light" and response.last_contact.source_id == source.get_instance_id()
	checks.victim_only_preserves_surface_detail = mesh.material_overlay == response.overlay and other_mesh.material_overlay == prior_overlay and mesh.material_override == material and other_mesh.material_override == material and material.albedo_color == Color(0.22, 0.38, 0.17) and response.overlay != other_response.overlay
	var before: float = response.remaining
	checks.duplicate_notification_does_not_restart = not response.resolved(result, attack.name) and response.remaining == before
	checks.duplicate_contact_no_damage_or_reaction = hitbox.contact(source, Vector3.ZERO).is_empty() and health.health == 88.0 and reactions[0] == 1 and notices[0] == 1
	response.advance(0.04)
	checks.short_response_fades = response.remaining < before and response.overlay.get_shader_parameter("opacity") < response.peak
	response.advance(1.0)
	checks.authored_overlay_restored = mesh.material_overlay == prior_overlay and other_mesh.material_overlay == prior_overlay and response.bindings.is_empty()
	for outcome in ["miss", "obstruction", "block", "immune"]:
		checks["reject_" + outcome] = not response.resolved({"accepted": true, "outcome": outcome, "hp_loss": 12.0}) and mesh.material_overlay == prior_overlay
	checks.reject_zero_loss = not response.resolved({"accepted": true, "outcome": "hit", "hp_loss": 0.0})
	checks.reject_unaccepted = not response.resolved({"accepted": false, "outcome": "hit", "hp_loss": 12.0})
	source.instance += 1
	attack.name = "sword/Grounded_Finisher"
	source.damage_attributes.health = 28.0
	hitbox.contact(source, Vector3.ZERO)
	checks.finisher_uses_resolved_intensity = response.response_kind == "strong" and response.duration == response.STRONG_DURATION and health.health == 60.0 and reactions[0] == 2
	# Real tree pause leaves the effect lifetime and shader opacity unchanged.
	var was_paused := tree.paused
	tree.paused = true
	before = response.remaining
	var opacity = response.overlay.get_shader_parameter("opacity")
	response.advance(1.0)
	checks.pause_suspends_effect = response.remaining == before and response.overlay.get_shader_parameter("opacity") == opacity
	tree.paused = was_paused
	source.instance += 1
	source.damage_attributes.health = 1000.0
	result = hitbox.contact(source, Vector3.ZERO)
	checks.lethal_clamps_once_and_ends_briefly = result.outcome == "defeat" and result.hp_loss == 60.0 and health.health == 0.0 and response.response_kind == "lethal" and response.duration == response.LETHAL_DURATION and notices[0] == 3
	response.advance(1.0)
	checks.lethal_restores_without_gameplay_change = mesh.material_overlay == prior_overlay and health.health == 0.0 and reactions[0] == 3
	# A reset/retry/load caller uses clear(), then a fresh instance may respond.
	response.clear()
	hitbox.reset_contacts()
	health.health = 100.0
	source.instance += 1
	source.damage_attributes.health = 12.0
	hitbox.contact(source, Vector3.ZERO)
	response.clear()
	checks.reset_clears_overlay_and_identity = mesh.material_overlay == prior_overlay and response.remaining == 0.0 and response.last_contact.is_empty()
	source.instance += 1
	hitbox.contact(source, Vector3.ZERO)
	response.free()
	checks.removal_restores_live_model = mesh.material_overlay == prior_overlay and other_mesh.material_overlay == prior_overlay
	var passed := true
	for value in checks.values(): passed = passed and value
	stage.free()
	tree.paused = entry_paused
	return {"passed": passed, "checks": checks, "scope": "component isolation and resolved-contact lifecycle; ordinary camera, held audio, combo/heavy and earned progression remain independent runtime checks"}

static func make_actor(material: Material, overlay: Material) -> Node3D:
	var actor := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.material_override = material
	mesh.material_overlay = overlay
	actor.add_child(mesh)
	return actor
