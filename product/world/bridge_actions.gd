extends Node3D
const GROUND = preload("res://forest_ground.gd")
const LAMP_XZ := Vector2(124, 116)
const RESIDENT_XZ := Vector2(130, 130)
const RETURN_ROUTE := [Vector2(129,126), Vector2(127,122), Vector2(124,118)]
var world: Node3D
var state: Node
var resident: CharacterBody3D
var lamp: Node3D
var lamp_visual: Node3D
var warm_light: OmniLight3D
var approach_light: OmniLight3D
var rescue_switch: ShortSwitch
var lamp_switch: ShortSwitch
var route: Array[Vector3] = []
var trapped_position := Vector3.ZERO
var grounded := false
var restoring := false
var observed_order := ""
var observed_rescue := false
var observed_light := false
var notice_cooldown := 0.0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	resident = preload("res://actors/BridgeResident.tscn").instantiate()
	add_child(resident)
	lamp = preload("res://Prefabs/Prop/Container/EA03_Prop_Container_Crate_01a_PRE.prefab.scn").instantiate()
	lamp.name = "BridgeLamp"
	add_child(lamp)
	lamp_visual = preload("res://assets/equipment/old_lamp.tscn").instantiate()
	lamp_visual.position.y = 1.35
	lamp_visual.scale = Vector3.ONE * 1.8
	lamp.add_child(lamp_visual)
	warm_light = OmniLight3D.new()
	warm_light.name = "RestoredWarmLight"
	warm_light.light_color = Color(1,0.63,0.24)
	warm_light.light_energy = 5
	warm_light.omni_range = 17
	warm_light.omni_attenuation = 0.6
	warm_light.position.y = 2.5
	lamp.add_child(warm_light)
	approach_light = OmniLight3D.new()
	approach_light.name = "BridgeApproachLight"
	approach_light.light_color = warm_light.light_color
	approach_light.light_energy = 3
	approach_light.omni_range = 14
	approach_light.omni_attenuation = 0.6
	add_child(approach_light)
	rescue_switch = preload("res://interaction/nodragem/short_interaction_switch.gd").new()
	rescue_switch.name = "ResidentRescueSwitch"
	add_child(rescue_switch)
	rescue_switch.activation_signal.connect(_rescue_activated)
	lamp_switch = preload("res://interaction/nodragem/short_interaction_switch.gd").new()
	lamp_switch.name = "BridgeLampSwitch"
	add_child(lamp_switch)
	lamp_switch.activation_signal.connect(_lamp_activated)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if not GROUND.place(world, lamp, LAMP_XZ) or not GROUND.place(world, resident, RESIDENT_XZ): continue
		trapped_position = resident.global_position
		route.clear()
		var marker := Node3D.new()
		add_child(marker)
		var all_supported := true
		for point in RETURN_ROUTE:
			if not GROUND.place(world, marker, point): all_supported = false; break
			route.append(marker.global_position)
		marker.free()
		grounded = all_supported
		if grounded: break
	if not grounded: push_error("Bridge actions lack supported interaction/return space"); return
	approach_light.global_position = trapped_position + Vector3.UP * 2.5
	restore_history()

func restore_history() -> void:
	if not grounded: return
	restoring = true
	rescue_switch.is_activated = state.bridge_resident_rescued
	lamp_switch.is_activated = state.bridge_lamp_lit
	restoring = false
	resident.restore(state.bridge_resident_rescued, trapped_position, route.back(), route)
	_sync_light()
	observed_order = state.bridge_first_action
	observed_rescue = state.bridge_resident_rescued
	observed_light = state.bridge_lamp_lit

func _sync_light() -> void:
	warm_light.visible = state.bridge_lamp_lit
	approach_light.visible = state.bridge_lamp_lit

func _reachable(target: Node3D) -> bool:
	if world.player.global_position.distance_to(target.global_position) > 2.4: return false
	var ray := PhysicsRayQueryParameters3D.create(world.player.global_position + Vector3.UP, target.global_position + Vector3.UP, 1, [world.player.get_rid(), resident.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func interaction_prompt() -> String:
	if not grounded or not state.bridge_briefing_available() or state.health <= 0: return ""
	if _reachable(lamp):
		if not state.bridge_lamp_lit: return "[E] 恢复桥灯 · 先点灯可看清巡守并领取桥头补给"
		if state.bridge_supply_available(): return "[E] 领取桥头补给 · 生命 +30 / 箭 +4（容量上限）"
		return "桥灯已亮 · " + ("补给已领取" if state.bridge_supply_claimed else "先救人：前方安全点补给待交付")
	if _reachable(resident):
		if not state.bridge_resident_rescued: return "[E] 拉出桥边居民 · " + ("暗处有巡守！先救人，补给稍后交付" if not state.bridge_lamp_lit else "灯已照清出口，居民仍在等待")
		return "[E] 与获救居民交谈"
	return ""

func interact() -> bool:
	if not grounded or not state.bridge_briefing_available(): return false
	if not _reachable(lamp) and not _reachable(resident): return false
	if not world.training.can_save() or not world.bow_training.can_save():
		world.training.tell("巡守正在逼近 · 先躲开攻击、等出手结束再伸手；可退回罗恩处",5)
		return true
	if _reachable(lamp):
		if not state.bridge_lamp_lit: lamp_switch.on_interaction(true)
		elif state.bridge_supply_available():
			var grant: Dictionary = state.claim_bridge_supply()
			if not grant.is_empty():
				world.training.commit()
				world.training.tell("桥头补给已交付 · 生命 +%d / 箭 +%d · 只能领取一次" % [grant.health,grant.arrows],6)
		else: world.training.tell("桥灯已恢复 · " + ("桥头补给已领取" if state.bridge_supply_claimed else "罗恩的补给在前方安全点待交付"),5)
		return true
	if not state.bridge_resident_rescued: rescue_switch.on_interaction(true)
	else: world.training.tell("居民：" + state.bridge_response(),8)
	return true

func _rescue_activated(active: bool) -> void:
	if restoring or not active: return
	if not state.perform_bridge_action("rescue"):
		restoring = true
		rescue_switch.is_activated = state.bridge_resident_rescued
		restoring = false
		return
	resident.release()
	observed_rescue = true
	observed_order = state.bridge_first_action
	world.training.commit()
	world.training.tell("居民：谢谢你先拉我出来。罗恩会在前方安全点留下补给。" if state.bridge_first_action == "rescue" else "居民：灯亮了，我终于看清出口。谢谢你回来；桥头补给留给你。",8)

func _lamp_activated(active: bool) -> void:
	if restoring or not active: return
	if not state.perform_bridge_action("light"):
		restoring = true
		lamp_switch.is_activated = state.bridge_lamp_lit
		restoring = false
		return
	_sync_light()
	observed_light = true
	observed_order = state.bridge_first_action
	world.training.commit()
	world.training.tell("桥灯恢复 · 路线与巡守已照亮 · 再按 E 领取一次桥头补给" if state.bridge_first_action == "light" else "桥灯恢复 · 居民已安全，罗恩将在前方安全点交付补给",7)

func _physics_process(delta: float) -> void:
	if not grounded: return
	if observed_order != state.bridge_first_action or observed_rescue != state.bridge_resident_rescued or observed_light != state.bridge_lamp_lit: restore_history()
	notice_cooldown = maxf(0,notice_cooldown - delta)
	if notice_cooldown <= 0 and state.bridge_briefing_available() and not state.bridge_lamp_lit and world.player.global_position.distance_to(trapped_position) < 7:
		world.training.tell("桥灯熄灭 · 暗处有巡守！可先救居民，补给稍后交付；或返回入口点灯，立即领桥头补给。",7)
		notice_cooldown = 12

func _mcp_state() -> Dictionary:
	return {"grounded":grounded, "resident_rescued":state.bridge_resident_rescued, "lamp_lit":state.bridge_lamp_lit, "first_action":state.bridge_first_action, "supply_available":state.bridge_supply_available(), "supply_claimed":state.bridge_supply_claimed, "later_supply_due":state.bridge_later_supply_due, "warm_light_visible":warm_light.visible, "resident_position":str(resident.global_position), "lamp_position":str(lamp.global_position)}
