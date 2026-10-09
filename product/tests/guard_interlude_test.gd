extends RefCounted
## Explicit opt-in fixture. Never calls real-world saving or loads user progress.
const INTERLUDE = preload("res://ui/guard_interlude.gd")
const SCENE = preload("res://ui/guard_interlude.tscn")
const GUARD_TEST = preload("res://tests/channel_guard_test.gd")

class IsolatedWorld extends Node3D:
	var dialogue_state: Node
	var training: Node
	var pause_owners := {}
	var save_calls := 0
	var objective_message := ""
	func _init() -> void:
		dialogue_state = GUARD_TEST.prepared()
		training = self
	func _set_pause_owner(id: String, enabled: bool) -> void:
		if enabled: pause_owners[id] = true
		else: pause_owners.erase(id)
	func _save_opening(_slot: int) -> void:
		# Count the boundary request without touching the real save owner or files.
		save_calls += 1
	func tell(message: String, _seconds: float) -> void:
		objective_message = message
	func _exit_tree() -> void:
		dialogue_state.free()
	func _mcp_state() -> Dictionary:
		return {"isolated_fixture":true,"save_calls":save_calls,"seen":dialogue_state.guard_interlude_seen,"experience":dialogue_state.experience,"rewards":dialogue_state.reward_history.size(),"objective":objective_message,"pause_owners":pause_owners.keys()}

static func attach(parent: Node) -> Node3D:
	var world := IsolatedWorld.new()
	world.name = "IsolatedGuardPresentation"
	parent.add_child(world)
	var interlude := SCENE.instantiate()
	interlude.name = "GuardInterlude"
	interlude.world = world
	world.add_child(interlude)
	return world

static func run(parent: Node) -> Dictionary:
	var checks := {}
	var world := attach(parent)
	var interlude: CanvasLayer = world.get_node("GuardInterlude")
	interlude.set_process(false)
	var state: Node = world.dialogue_state
	var starting_xp: int = state.experience
	checks.media_available = INTERLUDE.available()
	checks.earned_gate = INTERLUDE.eligible(state)
	state.bridge_resident_rescued = false
	checks.reject_unearned = not INTERLUDE.eligible(state)
	state.bridge_resident_rescued = true
	interlude._process(0)
	interlude._process(0.5)
	checks.first_painting = interlude.picture.texture != null and interlude.beat == 0 and interlude.veil.color.a == 0
	checks.motion = interlude.picture.scale.x >= 1.02 and interlude.picture.scale.x <= 1.04
	interlude.toggle_pause()
	var clock: float = interlude.total_elapsed
	interlude._process(0)
	interlude._process(1)
	checks.pause_clock = interlude.total_elapsed == clock
	interlude.toggle_pause()
	interlude._process(0)
	state.reduced_motion = true
	interlude._process(0.1)
	checks.reduced_motion = interlude.picture.scale == Vector2.ONE
	interlude._process(1.3)
	checks.black_boundary = interlude.veil.color.a > 0.4
	interlude._process(0.2)
	checks.second_painting = interlude.beat == 1 and interlude.picture.texture != null
	interlude._process(2)
	checks.third_painting = interlude.beat == 2 and interlude.picture.texture != null
	interlude._process(2)
	interlude.finish()
	checks.normal_once = state.guard_interlude_seen and world.save_calls == 1 and world.pause_owners.is_empty()
	checks.no_victory_or_reward = state.experience == starting_xp and state.reward_history.is_empty() and not state.guards_defeated()
	checks.objective_handoff = world.objective_message == state.guard_objective()
	checks.no_replay = not INTERLUDE.eligible(state)
	var config: ConfigFile = GUARD_TEST.BRIDGE_TEST.config_for(state)
	checks.valid_seen_boundary = state.config_unavailable_reason(config) == ""
	var restored: Node = GUARD_TEST.STATE.new()
	restored.restore_config(config)
	checks.restored_no_replay_or_grant = restored.guard_interlude_seen and not INTERLUDE.eligible(restored) and restored.experience == starting_xp and restored.reward_history.is_empty()
	restored.free()
	interlude.free()
	world.free()
	world = attach(parent)
	interlude = world.get_node("GuardInterlude")
	interlude.set_process(false)
	interlude._process(0)
	interlude.finish()
	checks.skip_once = world.dialogue_state.guard_interlude_seen and world.save_calls == 1 and world.pause_owners.is_empty()
	interlude.free()
	world.free()
	world = attach(parent)
	interlude = world.get_node("GuardInterlude")
	interlude.free()
	checks.interrupted_reentry = not world.dialogue_state.guard_interlude_seen and world.save_calls == 0 and world.pause_owners.is_empty() and INTERLUDE.eligible(world.dialogue_state)
	world.free()
	return checks
