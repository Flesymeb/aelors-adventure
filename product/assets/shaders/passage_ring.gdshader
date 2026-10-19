// Adapted from CasualGarageCoder, Ring of Power, CC0:
// https://godotshaders.com/shader/ring-of-power/
// Polar noise ring moved from canvas to depth-tested world geometry.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec4 color : source_color = vec4(0.08,0.6,1.0,0.65);
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float effect_clock = 0.0;
uniform float strength = 1.0;
void fragment() {
	vec2 v = vec2(0.5) - UV;
	float d = length(v) * 2.0;
	float angle = atan(v.y, v.x) + effect_clock * 0.4;
	float band = max(0.0, 1.0 - abs(d - 0.7) / 0.12);
	vec2 polar = fract(vec2(angle / 6.283185, d - effect_clock * 0.2));
	float flow = mix(0.45,1.0,texture(noise_tex,polar).r);
	ALBEDO = color.rgb;
	EMISSION = color.rgb * band * flow * strength * 1.8;
	ALPHA = band * flow * color.a * strength;
}
