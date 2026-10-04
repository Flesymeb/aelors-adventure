shader_type spatial;

uniform sampler2D dirt_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D detail_noise : filter_linear_mipmap, repeat_enable;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec2 uv = world_position.xz;
	vec3 soil = mix(vec3(0.29, 0.27, 0.24), texture(dirt_texture, uv * 0.35).rgb * vec3(0.65, 0.64, 0.60), 0.5);
	vec3 grain = texture(detail_noise, uv * 1.4).rgb;
	float macro = texture(detail_noise, uv * 0.025).r;
	float snow_cover = smoothstep(0.40, 0.64, world_normal.y) * smoothstep(0.16, 0.48, macro);
	vec3 snow = vec3(0.78, 0.84, 0.89) * (0.93 + grain.r * 0.13);
	ALBEDO = mix(soil, snow, snow_cover);
	ROUGHNESS = mix(0.91, 0.83, snow_cover);
	SPECULAR = 0.18;
	// A restrained micro-normal in world space, independent of imported UVs.
	vec3 bumped = normalize(world_normal + vec3(grain.g - 0.5, 0.0, grain.b - 0.5) * 0.12);
	NORMAL = normalize((VIEW_MATRIX * vec4(bumped, 0.0)).xyz);
}
