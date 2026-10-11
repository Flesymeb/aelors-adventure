extends CanvasLayer
var training: Node3D
var root: Control
var status: Label
var enemy: VBoxContainer
var enemy_name: Label
var enemy_hp: ProgressBar
var bridge_bars: Dictionary = {}

func _ready() -> void:
	layer = 5
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = preload("res://dialogue_theme.tres").duplicate()
	root.theme.set_color("font_color", "Label", Color(1, 0.91, 0.73))
	root.theme.set_color("font_outline_color", "Label", Color(0.07, 0.06, 0.03))
	root.theme.set_constant("outline_size", "Label", 5)
	add_child(root)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(status)
	enemy = VBoxContainer.new()
	enemy.custom_minimum_size = Vector2(190, 50)
	root.add_child(enemy)
	enemy_name = Label.new()
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy.add_child(enemy_name)
	enemy_hp = meter(Color(0.75, 0.18, 0.11), 24)
	enemy.add_child(enemy_hp)

func frame() -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = preload("res://assets/dialogue/borders/PNG/Default/Panel/panel-013.png")
	style.modulate_color = Color(0.25, 0.22, 0.17, 0.94)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 10)
		style.set_content_margin(side, 12)
	return style

func meter(color: Color, maximum: float) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.max_value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(220, 10)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.06, 0.04, 0.88)
	bg.border_color = Color(0.59, 0.48, 0.29)
	bg.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", bg)
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _process(_delta: float) -> void:
	var state: Node = training.state
	root.visible = training.world.pause_owners.is_empty()
	var viewport = get_viewport().get_visible_rect().size
	# Teaching/reward/restoration notices share the themed gameplay notification lane.
	status.text = ""
	var opponent: CharacterBody3D = training.monster
	var point = opponent.global_position + Vector3.UP * 2.1
	var camera: Camera3D = training.player.camera
	var in_view = not camera.is_position_behind(point)
	var pixel = camera.unproject_position(point) if in_view else Vector2(-1000, -1000)
	enemy.visible = opponent.engaged and opponent.health > 0 and in_view and Rect2(Vector2.ZERO, viewport).has_point(pixel) and opponent.line_clear(training.player.global_position)
	enemy.position = pixel - Vector2(110, 50)
	enemy_hp.max_value = opponent.health_component.max_health
	enemy_hp.value = opponent.health
	enemy_name.text = "◇ 抬手预告" if opponent.phase == "telegraph" else "训练怪 · %d/%d" % [int(opponent.health), int(opponent.health_component.max_health)]
	enemy_name.add_theme_font_size_override("font_size", int(17 * state.text_scale))
	var opponents: Array = []
	var occupied: Array[Rect2] = []
	if enemy.visible: occupied.append(enemy.get_global_rect().grow(6))
	var hud: Node = training.world.gameplay_hud
	if hud and is_instance_valid(hud.tracker) and hud.tracker.is_visible_in_tree():
		occupied.append(hud.tracker.get_global_rect().grow(8))
	if training.world.bridge_encounter:
		opponents.append_array(training.world.bridge_encounter.enemies)
	if training.world.pressure_encounter:
		opponents.append_array(training.world.pressure_encounter.enemies)
	if training.world.ambush_encounter:
		opponents.append_array(training.world.ambush_encounter.enemies)
	if training.world.get("line_encounter"):
		opponents.append_array(training.world.line_encounter.enemies)
	if training.world.channel_guards:
		opponents.append_array(training.world.channel_guards.enemies)
	if training.world.dynamic_encounters:
		opponents.append_array(training.world.dynamic_encounters.enemies)
	for stale in bridge_bars.keys():
		if not is_instance_valid(stale) or stale.is_queued_for_deletion() or not opponents.has(stale):
			bridge_bars[stale].rows.queue_free()
			bridge_bars.erase(stale)
	for opponent2 in opponents:
		if is_instance_valid(opponent2) and not opponent2.is_queued_for_deletion():
			if not bridge_bars.has(opponent2):
				var rows = VBoxContainer.new()
				var title = Label.new()
				title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				rows.add_child(title)
				var bar = meter(Color(0.75,0.18,0.11),24)
				rows.add_child(bar)
				root.add_child(rows)
				bridge_bars[opponent2] = {"rows":rows,"title":title,"bar":bar}
			var b = bridge_bars[opponent2]
			var p = opponent2.global_position + Vector3.UP * 2.4
			var front = not camera.is_position_behind(p)
			var px = camera.unproject_position(p) if front else Vector2(-1000,-1000)
			b.rows.visible = opponent2.visible and opponent2.hitbox.enabled and opponent2.health > 0 and opponent2.engaged and front and Rect2(Vector2.ZERO,viewport).has_point(px) and opponent2.line_clear(training.player.global_position)
			b.bar.value = opponent2.health
			b.bar.max_value = opponent2.health_component.max_health
			b.title.text = opponent2.display_name + (" · 抬手预告" if opponent2.phase == "telegraph" else " · %d/%d" % [int(opponent2.health),int(opponent2.health_component.max_health)])
			b.title.add_theme_font_size_override("font_size",int(17 * state.text_scale))
			if b.rows.visible:
				place_enemy_bar(b.rows,px,viewport,occupied)
	if training.notice_time > 0: status.add_theme_color_override("font_color", Color(1, 0.91, 0.64))

func place_enemy_bar(rows: Control, anchor: Vector2, viewport: Vector2, occupied: Array[Rect2]) -> void:
	var size := rows.get_combined_minimum_size()
	rows.size = size
	var top := viewport.y * 0.24
	var bottom := maxf(top, viewport.y - 130 - size.y)
	var origin := Vector2(clampf(anchor.x-size.x*0.5,12,maxf(12,viewport.x-size.x-12)),clampf(anchor.y-50,top,bottom))
	var placement := Rect2(origin,size)
	# Nearby world anchors must not merge distinct identities/HP into one label.
	# Keep the normal world projection, then use the nearest free vertical lane.
	for offset in [0,-1,1,-2,2,-3,3,-4,4,-5,5]:
		var candidate := Rect2(Vector2(origin.x,clampf(origin.y+offset*(size.y+8),top,bottom)),size)
		var overlaps := false
		for other in occupied:
			if candidate.grow(4).intersects(other): overlaps = true; break
		if not overlaps:
			placement = candidate
			break
	rows.position = placement.position
	occupied.append(placement.grow(4))

func _mcp_state() -> Dictionary:
	return {"health": training.state.health, "experience_target": training.state.experience, "enemy_bar_visible": enemy.visible, "enemy_hp": enemy_hp.value, "enemy_bar_rect": str(enemy.get_global_rect()), "status": status.text}

func readout_obstacles() -> Array[Rect2]:
	# This owner supplies geometry only; HP still comes from health_component.
	var rects: Array[Rect2] = []
	if enemy.is_visible_in_tree(): rects.append(enemy.get_global_rect().grow(12))
	for entry in bridge_bars.values():
		if entry.rows.is_visible_in_tree(): rects.append(entry.rows.get_global_rect().grow(12))
	return rects
