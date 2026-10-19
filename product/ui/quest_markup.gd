extends RefCounted
## Mark up plain authoritative text once; never rewrite facts or action keys.
const PEOPLE := ["伊莎","奥伦","赫斯","罗恩","艾洛"]
const PLACES := ["蓝色洞口（蓝色柱群）","蓝色柱群","蓝色洞口","蓝光通道","石桥","村庄广场","林缘草甸","墓殿灯台"]
const QUESTS := ["救援请求","返回交谈","离村确认","出发前的训练","防御练习","元素练习","旧灯练习","通道守卫","首次升级","巡路剑","巡路弓","当前行动"]
static func format_text(plain: String, on_paper := false) -> String:
	var tokens: Array = PEOPLE + PLACES + QUESTS
	tokens.sort_custom(func(a,b): return a.length() > b.length())
	var output := ""
	var position := 0
	while position < plain.length():
		var matched := ""
		for token in tokens:
			if plain.substr(position,token.length()) == token:
				matched = token
				break
		if matched != "":
			var color := "#ffaaa0" if matched in PEOPLE else ("#a6dcff" if matched in PLACES else "#a9e3ae")
			if on_paper:
				color = "#8f2028" if matched in PEOPLE else ("#15527b" if matched in PLACES else "#245b2c")
			output += "[b][color=" + color + "]" + matched + "[/color][/b]"
			position += matched.length()
		else:
			var character := plain.substr(position,1)
			output += "[lb]" if character == "[" else ("[rb]" if character == "]" else character)
			position += 1
	return output

static func configure(label: RichTextLabel, font: Font, on_paper := false) -> void:
	label.bbcode_enabled = true
	label.add_theme_font_override("normal_font",font)
	var bold := FontVariation.new()
	bold.base_font = font
	bold.variation_embolden = 0.6
	label.add_theme_font_override("bold_font",bold)
	# Parchment needs dark ink; the HUD needs light text over its dark panel.
	label.add_theme_color_override("default_color", Color(0.20,0.13,0.07) if on_paper else Color(1,0.94,0.81))
	label.add_theme_color_override("font_outline_color", Color(0.04,0.05,0.03))
	label.add_theme_constant_override("outline_size",0 if on_paper else 2)
