extends Control

var player: CharacterBody3D
var font := SystemFont.new()


func _ready() -> void:
	font.font_names = PackedStringArray(["Inter", "Ubuntu", "Noto Sans"])
	font.font_weight = 500
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player == null or player.weapon_mode != "bow" or player.aim_blend < 0.01:
		return
	var center := size * 0.5
	var alpha: float = player.aim_blend
	var charge: float = player.bow_charge
	var gap := lerpf(11.0, 5.0, charge)
	var white := Color(0.95, 0.98, 1.0, alpha)
	var shadow := Color(0.025, 0.035, 0.05, alpha * 0.85)
	for axis in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + axis * gap, center + axis * (gap + 6.0), shadow, 4.0, true)
		draw_line(center + axis * gap, center + axis * (gap + 6.0), white, 1.5, true)
	draw_circle(center, 2.8, shadow)
	draw_circle(center, 1.3, white)
	# Large-radius arc with its center left of the reticle: only a small
	# angle is visible on the right, forming a gently curved charge gauge.
	# Screen Y points down: decreasing the angle fills from bottom to top.
	var start := deg_to_rad(15.0)
	var sweep := deg_to_rad(-30.0)
	var arc_center := center + Vector2(-65.0, 0)
	draw_arc(arc_center, 104.0, start, start + sweep, 32, shadow, 4.0, true)
	draw_arc(arc_center, 104.0, start, start + sweep, 32, Color(1, 1, 1, alpha * 0.25), 1.5, true)
	if charge > 0.001:
		var color := Color(0.36, 0.82, 1.0, alpha).lerp(Color(1.0, 0.72, 0.25, alpha), charge)
		draw_arc(arc_center, 104.0, start, start + sweep * charge, maxi(2, int(32 * charge)), color, 2.5, true)
		var text := "READY" if charge >= 0.99 else "%d%%" % int(charge * 100)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var at := center + Vector2(49.0, 4.0)
		# A subtle pill provides contrast without thick text outlines.
		var pill := StyleBoxFlat.new()
		pill.bg_color = Color(0.04, 0.07, 0.10, alpha * 0.65)
		pill.set_corner_radius_all(5)
		draw_style_box(pill, Rect2(at + Vector2(-6, -14), Vector2(width + 12, 20)))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
