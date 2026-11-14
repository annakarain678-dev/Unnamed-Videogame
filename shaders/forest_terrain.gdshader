// The ground of the giant forest: meadow, needle duff, moss and layered rock, plus a dark canopy
// tone far away (where individual trees are too small to draw).
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 meadow : source_color = vec3(0.34, 0.42, 0.15);
uniform vec3 meadow_dry : source_color = vec3(0.52, 0.48, 0.22);
uniform vec3 duff : source_color = vec3(0.34, 0.20, 0.11);
uniform vec3 moss : source_color = vec3(0.20, 0.30, 0.11);
uniform vec3 rock_light : source_color = vec3(0.56, 0.47, 0.38);
uniform vec3 rock_dark : source_color = vec3(0.32, 0.27, 0.23);
uniform vec3 canopy : source_color = vec3(0.07, 0.16, 0.07);

varying vec3 wpos;
varying vec3 wnormal;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = wpos.xz;
	float n1 = texture(noise_tex, p * 0.0031).r;
	float n2 = texture(noise_tex, p * 0.021).r;
	float n3 = texture(noise_tex, p * 0.19).r;
	float far_n = texture(noise_tex, p * 0.00011).r;
	float forest = COLOR.r;
	float dist = length(VERTEX);

	float slope = 1.0 - normalize(wnormal).y;

	// Open ground: golden grass that dries out in patches.
	vec3 open_ground = mix(meadow, meadow_dry, smoothstep(0.52, 0.8, n1));
	open_ground *= 0.82 + 0.36 * n2;
	// Forest floor: red-brown needle duff with mossy patches.
	vec3 floor_ground = duff * (0.72 + 0.55 * n3);
	floor_ground = mix(floor_ground, moss, smoothstep(0.58, 0.82, n1) * 0.6);
	vec3 ground = mix(open_ground, floor_ground, smoothstep(0.1, 0.8, forest));

	// Rock, in warm layers (strata), on steeper ground.
	float strata = sin(wpos.y * 0.5 + n1 * 7.0) * 0.5 + 0.5;
	vec3 rock = mix(rock_dark, rock_light, strata * 0.6 + n3 * 0.4);
	float rock_amount = smoothstep(0.2, 0.38, slope + (n2 - 0.5) * 0.12);
	vec3 albedo = mix(ground, rock, rock_amount);

	// Far away, a forest reads as a dark, lumpy green mass.
	float canopy_amount = forest * (1.0 - rock_amount) * smoothstep(300.0, 2600.0, dist);
	vec3 canopy_color = canopy * (0.65 + 0.9 * far_n) * (0.8 + 0.4 * n2);
	albedo = mix(albedo, canopy_color, canopy_amount);

	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	SPECULAR = 0.12;
}
