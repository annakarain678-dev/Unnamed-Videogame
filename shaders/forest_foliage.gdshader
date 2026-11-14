// Fronds, branches, ferns and bushes. Each card is cut into a leafy shape by the shader (so there are
// no textures to draw), is lit softly from both sides, and sways gently in the wind.
// For solid crown shapes the mesh sets UV to (0, 0), which keeps every pixel.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float wind = 1.0;

varying vec3 n_world;
varying float tint;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * 0.7;
	float gust = sin(t + origin.x * 0.013 + origin.z * 0.011) + 0.5 * sin(t * 2.3 + wp.x * 0.08);
	// COLOR.a is how free this vertex is to move (tips more than bases).
	float sway = wind * COLOR.a * gust * 0.12;
	VERTEX.x += sway * (1.0 + VERTEX.y * 0.012);
	VERTEX.z += sway * 0.6 * (1.0 + VERTEX.y * 0.012);
	n_world = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	tint = texture(noise_tex, origin.xz * 0.0071).r;
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	// A feathery frond: leaflets along a central rib, shorter toward the tip.
	float taper = 1.0 - u * 0.8;
	float leaflets = abs(fract(u * 10.0 + step(0.0, v) * 0.5) - 0.5) * 2.0;
	float reach = taper * (0.46 + 0.54 * leaflets);
	float rib = 1.0 - smoothstep(0.0, 0.09, abs(v));
	float shape = max(1.0 - smoothstep(reach - 0.02, reach, abs(v)), rib);
	ALPHA = shape;
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	vec3 base = COLOR.rgb;
	// Slightly warmer or cooler from tree to tree.
	base *= vec3(0.9 + 0.2 * tint, 0.95 + 0.1 * tint, 0.85 + 0.2 * (1.0 - tint));
	ALBEDO = base * mix(0.7, 1.12, u);
	// Soft, round lighting instead of flat cards: ignore which side of the card we see.
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	BACKLIGHT = base * 0.35;
}
