// Redwood-style bark: deep vertical furrows, reddish brown, darker at the burnt base.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 bark_light : source_color = vec3(0.42, 0.21, 0.12);
uniform vec3 bark_dark : source_color = vec3(0.17, 0.08, 0.06);

void fragment() {
	// UV.x runs around the trunk (0 to 1), UV.y up it in meters.
	float furrow = texture(noise_tex, vec2(UV.x * 5.0, UV.y * 0.035)).r;
	float fine = texture(noise_tex, vec2(UV.x * 11.0, UV.y * 0.12)).r;
	float ridge = smoothstep(0.32, 0.68, furrow * 0.75 + fine * 0.25);
	vec3 c = mix(bark_dark, bark_light, ridge) * COLOR.rgb;
	ALBEDO = c;
	AO = mix(0.35, 1.0, ridge);
	AO_LIGHT_AFFECT = 0.8;
	ROUGHNESS = 1.0;
	SPECULAR = 0.05;
}
