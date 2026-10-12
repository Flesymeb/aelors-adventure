extends Node
## Explicit memory-only prepared combat; not earned LN02 or Continue evidence.
const ENTRY = preload("res://tests/map03_entry_test.gd")
const CIRCUIT = preload("res://tests/map03_barrier_test.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const STATE = preload("res://dialogue_state.gd")

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

static func run() -> Dictionary:
	var checks := {}
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
	checks.victory_journal = restored.quest_entries().any(func(row): return row.id == "warden" and row.complete and row.context.contains("逐人释放"))
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
