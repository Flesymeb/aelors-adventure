extends RefCounted
## Explicit opt-in fixture. Never calls real-world saving or loads user progress.
const INTERLUDE = preload("res://ui/guard_interlude.gd")
const SCENE = preload("res://ui/guard_interlude.tscn")
const GUARD_TEST = preload("res://tests/channel_guard_test.gd")

class FixturePlayer extends Node3D:
	var controls_open := false
	var handoff_calls := 0
	func set_controls_open(open: bool) -> void:
		controls_open = open
		handoff_calls += 1

class FixtureCharacter extends Node:
	var anim_tree: AnimationTree

class FixtureGuard extends CharacterBody3D:
	var health := 42.0
	var home := Vector3.ZERO
	var model: Node3D
	var animator: AnimationPlayer
	var character: Node
	var presentation: Node3D
	var phase := "idle"
	var engaged := false
	func _ready() -> void:
		model = Node3D.new()
		model.name = "Model"
		add_child(model)
		animator = AnimationPlayer.new()
		model.add_child(animator)
		var library := AnimationLibrary.new()
		for clip in ["Idle","Walk"]:
			var animation := Animation.new()
			animation.length = 1
			animation.loop_mode = Animation.LOOP_LINEAR
			var track := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track,NodePath(".:rotation:x"))
			animation.track_insert_key(track,0,0.0)
			animation.track_insert_key(track,0.5,0.08)
			library.add_animation(clip,animation)
		animator.add_animation_library("",library)
		animator.play("Idle")
		character = FixtureCharacter.new()
		add_child(character)

class FixtureRangedPresentation extends Node3D:
	var animation_player: AnimationPlayer

class IsolatedEncounter extends "res://combat/channel_guard_encounter.gd":
	func presentation_ground(destination: Vector3, _fallback: Vector3) -> Vector3:
		return destination
	func populate() -> void:
		for i in 3:
			var guard := FixtureGuard.new()
			add_child(guard)
			guard.position = Vector3(i*2,0,5)
			guard.home = guard.position
			if i == 2:
				var visual := FixtureRangedPresentation.new()
				guard.add_child(visual)
				visual.animation_player = guard.animator
				guard.presentation = visual
			enemies.append(guard)
		grounded = true
		set_physics_process(false)

class IsolatedWorld extends Node3D:
	var dialogue_state: Node
	var training: Node
	var channel_guards: Node3D
	var player: Node3D
	var isha: Node3D
	var bridge_actions: Node3D
	var gameplay_hud: CanvasLayer
	var weapon_label: Label
	var camera: Camera3D
	var pause_owners := {}
	var save_calls := 0
	var objective_message := ""
	func _init() -> void:
		dialogue_state = GUARD_TEST.prepared()
		training = self
	func _ready() -> void:
		player = FixturePlayer.new()
		add_child(player)
		channel_guards = IsolatedEncounter.new()
		channel_guards.world = self
		channel_guards.state = dialogue_state
		add_child(channel_guards)
		channel_guards.populate()
		camera = Camera3D.new()
		add_child(camera)
		camera.current = true
		gameplay_hud = CanvasLayer.new()
		add_child(gameplay_hud)
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
	checks.live_route = interlude.live_ready and interlude.beat == 0 and interlude.camera.current and not interlude.picture.visible and interlude.veil.color.a == 0
	var guard: Node3D = world.channel_guards.enemies[0]
	var initial_transform: Transform3D = world.channel_guards.presentation_records[0].transform
	checks.existing_cast_only = world.channel_guards.enemies.size() == 3 and world.channel_guards.presentation_records.size() == 3
	checks.repeated_presentation_is_idempotent = world.channel_guards.begin_presentation() and world.channel_guards.presentation_records.size() == 3
	checks.visual_clip_advances_without_gameplay = guard.animator.current_animation_position > 0 and guard.phase == "idle" and not guard.engaged and guard.health == 42
	checks.world_gameplay_paused = world.pause_owners.has("guard_interlude") and not world.gameplay_hud.visible and not world.channel_guards.combat_allowed()
	interlude.toggle_pause()
	var clock: float = interlude.total_elapsed
	var animation_clock: float = guard.animator.current_animation_position
	interlude._process(0)
	interlude._process(1)
	checks.pause_clock = interlude.total_elapsed == clock and guard.animator.current_animation_position == animation_clock
	world._set_pause_owner("controls",true)
	interlude.paused = false
	interlude._process(1)
	checks.nested_pause_freezes_cast_and_clock = interlude.total_elapsed == clock and not interlude.plate.visible and interlude.ambience.stream_paused
	world._set_pause_owner("controls",false)
	interlude.paused = true
	interlude.toggle_pause()
	interlude._process(0)
	state.reduced_motion = true
	interlude._process(0.1)
	var camera_position: Vector3 = interlude.camera.global_position
	interlude._process(0.1)
	checks.reduced_motion = interlude.camera.global_position == camera_position and interlude.live_ready
	interlude._process(2.5)
	checks.second_live_shot = interlude.beat == 1 and interlude.captions.text.contains("奥伦")
	interlude._process(3)
	checks.third_live_shot = interlude.beat == 2 and interlude.live_ready
	interlude._process(0.6)
	interlude._process(0.1)
	checks.guard_patrol_is_reversible_live_motion = guard.global_transform != initial_transform and guard.animator.assigned_animation == "Walk" and guard.phase == "idle" and guard.health == 42
	interlude._process(3)
	interlude.finish()
	checks.normal_once = state.guard_interlude_seen and world.save_calls == 1 and world.pause_owners.is_empty()
	checks.restores_cast_camera_hud = guard.global_transform == initial_transform and not world.channel_guards.presentation_active and world.channel_guards.presentation_records.is_empty() and world.camera.current and world.gameplay_hud.visible
	checks.reuses_player_fresh_input_handoff = world.player.handoff_calls == 1 and not world.player.controls_open
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
	world._set_pause_owner("controls",true)
	interlude.finish()
	checks.skip_keeps_nested_pause_owner = world.pause_owners.has("controls") and not world.pause_owners.has("guard_interlude")
	world._set_pause_owner("controls",false)
	checks.skip_once = world.dialogue_state.guard_interlude_seen and world.save_calls == 1 and world.pause_owners.is_empty()
	interlude.free()
	world.free()
	world = attach(parent)
	interlude = world.get_node("GuardInterlude")
	interlude._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	checks.focus_loss_suspends_without_commit = interlude.paused and not interlude.armed and world.save_calls == 0
	interlude.free()
	checks.interrupted_reentry = not world.dialogue_state.guard_interlude_seen and world.save_calls == 0 and world.pause_owners.is_empty() and INTERLUDE.eligible(world.dialogue_state)
	world.free()
	return checks

class LiveGuardRouter extends "res://tests/chapter_travel_test.gd".DiagnosticRouter:
	# Opt-in production-actor smoke. Uses memory-only save owner, never Continue.
	func _ready() -> void:
		super()
		var prepared: Node = GUARD_TEST.prepared()
		state.restore_config(load("res://tests/chapter_travel_test.gd").history(prepared))
		prepared.free()
	func _process(delta: float) -> void:
		super(delta)
		if diagnostic_ready: world._try_guard_interlude()
