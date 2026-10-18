shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
// Product-authored world-space warning. No screen distortion or hidden damage.
uniform vec4 warning_color : source_color = vec4(1.0, 0.35, 0.08, 1.0);
uniform float sector = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float release : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float r = length(p);
    float ring = smoothstep(0.83, 0.89, r) * (1.0 - smoothstep(0.96, 1.0, r));
    float fill = (1.0 - smoothstep(0.94, 1.0, r)) * (0.12 + progress * 0.16);
    // A closing perimeter and four spokes communicate timing without color.
    float angle = atan(p.x, p.y);
    float countdown = step(abs(angle), progress * 3.141593) * ring;
    float spokes = (1.0 - smoothstep(0.015, 0.03, min(abs(p.x), abs(p.y)))) * step(0.12,r) * (1.0-step(0.96,r));
    float wavefront = (1.0-smoothstep(0.035,0.10,abs(r-release))) * (1.0-release);
    float arc = sector < 0.5 ? 1.0 : step(0.5, p.y / max(r, 0.001));
    ALBEDO = warning_color.rgb;
    EMISSION = warning_color.rgb * 0.6;
    // Heavy's frontal lane uses advancing arrowheads and a closing edge;
    // the wave retains its complete radial perimeter and four spokes.
    // The owner advances progress, so menus/focus pause the cue without TIME.
    float chevron_y = p.y - abs(p.x) * 0.65;
    float chevrons = 1.0 - smoothstep(0.025, 0.055,
        min(abs(chevron_y - 0.30), abs(chevron_y - 0.61)));
    float heavy_edge = (1.0 - smoothstep(0.02, 0.055, abs(r - mix(0.92, 0.25, progress)))) * 0.45;
    float warning = sector < 0.5 ? ring * 0.45 + countdown * 0.5 + fill + spokes * 0.25
        : ring * (0.5 + progress * 0.4) + fill + chevrons * 0.55 + heavy_edge;
    ALPHA = (release > 0.0 ? wavefront * 0.85 : warning) * arc * warning_color.a;
}
