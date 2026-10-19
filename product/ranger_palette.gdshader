shader_type spatial;

uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_texture : filter_linear_mipmap_anisotropic;
uniform vec4 dye_color : source_color = vec4(0.42, 0.70, 1.0, 1.0);

void fragment() {
	vec3 base = texture(base_texture, UV).rgb;
	float green_mask = smoothstep(0.025, 0.095, base.g - max(base.r, base.b));
	vec3 dyed = base.g * dye_color.rgb * 1.5;
	ALBEDO = mix(base, dyed, green_mask);
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	vec3 orm = texture(orm_texture, UV).rgb;
	AO = orm.r;
	ROUGHNESS = orm.g;
	METALLIC = orm.b;
}
