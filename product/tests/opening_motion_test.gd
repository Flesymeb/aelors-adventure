extends RefCounted
## Opt-in disposable component checks. They do not establish generated motion,
## earned histories, actual decoding or independent cinematic acceptance.
class QuietOpening extends "res://ui/illustrated_opening.gd":
	func _ready() -> void:
		set_process(false)

class Preferences extends Node:
	var reduced_motion := false

static func lifecycle_checks(parent: Node) -> Dictionary:
	var opening := QuietOpening.new()
	opening.name = "DisposableOpeningMotion"
	var preferences := Preferences.new()
	opening.state = preferences
	opening.add_child(preferences)
	opening.video = VideoStreamPlayer.new()
	opening.add_child(opening.video)
	opening.music = AudioStreamPlayer.new()
	opening.add_child(opening.music)
	opening.ambience = AudioStreamPlayer.new()
	opening.add_child(opening.ambience)
	opening.cue = AudioStreamPlayer.new()
	opening.add_child(opening.cue)
	opening.slides = [{"video": "__missing_motion_test__.ogv"}]
	parent.add_child(opening)
	var checks := {}
	opening._start_video()
	checks.missing_media_retains_fallback = opening.video_status == "missing_media" and not opening.video_active and not opening.video.visible
	checks.missing_media_does_not_finish = not opening.finished
	preferences.reduced_motion = true
	opening._start_video()
	checks.reduced_motion_skips_decoder = opening.video_status == "reduced_motion" and opening.video.stream == null
	# A streamless native player has no playback state to pause. Give the audio
	# owners real disposable silent playbacks; absent video must stay decoder-free.
	var silence := AudioStreamWAV.new()
	silence.format = AudioStreamWAV.FORMAT_8_BITS
	silence.mix_rate = 8000
	var samples := PackedByteArray()
	samples.resize(8000)
	samples.fill(128)
	silence.data = samples
	for player in [opening.music, opening.ambience, opening.cue]:
		player.stream = silence
		player.volume_db = -80
		player.play()
	opening._set_presentation_paused(true)
	checks.pause_has_one_boundary = not opening.video_active and opening.video.stream == null and opening.music.stream_paused and opening.ambience.stream_paused and opening.cue.stream_paused
	opening._set_presentation_paused(false)
	checks.resume_releases_all = not opening.video_active and opening.video.stream == null and not opening.music.stream_paused and not opening.ambience.stream_paused and not opening.cue.stream_paused
	opening.shutdown()
	opening.shutdown()
	checks.idempotent_shutdown = opening.finished and not opening.video_active and opening.video.stream == null and not opening.video.visible and not opening.music.playing and not opening.ambience.playing and not opening.cue.playing
	opening.free()
	return {"scope": "disposable normal-tree opening media lifecycle only; no footage or save acceptance", "checks": checks, "unverified": ["decoded video pause/resume requires qualified footage"]}
