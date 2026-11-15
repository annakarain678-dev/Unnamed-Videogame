// The ground of the first region, in colour: meadow, forest floor, dead wood round the darklings, bare earth
// in the town and the quarry, dirt roads, sand round the lake, layered rock on steep ground, snow on the high
// rim, and plain stone for cave walls. G in the game turns on the grey-box contour lines and 100 m grid.
shader_type spatial;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float map_lines : hint_range(0.0, 1.0) = 0.0;
uniform float lake_level = 49.3;
uniform vec2 lake_center = vec2(-150.0, 560.0);
uniform float lake_radius = 62.0;
uniform vec2 town_center = vec2(0.0, 0.0);
uniform vec2 quarry_center = vec2(620.0, 40.0);

uniform vec3 meadow : source_color = vec3(0.33, 0.45, 0.16);
uniform vec3 meadow_dry : source_color = vec3(0.55, 0.50, 0.24);
uniform vec3 duff : source_color = vec3(0.30, 0.20, 0.11);
uniform vec3 moss : source_color = vec3(0.18, 0.30, 0.11);
uniform vec3 dead_color : source_color = vec3(0.30, 0.26, 0.22);
uniform vec3 earth : source_color = vec3(0.50, 0.40, 0.27);
uniform vec3 road_color : source_color = vec3(0.60, 0.50, 0.34);
uniform vec3 sand : source_color = vec3(0.68, 0.60, 0.42);
uniform vec3 lake_bed : source_color = vec3(0.22, 0.30, 0.28);
uniform vec3 rock_light : source_color = vec3(0.56, 0.50, 0.42);
uniform vec3 rock_dark : source_color = vec3(0.30, 0.27, 0.24);
uniform vec3 snow_color : source_color = vec3(0.92, 0.94, 0.96);
uniform vec3 stone_light : source_color = vec3(0.40, 0.38, 0.35);
uniform vec3 stone_dark : source_color = vec3(0.22, 0.21, 0.20);

varying vec3 wpos;
varying vec3 wnormal;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float line(float v, float period, float width) {
	float x = v / period;
	float d = abs(fract(x + 0.5) - 0.5) / max(fwidth(x), 0.0001);
	return 1.0 - clamp(d / width, 0.0, 1.0);
}

void fragment() {
	// COLOR: r = road, g = cave wall, b = forest, a = dead wood.
	vec2 p = wpos.xz;
	float n1 = texture(noise_tex, p * 0.004).r;
	float n2 = texture(noise_tex, p * 0.03).r;
	float n3 = texture(noise_tex, p * 0.21).r;
	float steep = clamp(1.0 - wnormal.y, 0.0, 1.0);

	vec3 open_ground = mix(meadow, meadow_dry, smoothstep(0.45, 0.78, n1)) * (0.82 + 0.36 * n2);
	vec3 floor_ground = mix(duff * (0.7 + 0.6 * n3), moss, smoothstep(0.55, 0.8, n1) * 0.6);
	vec3 ground = mix(open_ground, floor_ground, smoothstep(0.15, 0.8, COLOR.b));
	ground = mix(ground, dead_color * (0.8 + 0.4 * n2), COLOR.a);

	// Bare earth in the town and the quarry.
	float town = 1.0 - smoothstep(70.0, 125.0, length(p - town_center));
	float quarry = 1.0 - smoothstep(48.0, 90.0, length(p - quarry_center));
	ground = mix(ground, earth * (0.85 + 0.3 * n3), max(town * 0.85, quarry * 0.95));
	ground = mix(ground, road_color * (0.9 + 0.2 * n3), COLOR.r * 0.9);

	// Sand round the lake, and dark mud under it.
	float lake_d = length(p - lake_center);
	float near_lake = 1.0 - smoothstep(lake_radius * 1.0, lake_radius * 1.45, lake_d);
	ground = mix(ground, sand, near_lake * (1.0 - smoothstep(lake_level + 0.6, lake_level + 2.5, wpos.y)));
	ground = mix(ground, lake_bed, near_lake * (1.0 - smoothstep(lake_level - 3.0, lake_level - 0.2, wpos.y)) * 0.8);

	// Layered rock on steep ground.
	float strata = sin(wpos.y * 0.6 + n1 * 6.0) * 0.5 + 0.5;
	vec3 rock = mix(rock_dark, rock_light, strata * 0.6 + n3 * 0.4);
	float rock_amount = smoothstep(0.2, 0.36, steep + (n2 - 0.5) * 0.12);
	vec3 albedo = mix(ground, rock, rock_amount);

	// Snow on the high rim.
	float snow = smoothstep(150.0, 200.0, wpos.y + (n2 - 0.5) * 30.0) * (1.0 - rock_amount * 0.5);
	albedo = mix(albedo, snow_color, snow);

	// Grey-box contour lines and grid.
	float contour = max(line(wpos.y, 10.0, 0.8) * 0.35, line(wpos.y, 50.0, 1.3) * 0.55);
	float grid = max(line(wpos.x, 100.0, 0.6), line(wpos.z, 100.0, 0.6)) * 0.12;
	albedo *= 1.0 - map_lines * (contour + grid) * (1.0 - COLOR.g);

	// Cave walls: plain stone.
	vec3 stone = mix(stone_dark, stone_light, n3 * 0.6 + n2 * 0.4);
	albedo = mix(albedo, stone, COLOR.g);

	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
