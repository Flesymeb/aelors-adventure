extends Control
## Maaack progress/stall messaging adapted to resource + safe-world stages.
signal retry_requested
signal back_requested
var host: Control
var message: Label
var progress_bar: ProgressBar
var error := ""
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://assets/ui/main_menu_background.png")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var column: VBoxContainer = host.create_page(self, "循灯前行", true)
	message = host.paragraph(column, "正在加载河谷…")
	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.max_value = 1.0
	column.add_child(progress_bar)
	host.paragraph(column, "旧灯的光，照见归途。")
	var retry: Button = host.button(column, "重试", func(): retry_requested.emit())
	retry.name = "Retry"
	var back: Button = host.button(column, "返回标题", func(): back_requested.emit())
	back.name = "Back"
	retry.hide()
	back.hide()
	host.reflow(self)
func show_error(reason: String) -> void:
	error = reason
	message.text = reason
	find_child("Retry", true, false).show()
	find_child("Back", true, false).show()
	find_child("Back", true, false).grab_focus.call_deferred()
	host.reflow(self)
func update_progress(value: float, initializing: bool) -> void:
	if error != "": return
	progress_bar.value = value
	message.text = "正在准备安全落脚点…" if initializing else "正在加载河谷…"
func _mcp_state() -> Dictionary:
	return {"message": message.text, "resource_progress": progress_bar.value, "error": error, "visible": visible}
