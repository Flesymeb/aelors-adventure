extends Control
## Confirmation signal and exclusive submenu adapted from Maaack's MIT unit.
signal confirmed
signal closed
var host: Control
var heading := ""
var message := ""
var action: Callable
var busy := false
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column: VBoxContainer = host.create_page(self, heading, true)
	host.paragraph(column, message)
	var cancel: Button = host.button(column, "取消", close)
	host.button(column, "确认", confirm)
	cancel.grab_focus.call_deferred()
	host.reflow(self)
func confirm() -> void:
	if busy: return
	busy = true
	confirmed.emit()
	action.call()
	close(false)
func close(play_back := true) -> void:
	if play_back: host.audio.play_cue("back")
	closed.emit()
