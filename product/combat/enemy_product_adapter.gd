extends "res://combat/snaiel/scripts/entities/enemy.gd"
## Thin product adapter. SwordTraining retains teaching/recovery, DialogueState
## retains save/quest/reward facts; the reusable unit owns enemy execution.
var training: Node3D

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
	reset_unit(training.state.encounter_defeated, training.state.remnant_collected)
	if not navigation_region and training.grounded: build_navigation()

func begin_practice_replay() -> void:
	reset_unit(false, false)
	practice_replay = true

func _settle_defeat() -> void:
	if not practice_replay: training.enemy_defeated()
	else: training.tell("复练结束 · 不重复发放初战奖励", 4)
