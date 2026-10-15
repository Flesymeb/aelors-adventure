shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;
// Product adaptation of the Cats transparent gradient: no TIME, textures,
// screen reads or renderer-specific particle trails. Depth testing stays on.
void fragment() {
	float blade_taper = smoothstep(0.0, 0.22, UV.y) * (1.0 - smoothstep(0.92, 1.0, UV.y));
	ALBEDO = mix(vec3(0.66, 0.71, 0.63), vec3(1.0, 0.91, 0.66), UV.y);
	ALPHA = COLOR.a * blade_taper * 0.30;
}
