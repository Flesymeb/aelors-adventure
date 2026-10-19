extends Node3D
## Attempt-owned creature voice and distinct skill sounds on the Effects bus.
## Spatial gain is calibrated for a third-person listener, not a one-metre mic.
const ROOT := "res://assets/audio/veyne/"
const EVENTS := {
	"reveal":"roar_reveal", "phase":"roar_phase", "death":"death_roar",
	"melee":"claw", "beam_warning":"lightning_charge", "beam":"lightning",
	"fire_warning":"fire_inhale", "fire_breath":"fire_breath",
	"charge_warning":"charge_warning", "charge":"charge",
	"dive_warning":"wing_takeoff", "dive":"dive", "landing":"landing",
	"rift_warning":"rift_warning", "rift":"rift_contact"
}
var encounter: Node3D
var voice: AudioStreamPlayer3D
var attack: AudioStreamPlayer3D
var transients: Array[AudioStreamPlayer3D] = []
var transient_index := 0
var sustain: AudioStreamPlayer3D
var streams: Dictionary = {}
var event_counts: Dictionary = {}
var sustained_event := ""

func configure(owner_encounter: Node3D) -> void:
	encounter = owner_encounter
	process_mode = Node.PROCESS_MODE_PAUSABLE
	voice = _channel("DragonVoice", 0.0, 2)
	for index in 6:
		transients.append(_channel("SkillTransient" + str(index), -3.0, 1))
	attack = transients[0]
	sustain = _channel("BreathSustain", -4.0, 1)
	for stem in EVENTS.values():
		if streams.has(stem): continue
		var path: String = ROOT + str(stem) + ".ogg"
		if ResourceLoader.exists(path): streams[stem] = load(path)

func _channel(label: String, gain: float, polyphony: int) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = label
	player.bus = "Effects"
	player.volume_db = gain
	player.unit_size = 12.0
	player.max_distance = 100.0
	player.max_polyphony = polyphony
	add_child(player)
	return player

func play_event(event: String) -> bool:
	var stem: String = EVENTS.get(event, "")
	if stem.is_empty() or not streams.has(stem): return false
	var channel: AudioStreamPlayer3D = voice
	if event not in ["reveal", "phase", "death"]:
		channel = transients[transient_index]
		transient_index = (transient_index + 1) % transients.size()
		attack = channel
	channel.stream = streams[stem]
	channel.pitch_scale = 1.0
	channel.stream_paused = false
	channel.play()
	event_counts[event] = int(event_counts.get(event, 0)) + 1
	return true

func begin_breath() -> void:
	stop_breath()
	if not streams.has("fire_breath"): return
	# Loop only while the production breath action owns its active interval.
	var stream := streams["fire_breath"].duplicate() as AudioStreamOggVorbis
	stream.loop = true
	sustain.stream = stream
	sustain.stream_paused = false
	sustain.play()
	sustained_event = "fire_breath"
	event_counts[sustained_event] = int(event_counts.get(sustained_event, 0)) + 1

func stop_breath() -> void:
	if is_instance_valid(sustain): sustain.stop()
	sustained_event = ""

func set_paused(value: bool) -> void:
	for channel in [voice, sustain] + transients:
		if is_instance_valid(channel): channel.stream_paused = value

func _process(_delta: float) -> void:
	if not is_instance_valid(encounter): return
	# Match the encounter's presentation pause owner, including nested settings.
	var paused: bool = encounter.world.pause_owners.keys().any(func(key): return key != "veyne_presentation")
	set_paused(paused)

func stop_all() -> void:
	for channel in [voice, sustain] + transients:
		if is_instance_valid(channel):
			channel.stop()
			channel.stream_paused = false
	sustained_event = ""

func snapshot() -> Dictionary:
	return {"events":event_counts.duplicate(), "sustained_event":sustained_event,
		"voice_playing":voice.playing if voice else false,
		"attack_playing":attack.playing if attack else false,
		"sustain_playing":sustain.playing if sustain else false,
		"bus":"Effects", "unit_size":12.0, "max_distance":100.0}
