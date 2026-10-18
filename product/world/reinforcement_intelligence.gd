extends Node3D
## Optional intelligence has its own fixed source, village interpretation and
## precombat operation. It never grants route fragments or changes main gates.
var world: Node3D
var state: Node
var anchor: Node3D
var heading: Label3D
var kind := ""
var grounded := false

class Mara extends "res://isha_npc.gd":
	func _ready() -> void:
		super()
		remove_from_group("isha")
	func _ground() -> void:
		# The shared interaction owner places this actor at her own village anchor.
		pass

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if world.active_map_id() == state.MAP03:
		kind = "node"
		anchor = preload("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn").instantiate()
		anchor.scale *= 0.5
	elif world.active_map_id() == state.MAP02:
		kind = "record"
		anchor = preload("res://Prefabs/Prop/Container/EA03_Prop_Container_Chest_02a_PRE.prefab.scn").instantiate()
	else:
		kind = "mara"
		anchor = Mara.new()
		var model: Node3D = preload("res://assets/dialogue/isha_actor.glb").instantiate()
		model.name = "Model"
		anchor.add_child(model)
	anchor.name = "Mara" if kind == "mara" else "DeploymentRecord" if kind == "record" else "ReinforcementNode"
	add_child(anchor)
	heading = Label3D.new()
	heading.text = "玛拉 · 情报核对" if kind == "mara" else "完整布防记录" if kind == "record" else "增援节点"
	heading.font = preload("res://dialogue_theme.tres").default_font
	heading.position.y = 2.1 / anchor.scale.y
	heading.font_size = 36
	heading.pixel_size = 0.003 / anchor.scale.y
	heading.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	anchor.add_child(heading)
	ground.call_deferred()

func ground() -> void:
	var xz := Vector2(120,94.5) if kind == "mara" else Vector2(9,66) if kind == "record" else Vector2(-2.5,-5)
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world): return
		if world.ground_policy.place(world,anchor,xz):
			grounded = true
			if kind == "mara": anchor.grounded = true
			return
	# An optional interaction failure does not waive the main entry or fake support.
	world.training.tell("情报交互点缺少安全支撑，请从灯台重新进入。",5)

func reachable() -> bool:
	if not grounded or not world.travel_safe() or state.health <= 0 or state.recovery_pending: return false
	if world.player.global_position.distance_to(anchor.global_position) > 2.4: return false
	var excludes: Array[RID] = [world.player.get_rid()]
	if anchor is CollisionObject3D: excludes.append(anchor.get_rid())
	var ray := PhysicsRayQueryParameters3D.create(world.player.global_position+Vector3.UP,anchor.global_position+Vector3.UP,1,excludes)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or anchor.is_ancestor_of(hit.collider)

func node_available() -> bool:
	return state.ln02_purified and not state.veyne_defeated and world.veyne_encounter.phase == "waiting"

func interaction_prompt() -> String:
	if not reachable(): return ""
	match kind:
		"mara": return "[E] 与玛拉核对情报" if state.sq02_record_found and not state.sq02_completed else "[E] 与玛拉交谈"
		"record": return "[E] 查阅完整布防记录" if state.sq02_record_found else "[E] 调查布防记录箱"
		"node":
			if state.veyne_node_closed: return "[E] 查看已封住的增援节点"
			if not node_available(): return ""
			return "[E] 封住增援节点" if state.sq02_completed and state.ritual_record_read else "[E] 调查增援节点"
	return ""

func interact() -> bool:
	if interaction_prompt() == "": return false
	var previous: Dictionary = state.adventure_snapshot()
	var changed := false
	match kind:
		"record": changed = state.acquire_deployment_record()
		"mara": changed = state.interpret_deployment_record()
		"node":
			if node_available(): changed = state.close_veyne_node()
	if changed:
		state.selected_equipment = world.player.weapon_mode
		if state.save_progress(world.player.global_position,world.player.arm.rotation.y) != OK:
			state.restore_adventure(previous)
			world.gameplay_hud.restore_view()
			world.training.tell("情报进度保存失败 · 原历史已保留，请重试。",5)
			return true
		world.menu_audio.play_cue("confirm")
		world.gameplay_hud.restore_view()
	var message: String = state.intelligence_information()
	if kind == "node" and not state.veyne_node_closed:
		message = "节点仍开放 · 需要玛拉核对完整布防记录，并调查入口仪式记录，才能在交战前封印。"
	world.training.tell(message,9)
	return true

func _mcp_state() -> Dictionary:
	return {"kind":kind,"grounded":grounded,"position":str(anchor.global_position) if grounded else null,"record_found":state.sq02_record_found,"interpreted":state.sq02_completed,"node_closed":state.veyne_node_closed,"prompt":interaction_prompt() if grounded else ""}
