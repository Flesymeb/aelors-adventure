extends RefCounted
## Explicit opt-in component tests. Prepared histories never prove earned routes.
const CIRCUIT = preload("res://tests/map03_barrier_test.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const STATE = preload("res://dialogue_state.gd")

class DiskState extends "res://dialogue_state.gd":
	var fail_next := false
	func _ready() -> void: pass
	func _history_path(_slot: int) -> String: return "user://map03_rescue_disposable_test.cfg"
	func save_progress(at: Vector3, yaw: float, slot := 0) -> Error:
		if fail_next: fail_next = false; return ERR_CANT_CREATE
		return super(at,yaw,slot)

class FakePlayer extends Node3D:
	var weapon_mode := "lamp"
	var arm := Node3D.new()
	var current_animation := ""
	var attack_timer := 0.0
	func _play_animation(_clip: String, _speed: float) -> void: pass
class QuietTraining extends RefCounted:
	func tell(_text: String, _seconds: float) -> void: pass
class QuietHud extends RefCounted:
	func restore_view() -> void: pass
class QuietAudio extends RefCounted:
	var cues := 0
	func play_cue(_cue: String) -> void: cues += 1
class OperationWorld extends Node3D:
	var player := FakePlayer.new()
	var training := QuietTraining.new()
	var gameplay_hud := QuietHud.new()
	var menu_audio := QuietAudio.new()
	func _init() -> void:
		add_child(player)
		player.add_child(player.arm)
class TestRescue extends "res://world/map03_rescue.gd":
	var allow_reach := true
	func reachable(_anchor: Node3D, _distance := 2.0) -> bool: return allow_reach
	func restore_history() -> void: pass
	func start_assembly_scene() -> void: assembly_scene_starts += 1

static func prepared() -> Node:
	var state: Node = CIRCUIT.prepared()
	state.reveal_ln02(); state.cut_ln02_supply("north"); state.cut_ln02_supply("south"); state.purify_ln02()
	state.selected_equipment = "lamp"
	return state

static func run(parent: Node) -> Dictionary:
	var checks := {}
	for order in ["rescue_first", "veyne_first"]:
		var source: Node = prepared()
		var state := DiskState.new()
		state.restore_config(HISTORY.history(source))
		parent.add_child(state)
		state.inventory = preload("res://inventory/product_inventory.gd").new()
		state.inventory.state = state
		state.add_child(state.inventory)
		state.inventory.restore()
		source.free()
		checks[order+"_lock_required"] = not state.release_captive("oren")
		state.defeat_warden(); state.inspect_warden_device()
		if order == "veyne_first": state.defeat_veyne(); state.take_veyne_key()
		state.selected_equipment = "sword"
		checks[order+"_lamp_required"] = not state.release_captive("oren")
		state.selected_equipment = "lamp"
		state.health = 40; state.arrows = 0
		var xp: int = state.experience
		checks[order+"_selected_only"] = state.release_captive("villager_c") and state.rescue_released.size() == 1 and not state.rescue_released.has("oren")
		checks[order+"_no_early_assembly"] = not state.assemble_captives() and not state.rescue_supply_claimed
		checks[order+"_partial_disk_save"] = state.save_progress(Vector3(0,0,5),0) == OK
		state.rescue_released = {}
		checks[order+"_partial_disk_reload"] = not state.load_progress().is_empty() and state.rescue_released == {"villager_c":true} and state.rescue_order == order
		for id in ["villager_b","oren","villager_a"]: checks[order+"_release_"+id] = state.release_captive(id)
		checks[order+"_no_duplicate"] = not state.release_captive("oren") and not state.release_captive("unknown")
		checks[order+"_explicit_assembly"] = not state.rescue_assembled and state.assemble_captives() and state.rescue_supply_claimed and state.health == 70 and state.arrows == 4 and state.experience == xp
		checks[order+"_other_boss_preserved"] = state.veyne_defeated == (order == "veyne_first") and state.warden_defeated
		checks[order+"_once_only"] = not state.assemble_captives() and state.health == 70 and state.arrows == 4
		checks[order+"_assembly_disk_save"] = state.save_progress(Vector3(0,0,5),0) == OK
		state.reset_adventure()
		checks[order+"_assembly_disk_restore"] = not state.load_progress().is_empty() and state.rescue_assembled and state.rescue_supply_claimed and state.rescue_released.size() == 4 and state.rescue_order == order and not state.assemble_captives() and state.health == 70 and state.arrows == 4
		var valid := HISTORY.history(state)
		checks[order+"_valid_history"] = state.config_unavailable_reason(valid) == ""
		for pair in [["rescue_released",{"unknown":true}],["rescue_released",{"oren":false}],["rescue_released",{"oren":true}],["rescue_supply_claimed",false],["rescue_order",""],["rescue_assembled","true"]]:
			var invalid := HISTORY.history(state)
			invalid.set_value("post_bow",pair[0],pair[1])
			checks[order+"_reject_"+str(pair)] = state.config_unavailable_reason(invalid) != ""
		var legacy := HISTORY.history(state)
		for key in ["rescue_released","rescue_assembled","rescue_supply_claimed","rescue_order"]: legacy.erase_section_key("post_bow",key)
		checks[order+"_legacy_valid"] = state.config_unavailable_reason(legacy) == ""
		state.restore_config(legacy)
		checks[order+"_legacy_unreleased"] = state.rescue_released.is_empty() and not state.rescue_assembled and not state.rescue_supply_claimed and state.rescue_order == ""
		state.free()
	checks.merge(rollback_checks(parent))
	DirAccess.remove_absolute("user://map03_rescue_disposable_test.cfg")
	DirAccess.remove_absolute("user://map03_rescue_disposable_test.cfg.tmp")
	return {"checks":checks,"scope":"disposable prepared component/disk tests; no earned progression or ordinary route acceptance"}

static func rollback_checks(parent: Node) -> Dictionary:
	var checks := {}
	var source: Node = prepared()
	source.defeat_warden(); source.inspect_warden_device()
	var state := DiskState.new()
	state.restore_config(HISTORY.history(source)); source.free()
	parent.add_child(state)
	state.inventory = preload("res://inventory/product_inventory.gd").new()
	state.inventory.state = state
	state.add_child(state.inventory)
	state.inventory.restore()
	state.health = 40; state.arrows = 0
	var world := OperationWorld.new()
	parent.add_child(world)
	var adapter := TestRescue.new()
	world.add_child(adapter)
	adapter.world = world; adapter.state = state
	adapter.assembly = Node3D.new(); adapter.add_child(adapter.assembly)
	for id in state.CAPTIVE_IDS:
		var actor := Node3D.new(); adapter.add_child(actor); adapter.captives[id] = actor
	for id in state.CAPTIVE_IDS + ["assembly"]:
		state.fail_next = true
		var before: Dictionary = state.adventure_snapshot()
		checks[id+"_failed_write_rollback"] = not adapter.operate(id) and state.adventure_snapshot() == before and adapter.assembly_scene_starts == 0
		adapter.allow_reach = false
		checks[id+"_distance_obstruction_rejected"] = not adapter.operate(id) and state.adventure_snapshot() == before
		adapter.allow_reach = true
		checks[id+"_retry_once"] = adapter.operate(id) and not adapter.operate(id)
	checks.rollback_supply_once = state.health == 70 and state.arrows == 4 and adapter.activation_count == 5 and world.menu_audio.cues == 5 and adapter.assembly_scene_starts == 1
	world.free(); state.free()
	return checks

static func qualify_cast(parent: Node) -> Dictionary:
	var result := {}
	for scene in ["oren_captive","captive_villager_a","captive_villager_b","captive_villager_c"]:
		var actor: Node3D = load("res://actors/"+scene+".tscn").instantiate()
		parent.add_child(actor)
		var animator: AnimationPlayer = actor.presentation.animation_player
		var clips := {}
		for clip in ["Fixing_Kneeling","Idle","Interact","Idle_Talking"]: clips[clip] = animator.has_animation(clip)
		var visible_parts: Array[String] = []
		for mesh in actor.presentation.character_model.find_children("*","MeshInstance3D",true,false):
			if mesh.is_visible_in_tree(): visible_parts.append(str(mesh.name))
		result[actor.captive_id] = {"head_components":actor.presentation.head_components.size(),"bones":actor.presentation.skeleton.get_bone_count(),"clips":clips,"current":animator.current_animation,"visible_parts":visible_parts}
		actor.free()
	return result

class SceneWorld extends OperationWorld:
	var dialogue_state: Node
	var pause_owners := {}
	func _set_pause_owner(id: String, enabled: bool) -> void:
		if enabled: pause_owners[id] = true
		else: pause_owners.erase(id)
class ScenePlayer extends FakePlayer:
	var controls_open := false
	func set_controls_open(value: bool) -> void: controls_open = value

static func assembly_scene_checks(parent: Node) -> Dictionary:
	var checks := {}
	for ending in ["natural","skip","restore"]:
		var world := SceneWorld.new()
		world.player.free()
		world.player = ScenePlayer.new()
		world.add_child(world.player)
		world.dialogue_state = prepared()
		parent.add_child(world)
		world.add_child(world.dialogue_state)
		world.dialogue_state.inventory.restore()
		world.dialogue_state.defeat_warden(); world.dialogue_state.inspect_warden_device()
		for id in world.dialogue_state.CAPTIVE_IDS: world.dialogue_state.release_captive(id)
		world.dialogue_state.assemble_captives()
		var original_camera := Camera3D.new()
		world.add_child(original_camera); original_camera.current = true
		var rescue := preload("res://world/map03_rescue.gd").new()
		world.add_child(rescue); rescue.world = world; rescue.state = world.dialogue_state
		rescue.grounded = true
		rescue.assembly_label = Label3D.new(); rescue.add_child(rescue.assembly_label)
		for i in 4:
			var actor: Node3D = rescue.SCENES[i].instantiate()
			rescue.add_child(actor)
			var id: String = actor.captive_id
			rescue.captives[id] = actor
			rescue.safe_positions[id] = Vector3(i*0.6,0,0)
			actor.restore(true,true)
			var switch := rescue.SWITCH.new(); rescue.add_child(switch); rescue.switches[id] = switch
		var before: Dictionary = world.dialogue_state.adventure_snapshot()
		rescue.start_assembly_scene()
		var scene: CanvasLayer = rescue.assembly_scene
		checks[ending+"_cast_clips"] = world.dialogue_state.rescue_assembled and scene.actors.size()==4 and scene.actors.all(func(actor): return actor.presentation.animation_player.current_animation == "Interact" and actor.presentation.head_components.size()>0)
		scene.paused = true; scene._process(1.0)
		checks[ending+"_pause_freezes"] = scene.elapsed == 0 and scene.actors.all(func(actor): return actor.presentation.animation_player.speed_scale == 0)
		scene.paused = false
		if ending == "natural": scene._process(7.3)
		elif ending == "restore": rescue.restore_history()
		else: scene.finish()
		checks[ending+"_identical_commit_and_cleanup"] = world.dialogue_state.adventure_snapshot() == before and scene.finished and not world.pause_owners.has("rescue_assembly") and original_camera.current and scene.actors.all(func(actor): return not actor.performing_assembly and actor.presentation.animation_player.speed_scale == 1)
		world.dialogue_state.free()
		world.free()
	return checks
