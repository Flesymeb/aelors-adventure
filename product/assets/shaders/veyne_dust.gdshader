shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform float effect_clock = 0.0;
uniform vec4 dust_tint : source_color = vec4(0.47, 0.43, 0.37, 0.36);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), f.x), f.y);
}

void vertex() {
	// Camera-facing particles retain each particle's world position and scale.
	mat4 facing = MODEL_MATRIX;
	facing[0].xyz = INV_VIEW_MATRIX[0].xyz * length(MODEL_MATRIX[0].xyz);
	facing[1].xyz = INV_VIEW_MATRIX[1].xyz * length(MODEL_MATRIX[1].xyz);
	facing[2].xyz = INV_VIEW_MATRIX[2].xyz * length(MODEL_MATRIX[2].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * facing;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float edge = 1.0 - smoothstep(0.35, 1.0, length(p));
	vec2 flow = UV * 4.5 + vec2(effect_clock * 0.18, -effect_clock * 0.24);
	float wisps = noise2(flow) * 0.65 + noise2(flow * 2.07) * 0.35;
	ALBEDO = dust_tint.rgb * mix(0.8, 1.12, wisps) * COLOR.rgb;
	ALPHA = min(0.42, edge * smoothstep(0.12, 0.7, wisps) * dust_tint.a * COLOR.a);
}
