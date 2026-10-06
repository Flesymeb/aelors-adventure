class_name SnaielMeleeAnimations
extends Node
## Snaiel's signal/event interface adapted from AnimationTree to method tracks.
signal secondary_movement(attack: SnaielMeleeAttack)
signal damage_attributes(attributes: SnaielDamageAttributes)
signal can_damage(flag: bool, weapon_names: Array[StringName])
signal can_rotate(flag: bool)
signal can_attack_again(flag: bool)
signal can_play_animation
signal attacking_finished
signal stage_changed(stage: String)
var attacks: Array[SnaielMeleeAttack] = []
var attacking = false
var _level = 0
var timeline: AnimationPlayer
var stage = "idle"
var _all_weapons: Array[StringName] = []

func configure(strategies: Array[SnaielMeleeAttack]) -> void:
	attacks = strategies
	timeline = AnimationPlayer.new()
	timeline.name = "AttackEvents"
	timeline.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	timeline.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	add_child(timeline)
	var library = AnimationLibrary.new()
	for index in attacks.size():
		var strategy = attacks[index]
		var animation = Animation.new()
		animation.length = strategy.anticipation + strategy.strike_delay + strategy.contact_time + strategy.recovery
		var track = animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(track, NodePath("."))
		animation.track_insert_key(track, strategy.anticipation, {"method": "receive_strike", "args": []})
		animation.track_insert_key(track, strategy.anticipation + strategy.strike_delay, {"method": "receive_can_damage", "args": []})
		animation.track_insert_key(track, strategy.anticipation + strategy.strike_delay + strategy.contact_time, {"method": "receive_cannot_damage", "args": []})
		library.add_animation(str(index), animation)
	timeline.add_animation_library("", library)
	timeline.animation_finished.connect(func(_key): receive_attack_finished())

func attack(level: int, _override_can_play = false) -> void:
	_level = level
	attacking = true
	damage_attributes.emit(attacks[level].damage_attributes)
	can_rotate.emit(false)
	stage = "anticipation"
	stage_changed.emit(stage)
	timeline.play(str(level))

func stop_attacking() -> void:
	if timeline: timeline.stop()
	can_damage.emit(false, _all_weapons)
	can_rotate.emit(true)
	attacking = false
	stage = "idle"

func receive_strike() -> void:
	if not attacking: return
	stage = "strike"
	stage_changed.emit(stage)
	secondary_movement.emit(attacks[_level])

func receive_can_damage() -> void:
	if not attacking: return
	stage = "contact"
	stage_changed.emit(stage)
	can_damage.emit(true, _all_weapons)

func receive_cannot_damage() -> void:
	if not attacking: return
	can_damage.emit(false, _all_weapons)
	stage = "recovery"
	stage_changed.emit(stage)
	can_attack_again.emit(true)
	can_play_animation.emit()

func receive_attack_finished() -> void:
	if not attacking: return
	stop_attacking()
	attacking_finished.emit()
