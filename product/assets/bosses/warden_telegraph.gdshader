shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
// Product-authored world-space warning. No screen distortion or hidden damage.
uniform vec4 warning_color : source_color = vec4(1.0, 0.35, 0.08, 1.0);
uniform float sector = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float r = length(p);
    float ring = smoothstep(0.83, 0.89, r) * (1.0 - smoothstep(0.96, 1.0, r));
    float fill = (1.0 - smoothstep(0.94, 1.0, r)) * (0.12 + progress * 0.16);
    float arc = sector < 0.5 ? 1.0 : step(0.5, p.y / max(r, 0.001));
    ALBEDO = warning_color.rgb;
    EMISSION = warning_color.rgb * 0.6;
    ALPHA = (ring * 0.8 + fill) * arc * warning_color.a;
}
