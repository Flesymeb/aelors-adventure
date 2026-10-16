extends RefCounted
## Disposable adapter checks only. No encounter grants, saves or earned entry.
class Preferences extends Node:
	var reduced_motion := false
	var text_scale := 1.0

class DeniedVideo extends "res://ui/boss_reveal_video.gd":
	func source_manifest() -> Variant:
		return {"provider":"provider","terms":"unqualified fixture"}

class MissingVideo extends "res://ui/boss_reveal_video.gd":
	func media_path() -> String:
		return "res://assets/cinematics/veyne/__missing_test__.ogv"

class HandoffState extends Preferences:
	var veyne_defeated := false
	var health := 73.0
	var lives := 3
	var experience := 42
	var equipment := "fixture"
	func facts() -> Array:
		return [veyne_defeated,health,lives,experience,equipment]

class HandoffPlayer extends CharacterBody3D:
	var camera: Camera3D
	var suppressions := 0
	func release_encounter_camera() -> void: pass
	func suppress_held_combat_actions() -> void: suppressions += 1

class HandoffCharacter extends RefCounted:
	var clip := ""
	func posed_bounds(_model: Node3D) -> AABB: return AABB(Vector3.ZERO,Vector3.ONE)
	func play(value: String, _speed: float, _restart: bool) -> void: clip = value

class HandoffActor extends CharacterBody3D:
	var model: Node3D
	var character := HandoffCharacter.new()
	var engaged := false
	func interrupt_action() -> void: pass
	func reset_encounter() -> void: engaged = false

class HandoffReinforcements extends Node3D:
	func clear_wave(_reset := false) -> void: pass

class HandoffTraining extends Node:
	func interrupt(_kind: String) -> void: pass
	func tell(_message: String, _seconds: float) -> void: pass

class HandoffWorld extends Node3D:
	var player: HandoffPlayer
	var training: HandoffTraining
	var pause_owners := {}
	var menu_audio: Node
	func _set_pause_owner(key: String, enabled: bool) -> void:
		if enabled: pause_owners[key] = true
		else: pause_owners.erase(key)
		var owner := get_node_or_null("Owner")
		if owner:
			owner.set_menu_paused(pause_owners.keys().any(func(value): return value != "veyne_presentation"))
	func _open_controls() -> void: _set_pause_owner("controls",true)

class HandoffAudio extends Node:
	var music: AudioStreamPlayer

class HandoffOwner extends "res://combat/map03_veyne.gd":
	# Camera geometry and combat eligibility are intentionally outside this
	# disposable interface fixture; never construct a second live encounter.
	func frame_presentation() -> void: pass

static func prepare_handoff(parent: Node, reduced := false, missing := false) -> Node3D:
	var world := HandoffWorld.new()
	world.name = "VeyneVideoHandoffFixture"
	parent.add_child(world)
	world.player = HandoffPlayer.new()
	world.add_child(world.player)
	world.player.camera = Camera3D.new()
	world.player.add_child(world.player.camera)
	world.training = HandoffTraining.new()
	world.add_child(world.training)
	world.menu_audio = HandoffAudio.new()
	world.add_child(world.menu_audio)
	world.menu_audio.music = AudioStreamPlayer.new()
	world.menu_audio.add_child(world.menu_audio.music)
	var owner := HandoffOwner.new()
	owner.name = "Owner"
	owner.world = world
	owner.state = HandoffState.new()
	owner.state.reduced_motion = reduced
	owner.add_child(owner.state)
	owner.actor = HandoffActor.new()
	owner.add_child(owner.actor)
	owner.actor.model = Node3D.new()
	owner.actor.add_child(owner.actor.model)
	owner.reveal_camera = Camera3D.new()
	owner.add_child(owner.reveal_camera)
	owner.reveal_panel = PanelContainer.new()
	owner.add_child(owner.reveal_panel)
	owner.reveal_caption = Label.new()
	owner.reveal_panel.add_child(owner.reveal_caption)
	for key in ["music","cue"]:
		owner.set(key,AudioStreamPlayer.new())
		owner.get(key).bus = "Music"
		owner.get(key).volume_db = -80
		owner.add_child(owner.get(key))
	var score := preload("res://assets/audio/warden_battle.ogg").duplicate() as AudioStreamOggVorbis
	score.loop = true
	owner.music.stream = score
	owner.effects = AudioStreamPlayer3D.new()
	owner.effects.bus = "Effects"
	owner.add_child(owner.effects)
	owner.reinforcements = HandoffReinforcements.new()
	owner.add_child(owner.reinforcements)
	owner.reveal_video = MissingVideo.new() if missing else preload("res://ui/boss_reveal_video.gd").new()
	owner.reveal_video.name = "Video"
	owner.add_child(owner.reveal_video)
	owner.reveal_video.completed.connect(owner.finish_presentation)
	owner.reveal_video.fallback_requested.connect(owner._video_fallback)
	world.add_child(owner)
	owner.set_process(false)
	owner.grounded = true
	world.set_meta("before_facts",owner.state.facts())
	return world

static func handoff_observation(world: Node3D) -> Dictionary:
	var owner: Node = world.get_node("Owner")
	return {"phase":owner.phase,"battle_starts":owner.battle_starts,"engaged":owner.actor.engaged,"normal_camera":world.player.camera.current,"pause_released":not world.pause_owners.has("veyne_presentation"),"facts_unchanged":owner.state.facts()==world.get_meta("before_facts"),"suppression_called":world.player.suppressions==1,"decoder_released":owner.reveal_video.video.stream==null,"score_owned":owner.owns_score,"battle_music":owner.music.playing}

static func run(parent: Node) -> Dictionary:
	var adapter := DeniedVideo.new()
	var settings := Preferences.new()
	parent.add_child(settings)
	parent.add_child(adapter)
	var checks := {}
	checks.unqualified_media_gate = not adapter.begin(settings) and adapter.status == "unqualified_media" and not adapter.active and adapter.video.stream == null and not adapter.video.visible
	var missing := MissingVideo.new()
	parent.add_child(missing)
	checks.qualified_manifest_bound = missing.qualified_manifest(missing.source_manifest())
	checks.missing_media_retains_live_reveal = not missing.begin(settings) and missing.status == "missing_media" and missing.video.stream == null and not missing.active
	missing.free()
	checks.provider_label_is_not_permission = not adapter.qualified_manifest({"provider":"provider","terms":"applicable terms"})
	checks.missing_grant_is_rejected = not adapter.qualified_manifest({"qualification":{"distribution_terms_reviewed":true,"terms_reference":""}})
	settings.reduced_motion = true
	checks.reduced_motion_retains_live_reveal = not adapter.begin(settings) and adapter.status == "reduced_motion" and not adapter.active and adapter.video.stream == null
	var finished := [0]
	var fallback := [0]
	adapter.completed.connect(func(): finished[0] += 1)
	adapter.fallback_requested.connect(func(): fallback[0] += 1)
	adapter._finished()
	checks.inactive_completion_cannot_start_fight = finished[0] == 0
	# Controlled streamless fixture tests lifecycle signals, not decoding.
	adapter.active = true
	adapter._finished()
	adapter._finished()
	checks.completion_once_and_release = finished[0] == 1 and not adapter.active and adapter.video.stream == null
	adapter.active = true
	adapter.set_paused(true)
	adapter._process(0.5)
	checks.pause_freezes_owned_clock = adapter.stall_seconds == 0.0 and adapter.paused and not adapter.panel.visible
	adapter.set_paused(false)
	adapter._process(2.1)
	checks.failed_decoder_releases_to_live_reveal = fallback[0] == 1 and not adapter.active and adapter.status == "decoder_stalled" and adapter.video.stream == null
	for scale in [1.0,1.5,2.0]:
		settings.text_scale = scale
		adapter.preferences = settings
		adapter._layout()
		checks["native_caption_scale_"+str(scale)] = adapter.caption.get_theme_font_size("font_size") == int(24*scale)
	checks.caption_clock_has_three_beats = adapter.caption_at(0) != adapter.caption_at(6) and adapter.caption_at(6) != adapter.caption_at(12)
	adapter.shutdown()
	adapter.shutdown()
	checks.idempotent_shutdown = not adapter.active and not adapter.paused and adapter.video.stream == null and not adapter.panel.visible
	adapter.free()
	settings.free()
	return {"checks":checks,"scope":"adapter qualification/fallback/signal/clock/layout only; actual footage, decoded motion, earned natural/skip equivalence and physical focus require qualified media and independent observation"}
