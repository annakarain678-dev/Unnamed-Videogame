// Grey-box ground: plain grey that gets paler with height, darker on steep slopes, with a contour line
// every 10 m (a heavier one every 50 m), a faint 100 m grid, and pale roads. In caves: plain grey rock.
shader_type spatial;

uniform float map_lines : hint_range(0.0, 1.0) = 1.0;

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
	// COLOR.r = road, COLOR.g = rock wall (cave) rather than open ground.
	float steep = clamp(1.0 - wnormal.y, 0.0, 1.0);
	float tone = mix(0.07, 0.30, clamp((wpos.y - 25.0) / 170.0, 0.0, 1.0));
	tone *= 1.0 - 0.55 * smoothstep(0.1, 0.5, steep);
	// Roads are paler.
	tone = mix(tone, 0.38, COLOR.r * 0.8);
	float contour = max(line(wpos.y, 10.0, 0.8) * 0.35, line(wpos.y, 50.0, 1.3) * 0.55);
	float grid = max(line(wpos.x, 100.0, 0.6), line(wpos.z, 100.0, 0.6)) * 0.12;
	tone *= 1.0 - map_lines * (contour + grid) * (1.0 - COLOR.g);
	float lump = sin(wpos.x * 0.21) * sin(wpos.z * 0.17) * sin(wpos.y * 0.23);
	tone = mix(tone, 0.22 + 0.04 * lump, COLOR.g);
	ALBEDO = vec3(tone);
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
