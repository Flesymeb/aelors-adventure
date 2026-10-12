extends "res://ui/menu_foundation/main_menu.gd"
## Read-only earned route-record projection through the retained Maaack page/focus lifecycle.
const GROUND = preload("res://world/map02_ground.gd")
var world: Node3D
var suspended := false
var information: Label
var diagram: Control

class RouteDiagram extends Control:
	var state: Node
	var player: Node3D
	func point(xz: Vector2) -> Vector2:
		var north := 120.0 if state.mf02_acquired else 80.0
		return Vector2(size.x * (0.28 + xz.x / 35.0), 30 + (north - xz.y) / (north - 20.0) * (size.y - 70))
	func _draw() -> void:
		if state.current_map == state.MAP03:
			_draw_tomb()
			return
		var ground = preload("res://world/map02_ground.gd")
		var font: Font = get_theme_default_font()
		var font_size := get_theme_default_font_size()
		var ink := Color(0.20, 0.15, 0.08)
		var route: PackedVector2Array = []
		var marks := [[ground.ENTRY,"草甸灯台"], [ground.ROADBLOCK,"路障泥路"]]
		if state.mf01_acquired:
			marks.append_array([[ground.PRESSURE_FLANK[0],"岩石右侧绕行"], [ground.ROUTE_RECORD,"林缘 · 固定路碑"]])
		if state.mf02_acquired:
			marks.append_array([[ground.LINE_APPROACH,"树线后的林路"], [ground.LINE_RECORD,"墓殿方向 · 结界记号"], [ground.LN01_PASSAGE,"通道已稳定" if state.ln01_location_purified else "林缘通道 · 结界"]])
		for mark in marks: route.append(point(mark[0]))
		draw_polyline(route, ink, 3, true)
		for mark in marks:
			var p := point(mark[0])
			draw_texture_rect(preload("res://assets/ui/journal_icons.svg"), Rect2(p - Vector2(13,13), Vector2(26,26)), false, ink)
			var label_width := font.get_string_size(mark[1], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var label_x := p.x - label_width - 24 if mark[1] == "岩石右侧绕行" else p.x + 24
			label_x = clampf(label_x, 0, maxf(0, size.x - label_width))
			draw_string(font, Vector2(label_x, p.y + font_size * 0.3), mark[1], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
		if state.mf01_acquired:
			var rock := point(ground.PRESSURE_COVER)
			draw_circle(rock, 9, Color(0.6,0.61,0.56))
			draw_string(font, rock + Vector2(20,7), "岩石掩体", HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_default_font_size(), ink)
		if is_instance_valid(player) and state.current_map == state.MAP02:
			var xz := Vector2(player.global_position.x, player.global_position.z)
			if xz.y >= 20 and xz.y <= (120 if state.mf02_acquired else 80):
				draw_circle(point(xz), 7, ink)
				draw_circle(point(xz), 4, Color(1,0.9,0.5))

	func _draw_tomb() -> void:
		var font := get_theme_default_font()
		var ink := Color(0.2,0.15,0.08)
		var marks := [[Vector2(0.50,0.82),"CP03 灯台"],[Vector2(0.25,0.82),"蓝光 · 返回草甸"],[Vector2(0.74,0.32),"仪式记录"],[Vector2(0.50,0.12),"入口已净化 · 石阶" if state.ln02_purified else "入口结界 · 双供能"]]
		if state.ln02_revealed:
			marks.append_array([[Vector2(0.25,0.27),"北侧 · 已切断" if state.ln02_north_cut else "北侧 · 螺旋供能"],[Vector2(0.25,0.51),"南侧 · 已切断" if state.ln02_south_cut else "南侧 · 箭纹供能"]])
		draw_polyline(PackedVector2Array([size*marks[1][0],size*marks[0][0],size*Vector2(0.5,0.32),size*marks[2][0]]),ink,3,true)
		for mark in marks:
			var p: Vector2 = size*mark[0]
			draw_circle(p,6,ink)
			draw_string(font,p+Vector2(12,5),mark[1],HORIZONTAL_ALIGNMENT_LEFT,-1,get_theme_default_font_size(),ink)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$BackgroundTextureRect.hide()
	%MenuContainer.hide()
	set_meta("page_width", 1040)
	var column := create_page(self, "押送路线 · 路线图 [M]", true)
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
	# Give scaled labels their own vertical space; the retained page scrolls.
	diagram.custom_minimum_size.y = 310 * state.text_scale
	information.text = ("裂隙墓殿入口 · " + state.ritual_information() + "\n两院营救区域仍被封锁。" if state.current_map == state.MAP03 else state.mf01_information()) + ("\n\n" + state.mf02_information() if state.mf02_acquired else "")
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
	return {"open":visible, "acquired":state.mf01_acquired, "mf02_acquired":state.mf02_acquired, "information":information.text, "pause_owned":world.pause_owners.has("map")}
