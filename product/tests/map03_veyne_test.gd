extends RefCounted
## Component checks on explicit memory-only fixtures; not ordinary earning/QA.
const CIRCUIT = preload("res://tests/map03_barrier_test.gd")
const HISTORY = preload("res://tests/chapter_travel_test.gd")
const STATE = preload("res://dialogue_state.gd")

static func state_checks() -> Dictionary:
	var state: Node = CIRCUIT.prepared()
	var checks := {"before_ln02_rejected":not state.defeat_veyne() and not state.take_veyne_key()}
	state.reveal_ln02(); state.cut_ln02_supply("north"); state.cut_ln02_supply("south"); state.purify_ln02()
	var old: Dictionary = state.training_snapshot().duplicate(true)
	checks.independent_of_warden = state.defeat_veyne() and not state.warden_defeated
	checks.once_only_defeat = not state.defeat_veyne()
	checks.victory_not_key = not state.veyne_release_key
	checks.key_once_only = state.take_veyne_key() and not state.take_veyne_key()
	var config: ConfigFile = HISTORY.history(state)
	checks.save_valid = state.config_unavailable_reason(config)==""
	var restored: Node = STATE.new()
	restored.restore_config(config)
	checks.new_facts_restored = restored.veyne_defeated and restored.veyne_release_key and not restored.warden_defeated
	config.erase_section_key("post_bow","veyne_defeated")
	config.erase_section_key("post_bow","veyne_release_key")
	checks.old_save_compatible = state.config_unavailable_reason(config)==""
	restored.restore_config(config)
	checks.old_save_defaults = not restored.veyne_defeated and not restored.veyne_release_key
	config.set_value("post_bow","veyne_release_key",true)
	checks.key_without_defeat_rejected = state.config_unavailable_reason(config)!=""
	config.set_value("post_bow","veyne_release_key",false)
	config.set_value("post_bow","veyne_defeated",true)
	config.set_value("post_bow","ln02_purified",false)
	checks.defeat_without_ln02_rejected = state.config_unavailable_reason(config)!=""
	state.restore_adventure(old)
	checks.rollback_clears_new_facts = not state.veyne_defeated and not state.veyne_release_key
	state.defeat_warden(); state.inspect_warden_device()
	checks.warden_first_allowed = state.defeat_veyne() and state.warden_defeated and state.warden_lock_released and state.emergency_release_tool
	restored.free(); state.free()
	return checks

static func binding_checks(actor: Node) -> Dictionary:
	var checks := {}
	checks.rig_present = actor.character.skeleton.get_bone_count()>10
	checks.skinned_mesh_present = actor.model.find_children("*","MeshInstance3D",true,false).any(func(mesh): return mesh.skin!=null)
	checks.contact_socket_present = actor.character.skeleton.find_bone(actor.character.contact_socket.bone_name)>=0
	for alias in ["Idle","Walk","Punch","HitReact","Death","Cast","Reveal"]:
		checks[alias+"_bound"] = actor.animator.has_animation(alias) or actor.animator.has_animation("veyne/"+alias)
	return checks

static func transaction_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.veyne_encounter
	if not boss.combat_allowed(): return {"ready":false,"reason":"prepared active fight required"}
	var snapshot: Dictionary = world.dialogue_state.adventure_snapshot()
	var source := SnaielDamageSource.new()
	source.entity = world.player
	source.can_damage = true
	source.damage_attributes.health = 500
	source.instance = 900
	world.dialogue_state.fail_save_after = 0
	var result: Dictionary = boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	var checks := {"lethal_contact":result.get("outcome","")=="defeat","failed_save_rolls_back":not world.dialogue_state.veyne_defeated and boss.victory_pending,"damage_closed":not boss.actor.source.can_damage and not boss.actor.beam_effect.active}
	boss.settle_defeat()
	checks.commit_once = world.dialogue_state.veyne_defeated and boss.victory_commits==1 and not boss.victory_pending
	checks.key_separate = not world.dialogue_state.veyne_release_key
	checks.wave_cleared = boss.reinforcements.units.is_empty()
	checks.key_approach_supported = world.ground_policy.place(world,world.player,Vector2(-5,-11.4))
	checks.key_prompt_available = boss.device.interaction_prompt()!=""
	world.dialogue_state.fail_save_after = 0
	boss.device.interact()
	checks.key_failed_save_rolls_back = not world.dialogue_state.veyne_release_key
	boss.device.interact()
	checks.key_commit_once = world.dialogue_state.veyne_release_key and boss.device.inspections==1
	boss.device.interact()
	checks.key_no_repeat = boss.device.inspections==1
	var committed: ConfigFile = world.dialogue_state.histories[0]
	checks.committed_valid = world.dialogue_state.config_unavailable_reason(committed)==""
	world.dialogue_state.restore_config(committed)
	boss.restore_history()
	checks.restore_defeat_key = boss.actor.health==0 and world.dialogue_state.veyne_release_key and not boss.music.playing
	world.dialogue_state.restore_adventure(snapshot)
	boss.restore_history()
	source.free()
	return checks

static func phase_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.veyne_encounter
	if not boss.combat_allowed(): return {"ready":false}
	var source := SnaielDamageSource.new()
	source.entity = world.player
	source.can_damage = true
	source.damage_attributes.health = 210
	source.instance = 800
	boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	var checks := {"threshold_no_heal":boss.actor.health==210 and boss.phase=="phase_transition" and boss.phase_starts==1,"damage_suspended":not boss.combat_allowed()}
	source.instance += 1
	var result: Dictionary = boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	checks.transition_contact_rejected = not result.get("accepted",false) and boss.actor.health==210
	boss.finish_presentation()
	checks.one_two_melee_wave = boss.reinforcements.wave_count==1 and boss.reinforcements.units.size()==2
	boss.begin_second_phase()
	checks.phase_once = boss.phase_starts==1 and boss.actor.health==210 and boss.reinforcements.wave_count==1
	boss.spawn_rifts()
	checks.rifts_warn_before_active = boss.rifts.size()==2 and not boss.rifts[0].source.can_damage
	var saved_warden: bool = world.dialogue_state.warden_defeated
	world.training.last_hp_loss = world.dialogue_state.health
	world.dialogue_state.health = 0
	var lives: int = world.dialogue_state.lives
	world.training.settle_death()
	checks.life_once = world.dialogue_state.lives==lives-1
	world.training.settle_death()
	checks.life_not_repeat = world.dialogue_state.lives==lives-1
	world.training.recover_at_checkpoint()
	checks.retry_reset = boss.actor.health==420 and not boss.actor.pressure_phase and boss.phase=="waiting" and boss.reinforcements.wave_count==0 and boss.reinforcements.units.is_empty() and boss.rifts.is_empty() and not boss.actor.beam_effect.active
	checks.warden_preserved = world.dialogue_state.warden_defeated==saved_warden
	checks.cp03_position = Vector2(world.player.global_position.x,world.player.global_position.z).distance_to(world.checkpoint_xz())<0.1
	checks.ownership_released = world.pause_owners.is_empty() and world.player.camera.current and not boss.music.playing
	source.free()
	return checks

static func beam_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.veyne_encounter
	if not boss.combat_allowed(): return {"ready":false}
	var effect: Node = boss.actor.beam_effect
	var hp: float = world.dialogue_state.health
	var old_pos: Vector3 = world.player.global_position
	boss.actor.interrupt_action()
	world.training.protection = 0
	world.training.parry_window = 0.25
	world.training.blocking = true
	world.player.visual.rotation.y = PI
	world.ground_policy.place(world,world.player,Vector2(-4,-9.8))
	await world.get_tree().create_timer(0.1,false,true).timeout
	effect.prepare(boss.actor.global_position+Vector3.UP,Vector3.BACK)
	effect.effect(700)
	var hit: Dictionary = effect.sample_contact()
	var checks := {"physical_hit":hit.get("accepted",false) and hit.get("outcome","")=="hurt" and world.dialogue_state.health<hp,"beam_not_parried":hit.get("outcome","")!="parry" and effect.active}
	var after: float = world.dialogue_state.health
	effect.sample_contact()
	checks.single_instance = world.dialogue_state.health==after
	effect.end()
	world.training.blocking = false
	world.training.parry_window = 0
	world.dialogue_state.health = hp
	world.ground_policy.place(world,world.player,Vector2(-5.1,-9.8))
	await world.get_tree().create_timer(0.1,false,true).timeout
	effect.prepare(boss.actor.global_position+Vector3.UP,Vector3.BACK)
	effect.effect(701)
	checks.lateral_miss = effect.sample_contact().is_empty() and world.dialogue_state.health==hp
	effect.end()
	world.ground_policy.place(world,world.player,Vector2(4,-12))
	await world.get_tree().create_timer(0.1,false,true).timeout
	effect.prepare(boss.actor.global_position+Vector3.UP,Vector3.RIGHT)
	effect.effect(702)
	checks.native_obstruction = effect.blocked and effect.clipped_length<6.0 and effect.sample_contact().is_empty() and world.dialogue_state.health==hp
	effect.end()
	world.player.global_position = old_pos
	world.player.visual.rotation.y = 0
	world.training.hurt_time = 0
	world.training.phase = "idle"
	return checks

static func rift_checks(world: Node3D) -> Dictionary:
	var boss: Node = world.veyne_encounter
	if not boss.combat_allowed() or not boss.actor.pressure_phase: return {"ready":false}
	world.training.protection = 0
	world.training.hurt_time = 0
	world.training.blocking = false
	var hp: float = world.dialogue_state.health
	boss.spawn_rifts()
	boss.update_rifts(0.8)
	var checks := {"warning_no_damage":world.dialogue_state.health==hp}
	boss.update_rifts(0.5)
	checks.active_inside_damage = world.dialogue_state.health==hp-12 and boss.rift_contacts>0
	var after: float = world.dialogue_state.health
	boss.update_rifts(0.01)
	checks.once_per_rift = world.dialogue_state.health==after
	boss.clear_rifts()
	checks.cleanup_closes_danger = boss.rifts.is_empty()
	return checks
