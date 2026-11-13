// The floor inside a possessed heart: rough black stone with a few gold grooves and gashes
// running through it, and scattered gold flecks (like gilded blackstone).
// While corrupted, the grooves pulse red outward from the heart; once cleansed, soft bluish-white.
shader_type spatial;

uniform vec3 stone_color : source_color = vec3(0.075, 0.07, 0.08);
uniform vec3 gilding_color : source_color = vec3(0.70, 0.55, 0.25);
uniform vec3 corrupt_glow : source_color = vec3(0.95, 0.12, 0.08);
uniform vec3 clean_glow : source_color = vec3(0.70, 0.85, 1.0);
// 0 = corrupted (red), 1 = cleansed (bluish-white).
uniform float cleansed = 0.0;
// Where the heart is, so the pulses ripple outward from it.
uniform vec3 heart_position = vec3(0.0);

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Smooth random hills and valleys.
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float layered_noise(vec2 p) {
	return (noise(p) * 0.55 + noise(p * 2.1 + 3.7) * 0.3 + noise(p * 4.3 + 9.1) * 0.15);
}

// A thin, wandering line (where the noise crosses its middle value), broken into gashes.
float groove(vec2 p, float scale, float width, float seed) {
	float n = layered_noise(p * scale + seed);
	float line = 1.0 - smoothstep(0.0, width, abs(n - 0.5));
	float pieces = smoothstep(0.42, 0.58, noise(p * scale * 0.6 + seed * 2.3));
	return line * pieces;
}

void fragment() {
	vec2 p = world_position.xz;

	// Rough black stone: blotchy shading plus fine grit.
	float blotch = noise(p * 1.3) * 0.5 + noise(p * 3.7) * 0.3;
	float grit = hash(floor(p * 18.0));
	vec3 stone = stone_color * (0.65 + blotch * 0.6 + grit * 0.15);

	// A few long grooves, and some shorter, finer gashes.
	float vein = clamp(groove(p, 0.09, 0.018, 0.0) + groove(p, 0.22, 0.012, 17.0) * 0.8, 0.0, 1.0);
	// Scattered gold flecks.
	float fleck = step(0.992, hash(floor(p * 5.0))) * step(0.4, hash(floor(p * 5.0) + 3.1));

	float gold = max(vein, fleck);
	ALBEDO = mix(stone, gilding_color, gold);
	METALLIC = gold * 0.8;
	ROUGHNESS = mix(0.95, 0.35, gold);

	// Pulses ripple outward from the heart through the grooves, like a heartbeat.
	float distance_from_heart = length(p - heart_position.xz);
	float pulse = pow(0.5 + 0.5 * sin(TIME * 2.6 - distance_from_heart * 0.55), 3.0);
	vec3 glow = mix(corrupt_glow, clean_glow, cleansed);
	EMISSION = glow * vein * (0.3 + 2.4 * pulse) + gilding_color * fleck * 0.15;
}
