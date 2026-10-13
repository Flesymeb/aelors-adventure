// Product-authored spatial contact glow; no screen copy or autonomous clock.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0, 0.35, 0.06, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float effect_time = 0.0;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 1.5);
	ALBEDO = tint.rgb;
	EMISSION = tint.rgb * 1.4;
	ALPHA = (0.15 + rim * 0.75) * opacity;
}
