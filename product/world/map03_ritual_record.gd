extends Node3D
## Nodragem switch projects one durable fact; restoration never emits activation.
const GROUND = preload("res://world/map03_ground.gd")
const SWITCH = preload("res://interaction/nodragem/short_interaction_switch.gd")
var world: Node3D
var state: Node
var stone: Node3D
var record_switch: ShortSwitch
var grounded := false

func configure(owner_world: Node3D) -> void:
	world = owner_world
	state = world.dialogue_state
	process_mode = Node.PROCESS_MODE_PAUSABLE
	stone = preload("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn").instantiate()
	stone.name = "RitualStone"
	stone.scale *= 0.5
	add_child(stone)
	record_switch = SWITCH.new()
	add_child(record_switch)
	restore_history()
	record_switch.activation_signal.connect(_activated)
	var heading := Label3D.new()
	heading.text = "仪式记录"
	heading.font = preload("res://dialogue_theme.tres").default_font
	heading.position.y = 2.0
	heading.font_size = 40
	heading.pixel_size = 0.003
	heading.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stone.add_child(heading)
	var torch := OmniLight3D.new()
	torch.position = Vector3(0,2,0)
	torch.light_color = Color(1,0.58,0.20)
	torch.light_energy = 1.4
	torch.omni_range = 5
	stone.add_child(torch)
	ground.call_deferred()

func ground() -> void:
	for attempt in 120:
		await get_tree().physics_frame
		if GROUND.place(world,stone,GROUND.RECORD): grounded = true; return
	world.entry_failed.emit("仪式记录没有可到达的石地支撑。")

func restore_history() -> void:
	if not is_instance_valid(record_switch): return
	record_switch.set_block_signals(true)
	record_switch.is_activated = state.ritual_record_read
	record_switch.set_block_signals(false)

func reachable() -> bool:
	if not grounded or not world.travel_safe() or state.health <= 0 or state.recovery_pending: return false
	if world.player.global_position.distance_to(stone.global_position) > 2.4: return false
	var ray := PhysicsRayQueryParameters3D.create(world.player.global_position+Vector3.UP,stone.global_position+Vector3.UP,1,[world.player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or stone.is_ancestor_of(hit.collider)

func interaction_prompt() -> String:
	if not reachable(): return ""
	return "[E] 查阅仪式记录 · [J] 日志" if state.ritual_record_read else "[E] 调查仪式记录"

func interact() -> bool:
	if not reachable(): return false
	if state.ritual_record_read: world.training.tell(state.ritual_information(),8)
	else: record_switch.on_interaction(true)
	return true

func _activated(active: bool) -> void:
	if not active: return
	var previous: Dictionary = state.adventure_snapshot()
	if not state.acquire_ritual_record(): restore_history(); return
	state.selected_equipment = world.player.weapon_mode
	if state.save_progress(world.player.global_position,world.player.arm.rotation.y) != OK:
		state.restore_adventure(previous)
		restore_history()
		world.training.tell("记录未能保存 · 请重试调查；原历史仍保留。",5)
		return
	world.menu_audio.play_cue("confirm")
	world.gameplay_hud.restore_view()
	world.training.tell("仪式记录已保存 · " + state.ritual_information(),9)

func _mcp_state() -> Dictionary:
	return {"grounded":grounded,"record_read":state.ritual_record_read if is_instance_valid(state) else null,"reachable":reachable() if grounded else false,"record_position":str(stone.global_position) if grounded else null,"prompt":interaction_prompt() if grounded else ""}
