extends Control
## Keyboard skill HUD. Only reflects the authoritative training action.
var cooldown := 0.0
var equipped := false
var casting := false
var key_text := "X"
var text_scale := 1.0
var sword: Texture2D = preload("res://assets/ui/icons/sword.png")

func _ready() -> void:
	name = "WhirlwindSkill"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = "回旋斩 · 两圈剑击 · 施放时抗打断，仍会受伤 · 冷却 6 秒"

func refresh(action: Node, player: Node, owned: bool, scale_value: float, view: Vector2) -> void:
	visible = owned
	cooldown = action.cooldown if is_instance_valid(action) else 0.0
	casting = action.active if is_instance_valid(action) else false
	equipped = player.weapon_mode == "sword"
	key_text = player.key_prompt("whirlwind")
	text_scale = minf(scale_value, 1.3)
	size = Vector2(104,128) * text_scale
	position = Vector2(view.x - size.x - 24, view.y - size.y - 138)
	queue_redraw()

func _draw() -> void:
	var k := text_scale
	var center := Vector2(52,44) * k
	var gold := Color(0.94,0.78,0.39)
	var ready := equipped and cooldown <= 0.0
	draw_circle(center, 40*k, Color(0.025,0.04,0.045,0.94))
	draw_arc(center,40*k,0,TAU,64,Color(0.45,0.39,0.24),2*k,true)
	var tint := gold if ready or casting else Color(0.47,0.49,0.48)
	draw_texture_rect(sword,Rect2(center-Vector2(23,23)*k,Vector2(46,46)*k),false,tint)
	# Two curved strokes distinguish the rotating sword from the weapon slot.
	for start in [-0.65, PI-0.65]:
		draw_arc(center,29*k,start,start+1.65,24,tint,2*k,true)
		var end: float = start+1.65
		var tip := center+Vector2(cos(end),sin(end))*29*k
		draw_line(tip,tip+Vector2(0,-7).rotated(end)*k,tint,2*k,true)
	if cooldown > 0.0:
		var points := PackedVector2Array([center])
		for i in 49:
			var a := -PI/2 + TAU*clampf(cooldown/6.0,0,1)*float(i)/48.0
			points.append(center+Vector2(cos(a),sin(a))*37*k)
		draw_colored_polygon(points,Color(0.02,0.025,0.035,0.68))
		draw_arc(center,40*k,-PI/2,-PI/2+TAU*(1-clampf(cooldown/6.0,0,1)),64,gold,3*k,true)
	if casting: draw_arc(center,42*k,0,TAU,64,Color(0.35,1,0.8),3*k,true)
	var font := get_theme_default_font()
	var state_text := "%.1f" % cooldown if cooldown > 0 else ("施放中" if casting else ("就绪" if equipped else "请持剑"))
	var fs := int(14*k)
	if cooldown > 0: draw_string(font,Vector2(0,50)*k,state_text,HORIZONTAL_ALIGNMENT_CENTER,size.x,int(22*k),Color.WHITE)
	draw_circle(Vector2(80,74)*k,15*k,Color(0.06,0.08,0.08,0.98))
	draw_arc(Vector2(80,74)*k,15*k,0,TAU,32,gold,1.5*k,true)
	draw_string(font,Vector2(64,80)*k,key_text,HORIZONTAL_ALIGNMENT_CENTER,32*k,int(15*k),gold)
	draw_string(font,Vector2(0,104)*k,"回旋斩",HORIZONTAL_ALIGNMENT_CENTER,size.x,int(17*k),Color(0.98,0.91,0.72))
	if cooldown <= 0: draw_string(font,Vector2(0,124)*k,state_text,HORIZONTAL_ALIGNMENT_CENTER,size.x,fs,tint)
