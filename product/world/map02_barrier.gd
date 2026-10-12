extends Node3D
## One scene owner; durable circuit facts belong exclusively to DialogueState.
const GROUND = preload("res://world/map02_ground.gd")
const SWITCH = preload("res://interaction/nodragem/short_interaction_switch.gd")
const ROCK = preload("res://assets/maps/map02/Meshes/Rocks/rock_moss_set_01_rock06.glb")
const SIGN = preload("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn")
const FONT = preload("res://assets/dialogue/zhuque/ZhuqueFangsong-Regular.ttf")
var world: Node3D
var state: Node
var clue: Node3D
var supply: Node3D
var location: Node3D
var passage: Node3D
var supply_switch: ShortSwitch
var location_switch: ShortSwitch
var supply_mark: MeshInstance3D
var location_mark: MeshInstance3D
var supply_lines: Node3D
var location_lines: Node3D
var hostile: MeshInstance3D
var stable: Node3D
var blocker: CollisionShape3D
var supply_label: Label3D
var location_label: Label3D
var grounded := false
var flow_phase := 0.0

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	clue = SIGN.instantiate()
	clue.name = "CircuitClue"
	clue.scale *= 0.5
	add_child(clue)
	supply = Node3D.new(); supply.name = "SpiralSupply"; add_child(supply)
	location = Node3D.new(); location.name = "ArrowLocation"; add_child(location)
	passage = $Passage
	supply_switch = SWITCH.new(); supply_switch.name = "SupplySwitch"; add_child(supply_switch)
	location_switch = SWITCH.new(); location_switch.name = "LocationSwitch"; add_child(location_switch)
	for anchor in [supply, location]:
		var rock: Node3D = ROCK.instantiate()
		anchor.add_child(rock)
		rock.scale = Vector3(0.65,1.4,0.65)
		rock.position.y = 0.73
	supply_mark = mark(supply, preload("res://assets/effects/ln01_supply.tres"))
	location_mark = mark(location, preload("res://assets/effects/ln01_location.tres"))
	supply_label = label(supply, "螺旋 · 结界供能", 2.7)
	location_label = label(location, "箭头 · 通道定位", 2.7)
	var clue_label := label(clue, "通道线路 · 查阅线索", 1.7)
	clue_label.font_size = 36; clue_label.pixel_size = 0.0033
	hostile = $Passage/HostileVeil
	stable = $Passage/StableLight
	build_stable_ribbons()
	blocker = $Passage/BarrierBody/CollisionShape3D
	state.progression_changed.connect(restore_history)
	restore_history()
	supply_switch.activation_signal.connect(_cut_supply)
	location_switch.activation_signal.connect(_purify_location)
	ground.call_deferred()

func mark(anchor: Node3D, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new(); quad.size = Vector2(0.8,0.8)
	node.mesh = quad; node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anchor.add_child(node); node.position = Vector3(0,1.75,-0.85)
	return node

func label(anchor: Node3D, text: String, height: float) -> Label3D:
	var node := Label3D.new()
	node.text = text; node.font = FONT; node.font_size = 48; node.pixel_size = 0.006
	node.outline_size = 10; node.modulate = Color(1,0.92,0.71)
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	anchor.add_child(node); node.position = Vector3(0,height,0)
	return node

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if is_queued_for_deletion() or not is_instance_valid(world) or world.is_queued_for_deletion(): return
		var all_grounded := GROUND.place(world, clue, GROUND.LN01_CLUE)
		all_grounded = GROUND.place(world,supply,GROUND.LN01_SUPPLY) and all_grounded
		all_grounded = GROUND.place(world,location,GROUND.LN01_LOCATION) and all_grounded
		all_grounded = GROUND.place(world,passage,GROUND.LN01_PASSAGE) and all_grounded
		if not all_grounded: continue
		for pair in [["LeftStone",Vector2(4,111)], ["RightStone",Vector2(8,111)]]:
			var pillar := Node3D.new(); pillar.name = pair[0]; add_child(pillar)
			if not GROUND.place(world,pillar,pair[1]): pillar.queue_free(); all_grounded = false; break
			var rock: Node3D = ROCK.instantiate(); pillar.add_child(rock)
			rock.scale = Vector3(1.1,3.1,1.1); rock.position.y = 1.62
		if not all_grounded:
			world.entry_failed.emit("通道石柱缺少安全落脚点，保留原有进度。")
			return
		supply_lines = circuit(supply.global_position + Vector3.UP, passage.global_position + Vector3(-0.7,2,0))
		location_lines = circuit(location.global_position + Vector3.UP, passage.global_position + Vector3(0.7,2,0))
		grounded = true
		restore_history()
		return
	world.entry_failed.emit("通道线路缺少安全落脚点，保留原有进度。")

func circuit(from: Vector3, to: Vector3) -> Node3D:
	var lines := Node3D.new(); add_child(lines)
	# Native tubes avoid screen/depth dependencies and shader TIME during pause.
	for i in 8:
		var a := from.lerp(to,float(i)/8); a.y += sin(float(i)/8 * PI) * 0.35
		var b := from.lerp(to,float(i+1)/8); b.y += sin(float(i+1)/8 * PI) * 0.35
		var tube := MeshInstance3D.new(); var mesh := CylinderMesh.new()
		mesh.top_radius = 0.018; mesh.bottom_radius = 0.018; mesh.height = a.distance_to(b); mesh.radial_segments = 6
		tube.mesh = mesh; tube.material_override = preload("res://assets/effects/ln01_flow.tres")
		tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lines.add_child(tube); tube.global_position = (a+b)*0.5
		tube.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
	return lines

func build_stable_ribbons() -> void:
	var ribbon: Node3D = $Passage/StableLight/Ribbon
	for strand in 2:
		for i in 18:
			var t := float(i)/18
			var next := float(i+1)/18
			var offset: float = strand * PI
			var a := Vector3(sin(t*TAU+offset)*0.55,0.25+t*2.9,cos(t*TAU+offset)*0.28)
			var b := Vector3(sin(next*TAU+offset)*0.55,0.25+next*2.9,cos(next*TAU+offset)*0.28)
			var tube := MeshInstance3D.new(); var mesh := CylinderMesh.new()
			mesh.top_radius = 0.025; mesh.bottom_radius = 0.025; mesh.height = a.distance_to(b); mesh.radial_segments = 6
			tube.mesh = mesh; tube.material_override = preload("res://assets/effects/ln01_flow.tres")
			tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			ribbon.add_child(tube); tube.position = (a+b)*0.5
			tube.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func restore_history() -> void:
	if not is_instance_valid(state) or not is_instance_valid(supply_switch): return
	for pair in [[supply_switch,state.ln01_supply_cut], [location_switch,state.ln01_location_purified]]:
		pair[0].set_block_signals(true); pair[0].is_activated = pair[1]; pair[0].set_block_signals(false)
	supply_mark.visible = state.ln01_revealed and not state.ln01_supply_cut
	location_mark.visible = state.ln01_revealed and not state.ln01_location_purified
	supply_label.text = "螺旋 · 供能已切断" if state.ln01_supply_cut else "螺旋 · 结界供能"
	location_label.text = "箭头 · 通道已稳定" if state.ln01_location_purified else "箭头 · 通道定位"
	supply_label.visible = state.ln01_revealed; location_label.visible = state.ln01_revealed
	if supply_lines: supply_lines.visible = state.ln01_revealed and not state.ln01_supply_cut
	if location_lines: location_lines.visible = state.ln01_revealed and not state.ln01_location_purified
	hostile.visible = not state.ln01_supply_cut
	stable.visible = state.ln01_location_purified
	blocker.set_deferred("disabled",state.ln01_location_purified)

func available() -> bool:
	return grounded and world.pause_owners.is_empty() and state.health > 0 and not state.recovery_pending and not world.training.player_locked() and not world.element_abilities.busy() and world.player.traversal.action == "" and world.player.switch_timer <= 0 and world.player.attack_timer <= 0

func clear_line(anchor: Node3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(world.player.global_position + Vector3.UP,anchor.global_position + Vector3.UP,1,[world.player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or anchor.is_ancestor_of(hit.collider)

func reachable(anchor: Node3D, distance := 2.4) -> bool:
	return available() and world.player.global_position.distance_to(anchor.global_position) <= distance and clear_line(anchor)

func lamp_target_available() -> bool:
	return reachable(clue,7) or reachable(supply,7) or reachable(location,7)

func reveal() -> bool:
	if not lamp_target_available(): return false
	if not state.ln01_available(): world.training.tell("先清除墓道守卫，调查墓殿路标 MF02。",4); return true
	if state.reveal_ln01():
		world.training.commit()
		world.training.tell("螺旋环形：敌方结界供能 · 箭头：通道定位\n先切断螺旋供能，再净化箭头定位。",6)
		world.training.feedback.spark(world.player.global_position + Vector3.UP,Color(0.4,0.85,1))
	else: world.training.tell(state.ln01_information(),5)
	return true

func selected_target() -> String:
	if grounded and available() and world.player.global_position.distance_to(passage.global_position) < 2.5: return "passage"
	if reachable(supply): return "supply"
	if reachable(location): return "location"
	if reachable(clue): return "clue"
	return ""

func interaction_prompt() -> String:
	var target := selected_target()
	if target == "": return ""
	if target == "passage": return "[E] 前往裂隙墓殿" if state.tomb_missing_conditions().is_empty() else "[E] 查看墓殿通道所需条件"
	if target == "clue": return "[E] 查阅通道线路 · [3] 旧灯 / [F] 显形"
	if not state.ln01_revealed: return "[3] 旧灯 · [F] 显露螺旋与箭头线路"
	if target == "supply": return "螺旋 · 供能已切断" if state.ln01_supply_cut else "[E] 切断螺旋供能 · 旧灯"
	return "箭头 · 通道已稳定" if state.ln01_location_purified else "[E] 净化箭头定位 · 旧灯"

func interact() -> bool:
	var target := selected_target()
	if target == "": return false
	if target == "passage":
		if not state.tomb_missing_conditions().is_empty(): world.training.tell("墓殿通道尚未开放 · " + "、".join(state.tomb_missing_conditions()),6)
		elif world.entry_router: world.entry_router.travel_to(state.MAP03)
		return true
	if target == "clue": world.training.tell(state.ln01_information(),6); return true
	if not state.ln01_revealed: world.training.tell("按 3 装备旧灯，再按 F 显露线路。",4); return true
	if world.player.weapon_mode != "lamp": world.training.tell("按 3 装备旧灯，才能操作线路。",4); return true
	if target == "supply":
		if state.ln01_supply_cut: world.training.tell("螺旋供能已切断 · 前往箭头定位。",4)
		else: supply_switch.on_interaction(true)
	else:
		if not state.ln01_supply_cut: world.training.tell("结界供能尚未切断",4)
		elif state.ln01_location_purified: world.training.tell(state.ln01_information(),5)
		else: location_switch.on_interaction(true)
	return true

func _cut_supply(active: bool) -> void:
	if not active: return
	if not state.cut_ln01_supply(): restore_history(); return
	feedback("螺旋供能已切断 · 敌方光纹消退。现在净化箭头定位。")

func _purify_location(active: bool) -> void:
	if not active: return
	if not state.purify_ln01_location(): restore_history(); return
	feedback("通道已稳定 · 林缘结界解除。四位村民仍待救援。")

func feedback(text: String) -> void:
	world.player.current_animation = ""; world.player.attack_timer = 0.6
	world.player._play_animation("Interact",1.8)
	world.training.commit(); world.menu_audio.play_cue("confirm"); world.training.tell(text,6)

func _process(delta: float) -> void:
	if not grounded or not available(): return
	if state.reduced_motion: flow_phase = 0
	else: flow_phase += delta * 0.5
	stable.get_node("Ribbon").rotation.y = sin(flow_phase)*0.12

func _mcp_state() -> Dictionary:
	return {"grounded":grounded,"revealed":state.ln01_revealed if state else null,"supply_cut":state.ln01_supply_cut if state else null,"location_purified":state.ln01_location_purified if state else null,"hostile_visible":hostile.visible if hostile else null,"passage_lit":stable.visible if stable else null,"collision_disabled":blocker.disabled if blocker else null,"supply_mark_visible":supply_mark.visible if supply_mark else null,"location_mark_visible":location_mark.visible if location_mark else null,"selected_target":selected_target() if grounded else "","prompt":interaction_prompt() if grounded else "","flow_phase":flow_phase}
