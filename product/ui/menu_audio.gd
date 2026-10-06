extends Node
## Existing licensed Kenney Interface Sounds; one voice prevents UI overlaps.
var state: Node
var voice: AudioStreamPlayer
var last_cue := ""
var streams := {
	"focus": preload("res://assets/dialogue/sounds/Audio/tick_002.ogg"),
	"confirm": preload("res://assets/dialogue/sounds/Audio/confirmation_001.ogg"),
	"back": preload("res://assets/dialogue/sounds/Audio/back_002.ogg"),
	"unavailable": preload("res://assets/dialogue/sounds/Audio/question_001.ogg"),
	"failure": preload("res://assets/dialogue/sounds/Audio/error_003.ogg")}
func _ready() -> void:
	voice = AudioStreamPlayer.new()
	voice.volume_db = -18
	add_child(voice)
func play_cue(cue: String) -> void:
	if state.muted_sound: return
	if cue == "focus" and voice.playing and last_cue != "focus": return
	last_cue = cue
	voice.stream = streams[cue]
	voice.play()
func _mcp_state() -> Dictionary:
	return {"last_cue": last_cue, "muted": state.muted_sound, "playing": voice.playing}
