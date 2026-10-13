extends Node
## Explicit, disposable prepared fixture. Never earns LN02 or writes user saves.
const ENTRY = preload("res://tests/map03_entry_test.gd")
const CIRCUIT = preload("res://tests/map03_barrier_test.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
@export var warden_completed := false
var router: Node
var code_checks := {}
var component_results := {}
var component_busy := false

class VeyneRouter extends ENTRY.DiagnosticTombRouter:
	var warden_completed := false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		state = ENTRY.TombState.new()
		state.name = "DiagnosticState"
		add_child(state)
		var prepared: Node = CIRCUIT.prepared()
		prepared.reveal_ln02(); prepared.cut_ln02_supply("north"); prepared.cut_ln02_supply("south"); prepared.purify_ln02()
		if warden_completed: prepared.defeat_warden(); prepared.inspect_warden_device()
		state.restore_config(HISTORY.history(prepared))
		prepared.free()
		state.selected_equipment = "sword"
		audio = preload("res://ui/menu_audio.gd").new()
		audio.name = "DiagnosticAudio"
		audio.state = state
		add_child(audio)
		_bind_tomb({"position":Vector3(-4,0,-5),"map_id":state.MAP03,"yaw":0.0})

func _ready() -> void:
	code_checks = preload("res://tests/map03_veyne_test.gd").state_checks()
	router = VeyneRouter.new()
	router.name = "VeyneDiagnostic"
	router.warden_completed = warden_completed
	add_child(router)

func _mcp_state() -> Dictionary:
	return {"fixture":"memory_only_after_ln02","earned_route":false,"warden_completed":warden_completed,"code_checks":code_checks,"ready":router.diagnostic_ready if router else false,"component_results":component_results,"component_busy":component_busy}

func run_component_checks(kind: String) -> void:
	if component_busy or not router.diagnostic_ready: return
	component_busy = true
	var world: Node3D = router.world
	var actor: CharacterBody3D = world.veyne_encounter.actor
	var mode := actor.process_mode
	var warden_mode: int = world.warden_encounter.process_mode
	world.warden_encounter.process_mode = Node.PROCESS_MODE_DISABLED
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	var test = preload("res://tests/map03_veyne_test.gd")
	if kind == "beam": component_results[kind] = await test.beam_checks(world)
	elif kind == "phase_retry": component_results[kind] = test.phase_checks(world)
	elif kind == "transaction": component_results[kind] = test.transaction_checks(world)
	actor.process_mode = mode
	world.warden_encounter.process_mode = warden_mode
	component_busy = false
