// Fixed moon/night composition adapted from krzmig's MIT simple sky project.
// See assets/bosses/presentation/LICENSES.txt. No calendar or shader TIME.
shader_type sky;
uniform float effect_time = 0.0;
uniform bool reduced_motion = false;
uniform sampler3D sample_noise : filter_linear, repeat_enable;
uniform vec3 night_top_color : source_color = vec3(0.018, 0.028, 0.075);
uniform vec3 night_bottom_color : source_color = vec3(0.12, 0.18, 0.28);
uniform vec3 moon_direction = vec3(0.48, 0.63, -0.61);
float sphere_intersect(vec3 view_dir, vec3 sphere_pos, float radius) {
    float b = dot(-sphere_pos, view_dir);
    float c = dot(-sphere_pos, -sphere_pos) - radius * radius;
    float h = b * b - c;
    return h < 0.0 ? -1.0 : -b - sqrt(max(0.0, h));
}
void sky() {
    vec3 direction = normalize(EYEDIR);
    float height = abs(sin(direction.y * PI * 0.5));
    vec3 color = mix(night_bottom_color, night_top_color, height);
    color = mix(color, vec3(0.016, 0.023, 0.04), smoothstep(0.0, 0.45, -direction.y));
    vec3 moon = normalize(moon_direction);
    float disc = 1.0 - smoothstep(0.034, 0.038, distance(direction, moon));
    float hit = sphere_intersect(direction, moon, 0.038);
    vec3 moon_normal = normalize(moon - direction * max(0.0, hit));
    float phase = pow(clamp(dot(moon_normal, normalize(vec3(-0.8, 0.4, 0.2))), 0.12, 1.0), 0.55);
    color += vec3(0.82, 0.87, 1.0) * disc * phase * 1.5;
    color += vec3(0.1, 0.16, 0.25) * pow(max(0.0, dot(direction, moon)), 55.0);
    // Directional noise has no division/sqrt singularity at the horizon.
    float clock = reduced_motion ? 0.0 : effect_time * 0.0015;
    float cloud = texture(sample_noise, direction * 1.25 + vec3(clock, 0.0, clock * 0.4)).r;
    float cover = smoothstep(0.46, 0.64, cloud) * smoothstep(-0.02, 0.2, direction.y);
    vec3 cell = floor(direction * 370.0);
    float star = fract(sin(dot(cell, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
    color += vec3(0.45, 0.57, 0.72) * step(0.9987, star) * smoothstep(0.05, 0.35, direction.y) * (1.0-cover);
    COLOR = mix(color, vec3(0.055, 0.075, 0.12) + vec3(0.07) * pow(max(0.0, dot(direction, moon)), 12.0), cover * 0.8);
}
