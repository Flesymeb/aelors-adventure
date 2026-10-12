extends Node
## Explicit disposable geometry fixture. No actors, rewards or saves are
## created; numeric layout qualification does not accept ordinary combat.
var observations: Dictionary = {}

func _ready() -> void:
	observations = await run(self)

func _mcp_state() -> Dictionary:
	return {"diagnostic_fixture": true, "observations": observations}

static func run(holder: Node) -> Dictionary:
	var hud: CanvasLayer = preload("res://combat_hud.gd").new()
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	holder.add_child(hud)
	hud.set_process(false)
	hud.enemy.hide()
	hud.boss_rows.hide()
	var checks := {}
	var cases: Array[Dictionary] = []
	var viewport := Vector2(1280, 720)
	var safe := Rect2(Vector2(12, viewport.y * 0.24), Vector2(viewport.x - 24, viewport.y * 0.76 - 130))
	for scale in [1.0, 1.5, 2.0]:
		var occupied: Array[Rect2] = [Rect2(Vector2(780, 180), Vector2(470, 120))]
		var raw_rows: Array[Dictionary] = []
		var case_rows: Array[Control] = []
		var separated := true
		var contained := true
		for i in 3:
			var rows := VBoxContainer.new()
			var title := Label.new()
			title.text = ["前哨守卫 · 抬手预告", "河道守卫 · 36/36", "河道守卫 · 抬手预告"][i]
			title.add_theme_font_size_override("font_size", int(17 * scale))
			rows.add_child(title)
			rows.add_child(hud.meter(Color(0.75, 0.18, 0.11), 36))
			hud.root.add_child(rows)
			case_rows.append(rows)
			await holder.get_tree().process_frame
			var anchor := Vector2(860 + i * 6, 390 + i * 4)
			var placed: bool = hud.place_enemy_bar(rows, anchor, viewport, occupied)
			await holder.get_tree().process_frame
			var rect := rows.get_global_rect()
			var prior := occupied.slice(0, occupied.size() - 1) if placed else occupied
			for other in prior:
				if rect.grow(4).intersects(other): separated = false
			contained = contained and placed and safe.encloses(rect)
			raw_rows.append({"title": title.text, "placed": placed, "position": [rect.position.x, rect.position.y], "size": [rect.size.x, rect.size.y], "minimum_size": [rows.get_combined_minimum_size().x, rows.get_combined_minimum_size().y]})
		checks["scale_%s_separated" % str(scale)] = separated
		checks["scale_%s_contained" % str(scale)] = contained
		cases.append({"scale": scale, "rows": raw_rows})
		for rows in case_rows: rows.free()
	# Exhaust every vertical candidate at the projected x. A free lateral area
	# remains: the former finite vertical search retained an overlapping origin.
	var blocked: Array[Rect2] = [Rect2(Vector2(470, safe.position.y), Vector2(320, safe.size.y))]
	var lateral: Rect2 = hud.find_enemy_bar_placement(Vector2(220, 55), Vector2(510, 300), safe, blocked)
	checks.vertical_exhaustion_uses_free_lateral_space = lateral.size != Vector2.ZERO and not lateral.grow(4).intersects(blocked[0]) and safe.encloses(lateral)
	var full: Array[Rect2] = [safe]
	checks.no_overlapping_fallback = hud.find_enemy_bar_placement(Vector2(220, 55), Vector2(510, 300), safe, full).size == Vector2.ZERO
	var empty: Array[Rect2] = []
	checks.oversized_row_rejected = hud.find_enemy_bar_placement(Vector2(2000, 55), Vector2.ZERO, safe, empty).size == Vector2.ZERO
	hud.free()
	return {"checks": checks, "cases": cases, "scope": "settled native Control geometry only; ordinary camera, visibility and actor association require independent observation"}
