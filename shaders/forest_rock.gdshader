// Boulders: warm grey stone with moss on the tops and a little layering.
shader_type spatial;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 stone_light : source_color = vec3(0.55, 0.49, 0.42);
uniform vec3 stone_dark : source_color = vec3(0.30, 0.26, 0.23);
uniform vec3 moss : source_color = vec3(0.21, 0.31, 0.12);

varying vec3 wpos;
varying vec3 wnormal;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float n = texture(noise_tex, wpos.xz * 0.35 + wpos.y * 0.2).r;
	float layers = sin(wpos.y * 3.0 + n * 5.0) * 0.5 + 0.5;
	vec3 stone = mix(stone_dark, stone_light, layers * 0.5 + n * 0.5) * COLOR.rgb;
	float top = smoothstep(0.55, 0.9, wnormal.y + (n - 0.5) * 0.5);
	ALBEDO = mix(stone, moss * (0.8 + 0.4 * n), top);
	ROUGHNESS = 0.95;
}
