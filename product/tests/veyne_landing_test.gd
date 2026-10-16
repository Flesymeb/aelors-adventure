extends RefCounted
## Explicit memory-only checks under a normal SceneTree. No earned Boss setup.
class LandingWorld extends Node3D:
	var pause_owners := {}
class LandingSettings extends Node:
	var reduced_motion := false
	var graphics_quality := "high"
class LandingPlayer extends Node3D:
	var impulses := 0
	var strength := 0.0
	func start_camera_shake(scale := 1.0, _duration := 0.18) -> void:
		impulses += 1; strength = scale

static func run(parent: Node) -> Dictionary:
	var actions = preload("res://combat/veyne_dragon_actions.gd")
	var visual = preload("res://combat/veyne_landing_presentation.gd")
	var support := {"position":Vector3.ZERO,"normal":Vector3.UP}
	var checks := {
		"actual_support_required":not actions.verified_arrival(Vector3(0,0.08,0),Vector3.ZERO,{}),
		"airborne_timer_not_arrival":not actions.verified_arrival(Vector3(0,2,0),Vector3.ZERO,support),
		"wrong_footprint_not_arrival":not actions.verified_arrival(Vector3(1,0.08,0),Vector3.ZERO,support),
		"grounded_arrival":actions.verified_arrival(Vector3(0,0.08,0),Vector3.ZERO,support),
		"falloff_bounded":visual.distance_strength(0)==1 and visual.distance_strength(6)==0.5 and visual.distance_strength(20)==0,
		"recovery_preserved":actions.RECOVERY.dive == 1.8
	}
	var world := LandingWorld.new()
	parent.add_child(world)
	var settings := LandingSettings.new()
	world.add_child(settings)
	var player := LandingPlayer.new()
	world.add_child(player)
	player.position = Vector3(6,0,0)
	var effect = preload("res://assets/bosses/veyne_landing_effect.tscn").instantiate()
	world.add_child(effect)
	effect.configure(world,settings)
	checks.grounded_miss_has_world_feedback = effect.emit_once(Vector3.ZERO,Vector3.UP,1,player) and effect.active and effect.sound.bus == &"Effects" and player.impulses == 1
	checks.same_attack_no_second_burst = not effect.emit_once(Vector3.ZERO,Vector3.UP,1,player) and effect.bursts == 1
	world.pause_owners.menu = true
	effect._process(0.5)
	# AudioStreamPlayer3D begins playback on its native update; this same-call
	# check establishes the simulation clock only. prepare/finish_pause_check
	# qualifies audio suspension after native playback has actually started.
	checks.pause_freezes_decay = effect.age == 0 and effect.active
	world.pause_owners.clear()
	effect._process(0.91)
	checks.bounded_cleanup = not effect.active and not effect.sound.playing and not effect.ring.visible
	settings.reduced_motion = true
	effect.emit_once(Vector3.ZERO,Vector3.UP,2,player)
	checks.reduced_motion_no_dust = not effect.dust.emitting and effect.ring.visible
	effect.clear()
	checks.interrupt_clears_effect = not effect.active and not effect.sound.playing and not effect.dust.emitting
	world.free()
	return checks

static func prepare_pause_check(parent: Node) -> Node3D:
	var world := LandingWorld.new()
	world.name = "LandingPauseFixture"
	parent.add_child(world)
	var settings := LandingSettings.new()
	world.add_child(settings)
	var effect = preload("res://assets/bosses/veyne_landing_effect.tscn").instantiate()
	effect.name = "Impact"
	world.add_child(effect)
	effect.configure(world,settings)
	effect.emit_once(Vector3.ZERO,Vector3.UP,1,null)
	return world

static func finish_pause_check(world: Node3D) -> Dictionary:
	var effect = world.get_node("Impact")
	var before: float = effect.age
	var started: bool = effect.sound.playing
	world.pause_owners.menu = true
	effect._process(0.2)
	var checks := {"native_audio_started":started,"pause_freezes_live_decay":effect.age == before,"pause_suspends_live_audio":effect.sound.stream_paused}
	world.pause_owners.clear()
	effect._process(0.01)
	checks.resume_releases_live_audio = not effect.sound.stream_paused
	effect.clear()
	checks.cleanup_releases_live_audio = not effect.sound.playing
	world.free()
	return checks
