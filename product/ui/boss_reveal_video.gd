extends CanvasLayer
## Media adapter only. The encounter owns entry, skip and battle settlement.
signal completed
signal fallback_requested
const MEDIA := "res://assets/cinematics/veyne/entrance.ogv"
const SOURCE := "res://assets/cinematics/veyne/SOURCE.json"
var video: VideoStreamPlayer
var panel: PanelContainer
var caption: Label
var hint: Label
var preferences: Node
var active := false
var paused := false
var position_seconds := 0.0
var stall_seconds := 0.0
var status := "inactive"

func media_path() -> String:
	return MEDIA

func source_manifest() -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(SOURCE)) if FileAccess.file_exists(SOURCE) else null

func _ready() -> void:
	layer = 7 # Below the retained pause/settings layer, above combat HUD.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	video = VideoStreamPlayer.new()
	video.name = "VeyneEntranceMotion"
	video.expand = true
	video.bus = "Effects"
	video.volume = 0.0 # Retained encounter cue/score is the sole audio owner.
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video.finished.connect(_finished)
	add_child(video)
	panel = PanelContainer.new()
	panel.theme = preload("res://dialogue_theme.tres")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.025,0.035,0.06,0.93)
	back.border_color = Color(0.6,0.52,0.32,0.8)
	back.set_border_width_all(1)
	back.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel",back)
	add_child(panel)
	caption = Label.new()
	caption.add_theme_color_override("font_color",Color(0.97,0.91,0.76))
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(caption)
	hint = Label.new()
	hint.theme = panel.theme
	hint.add_theme_color_override("font_color",Color(0.97,0.91,0.76))
	hint.text = "空格跳过 · Esc 暂停"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	_release("inactive")

static func qualified_manifest(data: Variant) -> bool:
	# A provider/model label is provenance, not distribution permission.
	return data is Dictionary and data.get("qualification",{}).get("distribution_terms_reviewed",false) == true and not str(data.get("qualification",{}).get("terms_reference","")).is_empty()

func begin(settings: Node) -> bool:
	_release("inactive")
	preferences = settings
	if settings.reduced_motion:
		status = "reduced_motion"
		return false
	var data: Variant = source_manifest()
	if not qualified_manifest(data):
		status = "unqualified_media"
		return false
	var path := media_path()
	if not ResourceLoader.exists(path):
		status = "missing_media"
		return false
	var stream := load(path) as VideoStream
	if stream == null:
		status = "unavailable_stream"
		return false
	video.stream = stream
	video.paused = false
	active = true
	paused = false
	position_seconds = 0.0
	stall_seconds = 0.0
	status = "playing"
	video.show()
	panel.show()
	hint.show()
	video.play()
	_layout()
	return true

func _process(delta: float) -> void:
	if not active: return
	_layout()
	if paused: return
	var current := video.stream_position
	if current > position_seconds + 0.001:
		position_seconds = current
		stall_seconds = 0.0
	else: stall_seconds += delta
	if stall_seconds > 2.0:
		_release("decoder_stalled")
		fallback_requested.emit()

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	# Full bleed without stretching the staged 16:9 composition.
	video.size = Vector2(maxf(view.x,view.y*16.0/9.0),maxf(view.y,view.x*9.0/16.0))
	video.position = (view-video.size)*0.5
	var scale: float = preferences.text_scale if is_instance_valid(preferences) else 1.0
	caption.add_theme_font_size_override("font_size",int(24*scale))
	caption.text = caption_at(position_seconds)
	panel.custom_minimum_size.x = view.x*0.88
	panel.size = Vector2(view.x*0.88,0)
	panel.position = Vector2(view.x*0.06,view.y-panel.get_combined_minimum_size().y-28)
	hint.add_theme_font_size_override("font_size",int(16*scale))
	hint.position = Vector2(28,22)

static func caption_at(seconds: float) -> String:
	if seconds < 5.0: return "维恩 · 裂隙祭坛"
	if seconds < 10.0: return "火息横移 · 冲锋侧闪 · 俯冲离开落点"
	return "青色灯束不可振刀 · 金色爪击可振刀"

func set_paused(value: bool) -> void:
	paused = value
	if is_instance_valid(video) and video.stream: video.paused = value
	# Native pause/settings retain the foreground and focus.
	if is_instance_valid(panel): panel.visible = active and not value
	if is_instance_valid(hint): hint.visible = active and not value

func _finished() -> void:
	if not active: return
	_release("completed")
	completed.emit()

func _release(reason := "interrupted") -> void:
	active = false
	paused = false
	status = reason
	if is_instance_valid(video):
		video.stop()
		video.paused = false
		video.stream = null
		video.hide()
	if is_instance_valid(panel): panel.hide()
	if is_instance_valid(hint): hint.hide()

func shutdown() -> void:
	_release()

func _exit_tree() -> void:
	_release()

func _mcp_state() -> Dictionary:
	return {"active":active,"status":status,"position":position_seconds,"paused":paused,"decoder_bound":is_instance_valid(video) and video.stream != null}
