extends SceneTree
var checks := {}
var peak := 0.0
var capture: AudioEffectCapture
func _initialize() -> void: call_deferred("run_probe")
func sample() -> void:
	var count := capture.get_frames_available()
	if count > 0:
		for frame in capture.get_buffer(count): peak = maxf(peak,maxf(absf(frame.x),absf(frame.y)))
func run_probe() -> void:
	var fixture = load("res://tests/chapter_travel_test.gd")
	var world = fixture.MotionWorld.new()
	root.add_child(world)
	world.dialogue_state = fixture.DiagnosticState.new()
	world.add_child(world.dialogue_state)
	var audio = load("res://ui/menu_audio.gd").new()
	audio.state = world.dialogue_state
	world.add_child(audio)
	capture = AudioEffectCapture.new()
	capture.buffer_length = 0.5
	AudioServer.add_bus_effect(0,capture)
	var overlay = load("res://ui/ChapterTransition.tscn").instantiate()
	overlay.world = world
	overlay.destination_map = world.dialogue_state.MAP02
	var boundary := [0]
	overlay.black_boundary.connect(func(): boundary[0] += 1)
	world.add_child(overlay)
	overlay.armed = true
	for i in 90:
		await process_frame
		sample()
	checks.farewell_1080_audio_movie_started = overlay.video_active and overlay.video.stream_position > 0.1 and overlay.video.volume > 0 and overlay.beat == 0
	var position: float = overlay.video.stream_position
	overlay._set_presentation_paused(true)
	for i in 20: await process_frame
	checks.pause_freezes_decoder = absf(overlay.video.stream_position-position) < 0.08
	overlay._set_presentation_paused(false)
	var saw_passage := false
	var saw_passage_motion := false
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start < 35000 and boundary[0] == 0:
		await process_frame
		sample()
		if overlay.beat == 1:
			saw_passage = true
			saw_passage_motion = saw_passage_motion or (overlay.video_active and overlay.video.stream_position > 0.1)
	checks.passage_plays_after_farewell = saw_passage and saw_passage_motion
	checks.natural_story_boundary_once = boundary[0] == 1 and overlay.phase == "loading"
	checks.natural_decoder_released = overlay.video.stream == null and not overlay.video.is_playing()
	checks.actual_audio_output = peak > 0.001 and peak < 0.99
	checks.no_story_rewards_or_rescue = world.dialogue_state.experience == 0 and not world.dialogue_state.departure_confirmed and not world.dialogue_state.homecoming_completed
	overlay._release_world()
	checks.pause_owner_released = world.pause_owners.is_empty()
	overlay.queue_free()
	await process_frame
	var fallback = load("res://ui/ChapterTransition.tscn").instantiate()
	world.dialogue_state.reduced_motion = true
	fallback.world = world
	fallback.destination_map = world.dialogue_state.MAP02
	world.add_child(fallback)
	fallback.armed = true
	await process_frame
	checks.reduced_motion_uses_audible_fallback = not fallback.video_active and fallback.cue.playing
	fallback.request_skip()
	for i in 25: await process_frame
	checks.skip_stops_audio_and_video = not fallback.cue.playing and fallback.video.stream == null
	fallback._release_world()
	fallback.queue_free()
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	world.queue_free()
	for i in 3: await process_frame
	var failures := []
	for key in checks:
		if not checks[key]: failures.append(key)
	print("CHAPTER_STORY_RESULT=" + JSON.stringify({"checks":checks,"assertions":checks.size(),"failures":failures,"audio_peak":peak,"scope":"Native 1080p movie decode/audio/lifecycle on prepared presentation owner; not earned travel or independent QA"}))
	quit(0 if failures.is_empty() else 3)
