extends SceneTree
## Real native mixer output, isolated scene; not ordinary Boss earning or listening.
var checks := {}
var measurements := {}
var capture: AudioEffectCapture

class Fixture extends Node3D:
	var world: Node
	var pause_owners := {}

func _initialize() -> void:
	call_deferred("run_probe")

func meter() -> Dictionary:
	var frames := capture.get_frames_available()
	if frames == 0: return {"frames":0,"peak":0.0,"rms":0.0}
	var data := capture.get_buffer(frames)
	var peak := 0.0
	var energy := 0.0
	for sample in data:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		energy += sample.length_squared()*0.5
	return {"frames":frames,"peak":peak,"rms":sqrt(energy/maxi(1,frames))}

func run_probe() -> void:
	var fixture := Fixture.new()
	fixture.world = fixture
	root.add_child(fixture)
	var listener := Camera3D.new()
	fixture.add_child(listener)
	listener.position = Vector3(0,2,25)
	listener.current = true
	listener.look_at(Vector3.ZERO)
	if AudioServer.get_bus_index("Effects") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,"Effects")
	capture = AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(0,capture)
	var voice := preload("res://combat/veyne_audio.gd").new()
	fixture.add_child(voice)
	voice.configure(fixture)
	await create_timer(0.15).timeout
	for event in ["reveal","phase","death","beam_warning","beam","fire_warning","charge","dive","landing","melee","rift"]:
		voice.stop_all()
		await create_timer(0.12).timeout
		capture.clear_buffer()
		checks[event+"_bound"] = voice.play_event(event)
		await create_timer(0.5).timeout
		var value := meter()
		measurements[event] = value
		checks[event+"_outputs_at_25m"] = value.frames > 500 and value.rms > 0.00001
		checks[event+"_not_clipped"] = value.peak < 0.99
	voice.stop_all()
	voice.begin_breath()
	await create_timer(0.15).timeout
	capture.clear_buffer()
	await create_timer(0.35).timeout
	checks.breath_loop_outputs = meter().rms > 0.00001
	fixture.pause_owners["controls"] = true
	voice.set_paused(true)
	await create_timer(0.15).timeout
	capture.clear_buffer()
	await create_timer(0.25).timeout
	checks.pause_silences_breath = meter().peak < 0.00001
	fixture.pause_owners.clear()
	voice.set_paused(false)
	await create_timer(0.15).timeout
	capture.clear_buffer()
	await create_timer(0.25).timeout
	checks.resume_restores_breath = meter().rms > 0.00001
	voice.stop_all()
	await create_timer(0.15).timeout
	capture.clear_buffer()
	await create_timer(0.2).timeout
	checks.interruption_stops_all_channels = meter().peak < 0.00001
	voice.play_event("reveal")
	var effects_bus := AudioServer.get_bus_index("Effects")
	AudioServer.set_bus_mute(effects_bus,true)
	await create_timer(0.15).timeout
	capture.clear_buffer()
	await create_timer(0.25).timeout
	checks.user_effects_mute_respected = meter().peak < 0.00001
	AudioServer.set_bus_mute(effects_bus,false)
	voice.stop_all()
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	fixture.queue_free()
	await process_frame
	var failures: Array = []
	for key in checks:
		if not checks[key]: failures.append(key)
	print("VEYNE_AUDIO_RESULT="+JSON.stringify({"checks":checks,"measurements":measurements,
		"failures":failures,"assertions":checks.size(),"scope":"Native AudioEffectCapture at 25m; functional output/lifecycle, not perceptual quality"}))
	quit(0 if failures.is_empty() else 3)
