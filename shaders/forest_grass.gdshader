// Grass tufts: a few crossed cards cut into blades by the shader. Blades shrink away to nothing with
// distance, so grass fades out instead of popping.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 root_color : source_color = vec3(0.17, 0.22, 0.07);
uniform vec3 tip_color : source_color = vec3(0.50, 0.58, 0.22);
uniform float fade_start = 170.0;
uniform float fade_end = 290.0;

varying float tint;
varying float height_amount;

float hash(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float cam_dist = length((VIEW_MATRIX * vec4(wp, 1.0)).xyz);
	VERTEX.y *= 1.0 - smoothstep(fade_start, fade_end, cam_dist);
	float t = TIME * 1.3;
	float sway = (sin(t + origin.x * 0.4 + origin.z * 0.3) + 0.4 * sin(t * 2.7 + wp.x)) * 0.06;
	VERTEX.x += sway * UV.y * UV.y * 3.0;
	tint = texture(noise_tex, origin.xz * 0.013).r;
	height_amount = UV.y;
}

void fragment() {
	float x = UV.x * 5.0;
	float id = floor(x);
	float across = abs(fract(x) - 0.5) * 2.0;
	float blade_height = 0.55 + 0.45 * hash(id);
	float width = (1.0 - UV.y / blade_height) * 0.95;
	float blade = step(across, width) * step(UV.y, blade_height);
	ALPHA = blade;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	vec3 tip = mix(tip_color, tip_color * vec3(0.7, 0.9, 0.6), tint);
	ALBEDO = mix(root_color, tip, smoothstep(0.0, 0.8, UV.y)) * (0.85 + 0.3 * hash(id + 3.0));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	NORMAL = vec3(0.0, 0.0, 1.0);
}
