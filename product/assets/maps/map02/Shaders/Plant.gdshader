// NOTE: Shader automatically converted from Godot Engine 4.0.beta8.mono's ORMMaterial3D.

shader_type spatial;
render_mode depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float alpha_scissor_threshold;
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_orm : hint_roughness_g,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D texture_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform bool roughness_only = false;
uniform float leaf_transmission : hint_range(0.0,0.3) = 0.0;
uniform float normal_scale : hint_range(-16,16);
uniform float ao_light_affect = 0.;
uniform vec2 uv1_scale;
uniform vec2 uv1_offset;

uniform float wind_speed = 1.;
uniform float wind_strength = 0.1;
uniform float wind_scale= 2.;

float sinCombined(float pos, float time, float rand)
{
	return sin(time + (pos * rand)) + cos(time + (pos * rand) * 0.894341);
}

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	
	//Wind animation
	float speed = TIME * wind_speed;
	vec3 pos = speed + (VERTEX.xyz + COLOR.rgb) * wind_scale;
	float vcolStr = clamp(COLOR.r + COLOR.g, 0, 1); //Strength of the wind, based on red and green vertex color
	
	VERTEX.xyz += vec3(sinCombined(pos.z, speed, 1.2), sinCombined(pos.x, speed, 1.78), sinCombined(pos.y, speed, 0.9)) * vcolStr * wind_strength/10.;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	vec4 orm_tex = texture(texture_orm,base_uv);
	ROUGHNESS = clamp(roughness_only ? orm_tex.r : orm_tex.g,0.45,1.0);
	METALLIC = 0.0; // Bark and leaves are dielectrics, including grey rough maps.
	BACKLIGHT = ALBEDO * leaf_transmission;
	NORMAL_MAP = texture(texture_normal,base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	ALPHA = albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	AO = roughness_only ? 1.0 : orm_tex.r;
	AO_LIGHT_AFFECT = ao_light_affect;
}
