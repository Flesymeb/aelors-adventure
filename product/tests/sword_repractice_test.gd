extends Node
## Opt-in diagnostic of the real product adapter and Snaiel health/contact
## owner. The isolated state never loads or writes ordinary player saves.
class PracticeWorld extends Node3D:
	var pause_owners: Array = []

class PracticePlayer extends CharacterBody3D:
	func key_prompt(action: String) -> String:
		return "Y" if action == "heavy" else "Ctrl"

class PracticeTraining extends "res://sword_training.gd":
	var commits := 0
	var remnants := 0
	func commit() -> bool:
		commits += 1
		return true
	func show_remnant() -> void:
		remnants += 1
	func resolved_enemy_contact(_result: Dictionary) -> void:
		pass
	func tell(message: String, seconds = 2.6, _event_id := "") -> void:
		notice = message
		notice_time = seconds

var observations: Dictionary = {}

func _ready() -> void:
	observations = run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture": true, "observations": observations}

static func run(holder: Node) -> Dictionary:
	var stage := Node3D.new()
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	holder.add_child(stage)
	var world := PracticeWorld.new()
	stage.add_child(world)
	var player := PracticePlayer.new()
	stage.add_child(player)
	var history = preload("res://dialogue_state.gd").new()
	# Deliberately outside the tree: no preferences, inventory restore or saves.
	var training := PracticeTraining.new()
	training.world = world
	training.player = player
	training.state = history
	training.grounded = true
	stage.add_child(training)
	var unit = preload("res://TrainingMonster.tscn").instantiate()
	unit.training = training
	stage.add_child(unit)
	training.monster = unit
	unit.home = Vector3(2.0, 0.0, 2.0)
	unit.ground_query = func(point: Vector3): return {"position": point}
	unit.navigation_region = NavigationRegion3D.new()
	stage.add_child(unit.navigation_region)
	unit.reset_encounter()
	var checks := {}
	checks.original_health_is_24 = unit.health == 24.0 and unit.health_component.max_health == 24.0 and not unit.practice_replay
	checks.unearned_replay_rejected = not unit.begin_practice_replay() and unit.health == 24.0
	history.sword_owned = true
	history.practice_hit = true
	history.practice_defense = true
	var source := SnaielDamageSource.new()
	source.entity = player
	source.can_damage = true
	source.damage_attributes.health = 12.0
	stage.add_child(source)
	unit.receive_contact(source, unit.home)
	var first_hp: float = unit.health
	source.instance += 1
	unit.receive_contact(source, unit.home)
	checks.original_settlement_once = first_hp == 12.0 and unit.health == 0.0 and history.encounter_defeated and training.commits == 1 and training.remnants == 1
	checks.uncollected_remnant_rejected = not unit.begin_practice_replay()
	history.remnant_collected = true
	var before := {"experience": history.experience, "lives": history.lives, "bow": history.bow_owned, "checkpoint": history.checkpoint_name(), "commits": training.commits, "remnants": training.remnants}
	checks.pre_bow_earned_replay_96 = not history.bow_owned and unit.begin_practice_replay() and unit.health == 96.0 and unit.health_component.max_health == 96.0 and unit.practice_replay
	unit.engaged = true
	unit.health_component.health = 80.0
	checks.engaged_restart_cannot_heal = not unit.begin_practice_replay() and unit.health == 80.0
	unit.engaged = false
	unit.health_component.health = 96.0
	for damage in [12.0, 15.0, 20.0, 28.0]:
		source.instance += 1
		source.damage_attributes.health = damage
		unit.receive_contact(source, unit.home)
	checks.full_existing_damage_sequence_survives = unit.health == 21.0
	source.instance += 1
	source.damage_attributes.health = 1000.0
	unit.receive_contact(source, unit.home)
	checks.replay_lethal_no_reward = unit.health == 0.0 and training.commits == before.commits and training.remnants == before.remnants
	unit.end_practice_replay()
	checks.teardown_restores_committed_defeat = not unit.practice_replay and unit.health == 0.0 and unit.health_component.max_health == 24.0 and not unit.visible and not unit.source.can_damage
	checks.repeat_start_allowed = unit.begin_practice_replay() and unit.health == 96.0
	unit.end_practice_replay()
	world.pause_owners.append("pause")
	checks.modal_start_rejected = not unit.begin_practice_replay()
	world.pause_owners.clear()
	checks.remapped_guidance = training.repractice_guidance().contains("[Y]") and training.repractice_guidance().contains("[Ctrl]")
	checks.progression_unchanged = history.experience == before.experience and history.lives == before.lives and history.bow_owned == before.bow and history.checkpoint_name() == before.checkpoint and history.encounter_defeated and history.remnant_collected
	var passed := true
	for value in checks.values(): passed = passed and value
	stage.free()
	history.free()
	return {"passed": passed, "checks": checks, "scope": "isolated earned-state adapter and actual Snaiel contact diagnostics; ordinary acquisition/remnant, A/B/C/T input, pause/resume, leash, Continue, heard audio and performance remain independent runtime checks"}
