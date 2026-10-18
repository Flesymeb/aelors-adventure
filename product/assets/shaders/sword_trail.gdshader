shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;
// Product adaptation of the Cats transparent gradient: no TIME, textures,
// screen reads or renderer-specific particle trails. Depth testing stays on.
uniform bool blade_overlay = false;
uniform vec3 stage_tint = vec3(0.94, 0.88, 0.68);
uniform float stage_strength : hint_range(0.0, 1.5) = 0.72;
varying float blade_height;

void vertex() {
	blade_height = VERTEX.y;
	// A fraction of a millimetre separates the next pass from the base depth.
	// The authored shape and textured base surface remain in place.
	if (blade_overlay) { VERTEX += NORMAL * 0.00012; }
}

void fragment() {
	if (blade_overlay) {
		float blade_mask = smoothstep(0.28, 0.34, blade_height);
		float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
		ALBEDO = stage_tint;
		ALPHA = blade_mask * (0.025 + rim * 0.12) * stage_strength;
	} else {
		float blade_taper = smoothstep(0.0, 0.22, UV.y) * (1.0 - smoothstep(0.92, 1.0, UV.y));
		ALBEDO = mix(vec3(0.66, 0.71, 0.63), stage_tint, UV.y);
		ALPHA = COLOR.a * blade_taper * 0.28 * stage_strength;
	}
}
