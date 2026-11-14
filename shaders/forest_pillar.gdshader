// The form pillar: a ruined, mossy obelisk of cool grey stone, grainy and cracked, with the form-change
// glyph worn into its front face. In spirit view the glyph glows faintly, so the wisp can find it.
shader_type spatial;

global uniform float spirit_view;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D glyph_tex : filter_linear_mipmap, repeat_disable;
uniform vec3 stone_light : source_color = vec3(0.47, 0.49, 0.47);
uniform vec3 stone_dark : source_color = vec3(0.30, 0.33, 0.33);
uniform vec3 moss : source_color = vec3(0.30, 0.42, 0.10);
uniform vec3 glow : source_color = vec3(1.0, 0.80, 0.38);

varying vec3 lpos;
varying vec3 lnormal;

void vertex() {
	lpos = VERTEX;
	lnormal = NORMAL;
}

// Noise projected from three sides, so it has no stretching on any face.
float tri(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	return texture(noise_tex, p.yz * scale).r * w.x
		+ texture(noise_tex, p.xz * scale).r * w.y
		+ texture(noise_tex, p.xy * scale).r * w.z;
}

void fragment() {
	vec3 n = normalize(lnormal);
	float big = tri(lpos, n, 0.9);
	float mid = tri(lpos, n, 3.5);
	float grain = tri(lpos, n, 24.0);

	vec3 stone = mix(stone_dark, stone_light, smoothstep(0.3, 0.7, big * 0.6 + mid * 0.4));
	stone *= 0.9 + 0.2 * grain;

	// Cracks: thin dark lines where two noise fields cross the same value.
	float c1 = abs(tri(lpos, n, 1.6) - 0.5);
	float c2 = abs(tri(lpos + 3.7, n, 3.1) - 0.5);
	float crack = 1.0 - smoothstep(0.0, 0.02, min(c1, c2 * 1.3));
	stone = mix(stone, vec3(0.07, 0.08, 0.09), crack * 0.9);

	// Moss: on top surfaces, up the damp foot, and in patches.
	float damp = 1.0 - smoothstep(0.0, 0.95, lpos.y);
	float patches = tri(lpos + 9.1, n, 2.2);
	float moss_amount = smoothstep(0.5, 0.85, n.y) * 1.1 + damp * 0.9 + (patches - 0.5) * 1.2 - 0.1;
	moss_amount = clamp(moss_amount, 0.0, 1.0) * smoothstep(0.3, 0.55, patches + damp * 0.35 + n.y * 0.3);
	stone = mix(stone, moss * (0.7 + 0.6 * mid), moss_amount * 0.9);

	// The glyph, worn away in places, on the front (+Z) face.
	float carved = 0.0;
	if (n.z > 0.55) {
		vec2 uv = (lpos.xy - vec2(0.0, 1.2)) / 0.46 + 0.5;
		uv.y = 1.0 - uv.y;
		if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
			float worn = smoothstep(0.15, 0.4, tri(lpos + 1.3, n, 5.0) + 0.25);
			carved = texture(glyph_tex, uv).a * worn;
		}
	}
	stone = mix(stone, stone * 0.22, carved);

	ALBEDO = stone;
	ROUGHNESS = 0.96;
	SPECULAR = 0.2;
	EMISSION = glow * carved * (0.06 + 1.4 * spirit_view);
}
