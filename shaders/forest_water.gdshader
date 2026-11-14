// Lake water: clear and shallow green at the edges, deeper blue-green in the middle, with soft ripples.
shader_type spatial;
render_mode depth_draw_never, specular_schlick_ggx;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec3 shallow_color : source_color = vec3(0.30, 0.55, 0.42);
uniform vec3 deep_color : source_color = vec3(0.05, 0.22, 0.30);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// How much water is between the surface and whatever is behind it.
	float raw = texture(depth_tex, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float thickness = max(VERTEX.z - view.z, 0.0);

	// Ripples: two slow, crossing layers of noise.
	vec2 p = wpos.xz;
	float t = TIME * 0.03;
	float a = texture(noise_tex, p * 0.045 + vec2(t, t * 0.6)).r;
	float b = texture(noise_tex, p * 0.09 - vec2(t * 0.8, t)).r;
	vec3 bump = vec3(a - 0.5, 0.0, b - 0.5) * 0.22;
	NORMAL = normalize(NORMAL + bump);

	float depth_mix = clamp(thickness / 3.5, 0.0, 1.0);
	ALBEDO = mix(shallow_color, deep_color, depth_mix);
	ALPHA = clamp(0.25 + thickness * 0.35, 0.0, 0.9) * smoothstep(0.0, 0.08, thickness);
	ROUGHNESS = 0.06;
	SPECULAR = 0.6;
}
