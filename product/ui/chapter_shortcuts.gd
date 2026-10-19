extends Node
## Opt-in keyboard preview. Normal adventure state and files are never reused
## as the prepared chapter state; Return to title restores the original owner.
var router: Node
var original_state: Node
var preview_state: Node
var switching := false
var banner: Label
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 105
	add_child(layer)
	banner = Label.new()
	banner.add_theme_font_override("font",preload("res://dialogue_theme.tres").default_font)
	banner.add_theme_font_size_override("font_size",17)
	banner.add_theme_color_override("font_color",Color(1,0.9,0.58))
	banner.add_theme_color_override("font_outline_color",Color(0.05,0.04,0.02,1))
	banner.add_theme_constant_override("outline_size",5)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(banner)
	banner.hide()
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not event.ctrl_pressed: return
	if event.keycode in [KEY_F1,KEY_F2,KEY_F3]:
		get_viewport().set_input_as_handled()
		if not switching: switch_chapter(int(event.keycode-KEY_F1)+1)
	elif event.keycode == KEY_F4 and is_instance_valid(original_state):
		get_viewport().set_input_as_handled()
		if not switching: router.return_to_title()
func switch_chapter(chapter: int) -> bool:
	if switching or chapter not in [1,2,3] or router.route not in ["title","world","game_over","error"]: return false
	switching = true
	if not is_instance_valid(original_state): original_state = router.state
	# Complete teardown before loading: only one chapter's geometry/nav/actors
	# are resident, important on the target 8 GB laptop GPU.
	await router.return_to_title()
	var old_preview: Node = preview_state
	preview_state = preload("res://ui/chapter_preview_state.gd").new()
	router.add_child(preview_state)
	for key in original_state.PREFERENCE_DEFAULTS: preview_state.set(key,original_state.get(key))
	preview_state.prepare(chapter)
	router.state = preview_state
	router.audio.state = preview_state
	if is_instance_valid(old_preview): old_preview.queue_free()
	router.entry_kind = "chapter_preview"
	router.previous_history = preview_state.adventure_snapshot()
	router.entry_error = ""
	router.replaying_opening = false
	router.player_ready = false
	router.title.hide()
	banner.text = "第 %d 章预览 · 不写正式存档 · Ctrl+F1/F2/F3 切章 · Ctrl+F4 返回标题" % chapter
	banner.show()
	router._start_loading()
	switching = false
	return true
func restore_original() -> void:
	if switching or not is_instance_valid(original_state): return
	router.state = original_state
	router.audio.state = original_state
	original_state = null
	if is_instance_valid(preview_state): preview_state.queue_free()
	preview_state = null
	banner.hide()
func _process(_delta: float) -> void:
	if banner.visible:
		banner.position = Vector2(maxf(310,(get_viewport().get_visible_rect().size.x-banner.size.x)*0.5),12)
