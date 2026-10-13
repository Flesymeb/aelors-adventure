extends Node
## Adapted Snaiel NonMeleeComponent + NonMeleeAnimations + SimpleNonMeleeAction.
## Source cbfecf427f9a703ebf7e940fd067ed31a729d637; MIT in LICENSES.txt.
## Product method-track events replace the upstream Globals/AnimationTree links.
signal stage_changed(stage: String)
signal action_effect
signal end_effect
signal animation_finished
var executing_action := false
var instance := 0
var timeline: AnimationPlayer
var stage := "idle"
const ANTICIPATION := 1.15
const ACTIVE := 0.45
const RECOVERY := 1.25

func configure() -> void:
	timeline = AnimationPlayer.new()
	timeline.name = "CastEvents"
	timeline.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	timeline.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	add_child(timeline)
	var library := AnimationLibrary.new()
	var clip := Animation.new()
	clip.length = ANTICIPATION + ACTIVE + RECOVERY
	var track := clip.add_track(Animation.TYPE_METHOD)
	clip.track_set_path(track,NodePath("."))
	clip.track_insert_key(track,ANTICIPATION,{"method":"receive_action_effect","args":[]})
	clip.track_insert_key(track,ANTICIPATION+ACTIVE,{"method":"receive_end_effect","args":[]})
	library.add_animation("cast",clip)
	timeline.add_animation_library("",library)
	timeline.animation_finished.connect(func(_key): receive_finished())

func perform_action() -> bool:
	if executing_action: return false
	instance += 1
	executing_action = true
	stage = "anticipation"
	stage_changed.emit(stage)
	timeline.play("cast")
	return true

func receive_action_effect() -> void:
	if not executing_action: return
	stage = "active"
	stage_changed.emit(stage)
	action_effect.emit()

func receive_end_effect() -> void:
	if not executing_action: return
	end_effect.emit()
	stage = "recovery"
	stage_changed.emit(stage)

func receive_finished() -> void:
	if not executing_action: return
	end_effect.emit()
	executing_action = false
	stage = "idle"
	animation_finished.emit()

func interrupt_action() -> void:
	if timeline: timeline.stop()
	end_effect.emit()
	executing_action = false
	stage = "idle"
