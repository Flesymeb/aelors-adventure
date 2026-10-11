extends RefCounted
## Opt-in component/state checks. They do not earn an ordinary route victory.
const AMBUSH = preload("res://tests/map02_ambush_test.gd")
const RECORD = preload("res://world/map02_line_record.gd")
const SWITCH = preload("res://interaction/nodragem/short_interaction_switch.gd")
const GROUND = preload("res://world/map02_ground.gd")

class Feedback extends Node:
	var commits := 0
	var cues := 0
	func commit() -> void: commits += 1
	func tell(_text: String, _duration: float) -> void: pass
	func play_cue(_cue: String) -> void: cues += 1

class DetachedWorld extends Node3D:
	var training := Feedback.new()
	var menu_audio := Feedback.new()
	func _init() -> void:
		add_child(training)
		add_child(menu_audio)

static func run() -> Dictionary:
	var checks := {}
	var state: Node = AMBUSH.prepared()
	var world := DetachedWorld.new()
	var record: Node = RECORD.new()
	world.add_child(record)
	record.world = world
	record.state = state
	record.record_switch = SWITCH.new()
	record.supply_switch = SWITCH.new()
	record.add_child(record.record_switch)
	record.add_child(record.supply_switch)
	record.restore_history()
	record.record_switch.activation_signal.connect(record._record_activated)
	record.supply_switch.activation_signal.connect(record._supply_activated)
	record.record_switch.on_interaction(true)
	record.supply_switch.on_interaction(true)
	checks.prerequisites_not_bypassed = not state.mf02_acquired and not state.line_supply_claimed and not record.record_switch.is_activated and not record.supply_switch.is_activated and world.training.commits == 0
	state.e03_revealed = true
	for id in state.AMBUSH_IDS: state.settle_ambush(Vector3(4,1,75), {}, id)
	for id in state.LINE_IDS: state.settle_line(Vector3(9,1,95), {}, id)
	record.record_switch.on_interaction(true)
	checks.record_once = state.mf02_acquired and record.record_switch.is_activated and world.training.commits == 1
	record.record_switch.on_interaction(true)
	record.restore_history()
	checks.restore_no_reaward = world.training.commits == 1 and state.mf02_acquired
	state.health = 100
	record.supply_switch.on_interaction(true)
	checks.full_health_keeps_source = not state.line_supply_claimed and not record.supply_switch.is_activated and world.training.commits == 1
	state.health = 60
	record.supply_switch.on_interaction(true)
	checks.separate_supply_once = state.health == 80 and state.line_supply_claimed and record.supply_switch.is_activated and world.training.commits == 2
	record.supply_switch.on_interaction(true)
	record.restore_history()
	checks.supply_restore_no_reaward = state.health == 80 and world.training.commits == 2
	checks.distinct_fixed_stances = GROUND.LINE_RECORD.distance_to(GROUND.LINE_SUPPLY) > 8 and GROUND.LINE_RECORD_APPROACH.distance_to(GROUND.LINE_RECORD) < 2.4 and GROUND.LINE_SUPPLY_APPROACH.distance_to(GROUND.LINE_SUPPLY) < 2.4
	checks.restore_region = GROUND.entry_xz(Vector3(11,2,101), GROUND.MAP02_ID) == Vector2(11,101)
	checks.native_props = load("res://Prefabs/Prop/Sign/EA03_Prop_Sign_Chapel_01_PRE.prefab.scn") != null and load("res://Prefabs/Prop/Container/EA03_Prop_Container_Chest_02a_PRE.prefab.scn") != null
	world.free()
	state.free()
	return checks
