extends RefCounted
## Opt-in component fixture: production contact/defense/death routing with
## presentation spies. No acquisition, progression or persistent save writes.

class ContactState extends Node:
	var health := 100.0
	var lives := 4
	var reduced_motion := false
	var recovery_pending := false
	var conversation_active := false
	var practice_defense := false
	var practice_parry := false
	func checkpoint_name() -> String: return "fixture"

class Traversal extends Node:
	var action := ""
	var action_time := 0.0

class ContactPlayer extends CharacterBody3D:
	var traversal: Traversal
	var visual: Node3D
	var animation_player: AnimationPlayer
	var attack_timer := 0.0
	var current_animation := ""
	var played := ""
	func reset_archery() -> void: pass
	func _play_animation(clip: String) -> void: played = clip

class ContactEnemy extends CharacterBody3D:
	var attack_origin := Vector3(0, 0, 1)
	var locked_direction := Vector3(0, 0, -1)
	func interrupt_action() -> void: pass

class ContactWorld extends Node3D:
	var veyne_encounter = null
	var warden_encounter = null
	var element_abilities = null
	var channel_guards = null
	var ambush_encounter = null
	var line_encounter = null
	var pressure_encounter = null
	var bridge_encounter = null
	var dynamic_encounters = null
	var bow_training = null

class ContactFeedback extends CanvasLayer:
	var events: Array[Dictionary] = []
	var clear_count := 0
	func impact(point: Vector3, label: String, loss: float, kind = "hit", contact: Dictionary = {}) -> void:
		events.append({"point": point, "label": label, "hp_loss": loss, "kind": kind, "contact": contact.duplicate(true)})
	func clear_feedback() -> void:
		events.clear()
		clear_count += 1

class ContactTraining extends "res://sword_training.gd":
	var commits := 0
	func commit() -> bool:
		commits += 1
		return true
	func tell(_message: String, _seconds = 2.6, _event_id := "") -> void: pass

static func run(holder: Node) -> Dictionary:
	var stage := ContactWorld.new()
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	holder.add_child(stage)
	var training := ContactTraining.new()
	stage.add_child(training)
	training.world = stage
	var state := ContactState.new()
	stage.add_child(state)
	training.state = state
	var player := ContactPlayer.new()
	player.name = "Player"
	stage.add_child(player)
	player.traversal = Traversal.new()
	player.add_child(player.traversal)
	player.visual = Node3D.new()
	player.add_child(player.visual)
	player.animation_player = AnimationPlayer.new()
	player.add_child(player.animation_player)
	training.player = player
	var feedback := ContactFeedback.new()
	stage.add_child(feedback)
	training.feedback = feedback
	var enemy := ContactEnemy.new()
	stage.add_child(enemy)
	training.monster = enemy
	var source := SnaielDamageSource.new()
	enemy.add_child(source)
	source.entity = enemy
	source.damage_attributes.health = 20.0
	source.can_damage = true
	var hitbox := SnaielHitbox.new()
	player.add_child(hitbox)
	hitbox.entity = player
	hitbox.policy = training.resolve_player_contact
	training.player_hitbox = hitbox
	var events := SnaielMeleeAnimations.new()
	stage.add_child(events)
	events.configure([])
	training.sword_events = events
	training.sword_source = SnaielDamageSource.new()
	stage.add_child(training.sword_source)
	var checks := {}
	var point := Vector3(0.38, 1.24, 0.15)
	var result := hitbox.contact(source, point)
	checks.hurt_resolves_actual_loss = result.outcome == "hurt" and state.health == 80.0 and result.hp_loss == 20.0
	checks.hurt_locality_and_identity = matches(feedback.events.back(), result, point, "hurt")
	var count := feedback.events.size()
	checks.duplicate_source_does_not_settle = hitbox.contact(source, Vector3(1, 1, 1)).is_empty() and state.health == 80 and feedback.events.size() == count
	reset_contact(training, source)
	training.blocking = true
	point = Vector3(-0.45, 1.45, 0.1)
	result = hitbox.contact(source, point)
	checks.block_mitigates_and_keeps_contact = result.outcome == "block" and result.hp_loss == 6.0 and state.health == 94.0 and matches(feedback.events.back(), result, point, "block")
	reset_contact(training, source)
	training.blocking = true
	training.parry_window = 0.1
	var parried := [0]
	source.parried.connect(func(): parried[0] += 1)
	result = hitbox.contact(source, point)
	checks.parry_keeps_contact_and_short_stop = result.outcome == "parry" and state.health == 100 and parried[0] == 1 and is_equal_approx(training.hit_stop, 0.055) and matches(feedback.events.back(), result, point, "parry")
	reset_contact(training, source)
	training.blocking = true
	training.parry_window = 0.1
	source.set_meta("unparryable", true)
	result = hitbox.contact(source, point)
	checks.unparryable_retains_block = result.outcome == "block" and training.hit_stop == 0 and parried[0] == 1
	source.remove_meta("unparryable")
	reset_contact(training, source)
	enemy.attack_origin = Vector3(0, 0, 8)
	source.set_meta("ranged_contact", true)
	point = Vector3(0.2, 0.65, -0.22)
	result = hitbox.contact(source, point)
	checks.projectile_keeps_tip_contact = result.hp_loss == 20.0 and matches(feedback.events.back(), result, point, "hurt")
	reset_contact(training, source)
	source.remove_meta("ranged_contact")
	result = hitbox.contact(source, point)
	checks.miss_has_no_feedback_or_stop = result.outcome == "miss" and state.health == 100 and feedback.events.is_empty() and training.hit_stop == 0
	reset_contact(training, source)
	enemy.attack_origin = Vector3(0, 0, 1)
	player.traversal.action = "dodge"
	player.traversal.action_time = 0.1
	result = hitbox.contact(source, point)
	checks.dodge_has_no_false_damage = result.outcome == "dodge" and state.health == 100 and result.hp_loss == 0 and feedback.events.is_empty()
	reset_contact(training, source)
	training.protection = 1
	result = hitbox.contact(source, point)
	checks.protection_has_no_feedback = result.outcome == "protected" and state.health == 100 and feedback.events.is_empty()
	reset_contact(training, source)
	state.health = 7
	result = hitbox.contact(source, point)
	checks.lethal_loss_clamped_once = state.health == 0 and state.lives == 3 and training.commits == 1 and result.hp_loss == 7 and feedback.events.size() == 1 and matches(feedback.events.back(), result, point, "death")
	checks.death_animation_and_pause_recovery = training.phase == "death" and player.played == "Death01" and state.recovery_pending
	training.buffered = true
	training.finisher_buffered = true
	training.interrupt("load")
	checks.load_clears_cues_buffers_and_stop = feedback.events.is_empty() and not training.buffered and not training.finisher_buffered and training.hit_stop == 0 and hitbox.last_result.is_empty() and player.animation_player.speed_scale == 1
	# Finisher uses the same retained contact-stop boundary without changing it.
	training.phase = "idle"
	training.combo = training.FINISHER_INDEX
	training.resolved_enemy_contact({"outcome": "hit", "source_id": training.sword_source.get_instance_id(), "point": point, "hp_loss": 28.0})
	checks.finisher_stop_preserved = is_equal_approx(training.hit_stop, 0.045)
	reset_contact(training, source)
	training.blocking = true
	var simulated := training.receive_attack(enemy.attack_origin, enemy.locked_direction, 6.0, true)
	checks.simulation_is_identified_without_real_damage = simulated == "block" and state.health == 100 and feedback.events.size() == 1 and feedback.events[0].contact.simulated and feedback.events[0].hp_loss == 0 and not feedback.events[0].contact.has("source_id")
	var presenter = preload("res://reward_feedback.gd").new()
	var observed: Dictionary = presenter._contact_observation({"id": 1, "world_point": point, "source_id": source.get_instance_id(), "attack_instance": source.instance, "receiver": str(player.get_path()), "outcome": "hurt", "simulated": false, "hp_before": 7.0, "hp_after": 0.0, "hp_loss": 7.0})
	checks.readout_observation_keeps_geometry_and_result = observed.world_point == point and observed.outcome == "hurt" and observed.hp_loss == 7 and observed.source_id == source.get_instance_id() and not observed.simulated
	presenter.free()
	stage.free()
	return {"checks": checks, "scope": "isolated production contact and feedback-input routing; ordinary combat frames, obstruction, heard audio and pause/retry journeys require independent runtime review"}

static func reset_contact(training: Node3D, source: SnaielDamageSource) -> void:
	training.interrupt("load")
	training.phase = "idle"
	training.state.health = 100.0
	training.protection = 0
	training.player.traversal.action = ""
	training.player.traversal.action_time = 0
	source.instance += 1

static func matches(event: Dictionary, result: Dictionary, point: Vector3, kind: String) -> bool:
	var contact: Dictionary = event.contact
	return event.point == point and event.kind == kind and event.hp_loss == result.hp_loss and contact.source_id == result.source_id and contact.attack_instance == result.attack_instance and contact.receiver == result.receiver and contact.hp_before == result.hp_before and contact.hp_after == result.hp_after and contact.hp_loss == result.hp_loss and contact.outcome == result.outcome and not contact.simulated
