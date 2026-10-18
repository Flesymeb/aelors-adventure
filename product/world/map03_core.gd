extends Node3D
## Ordinary old-lamp switch. The existing state/save owner commits every fact.
const SWITCH = preload("res://interaction/nodragem/short_interaction_switch.gd")
var world: Node3D
var state: Node
var core_switch: ShortSwitch
var light: OmniLight3D
var rift: MeshInstance3D
var closing := 0.0
var grounded := false
var last_result := ""

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	process_mode = Node.PROCESS_MODE_PAUSABLE
	core_switch = SWITCH.new()
	add_child(core_switch)
	core_switch.activation_signal.connect(_activated)
	# The existing altar/key device supplies authored geometry and support.
	light = OmniLight3D.new()
	light.position.y = 1.4
	light.light_color = Color(0.42,0.23,1.0)
	light.omni_range = 4
	add_child(light)
	rift = preload("res://assets/bosses/veyne_effects.tscn").instantiate()
	rift.name = "SummoningSeal"
	rift.material_override = rift.material_override.duplicate()
	rift.material_override.set_shader_parameter("radial",1.0)
	rift.material_override.set_shader_parameter("warning_color",Color(0.65,0.24,1.0,0.8))
	rift.rotation = Vector3.ZERO
	rift.position.y = 1.8
	rift.scale = Vector3(2.3,2.3,1)
	add_child(rift)
	restore_history()

func restore_history() -> void:
	core_switch.set_block_signals(true)
	core_switch.is_activated = state.core_closed
	core_switch.set_block_signals(false)
	light.light_energy = 0.0 if state.core_closed else 1.7
	if is_instance_valid(rift): rift.visible = not state.core_closed

func reachable() -> bool:
	if not is_instance_valid(world.veyne_encounter.device) or not world.veyne_encounter.grounded: return false
	global_position = world.veyne_encounter.device.global_position
	grounded = true
	if not world.travel_safe() or state.health <= 0 or state.recovery_pending: return false
	if world.player.global_position.distance_to(global_position) > 2.4: return false
	var ray := PhysicsRayQueryParameters3D.create(world.player.global_position+Vector3.UP,global_position+Vector3.UP,1,[world.player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or world.veyne_encounter.device.is_ancestor_of(hit.collider)

func interaction_prompt() -> String:
	if closing > 0 or not state.rescue_assembled or not reachable(): return ""
	return "[E] 沿安全通道回村" if state.core_closed else "[E] 用旧灯关闭召唤核心"

func interact() -> bool:
	if closing > 0 or not reachable(): return false
	if state.core_closed:
		world.entry_router.travel_home()
		return true
	state.selected_equipment = world.player.weapon_mode
	var missing: Array = state.core_missing_conditions()
	if not missing.is_empty():
		world.training.tell("奥伦：关闭核心还需要："+"、".join(missing),7)
		return true
	core_switch.on_interaction(true)
	return true

func _activated(active: bool) -> void:
	if active: close_core()

func close_core() -> bool:
	if not reachable() or world.player.weapon_mode != "lamp": return false
	var previous: Dictionary = state.adventure_snapshot()
	state.selected_equipment = world.player.weapon_mode
	if not state.close_summoning_core(): restore_history(); return false
	if state.save_progress(world.player.global_position,world.player.arm.rotation.y) != OK:
		state.restore_adventure(previous)
		restore_history()
		last_result = "保存失败 · 核心尚未关闭，请再次用旧灯操作。"
		world.training.tell(last_result,7)
		return false
	restore_history()
	closing = 0.9
	if is_instance_valid(rift): rift.show()
	world.veyne_encounter.clear_rifts()
	world.menu_audio.play_cue("confirm")
	world.gameplay_hud.restore_view()
	last_result = "奥伦：供能熄灭了。四个人都在，让我们沿灵光通道回家。"
	world.training.tell(last_result,8)
	return true

func _process(delta: float) -> void:
	if not is_instance_valid(world) or not is_instance_valid(world.veyne_encounter.device) or not world.veyne_encounter.grounded: return
	global_position = world.veyne_encounter.device.global_position
	grounded = true
	if closing > 0:
		closing = maxf(0,closing-delta)
		if is_instance_valid(rift):
			rift.scale = Vector3(2.3,2.3,1)*maxf(0.001,closing/0.9)
			rift.visible = closing > 0
		light.light_energy = closing

func _mcp_state() -> Dictionary:
	return {"closed":state.core_closed,"homecoming_completed":state.homecoming_completed,"grounded":grounded,"last_result":last_result,"light_energy":light.light_energy}
