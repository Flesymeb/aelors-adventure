extends RefCounted
## Opt-in transaction seams. No real saves, earning or ordinary route claims.
const CIRCUIT = preload("res://tests/map03_barrier_test.gd")
const ENTRY = preload("res://tests/map03_entry_test.gd")
class QuietTraining extends RefCounted:
	var allow_commit := true
	func commit() -> bool: return allow_commit
	func tell(_text: String, _seconds: float) -> void: pass
class QuietPlayer extends RefCounted:
	func release_encounter_camera() -> void: pass
class QuietWave extends Node3D:
	var units: Array = []
	func clear_wave(_reset := false) -> void: units.clear()
class DeadActor extends CharacterBody3D:
	var health := 0.0
	var engaged := false
	func interrupt_action() -> void: pass
class BeatProbe extends CanvasLayer:
	var active := false
	var starts := 0
	func begin() -> bool:
		starts += 1
		active = true
		return true
class QuietWorld extends Node3D:
	var training := QuietTraining.new()
	var player := QuietPlayer.new()
class Encounter extends "res://combat/map03_veyne.gd":
	func play_cue(_kind: String) -> void: pass
	func _process(_delta: float) -> void: pass
	func _exit_tree() -> void: pass

static func run(parent: Node) -> Dictionary:
	var world := QuietWorld.new()
	parent.add_child(world)
	var state: Node = CIRCUIT.prepared()
	# Off-tree fixture: no live GLoot bag exists. Match the established rollback
	# fixture boundary; snapshot durable scalar facts without a half-ready bag.
	state.inventory = null
	state.reveal_ln02(); state.cut_ln02_supply("north"); state.cut_ln02_supply("south"); state.purify_ln02()
	var boss := Encounter.new()
	boss.world = world
	boss.state = state
	boss.actor = DeadActor.new()
	boss.reinforcements = QuietWave.new()
	boss.music = AudioStreamPlayer.new()
	boss.defeat_scene = BeatProbe.new()
	for child in [boss.actor,boss.reinforcements,boss.music,boss.defeat_scene]: boss.add_child(child)
	world.add_child(boss)
	var before: Dictionary = state.adventure_snapshot()
	boss.actor.health = 10
	boss.settle_defeat()
	var checks := {"live_boss_no_beat":boss.defeat_scene.starts == 0 and not state.veyne_defeated}
	boss.actor.health = 0
	world.training.allow_commit = false
	boss.settle_defeat()
	checks.failed_commit_no_beat = boss.defeat_scene.starts == 0 and boss.victory_pending and not state.veyne_defeated and state.adventure_snapshot() == before
	world.training.allow_commit = true
	boss.settle_defeat()
	checks.new_durable_commit_starts_once = boss.defeat_scene.starts == 1 and boss.victory_commits == 1 and state.veyne_defeated and not boss.victory_pending
	checks.key_rescue_still_separate = not state.veyne_release_key and not state.rescue_assembled and state.rescue_released.is_empty()
	checks.beat_blocks_save = not boss.can_save()
	boss.settle_defeat()
	checks.repeat_no_beat = boss.defeat_scene.starts == 1 and boss.victory_commits == 1
	boss.defeat_scene.active = false
	checks.defeated_idle_savable = boss.can_save()
	checks.state_accurate_captions = preload("res://ui/veyne_defeat_scene.gd").caption_for(true,false).contains("已在蓝灯旁集合") and preload("res://ui/veyne_defeat_scene.gd").caption_for(false,false).contains("靠近后按 E")
	world.free()
	state.free()
	return {"checks":checks,"scope":"production durable trigger with memory-only commit seam; live Death, views, natural/skip and physical focus remain native/Tester checks"}

static func start_live_case(world: Node3D) -> Dictionary:
	# This is permitted only in the existing memory-history Tomb diagnostic.
	# It does not manufacture a reusable Continue or claim earned victory.
	if not world.entry_router is ENTRY.DiagnosticTombRouter:
		return {"ready":false,"reason":"memory-only Tomb diagnostic required"}
	if not world.dialogue_state.ln02_purified or world.dialogue_state.veyne_defeated:
		return {"ready":false,"reason":"fresh diagnostic LN02 fixture required"}
	world.warden_encounter.interrupt()
	var boss: Node3D = world.veyne_encounter
	if not world.ground_policy.place(world,world.player,Vector2(-4,-21)):
		return {"ready":false,"reason":"authored support unavailable"}
	boss.begin_reveal()
	boss.finish_presentation()
	var source := SnaielDamageSource.new()
	source.entity = world.player
	source.can_damage = true
	source.damage_attributes.health = 500
	source.instance = 9001
	var result: Dictionary = boss.actor.receive_contact(source,boss.actor.global_position+Vector3.UP)
	source.free()
	return {"ready":boss.defeat_scene.active,"result":result.get("outcome",""),"clip":boss.actor.character.current_clip(),"position":boss.actor.character.current_position(),"key_uncollected":not world.dialogue_state.veyne_release_key}
