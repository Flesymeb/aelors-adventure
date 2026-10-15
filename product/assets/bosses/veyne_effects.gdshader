shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
// Authored world-space beam/rift warning; no depth-buffer or compute dependency.
uniform vec4 warning_color : source_color = vec4(0.15,0.8,1.0,0.8);
uniform float radial = 0.0;
uniform bool footprint = false;
uniform float progress : hint_range(0.0,1.0) = 0.0;
void fragment() {
 vec2 p = UV * 2.0 - 1.0;
 float edge = radial > 0.5 ? length(p) : abs(p.x);
 if (footprint) { edge = max(abs(p.x),abs(p.y)); }
 float rim = smoothstep(0.78,0.86,edge) * (1.0-smoothstep(0.95,1.0,edge));
 float fill = (1.0-smoothstep(0.9,1.0,edge)) * (0.12+progress*0.24);
 ALBEDO = warning_color.rgb;
 EMISSION = warning_color.rgb * (0.6+progress);
 ALPHA = (rim+fill)*warning_color.a*(footprint ? COLOR.a : 1.0);
}
