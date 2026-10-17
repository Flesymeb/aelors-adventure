extends "res://combat/snaiel/scripts/entities/enemy.gd"
## Thin product adapter. SwordTraining retains teaching/recovery, DialogueState
## retains save/quest/reward facts; the reusable unit owns enemy execution.
var training: Node3D
const ENCOUNTER_HEALTH := 24.0
const REPLAY_HEALTH := 96.0

func _ready() -> void:
	target = training.player
	enabled_policy = func(): return training.grounded and training.state.practice_hit and training.state.practice_defense and training.state.sword_owned and not training.player_locked() and (practice_replay or not training.state.encounter_defeated)
	ground_query = func(point: Vector3): return preload("res://forest_ground.gd").support(training.world, Vector2(point.x, point.z), [get_rid(), target.get_rid()])
	contact_policy = func(damage_source, point): return training.player_hitbox.contact(damage_source, point)
	result_listener = training.resolved_enemy_contact
	attack_cue = training.feedback_swing
	acquired_cue = func(): training.tell("训练怪 · 抬手后出拳；退回赫斯处可脱离", 4)
	dead.connect(_settle_defeat)
	super()

func reset_encounter() -> void:
	health_component.max_health = ENCOUNTER_HEALTH
	reset_unit(training.state.encounter_defeated, training.state.remnant_collected)
	if not is_instance_valid(navigation_region) and training.grounded: build_navigation()

func begin_practice_replay() -> bool:
	# All callers use the earned product gate; reinteraction cannot heal, move
	# or restart an opponent that is still in a live replay.
	if practice_replay or engaged or returning or not training.can_repractice(): return false
	health_component.max_health = REPLAY_HEALTH
	reset_unit(false, false)
	practice_replay = true
	return true

func end_practice_replay() -> void:
	if not practice_replay: return
	reset_encounter()

func _physics_process(delta: float) -> void:
	var was_returning: bool = returning
	super(delta)
	# Keep ordinary pursuit and leash/return behavior. Only retire the optional
	# unit once that return has completed, without resetting an engaged target.
	if practice_replay and was_returning and health > 0 and not engaged and not returning and global_position.distance_to(home) <= 0.35 and target.global_position.distance_to(home) > 6.0:
		end_practice_replay()

func _settle_defeat() -> void:
	if not practice_replay: training.enemy_defeated()
	else: training.tell("复练结束 · 不重复发放初战奖励", 4)
