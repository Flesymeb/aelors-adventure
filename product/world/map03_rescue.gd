extends Node3D
## Thin Nodragem interaction adapter. No Boss, movement, reward or save authority.
const GROUND = preload("res://world/map03_ground.gd")
const SWITCH = preload("res://interaction/nodragem/short_interaction_switch.gd")
const CAST = preload("res://data/rescue_cast.json")
const SCENES = [preload("res://actors/oren_captive.tscn"),preload("res://actors/captive_villager_a.tscn"),preload("res://actors/captive_villager_b.tscn"),preload("res://actors/captive_villager_c.tscn")]
var world: Node3D
var state: Node
var captives: Dictionary = {}
var switches: Dictionary = {}
var trapped_positions: Dictionary = {}
var safe_positions: Dictionary = {}
var assembly: Node3D
var assembly_label: Label3D
var grounded := false
var selected := ""
var last_result := ""
var activation_count := 0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_cast()

func _build_cast() -> void:
	# The existing destination-ready gate keeps control locked while resources
	# are bound. Yield between complete actors instead of blocking one load frame.
	for i in state.CAPTIVE_IDS.size():
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world): return
		var id: String = state.CAPTIVE_IDS[i]
		var actor: Node3D = SCENES[i].instantiate()
		actor.name = id.capitalize()
		add_child(actor)
		captives[id] = actor
		var switch := SWITCH.new()
		switch.name = id.capitalize() + "Release"
		add_child(switch)
		switches[id] = switch
		switch.activation_signal.connect(_activated.bind(id))
	assembly = Node3D.new()
	assembly.name = "SafeAssembly"
	add_child(assembly)
	var sign: Node3D = preload("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn").instantiate()
	sign.scale *= 0.28
	assembly.add_child(sign)
	assembly_label = Label3D.new()
	assembly_label.font = preload("res://assets/dialogue/zhuque/ZhuqueFangsong-Regular.ttf")
	assembly_label.font_size = 40
	assembly_label.pixel_size = 0.003
	assembly_label.position.y = 1.8
	assembly_label.outline_size = 8
	assembly_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	assembly.add_child(assembly_label)
	var light := OmniLight3D.new()
	light.light_color = Color(0.35,0.75,1)
	light.light_energy = 0.7
	light.omni_range = 4
	light.position.y = 1.4
	assembly.add_child(light)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world): return
		var valid := GROUND.place(world,assembly,GROUND.RESCUE_ASSEMBLY)
		var probe := Node3D.new()
		add_child(probe)
		for i in state.CAPTIVE_IDS.size():
			var id: String = state.CAPTIVE_IDS[i]
			if GROUND.place(world,probe,GROUND.CAPTIVES[i]): trapped_positions[id] = probe.global_position
			else: valid = false
			if GROUND.place(world,probe,GROUND.ASSEMBLED[i]): safe_positions[id] = probe.global_position
			else: valid = false
			# Standing interaction approach is tested against authored geometry.
			valid = GROUND.place(world,probe,GROUND.CAPTIVES[i]+Vector2(1.25 if i < 2 else -1.25,0)) and valid
		probe.free()
		if not valid: continue
		grounded = true
		restore_history()
		return
	world.entry_failed.emit("营救院或集合点缺少石地支撑与可用站位，已保留上一处边界。")

func restore_history() -> void:
	if not grounded: return
	for id in captives:
		var released: bool = state.rescue_released.has(id)
		captives[id].global_position = safe_positions[id] if state.rescue_assembled else trapped_positions[id]
		captives[id].rotation.y = PI if state.rescue_assembled else 0.0
		captives[id].restore(released,state.rescue_assembled)
		switches[id].set_block_signals(true)
		switches[id].is_activated = released
		switches[id].set_block_signals(false)
	assembly_label.text = "蓝灯 · 四人已集合" if state.rescue_assembled else "蓝灯 · 安全集合点"

func available() -> bool:
	return grounded and world.travel_safe() and state.health > 0 and not state.recovery_pending and not world.element_abilities.busy()

func reachable(anchor: Node3D, distance := 2.0) -> bool:
	if not available() or world.player.global_position.distance_to(anchor.global_position) > distance: return false
	var ray := PhysicsRayQueryParameters3D.create(world.player.global_position+Vector3.UP,anchor.global_position+Vector3.UP,1,[world.player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or anchor.is_ancestor_of(hit.collider)

func selected_target() -> String:
	var best := ""
	var distance := INF
	for id in captives:
		if reachable(captives[id]):
			var current: float = world.player.global_position.distance_to(captives[id].global_position)
			if current < distance: best = id; distance = current
	if best == "" and reachable(assembly): return "assembly"
	return best

func interaction_prompt() -> String:
	var id := selected_target()
	if id == "": return ""
	if id == "assembly": return "[E] 查看四人集合" if state.rescue_assembled else "[E] 确认四人安全集合 · 已释放 %d/4" % state.rescue_released.size()
	return "[E] " + CAST.data[id].name + (" · 交谈" if state.rescue_released.has(id) else " · 用旧灯解除拘束")

func interact() -> bool:
	var id := selected_target()
	if id == "": return false
	if id == "assembly":
		if state.rescue_assembled: world.training.tell(state.rescue_information(),7)
		elif state.rescue_released.size() < 4:
			var names: Array[String] = []
			for captive in state.CAPTIVE_IDS:
				if not state.rescue_released.has(captive): names.append(CAST.data[captive].name)
			world.training.tell("仍需释放："+"、".join(names)+"。沿右侧石阶前往营救院，用旧灯逐人解除。",7)
		else: operate("assembly")
		return true
	if state.rescue_released.has(id): world.training.tell(CAST.data[id].name+"："+CAST.data[id].response,7); return true
	var missing: Array = state.rescue_missing_conditions()
	if world.player.weapon_mode != "lamp" and "按 3 装备旧灯" not in missing: missing.append("按 3 装备旧灯")
	if not missing.is_empty(): world.training.tell("解除拘束仍需："+"、".join(missing),6); return true
	switches[id].on_interaction(true)
	return true

func _activated(active: bool, id: String) -> void:
	if active: operate(id)

func operate(id: String) -> bool:
	# Recheck the physical boundary even when invoked from a switch callback.
	if id == "assembly":
		if not reachable(assembly): return false
	elif not captives.has(id) or not reachable(captives[id]) or world.player.weapon_mode != "lamp":
		return false
	var previous: Dictionary = state.adventure_snapshot()
	state.selected_equipment = world.player.weapon_mode
	var changed: bool = state.assemble_captives() if id == "assembly" else state.release_captive(id)
	if not changed: state.restore_adventure(previous); restore_history(); return false
	if state.save_progress(world.player.global_position,world.player.arm.rotation.y) != OK:
		state.restore_adventure(previous)
		restore_history()
		last_result = "保存失败 · 本次营救未提交，请重试。已救人员保持安全。"
		world.gameplay_hud.restore_view()
		world.training.tell(last_result,6)
		return false
	activation_count += 1
	restore_history()
	last_result = state.rescue_information() if id == "assembly" else CAST.data[id].name+"："+CAST.data[id].response
	world.player.current_animation = ""
	world.player.attack_timer = 0.6
	world.player._play_animation("Interact",1.8)
	world.menu_audio.play_cue("confirm")
	world.gameplay_hud.restore_view()
	world.training.tell(last_result,8)
	return true

func _process(_delta: float) -> void:
	if not grounded: return
	selected = selected_target()
	for id in captives: captives[id].label.visible = id == selected
	assembly_label.visible = world.player.global_position.distance_to(assembly.global_position) < 5.5

func _mcp_state() -> Dictionary:
	var observation := {"grounded":grounded,"selected_target":selected,"prompt":interaction_prompt() if grounded else "","last_result":last_result,"activation_count":activation_count,"assembled":state.rescue_assembled if state else false,"supply_claimed":state.rescue_supply_claimed if state else false,"order":state.rescue_order if state else ""}
	for id in captives:
		observation[id+"_released"] = state.rescue_released.has(id)
	return observation
