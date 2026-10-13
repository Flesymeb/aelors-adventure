extends Node3D
## Two permanent authored anchors; record and recovery are independent of corpses.
const GROUND = preload("res://world/map02_ground.gd")
const SWITCH = preload("res://interaction/nodragem/short_interaction_switch.gd")
const RECORD_PROP = preload("res://world/Map02RouteLandmark.tscn")
const SUPPLY_PROP = preload("res://Prefabs/Prop/Container/EA03_Prop_Container_Chest_02a_PRE.prefab.scn")
var world: Node3D
var state: Node
var signpost: Node3D
var supply: Node3D
var record_switch: ShortSwitch
var supply_switch: ShortSwitch
var grounded := false

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	signpost = RECORD_PROP.instantiate()
	signpost.name = "FixedTombRouteSign"
	# Match the retained prop to a standing investigation, preserving materials.
	# The qualified wrapper already owns the retained two-metre prop scale.
	signpost.get_node("EA03_Prop_Sign_Chapel_01_PRE").get_active_material(0).albedo_color = Color(0.50, 0.53, 0.45)
	add_child(signpost)
	supply = SUPPLY_PROP.instantiate()
	supply.name = "FixedRecoveryChest"
	add_child(supply)
	record_switch = SWITCH.new()
	supply_switch = SWITCH.new()
	add_child(record_switch)
	add_child(supply_switch)
	restore_history()
	record_switch.activation_signal.connect(_record_activated)
	supply_switch.activation_signal.connect(_supply_activated)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world) or world.is_queued_for_deletion(): return
		var record_grounded := GROUND.place(world, signpost, GROUND.LINE_RECORD)
		var supply_grounded := GROUND.place(world, supply, GROUND.LINE_SUPPLY)
		if record_grounded and supply_grounded:
			grounded = true
			return
	world.entry_failed.emit("墓殿路线记录与补给缺少安全落脚点。")

func restore_history() -> void:
	# Projection never invokes an interaction or grants a saved reward again.
	record_switch.set_block_signals(true)
	supply_switch.set_block_signals(true)
	record_switch.is_activated = state.mf02_acquired
	supply_switch.is_activated = state.line_supply_claimed
	record_switch.set_block_signals(false)
	supply_switch.set_block_signals(false)

func reachable(anchor: Node3D) -> bool:
	if not grounded or not is_instance_valid(anchor) or not world.pause_owners.is_empty(): return false
	if state.health <= 0 or state.recovery_pending: return false
	if world.training.player_locked() or world.element_abilities.busy() or world.player.traversal.action != "": return false
	if world.player.global_position.distance_to(anchor.global_position) > 2.4: return false
	var ray := PhysicsRayQueryParameters3D.create(world.player.global_position + Vector3.UP, anchor.global_position + Vector3.UP, 1, [world.player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or anchor.is_ancestor_of(hit.collider)

func interact() -> bool:
	if reachable(signpost):
		if not state.line_defeated():
			world.training.tell("先清除墓道守卫，再安全调查墓殿路标。", 4)
		elif state.mf02_acquired:
			world.training.tell("墓殿方向与结界标记已记录 · M 地图 / J 日志。", 4)
		else:
			record_switch.on_interaction(true)
		return true
	if reachable(supply):
		if not state.line_defeated():
			world.training.tell("战斗结束后才能安全取用补给。", 4)
		elif state.line_supply_claimed:
			world.training.tell("这份恢复补给已经用尽。", 3)
		elif not state.line_supply_available():
			world.training.tell("身体已恢复，补给留在这里，需要时再取。", 4)
		else:
			supply_switch.on_interaction(true)
		return true
	return false

func _record_activated(active: bool) -> void:
	if not active: return
	if not state.acquire_mf02():
		if not state.mf02_acquired: record_switch.is_activated = false
		return
	world.training.commit()
	world.menu_audio.play_cue("confirm")
	world.training.tell("路标指向裂隙墓殿 · 沿路前行，用旧灯显露线路。\n先切断螺旋供能，再净化箭头定位 · M 地图 / J 日志", 7)

func _supply_activated(active: bool) -> void:
	if not active: return
	var result: Dictionary = state.claim_line_supply()
	if result.is_empty():
		if not state.line_supply_claimed: supply_switch.is_activated = false
		world.training.tell("身体已恢复，补给留在这里，需要时再取。", 4)
		return
	world.training.commit()
	world.menu_audio.play_cue("confirm")
	world.training.tell("恢复补给已使用 · 生命 +%d。" % int(result.get("health", 0)), 4)

func interaction_prompt() -> String:
	if reachable(signpost):
		return "[E] 查阅墓殿路线记录 · [M] 地图" if state.mf02_acquired else "[E] 调查墓殿方向与结界标记" if state.line_defeated() else "墓殿路标 · 先清除墓道守卫"
	if reachable(supply):
		return "恢复补给已用尽" if state.line_supply_claimed else "[E] 使用恢复补给" if state.line_supply_available() else "[E] 查看恢复补给"
	return ""

func _mcp_state() -> Dictionary:
	return {"grounded":grounded, "acquired":state.mf02_acquired if is_instance_valid(state) else null,
		"record_available":reachable(signpost) and state.line_defeated() if grounded else false,
		"supply_available":reachable(supply) and state.line_supply_available() if grounded else false,
		"supply_claimed":state.line_supply_claimed if is_instance_valid(state) else null,
		"record_position":str(signpost.global_position) if grounded else null,
		"supply_position":str(supply.global_position) if grounded else null,
		"prompt":interaction_prompt() if grounded else ""}
