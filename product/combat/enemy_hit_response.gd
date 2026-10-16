extends Node
## Presentation after a resolved contact. No HP, animation or attack ownership.
## The transparent overlay leaves authored surface materials/textures intact.
const IMPACT = preload("res://assets/shaders/skill_impact.gdshader")
const LIGHT_DURATION := 0.12
const STRONG_DURATION := 0.18
const LETHAL_DURATION := 0.16
var model: Node3D
var overlay: ShaderMaterial
var bindings: Array[Dictionary] = []
var remaining := 0.0
var duration := 0.0
var peak := 0.0
var response_kind := ""
var last_contact: Dictionary = {}

func configure(actor_model: Node3D) -> void:
	clear()
	model = actor_model
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)
	overlay = ShaderMaterial.new()
	overlay.shader = IMPACT
	overlay.set_shader_parameter("opacity", 0.0)

func resolved(result: Dictionary, attack_name := "") -> bool:
	if not result.get("accepted", false) or result.get("outcome", "") not in ["hit", "defeat"] or float(result.get("hp_loss", 0.0)) <= 0.0:
		return false
	if not is_instance_valid(model) or overlay == null: return false
	# The hitbox already deduplicates; also keep presentation idempotent if the
	# same resolved notification is inadvertently delivered twice.
	var identity := {"source_id": result.get("source_id", 0), "attack_instance": result.get("attack_instance", -1), "receiver": result.get("receiver", "")}
	if identity == last_contact: return false
	last_contact = identity
	_restore_bindings()
	var lethal: bool = result.outcome == "defeat"
	var strong := attack_name.contains("Finisher") or attack_name.contains("Heavy") or attack_name.ends_with("Sword_Regular_C")
	response_kind = "lethal" if lethal else ("strong" if strong else "light")
	duration = LETHAL_DURATION if lethal else (STRONG_DURATION if strong else LIGHT_DURATION)
	remaining = duration
	peak = 0.68 if lethal else (0.58 if strong else 0.38)
	overlay.set_shader_parameter("tint", Color(1.0, 0.55, 0.25) if lethal else Color(1.0, 0.80, 0.55))
	overlay.set_shader_parameter("opacity", peak)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		bindings.append({"mesh": weakref(mesh), "original": mesh.material_overlay})
		mesh.material_overlay = overlay
	set_process(true)
	return true

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	# Explicit pause guard also protects opt-in component fixture calls.
	if is_inside_tree() and get_tree().paused: return
	if remaining <= 0.0: return
	remaining = maxf(0.0, remaining - maxf(0.0, delta))
	overlay.set_shader_parameter("opacity", peak * remaining / duration)
	if remaining <= 0.0:
		_restore_bindings()
		set_process(false)

func _restore_bindings() -> void:
	for binding in bindings:
		var mesh = binding.mesh.get_ref()
		# Do not overwrite a newer presentation owner when interrupted.
		if is_instance_valid(mesh) and mesh.material_overlay == overlay:
			mesh.material_overlay = binding.original
	bindings.clear()

func clear() -> void:
	_restore_bindings()
	remaining = 0.0
	duration = 0.0
	response_kind = ""
	last_contact.clear()
	if overlay: overlay.set_shader_parameter("opacity", 0.0)
	set_process(false)

func _exit_tree() -> void:
	clear()

func observation() -> Dictionary:
	return {"active": remaining > 0.0, "remaining": remaining, "kind": response_kind, "meshes": bindings.size(), "contact": last_contact.duplicate()}
