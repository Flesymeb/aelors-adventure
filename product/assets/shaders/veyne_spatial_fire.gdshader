// Bounded mouth-axis adaptation of Dari0us' MIT spatial fire raymarcher.
// Source ray/box intersection, noise advection and density integration retained;
// no billboard/depth reconstruction, jitter, extra damage, or shader TIME.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform sampler3D sample_noise : filter_linear, repeat_enable;
uniform float effect_time = 0.0;
uniform float flame_height = 8.0;
uniform float flame_height_offset = 0.0;
uniform float max_alpha = 0.42;
uniform bool core_layer = false;
uniform bool reduced_motion = false;
uniform bool layered_mode = false;
varying vec3 local_position;
varying vec3 local_camera;
float get_noise_value(vec3 p_coord, float scale_factor, float time_offset_y) {
    return texture(sample_noise, fract(p_coord * scale_factor + vec3(0.0,time_offset_y,0.0))).r;
}
float density_at(vec3 p) {
    float along = p.y / max(0.001, flame_height);
    float radius = (0.4 + max(0.0,p.y) * 0.18) * (core_layer ? 0.28 : 1.0);
    float radial = length(p.xz) / max(0.001,radius);
    float clock = reduced_motion ? 0.0 : -effect_time * 0.6;
    float noise = get_noise_value(p, 0.26, clock);
    float shape = (1.0-smoothstep(0.58,1.0,radial)) * smoothstep(0.0,0.035,along) * (1.0-smoothstep(0.86,1.0,along));
    return shape * smoothstep(0.28,0.68,noise);
}
void vertex() {
    if (core_layer) { VERTEX.xz *= 0.28; }
    else if (!layered_mode) {
        // Inward-only advected tongues break the smooth container silhouette.
        // The authored/clipped hazard envelope is an absolute upper bound.
        float clock = reduced_motion ? 0.0 : -effect_time * 0.9;
        float noise = get_noise_value(VERTEX, 0.48, clock);
        float along = VERTEX.y / max(0.001,flame_height);
        float tongues = mix(0.55,1.0,smoothstep(0.25,0.72,noise));
        float tail = 1.0-smoothstep(0.62,1.0,along)*0.45;
        VERTEX.xz *= tongues * tail;
    }
    local_position = VERTEX;
    local_camera = (inverse(MODELVIEW_MATRIX) * vec4(0.0,0.0,0.0,1.0)).xyz;
}
void fragment() {
    // One integration per pixel, despite two-sided mouth/end-cap geometry.
    if (!FRONT_FACING) { discard; }
    vec3 ray_direction = normalize(local_position-local_camera);
    float width = (0.4+flame_height*0.18) * (core_layer ? 0.28 : 1.0);
    // Preserve direction signs at grazing angles, never divide by zero.
    vec3 safe_direction = mix(vec3(-1.0),vec3(1.0),step(vec3(0.0),ray_direction)) * max(abs(ray_direction),vec3(0.0001));
    vec3 t0 = (vec3(-width,0.0,-width)-local_camera)/safe_direction;
    vec3 t1 = (vec3(width,flame_height,width)-local_camera)/safe_direction;
    vec3 smaller = min(t0,t1);
    vec3 larger = max(t0,t1);
    float t_enter = max(0.0,max(smaller.x,max(smaller.y,smaller.z)));
    float t_exit = min(larger.x,min(larger.y,larger.z));
    if (t_exit <= t_enter) { discard; }
    float density = 0.0;
    if (layered_mode) {
        // Lighter native spatial alternative: two nested, textured shells.
        float noise = get_noise_value(local_position,0.26,reduced_motion ? 0.0 : -effect_time*0.6);
        float along = local_position.y/max(0.001,flame_height);
        density = smoothstep(0.3,0.68,noise)*(1.0-smoothstep(0.8,1.0,along));
    } else {
        // Fixed six samples, versus upstream's view-dependent 6..24 and wobble.
        float step_size = (t_exit-t_enter)/6.0;
        for (int i=0;i<6;i++) {
            vec3 point = local_camera+ray_direction*(t_enter+(float(i)+0.5)*step_size);
            float alpha_step = 1.0-exp(-density_at(point)*step_size*1.6);
            density += (1.0-density)*alpha_step;
        }
    }
    vec3 color_outer = vec3(0.95,0.09,0.008);
    vec3 color_mid = vec3(1.0,0.44,0.035);
    vec3 color_core = vec3(1.0,0.88,0.42);
    ALBEDO = core_layer ? color_core : mix(color_outer,color_mid,density);
    ALPHA = clamp(density,0.0,1.0)*max_alpha;
}
