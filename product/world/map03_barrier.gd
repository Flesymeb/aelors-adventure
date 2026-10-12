extends Node3D
## Product adapter over the retained Nodragem switches. DialogueState owns all facts.
const GROUND = preload("res://world/map03_ground.gd")
const SWITCH = preload("res://interaction/nodragem/short_interaction_switch.gd")
const FONT = preload("res://assets/dialogue/zhuque/ZhuqueFangsong-Regular.ttf")
const SIGN = preload("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn")
var world: Node3D
var state: Node
var anchors: Dictionary = {}
var switches: Dictionary = {}
var symbols: Dictionary = {}
var gate_symbols: Dictionary = {}
var lines: Dictionary = {}
var labels: Dictionary = {}
var blocker: CollisionShape3D
var veil: MeshInstance3D
var grounded := false
var opened_route_supported := false
var support_samples := 0
var activation_count := 0
var last_result := ""

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	process_mode = Node.PROCESS_MODE_PAUSABLE
	veil = $Veil
	blocker = $Boundary/CollisionShape3D
	for side in ["north", "south", "device"]:
		var anchor := Node3D.new()
		anchor.name = side.capitalize() + "Node"
		add_child(anchor)
		anchors[side] = anchor
		var stone: Node3D = SIGN.instantiate()
		stone.scale *= 0.32
		anchor.add_child(stone)
		var switch := SWITCH.new()
		switch.name = side.capitalize() + "Switch"
		add_child(switch)
		switches[side] = switch
		switch.activation_signal.connect(_activated.bind(side))
		var title := Label3D.new()
		title.font = FONT
		title.font_size = 40
		title.pixel_size = 0.0035
		title.outline_size = 8
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		title.position.y = 2.0
		anchor.add_child(title)
		labels[side] = title
		if side == "device": continue
		var material: Material = preload("res://assets/effects/ln01_supply.tres") if side == "north" else preload("res://assets/effects/ln01_location.tres")
		symbols[side] = mark(anchor,material,Vector3(0,1.4,0.05))
		gate_symbols[side] = mark(self,material,Vector3(-4 if side == "north" else 4,3.5,-7.1))
	state.progression_changed.connect(restore_history)
	restore_history()
	ground.call_deferred()

func mark(parent: Node3D, material: Material, at: Vector3) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.85,0.85)
	mesh.mesh = quad
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	mesh.position = at
	return mesh

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world) or world.is_queued_for_deletion(): return
		var supported := true
		for pair in [["north",GROUND.NORTH],["south",GROUND.SOUTH],["device",GROUND.DEVICE]]:
			supported = GROUND.place(world,anchors[pair[0]],pair[1]) and supported
		if not supported: continue
		# Native authored stairs are the only route to the upper crypt floor.
		var stance := Node3D.new()
		add_child(stance)
		support_samples = 0
		for i in GROUND.OPEN_ROUTE.size()-1:
			for j in 13:
				if GROUND.route_clear(world,GROUND.OPEN_ROUTE[i].lerp(GROUND.OPEN_ROUTE[i+1],float(j)/12)): support_samples += 1
		stance.queue_free()
		opened_route_supported = support_samples == 39
		if not opened_route_supported:
			world.entry_failed.emit("墓殿石阶与入口内侧缺少真实支撑或净空，已保留上一处边界。")
			return
		for side in ["north","south"]:
			lines[side] = circuit(anchors[side].global_position + Vector3.UP*1.4,gate_symbols[side].global_position)
		grounded = true
		restore_history()
		return
	world.entry_failed.emit("入口供能节点缺少可到达的石地支撑。")

func circuit(from: Vector3, to: Vector3) -> Node3D:
	var result := Node3D.new()
	add_child(result)
	for i in 8:
		var a := from.lerp(to,float(i)/8)
		var b := from.lerp(to,float(i+1)/8)
		var node := MeshInstance3D.new()
		var tube := CylinderMesh.new()
		tube.top_radius = 0.016
		tube.bottom_radius = 0.016
		tube.height = a.distance_to(b)
		tube.radial_segments = 6
		node.mesh = tube
		node.material_override = preload("res://assets/effects/ln01_flow.tres")
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		result.add_child(node)
		node.global_position = (a+b)*0.5
		node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return result

func restore_history() -> void:
	if not is_instance_valid(state) or switches.is_empty(): return
	for side in switches:
		var active: bool = state.ln02_purified if side == "device" else state.get("ln02_"+side+"_cut")
		switches[side].set_block_signals(true)
		switches[side].is_activated = active
		switches[side].set_block_signals(false)
		if side != "device":
			symbols[side].visible = state.ln02_revealed and not active
			gate_symbols[side].visible = state.ln02_revealed and not active
			if lines.has(side): lines[side].visible = state.ln02_revealed and not active
			labels[side].text = ("北侧 · 螺旋" if side == "north" else "南侧 · 箭纹") + (" · 已切断" if active else " · 供能")
		else: labels[side].text = "入口 · 已净化" if active else "通行装置 · 净化"
		labels[side].visible = false
	veil.visible = not state.ln02_purified
	blocker.set_deferred("disabled",state.ln02_purified)

func available() -> bool:
	return grounded and world.travel_safe() and state.health > 0 and not state.recovery_pending and not world.element_abilities.busy()

func reachable(anchor: Node3D, distance := 2.4) -> bool:
	if not available() or world.player.global_position.distance_to(anchor.global_position) > distance: return false
	var ray := PhysicsRayQueryParameters3D.create(world.player.global_position+Vector3.UP,anchor.global_position+Vector3.UP,1,[world.player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or anchor.is_ancestor_of(hit.collider)

func selected_target() -> String:
	for side in ["north","south","device"]:
		if reachable(anchors[side]): return side
	return ""

func reveal() -> bool:
	if not available(): return false
	if not ["north","south","device"].any(func(side): return reachable(anchors[side],7)): world.training.tell("靠近入口外侧节点 · 旧灯范围 7 米，石墙会遮挡光脉冲。",4); return false
	if not state.ln02_revealed: operate("reveal")
	else: world.training.tell(state.ln02_information(),6)
	return true

func interaction_prompt() -> String:
	var side := selected_target()
	if side == "": return ""
	if not state.ln02_revealed: return "[3] 旧灯 · [F] 显露两条供能线路"
	if side == "device": return "入口已净化 · 沿石阶通行" if state.ln02_purified else "[E] 用旧灯净化入口"
	if state.get("ln02_"+side+"_cut"): return "北侧供能已切断" if side == "north" else "南侧供能已切断"
	return "[E] 切断北侧螺旋供能 · 旧灯" if side == "north" else "[E] 切断南侧箭纹供能 · 旧灯"

func interact() -> bool:
	var side := selected_target()
	if side == "": return false
	if not state.ln02_revealed: world.training.tell("按 3 装备旧灯，再按 F 显露两条独立线路。",4); return true
	if not state.lamp_owned or world.player.weapon_mode != "lamp": world.training.tell("按 3 装备旧灯，才能操作入口线路。",4); return true
	if side == "device" and not state.ln02_remaining().is_empty(): world.training.tell("入口仍被供能 · " + "、".join(state.ln02_remaining()),6); return true
	if switches[side].is_activated: world.training.tell(state.ln02_information(),5)
	else: switches[side].on_interaction(true)
	return true

func _activated(active: bool, side: String) -> void:
	if active: operate("purify" if side == "device" else side)

func operate(operation: String) -> bool:
	var previous: Dictionary = state.adventure_snapshot()
	var changed: bool = state.reveal_ln02() if operation == "reveal" else state.purify_ln02() if operation == "purify" else state.cut_ln02_supply(operation)
	if not changed: restore_history(); return false
	state.selected_equipment = world.player.weapon_mode
	if state.save_progress(world.player.global_position,world.player.arm.rotation.y) != OK:
		state.restore_adventure(previous)
		restore_history()
		last_result = "保存失败 · 操作未提交，请重试；已完成线路仍保留。"
		world.gameplay_hud.restore_view()
		world.training.tell(last_result,5)
		return false
	activation_count += 1
	last_result = state.ln02_information()
	world.player.current_animation = ""
	world.player.attack_timer = 0.6
	world.player._play_animation("Interact",1.8)
	world.menu_audio.play_cue("confirm")
	world.training.feedback.spark(world.player.global_position+Vector3.UP,Color(0.4,0.85,1))
	world.gameplay_hud.restore_view()
	world.training.tell(last_result,7)
	return true

func _process(_delta: float) -> void:
	if not grounded: return
	# Contextual names stay readable at a node without stacking distant labels
	# over the other supply or the gate. Symbols/lines remain visible at range.
	for side in labels:
		labels[side].visible = (side == "device" or state.ln02_revealed) and world.player.global_position.distance_to(anchors[side].global_position) < 3.3

func _mcp_state() -> Dictionary:
	return {"grounded":grounded,"opened_route_supported":opened_route_supported,"support_samples":support_samples,"revealed":state.ln02_revealed if state else null,"north_cut":state.ln02_north_cut if state else null,"south_cut":state.ln02_south_cut if state else null,"purified":state.ln02_purified if state else null,"collision_disabled":blocker.disabled if blocker else null,"north_symbol":gate_symbols.north.visible if gate_symbols.has("north") else null,"south_symbol":gate_symbols.south.visible if gate_symbols.has("south") else null,"north_line":lines.north.visible if lines.has("north") else null,"south_line":lines.south.visible if lines.has("south") else null,"selected_target":selected_target() if grounded else "","prompt":interaction_prompt() if grounded else "","activation_count":activation_count,"last_result":last_result}
