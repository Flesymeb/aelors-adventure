extends RefCounted
## Opt-in disposable transaction checks; prepared histories prove no earned route.
const STATE = preload("res://dialogue_state.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const RESCUE = preload("res://tests/map03_rescue_test.gd")

class DiskState extends "res://dialogue_state.gd":
	var fail_next := false
	func _ready() -> void:
		inventory = preload("res://inventory/product_inventory.gd").new()
		inventory.state = self
		add_child(inventory)
		inventory.restore()
	func _history_path(_slot: int) -> String: return "user://story_completion_disposable.cfg"
	func save_progress(at: Vector3, yaw: float, slot := 0) -> Error:
		if fail_next: fail_next = false; return ERR_CANT_CREATE
		return super(at,yaw,slot)

class QuietVeyne extends RefCounted:
	var clears := 0
	func clear_rifts() -> void: clears += 1
class OperationWorld extends RESCUE.OperationWorld:
	var veyne_encounter := QuietVeyne.new()
class CoreProbe extends "res://world/map03_core.gd":
	func reachable() -> bool: return true
	func restore_history() -> void: pass

class DiagnosticEndingRouter extends "res://tests/map03_entry_test.gd".DiagnosticTombRouter:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		state = preload("res://tests/map03_entry_test.gd").TombState.new()
		state.name = "DiagnosticState"
		add_child(state)
		var ending: Node = load("res://tests/story_completion_test.gd").prepared()
		state.restore_config(HISTORY.history(ending))
		ending.free()
		audio = preload("res://ui/menu_audio.gd").new()
		audio.state = state
		add_child(audio)
		_bind_tomb({"position":Vector3(-4,0,-30.8),"map_id":state.MAP03,"yaw":0.0})

class DiagnosticHomeRouter extends HISTORY.DiagnosticRouter:
	var started := false
	func _ready() -> void:
		super()
		var ending: Node = load("res://tests/story_completion_test.gd").prepared()
		ending.close_summoning_core()
		ending.commit_arrival(ending.GROUND.MAP_ID)
		ending.commit_homecoming()
		state.restore_config(HISTORY.history(ending))
		ending.free()
	func _process(delta: float) -> void:
		super(delta)
		if diagnostic_ready and not is_instance_valid(world.homecoming_residents): world.restore_destination_history()
		if diagnostic_ready and is_instance_valid(world.homecoming_residents) and world.homecoming_residents.grounded and not started:
			started = true
			var scene = load("res://ui/homecoming_scene.gd").new()
			scene.name = "DiagnosticHomecoming"
			scene.world = world
			add_child(scene)

static func prepared() -> Node:
	var state: Node = RESCUE.prepared()
	state.inventory = preload("res://inventory/product_inventory.gd").new()
	state.inventory.state = state
	state.add_child(state.inventory)
	state.inventory.restore()
	state.defeat_warden()
	state.inspect_warden_device()
	state.defeat_veyne()
	state.take_veyne_key()
	for id in state.CAPTIVE_IDS: state.release_captive(id)
	state.assemble_captives()
	return state

static func run(parent: Node) -> Dictionary:
	var checks := {}
	var source: Node = prepared()
	var state := DiskState.new()
	parent.add_child(state)
	state.restore_config(HISTORY.history(source))
	source.free()
	var original: Dictionary = state.adventure_snapshot()
	for fact in ["warden_defeated","veyne_defeated","rescue_assembled","lamp_owned","ln02_purified"]:
		state.set(fact,false)
		checks["requires_"+fact] = not state.close_summoning_core() and not state.core_closed
		state.restore_adventure(original.duplicate(true))
	state.selected_equipment = "sword"
	checks.requires_equipped_lamp = not state.close_summoning_core()
	state.restore_adventure(original.duplicate(true))
	state.rescue_released.erase("oren")
	checks.requires_quartet = not state.close_summoning_core()
	state.restore_adventure(original.duplicate(true))
	var world := OperationWorld.new()
	parent.add_child(world)
	var core := CoreProbe.new()
	world.add_child(core)
	core.world = world
	core.state = state
	state.fail_next = true
	checks.failed_save_rolls_back = not core.close_core() and state.adventure_snapshot() == original and world.veyne_encounter.clears == 0
	var xp: int = state.experience
	var rewards: Dictionary = state.reward_history.duplicate(true)
	checks.close_durable = core.close_core() and state.core_closed and not state.homecoming_completed and world.veyne_encounter.clears == 1
	checks.close_once = not core.close_core() and world.veyne_encounter.clears == 1 and state.experience == xp and state.reward_history == rewards
	checks.no_remote_ending = not state.commit_homecoming()
	checks.closed_history_valid = state.config_unavailable_reason(HISTORY.history(state)) == ""
	checks.village_arrival = state.commit_arrival(state.GROUND.MAP_ID) and state.commit_homecoming() and not state.commit_homecoming()
	checks.save_homecoming = state.save_progress(Vector3(116.5,10,97.25),0) == OK
	state.reset_adventure()
	checks.restore_completed = not state.load_progress().is_empty() and state.homecoming_completed and state.core_closed and state.rescue_released.size() == 4 and state.current_map == state.GROUND.MAP_ID
	checks.no_replay_reward = not state.close_summoning_core() and not state.commit_homecoming() and state.experience == xp and state.reward_history == rewards
	for first_action in ["rescue","light"]:
		state.conversation_active = false
		state.dialogue_kind = "isha"
		state.bridge_first_action = first_action
		state.begin()
		checks["reunion_response_"+first_action] = state.logical_node == ("END_RESCUE" if first_action == "rescue" else "END_LIGHT") and state.choose(0) and state.logical_node == "END02" and state.experience == xp and state.reward_history == rewards
	state.conversation_active = false
	state.logical_node = "D01"
	var legacy := HISTORY.history(state)
	legacy.erase_section_key("post_bow","core_closed")
	legacy.erase_section_key("post_bow","homecoming_completed")
	checks.old_save_valid = state.config_unavailable_reason(legacy) == ""
	state.restore_config(legacy)
	checks.old_save_defaults = not state.core_closed and not state.homecoming_completed
	for values in [[false,true],[true,"true"]]:
		var invalid := HISTORY.history(state)
		invalid.set_value("post_bow","core_closed",values[0])
		invalid.set_value("post_bow","homecoming_completed",values[1])
		checks["reject_invalid_ending_"+str(values)] = state.config_unavailable_reason(invalid) != ""
	world.free()
	state.free()
	DirAccess.remove_absolute("user://story_completion_disposable.cfg")
	DirAccess.remove_absolute("user://story_completion_disposable.cfg.tmp")
	return {"checks":checks,"scope":"isolated memory/disposable disk transactions; no ordinary earning or independent acceptance"}
