extends "res://ui/menu_foundation/main_menu.gd"
## Read-only earned route-record projection through the retained Maaack page/focus lifecycle.
const GROUND = preload("res://world/map02_ground.gd")
var world: Node3D
var suspended := false
var information: Label
var diagram: Control
var route_key: Label
var selected_approach := "warden"
var approach_buttons: Array[Button] = []
var navigation_hint: Label

static func mf01_navigation(owner: Node) -> String:
	var known: String = owner.mf01_information()
	if not owner.mf01_acquired: return known
	return mf01_approach(owner) + "\n\n" + known

static func mf01_approach(owner: Node) -> String:
	if not owner.mf01_acquired: return ""
	return "MF01 · 林缘调查路线：从固定路碑沿树根左侧前行，到树线前停下。按 3 装备旧灯，F 显形；靠近显露的魔痕，看到 E 提示后调查。\n返回灯台：从树根左侧回固定路碑，沿岩石右侧退回路障，再沿泥路回草甸灯台。"

static func known_route_marks(owner: Node) -> Array:
	var marks := [[GROUND.ENTRY, "草甸灯台"], [GROUND.ROADBLOCK, "路障泥路"]]
	if owner.mf01_acquired:
		marks.append_array([[GROUND.PRESSURE_FLANK[0], "岩石右侧绕行"], [GROUND.ROUTE_RECORD, "固定路碑 · MF01"], [GROUND.AMBUSH_APPROACH, "树根左侧 · 旧灯调查处"]])
	if owner.mf02_acquired:
		marks.append_array([[GROUND.LINE_APPROACH, "树线后的林路"], [GROUND.LINE_RECORD, "墓殿方向 · 结界记号"], [GROUND.LN01_PASSAGE, "通道已稳定" if owner.ln01_location_purified else "林缘通道 · 结界"]])
	return marks

class RouteDiagram extends Control:
	var state: Node
	var player: Node3D
	var marks: Array = []
	var selected_approach := "warden"
	var highlight_route: Array = []
	func point(xz: Vector2) -> Vector2:
		var north := 120.0 if state.mf02_acquired else 80.0
		return Vector2(size.x * (0.28 + xz.x / 35.0), 30 + (north - xz.y) / (north - 20.0) * (size.y - 70))
	func _draw() -> void:
		if state.current_map == state.MAP03:
			_draw_tomb()
			return
		var ground = preload("res://world/map02_ground.gd")
		var font: Font = get_theme_default_font()
		var font_size := int(16 * state.text_scale)
		var ink := Color(0.20, 0.15, 0.08)
		var route: PackedVector2Array = []
		for mark in marks: route.append(point(mark[0]))
		draw_polyline(route, ink, 3, true)
		for index in marks.size():
			var mark: Array = marks[index]
			var p := point(mark[0])
			draw_texture_rect(preload("res://assets/ui/journal_icons.svg"), Rect2(p - Vector2(13,13), Vector2(26,26)), false, ink)
			# Long, scaled names wrap in the page key rather than colliding on the map.
			draw_string(font, p + Vector2(24, font_size * 0.3), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
		if state.mf01_acquired:
			var rock := point(ground.PRESSURE_COVER)
			draw_circle(rock, 9, Color(0.6,0.61,0.56))
		if is_instance_valid(player) and state.current_map == state.MAP02:
			var xz := Vector2(player.global_position.x, player.global_position.z)
			if xz.y >= 20 and xz.y <= (120 if state.mf02_acquired else 80):
				draw_circle(point(xz), 7, ink)
				draw_circle(point(xz), 4, Color(1,0.9,0.5))

	static func tomb_point(xz: Vector2, area: Vector2) -> Vector2:
		# Same world coordinates as ground/encounter anchors; north is -Z.
		return Vector2(area.x * (0.22 + (xz.x + 13.0) / 26.0 * 0.52), 24.0 + (xz.y + 36.0) / 43.0 * (area.y - 48.0))

	static func tomb_routes(unlocked: bool) -> Array:
		var ground = preload("res://world/map03_ground.gd")
		var routes := [[ground.RETURN, ground.ENTRY, Vector2(0,-3), ground.RECORD], [Vector2(0,-3), ground.DEVICE]]
		if unlocked:
			routes.append([Vector2(0,-3)] + ground.VEYNE_ROUTE + [Vector2(-4,-15), preload("res://world/veyne_arena.gd").HOME])
			routes.append([Vector2(0,-3)] + ground.OPEN_ROUTE + [preload("res://combat/map03_warden.gd").HOME])
		return routes

	func _draw_tomb() -> void:
		var ground = preload("res://world/map03_ground.gd")
		var font := get_theme_default_font()
		var ink := Color(0.2,0.15,0.08)
		var font_size := int(15 * state.text_scale)
		var marks := [[ground.ENTRY,"CP03 灯台"],[ground.RETURN,"返回草甸"],[ground.RECORD,"仪式记录"],[ground.DEVICE,"入口已净化" if state.ln02_purified else "入口结界 · 双供能"]]
		if state.ln02_purified:
			marks.append([preload("res://world/veyne_arena.gd").HOME,"裂隙祭坛 · 钥印已取得" if state.veyne_release_key else "裂隙祭坛 · 检查钥印" if state.veyne_defeated else "裂隙祭坛 · 维恩"])
			marks.append([preload("res://combat/map03_warden.gd").HOME,"看守院 · 锁印已解除" if state.warden_lock_released else "看守院 · 检查装置" if state.warden_defeated else "看守院"])
		if state.ln02_revealed:
			marks.append_array([[ground.NORTH,"北供能 · 已切断" if state.ln02_north_cut else "北供能 · 螺旋"],[ground.SOUTH,"南供能 · 已切断" if state.ln02_south_cut else "南供能 · 箭纹"]])
		for anchors in tomb_routes(state.ln02_purified):
			var route := PackedVector2Array()
			for anchor in anchors: route.append(tomb_point(anchor,size))
			draw_polyline(route,ink,3,true)
		var selected_route: Array = highlight_route
		var highlight := PackedVector2Array()
		for anchor in selected_route: highlight.append(tomb_point(anchor,size))
		if highlight.size() > 1:
			draw_polyline(highlight,Color(0.72,0.35,0.04),6,true)
			for p in highlight: draw_circle(p,4,Color(0.96,0.72,0.20))
		for index in marks.size():
			var p := tomb_point(marks[index][0],size)
			draw_circle(p,5,ink)
			draw_string(font,p+Vector2(9,4),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)
		if is_instance_valid(player):
			var p := tomb_point(Vector2(player.global_position.x,player.global_position.z),size)
			draw_circle(p,9,ink)
			draw_circle(p,6,Color(1,0.85,0.36))
			var forward := Vector2(-sin(player.global_rotation.y),-cos(player.global_rotation.y))
			draw_line(p,p+forward*17,ink,3,true)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$BackgroundTextureRect.hide()
	%MenuContainer.hide()
	set_meta("page_width", 1040)
	var column := create_page(self, "押送路线 · 路线图 [M]", true)
	var approaches := HBoxContainer.new()
	approaches.add_theme_constant_override("separation",12)
	column.add_child(approaches)
	for destination in ["warden","veyne"]:
		var choice := button(approaches,"",select_approach.bind(destination))
		choice.toggle_mode = true
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		approach_buttons.append(choice)
	navigation_hint = paragraph(column, "")
	diagram = RouteDiagram.new()
	diagram.state = state
	diagram.player = world.player
	diagram.custom_minimum_size.y = 310
	diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(diagram)
	route_key = paragraph(column, "")
	information = paragraph(column, "")
	paragraph(column, "圆点：艾洛 · 路线示意，上方朝林缘")
	button(get_meta("footer_column"), "返回 [M / Esc]", close_panel)
	visibility_changed.connect(func():
		if not visible and not suspended: world._set_pause_owner("map", false))
	refresh()

static func approach_next(owner: Node, destination: String) -> String:
	if not owner.ln02_purified and not owner.ritual_record_read: return "先在入口调查仪式记录"
	if not owner.ln02_purified and not owner.ln02_revealed: return "装备旧灯，显形入口结界"
	if not owner.ln02_purified and not owner.ln02_north_cut: return "先切断北供能 · 螺旋"
	if not owner.ln02_purified and not owner.ln02_south_cut: return "先切断南供能 · 箭纹"
	if not owner.ln02_purified: return "回入口装置，用旧灯净化结界"
	if destination == "warden":
		return "右院锁印装置已解除；用旧灯逐人营救" if owner.warden_lock_released else "前往右院检查锁印装置" if owner.warden_defeated else "沿右侧石阶进入看守院 · 锁印看守"
	return "钥印已取得；继续营救与核心目标" if owner.veyne_release_key else "前往祭坛检查钥印" if owner.veyne_defeated else "沿左侧石阶进入裂隙祭坛 · 维恩"

static func selected_tomb_route(owner: Node, destination: String) -> Array:
	var ground = preload("res://world/map03_ground.gd")
	var start := [ground.ENTRY,Vector2(0,-3)]
	if not owner.ln02_purified and not owner.ritual_record_read: return start + [ground.RECORD]
	if not owner.ln02_purified and not owner.ln02_revealed: return start + [ground.DEVICE]
	if not owner.ln02_purified and not owner.ln02_north_cut: return start + [Vector2(-4,-3),ground.NORTH]
	if not owner.ln02_purified and not owner.ln02_south_cut: return start + [Vector2(-4,-3),ground.SOUTH]
	if not owner.ln02_purified: return start + [ground.DEVICE]
	return start + (ground.OPEN_ROUTE + [preload("res://combat/map03_warden.gd").HOME] if destination == "warden" else ground.VEYNE_ROUTE + [Vector2(-4,-15),preload("res://world/veyne_arena.gd").HOME])

func select_approach(destination: String) -> void:
	if destination not in ["warden","veyne"]: return
	selected_approach = destination
	refresh()

func refresh() -> void:
	# Give scaled labels their own vertical space; the retained page scrolls.
	diagram.custom_minimum_size.y = 310 * state.text_scale
	diagram.marks = known_route_marks(state)
	diagram.selected_approach = selected_approach
	diagram.highlight_route = selected_tomb_route(state,selected_approach) if state.current_map == state.MAP03 else []
	for index in approach_buttons.size():
		var choice: Button = approach_buttons[index]
		choice.visible = state.current_map == state.MAP03
		choice.set_pressed_no_signal(selected_approach == ("warden" if index == 0 else "veyne"))
		choice.text = ("◆ " if choice.button_pressed else "◇ ") + ("右阶 · 锁印看守" if index == 0 else "左阶 · 维恩")
	navigation_hint.visible = state.current_map == state.MAP03 or state.mf01_acquired
	navigation_hint.text = ("入口净化后，两侧石阶均可通行。左阶通往裂隙祭坛，右阶通往看守院；可自行选择顺序。" if state.ln02_purified else "入口结界尚未净化；先调查仪式记录并解除双供能。") if state.current_map == state.MAP03 else mf01_approach(state) if navigation_hint.visible else ""
	if state.current_map == state.MAP03:
		navigation_hint.text = "已选：" + ("右阶 · 锁印看守" if selected_approach == "warden" else "左阶 · 维恩") + "\n下一步：" + approach_next(state,selected_approach) + "\n金色连线为所选路线；选择不改变通行条件。"
	route_key.text = ""
	route_key.visible = true
	if state.current_map == state.MAP03:
		route_key.text = "1 · CP03 灯台    2 · 返回草甸    3 · 仪式记录    4 · 入口结界"
		if state.ln02_purified: route_key.text += "\n5 · 裂隙祭坛 · " + ("钥印已取得" if state.veyne_release_key else "检查钥印" if state.veyne_defeated else "维恩") + "    6 · 看守院 · " + ("锁印已解除" if state.warden_lock_released else "检查装置" if state.warden_defeated else "锁印看守")
		if state.ln02_revealed: route_key.text += "\n" + ("7" if state.ln02_purified else "5") + " · 北供能    " + ("8" if state.ln02_purified else "6") + " · 南供能"
	else:
		var marks := known_route_marks(state)
		for index in marks.size(): route_key.text += "%d · %s\n" % [index + 1, marks[index][1]]
		if state.mf01_acquired: route_key.text += "灰色圆点：岩石掩体"
	information.text = ("裂隙墓殿入口 · " + state.ritual_information() + "\n" + state.rescue_information() + ("\n左侧石阶通往裂隙祭坛，右侧石阶通往看守院。两院均可先行；右院逐人用旧灯营救；入口内侧蓝灯旁主动集合。" if state.ln02_purified else "\n两院营救区域仍被封锁。") if state.current_map == state.MAP03 else state.mf01_information()) + ("\n\n" + state.mf02_information() if state.mf02_acquired else "")
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
	return {"open":visible, "acquired":state.mf01_acquired, "mf02_acquired":state.mf02_acquired, "information":(navigation_hint.text + "\n\n" if navigation_hint.visible else "") + information.text, "route_key":route_key.text, "pause_owned":world.pause_owners.has("map")}
