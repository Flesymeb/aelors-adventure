shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float effect_age = 0.0;
uniform bool reduced_motion = false;
void fragment() {
	float t = clamp(effect_age / 0.9, 0.0, 1.0);
	float radius = reduced_motion ? 0.58 : mix(0.22, 0.92, t);
	float d = length(UV * 2.0 - 1.0);
	float band = smoothstep(radius - 0.15, radius - 0.055, d) * (1.0 - smoothstep(radius, radius + 0.06, d));
	ALBEDO = vec3(0.48, 0.39, 0.28);
	ALPHA = band * (1.0 - t) * 0.48;
}
