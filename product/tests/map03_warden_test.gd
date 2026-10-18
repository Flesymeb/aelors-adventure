extends Node
## Explicit memory-only prepared combat; not earned LN02 or Continue evidence.
const ENTRY = preload("res://tests/map03_entry_test.gd")
const CIRCUIT = preload("res://tests/map03_barrier_test.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const STATE = preload("res://dialogue_state.gd")

class HeavyPresentationProbe extends Node:
	# Explicitly attached by a Developer diagnostic; never normal startup.
	var observations: Dictionary = {}
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		observations = await load("res://tests/map03_warden_test.gd").heavy_presentation_checks(self)
	func _mcp_state() -> Dictionary:
		return observations

class WardenRouter extends ENTRY.DiagnosticTombRouter:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		state = ENTRY.TombState.new()
		state.name = "DiagnosticState"
		add_child(state)
		var prepared: Node = CIRCUIT.prepared()
		prepared.reveal_ln02()
		prepared.cut_ln02_supply("north")
		prepared.cut_ln02_supply("south")
		prepared.purify_ln02()
		state.restore_config(HISTORY.history(prepared))
		prepared.free()
		state.selected_equipment = "sword"
		audio = preload("res://ui/menu_audio.gd").new()
		audio.name = "DiagnosticAudio"
		audio.state = state
		add_child(audio)
		_bind_tomb({"position":Vector3(4,0,-9),"map_id":state.MAP03,"yaw":0.0})

func _ready() -> void:
	var router := WardenRouter.new()
	router.name = "WardenDiagnostic"
	add_child(router)

class PhaseEncounter extends Node3D:
	var cues := 0
	func enter_pressure_phase() -> void: cues += 1

static func binding_checks() -> Dictionary:
	var native: Node3D = preload("res://assets/bosses/warden_actor.glb").instantiate()
	var animator: AnimationPlayer = native.find_child("AnimationPlayer",true,false)
	var skeleton: Skeleton3D = native.find_child("Skeleton3D",true,false)
	var checks := {"native_complete":skeleton != null and native.find_children("*","MeshInstance3D",true,false).size() == 2,
		"native_boulder_bone":skeleton.find_bone("Boulder.r_12") >= 0,
		"native_clips":animator.has_animation("Idle") and animator.has_animation("Walk") and animator.has_animation("Attack1") and animator.has_animation("Attack3") and animator.has_animation("Defence3") and animator.has_animation("IdlePieces")}
	for key in ["Idle","Walk","Attack1","Attack3","Defence3","IdlePieces"]:
		var clip: Animation = animator.get_animation(key)
		for track in clip.get_track_count():
			var path: NodePath = clip.track_get_path(track)
			var node: Node = animator.get_node(animator.root_node).get_node_or_null(NodePath(path.get_concatenated_names()))
			checks[key+"_native_track_root"] = checks.get(key+"_native_track_root",true) and node == skeleton and skeleton.find_bone(path.get_subname(0)) >= 0
	var death: Animation = preload("res://assets/bosses/warden_animation_driver.gd").reversed_clip(animator.get_animation("IdlePieces"))
	checks.native_death_reverse = is_equal_approx(death.length,6.25) and death.get_track_count()==28
	for track in death.get_track_count():
		var source: Animation = animator.get_animation("IdlePieces")
		checks["death_reverses_track_"+str(track)] = death.track_get_key_value(track,0)==source.track_get_key_value(track,source.track_get_key_count(track)-1)
	var actor: Node = preload("res://assets/bosses/warden_actor.tscn").instantiate()
	var encounter := PhaseEncounter.new()
	actor.encounter = encounter
	actor.health_component = actor.get_node("HealthComponent")
	actor.health_component.max_health = 240
	actor.health_component.health = 121
	checks.no_early_phase = not actor.enter_pressure_if_needed() and encounter.cues==0
	actor.health_component.health = 120
	checks.threshold_once_without_heal = actor.enter_pressure_if_needed() and actor.health==120 and actor.pressure_phase and not actor.next_wave and encounter.cues==1
	actor.health_component.health = 60
	checks.phase_not_replayed = not actor.enter_pressure_if_needed() and actor.health==60 and actor.pressure_changes==1 and encounter.cues==1
	actor.free(); encounter.free(); native.free()
	return checks

static func heavy_presentation_checks(parent: Node) -> Dictionary:
	# Explicit disposable presentation fixture. These callbacks test ownership,
	# never establish a real boulder/floor contact or ordinary encounter entry.
	var fx := preload("res://combat/warden_heavy_presentation.gd").new()
	parent.add_child(fx)
	fx.configure(null)
	fx.begin(11)
	var checks := {"no_contact_no_burst":not fx.active and fx.bursts==0,
		"missing_surface_rejected":not fx.world_contact({},11),
		"invalid_normal_rejected":not fx.world_contact({"point":Vector3.ZERO,"normal":Vector3.ZERO},11),
		"stale_attack_rejected":not fx.world_contact({"point":Vector3.ZERO,"normal":Vector3.UP},10)}
	var hit := {"point":Vector3(1,0,2),"normal":Vector3.UP}
	checks.one_world_response = fx.world_contact(hit,11) and fx.active and fx.settled and fx.bursts==1 and fx.contact_kind=="floor"
	checks.repeat_contact_suppressed = not fx.world_contact(hit,11) and fx.bursts==1
	checks.effects_bus_and_locality = fx.impact.bus=="Effects" and fx.swing.bus=="Effects" and fx.global_position.distance_to(hit.point+Vector3.UP*0.035)<0.001
	# AudioStreamPlayer3D starts pending voices on its next physics update.
	# Exercise both live voices rather than asking an unstarted swing to pause.
	fx.play_swing(hit.point)
	await parent.get_tree().physics_frame
	await parent.get_tree().process_frame
	checks.pause_starts_with_live_voices = fx.impact.playing and fx.swing.playing and fx.impact.get_stream_playback()!=null and fx.swing.get_stream_playback()!=null
	# Use the actual tree pause lifecycle: manually calling a notification does
	# not suspend can_process(), and 3D audio reconciles playback against it.
	# The opt-in probe remains ALWAYS and restores exactly the prior pause state.
	var tree: SceneTree = parent.get_tree()
	var prior_paused: bool = tree.paused
	tree.paused = true
	await tree.process_frame
	await tree.process_frame
	checks.pause_voices = fx.impact.stream_paused and fx.swing.stream_paused
	tree.paused = prior_paused
	await tree.process_frame
	checks.resume_voices = not fx.impact.stream_paused and not fx.swing.stream_paused and fx.impact.playing and fx.swing.playing
	fx._process(1.5)
	checks.expiry_cleans_without_rearming = not fx.active and not fx.ring.visible and not fx.dust.emitting and not fx.impact.playing and not fx.world_contact(hit,11)
	fx.begin(12)
	checks.next_attack_can_contact = fx.world_contact({"point":Vector3.ZERO,"normal":Vector3.RIGHT},12) and fx.bursts==2 and fx.contact_kind=="stone"
	fx.clear()
	checks.interruption_cleans_singleton = not fx.active and not fx.ring.visible and not fx.dust.visible and not fx.impact.playing and not fx.swing.playing and fx.get_child_count()==4
	fx.free()
	return checks

static func run() -> Dictionary:
	var checks := binding_checks()
	var state: Node = CIRCUIT.prepared()
	checks.blocked_before_ln02 = not state.defeat_warden() and not state.inspect_warden_device()
	state.reveal_ln02(); state.cut_ln02_supply("south"); state.cut_ln02_supply("north"); state.purify_ln02()
	var xp: int = state.experience
	var lives: int = state.lives
	checks.defeat_once = state.defeat_warden() and not state.defeat_warden()
	checks.victory_not_release = state.warden_defeated and not state.warden_lock_released and not state.emergency_release_tool
	var victory: ConfigFile = HISTORY.history(state)
	checks.victory_valid = state.config_unavailable_reason(victory) == ""
	checks.device_once = state.inspect_warden_device() and not state.inspect_warden_device() and state.warden_lock_released and state.emergency_release_tool
	checks.no_duplicate_rewards = state.experience == xp and state.lives == lives
	var saved: ConfigFile = HISTORY.history(state)
	checks.device_history_valid = state.config_unavailable_reason(saved) == ""
	var restored: Node = STATE.new()
	restored.restore_config(saved)
	checks.native_decode = STATE.HISTORY_READER.decode(saved.encode_to_text()).reason == ""
	checks.restore = restored.warden_defeated and restored.warden_lock_released and restored.emergency_release_tool and not restored.inspect_warden_device() and restored.experience == xp
	checks.victory_journal = restored.quest_entries().any(func(row): return row.id == "warden" and row.complete and row.context.contains("旧灯逐人") and row.context.contains("应急解除器"))
	for key in ["warden_defeated","warden_lock_released","emergency_release_tool"]: saved.erase_section_key("post_bow",key)
	checks.old_save_valid = state.config_unavailable_reason(saved) == ""
	restored.restore_config(saved)
	checks.old_defaults = not restored.warden_defeated and not restored.warden_lock_released and not restored.emergency_release_tool
	for change in [{"key":"warden_defeated","value":"true"},{"key":"ln02_purified","value":false},{"key":"warden_defeated","value":false},{"key":"emergency_release_tool","value":false}]:
		var invalid: ConfigFile = HISTORY.history(state)
		invalid.set_value("post_bow",change.key,change.value)
		checks["invalid_"+change.key+str(change.value)] = state.config_unavailable_reason(invalid) != ""
	var actor: Node = load("res://assets/bosses/warden_actor.tscn").instantiate()
	actor.position = Vector3(3,2,-12)
	checks.wave_boundary = actor.wave_contains(Vector3(4.7,2,-12)) and not actor.wave_contains(Vector3(4.9,2,-12)) and not actor.wave_contains(Vector3(3,4,-12))
	actor.free(); state.free(); restored.free()
	return checks

static func live_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.warden_encounter
	if not boss.combat_allowed(): return {"ready":false,"reason":"requires active prepared combat"}
	var hp: float = world.dialogue_state.health
	var source := SnaielDamageSource.new()
	source.entity = world.player
	source.can_damage = true
	source.damage_attributes.health = 12
	source.instance = 104
	var before: float = boss.actor.health
	var first: Dictionary = boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	var second: Dictionary = boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	var checks := {"authoritative_health":first.get("hp_loss",0)==12 and boss.actor.health==before-12,"once_per_instance":second.is_empty() and boss.actor.health==before-12}
	boss.interrupt()
	checks.recovery_resets_unfinished = boss.actor.health==240 and not boss.actor.source.can_damage and not boss.actor.wave_source.can_damage and not boss.actor.telegraph.visible and not boss.music.playing and not boss.owns_score and boss.phase=="waiting" and world.player.camera.current
	checks.progress_preserved = world.dialogue_state.ln02_purified and not world.dialogue_state.warden_defeated and world.dialogue_state.health==hp
	source.free()
	return checks

static func transaction_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.warden_encounter
	if not boss.combat_allowed(): return {"ready":false,"reason":"requires active prepared combat"}
	# This test owns only the opt-in memory-history fixture, never user saves.
	var old: Dictionary = world.dialogue_state.adventure_snapshot()
	var source := SnaielDamageSource.new()
	source.entity = world.player
	source.can_damage = true
	source.instance = 904
	source.damage_attributes.health = 500
	var result: Dictionary = boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	var checks := {"death_resolved":result.get("outcome","")=="defeat","victory_committed_once":world.dialogue_state.warden_defeated and boss.victory_commits==1,"attacks_stopped":not boss.actor.source.can_damage and not boss.actor.wave_source.can_damage and not boss.actor.hitbox.enabled,"device_separate":not world.dialogue_state.warden_lock_released and not world.dialogue_state.emergency_release_tool}
	checks.device_approach_supported = world.ground_policy.place(world,world.player,Vector2(5.1,-12.5))
	checks.device_reachable = boss.device.interaction_prompt() != ""
	checks.inspect_commit = boss.device.interact() and world.dialogue_state.warden_lock_released and world.dialogue_state.emergency_release_tool
	var count: int = boss.device.inspections
	checks.repeat_no_grant = boss.device.interact() and count==1 and boss.device.inspections==count
	var config: ConfigFile = world.dialogue_state.histories[0]
	checks.committed_valid = world.dialogue_state.config_unavailable_reason(config)==""
	world.dialogue_state.restore_config(config)
	boss.restore_history()
	checks.restored_victory = boss.actor.health==0 and world.dialogue_state.warden_lock_released and world.dialogue_state.emergency_release_tool and not boss.music.playing
	world.dialogue_state.restore_adventure(old)
	boss.restore_history()
	source.free()
	return checks

static func recovery_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.warden_encounter
	if not boss.combat_allowed(): return {"ready":false,"reason":"requires active prepared combat"}
	var state: Node = world.dialogue_state
	var lives: int = state.lives
	var source := SnaielDamageSource.new()
	source.entity = boss.actor
	source.can_damage = true
	source.instance = 1204
	source.damage_attributes.health = 500
	source.set_meta("unblockable",true)
	source.set_meta("unparryable",true)
	source.set_meta("ranged_contact",true)
	var result: Dictionary = world.training.player_hitbox.contact(source,world.player.global_position+Vector3.UP)
	var checks := {"single_life_settlement":result.get("hp_after",-1)==0 and state.lives==lives-1 and state.recovery_pending,"death_cleans_encounter":boss.phase=="waiting" and not boss.music.playing and not boss.actor.source.can_damage and not boss.actor.wave_source.can_damage}
	world.training.recover_at_checkpoint()
	checks.cp03_recovery = Vector2(world.player.global_position.x,world.player.global_position.z).distance_to(world.checkpoint_xz()) < 0.01 and world.player.is_inside_tree() and state.health==100 and not state.recovery_pending
	checks.unfinished_reset = boss.actor.health==240 and not state.warden_defeated and state.ln02_purified and not boss.actor.telegraph.visible and world.player.camera.current
	checks.recovery_commit_valid = state.config_unavailable_reason(state.histories[0])==""
	source.free()
	return checks

static func approach_checks(parent: Node) -> Dictionary:
	var state: Node = CIRCUIT.prepared()
	parent.add_child(state)
	state.inventory.restore()
	var page := preload("res://ui/map_page.gd")
	var before: Dictionary = state.adventure_snapshot()
	var checks := {}
	for destination in ["warden","veyne"]:
		var route: Array = page.selected_tomb_route(state,destination)
		checks[destination+"_locked_prerequisite"] = route.back() == preload("res://world/map03_ground.gd").RECORD and page.approach_next(state,destination).contains("仪式记录") and state.adventure_snapshot()==before
	state.acquire_ritual_record()
	state.reveal_ln02(); state.cut_ln02_supply("north"); state.cut_ln02_supply("south"); state.purify_ln02()
	before = state.adventure_snapshot()
	checks.unlocked_distinct_routes = page.selected_tomb_route(state,"warden").back()==preload("res://combat/map03_warden.gd").HOME and page.selected_tomb_route(state,"veyne").back()==preload("res://world/veyne_arena.gd").HOME and state.adventure_snapshot()==before
	state.defeat_warden()
	checks.warden_next_device = page.approach_next(state,"warden").contains("检查")
	state.defeat_veyne()
	checks.veyne_next_key = page.approach_next(state,"veyne").contains("检查钥印")
	state.free()
	return checks
