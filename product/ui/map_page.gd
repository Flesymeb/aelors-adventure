extends "res://ui/menu_foundation/main_menu.gd"
## Read-only MF01 projection through the retained Maaack page/focus lifecycle.
const GROUND = preload("res://world/map02_ground.gd")
var world: Node3D
var suspended := false
var information: Label
var diagram: Control

class RouteDiagram extends Control:
	var state: Node
	var player: Node3D
	func point(xz: Vector2) -> Vector2:
		return Vector2(size.x * (0.28 + xz.x / 35.0), 30 + (70 - xz.y) / 45.0 * (size.y - 70))
	func _draw() -> void:
		var ground = preload("res://world/map02_ground.gd")
		var font: Font = get_theme_default_font()
		var ink := Color(0.20, 0.15, 0.08)
		var route: PackedVector2Array = []
		var marks := [[ground.ENTRY,"草甸灯台"], [ground.ROADBLOCK,"路障泥路"]]
		if state.mf01_acquired:
			marks.append_array([[ground.PRESSURE_FLANK[0],"岩石右侧绕行"], [ground.ROUTE_RECORD,"林缘 · 固定路碑"]])
		for mark in marks: route.append(point(mark[0]))
		draw_polyline(route, ink, 3, true)
		for mark in marks:
			var p := point(mark[0])
			draw_texture_rect(preload("res://assets/ui/journal_icons.svg"), Rect2(p - Vector2(13,13), Vector2(26,26)), false, ink)
			var label_offset := Vector2(-190,7) if mark[1] == "岩石右侧绕行" else Vector2(24,7)
			draw_string(font, p + label_offset, mark[1], HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_default_font_size(), ink)
		if state.mf01_acquired:
			var rock := point(ground.PRESSURE_COVER)
			draw_circle(rock, 9, Color(0.6,0.61,0.56))
			draw_string(font, rock + Vector2(20,7), "岩石掩体", HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_default_font_size(), ink)
		if is_instance_valid(player) and state.current_map == state.MAP02:
			var xz := Vector2(player.global_position.x, player.global_position.z)
			if xz.y >= 20 and xz.y <= 70:
				draw_circle(point(xz), 7, ink)
				draw_circle(point(xz), 4, Color(1,0.9,0.5))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$BackgroundTextureRect.hide()
	%MenuContainer.hide()
	set_meta("page_width", 1040)
	var column := create_page(self, "农田至林缘 · 路线图 [M]", true)
	diagram = RouteDiagram.new()
	diagram.state = state
	diagram.player = world.player
	diagram.custom_minimum_size.y = 310
	diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(diagram)
	information = paragraph(column, "")
	paragraph(column, "圆点：艾洛 · 路线示意，上方朝林缘")
	button(get_meta("footer_column"), "返回 [M / Esc]", close_panel)
	visibility_changed.connect(func():
		if not visible and not suspended: world._set_pause_owner("map", false))
	refresh()

func refresh() -> void:
	information.text = state.mf01_information()
	diagram.queue_redraw()
	reflow(self)

func open_panel() -> void:
	world._set_pause_owner("map", true)
	show()
	refresh()
	get_meta("footer_column").get_child(0).grab_focus.call_deferred()

func close_panel() -> void:
	suspended = false
	world._set_pause_owner("map", false)
	hide()
	audio.play_cue("back")

func suspend_for_menu() -> void:
	suspended = true
	hide()

func resume_from_menu() -> void:
	suspended = false
	show()
	refresh()
	get_meta("footer_column").get_child(0).grab_focus.call_deferred()

func _input(_event: InputEvent) -> void:
	pass

func _unhandled_input(_event: InputEvent) -> void:
	# Cancellation belongs to the persistent world pause/input owner.
	pass

func _mcp_state() -> Dictionary:
	return {"open":visible, "acquired":state.mf01_acquired, "information":information.text, "pause_owned":world.pause_owners.has("map")}
