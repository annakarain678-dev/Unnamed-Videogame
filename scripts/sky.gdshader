// The sky: color gradient, sun, moon, and stars. Driven by atmosphere.gd.
shader_type sky;

uniform vec3 sky_top : source_color = vec3(0.22, 0.45, 0.80);
uniform vec3 sky_horizon : source_color = vec3(0.78, 0.80, 0.78);
uniform vec3 ground_bottom : source_color = vec3(0.25, 0.32, 0.38);

// Directions point from the viewer toward the sun / moon.
uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.85);
uniform float sun_amount = 1.0;
uniform vec3 moon_direction = vec3(0.0, -1.0, 0.0);
uniform float moon_amount = 0.0;
// 0 = no stars (daytime, or spirit view), 1 = a full starry night.
uniform float star_amount = 0.0;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// A field of small stars: a few random cells on a grid around the sky each hold one star.
float stars(vec3 dir) {
	vec3 p = dir * 140.0;
	vec3 cell = floor(p);
	float pick = hash(cell);
	if (pick < 0.985) {
		return 0.0;
	}
	vec3 center = cell + 0.5 + (vec3(hash(cell + 1.7), hash(cell + 3.1), hash(cell + 5.3)) - 0.5) * 0.6;
	float d = length(p - center);
	float size = 0.08 + hash(cell + 7.9) * 0.12;
	float twinkle = 0.75 + 0.25 * sin(TIME * (1.0 + hash(cell + 9.1) * 3.0) + pick * 40.0);
	return smoothstep(size, 0.0, d) * twinkle * (0.5 + hash(cell + 2.2));
}

void sky() {
	vec3 dir = EYEDIR;
	float up = dir.y;

	vec3 color;
	if (up >= 0.0) {
		color = mix(sky_horizon, sky_top, pow(up, 0.6));
	} else {
		color = mix(sky_horizon, ground_bottom, clamp(-up * 4.0, 0.0, 1.0));
	}

	// Stars, fading out toward the horizon.
	if (star_amount > 0.0 && up > 0.0) {
		color += vec3(0.9, 0.93, 1.0) * stars(dir) * star_amount * smoothstep(0.0, 0.2, up) * 1.5;
	}

	// Sun: a bright disc with a soft glow around it.
	float to_sun = dot(dir, normalize(sun_direction));
	float sun_disc = smoothstep(0.99985, 0.9999, to_sun);
	float sun_glow = pow(max(to_sun, 0.0), 300.0) * 0.4 + pow(max(to_sun, 0.0), 20.0) * 0.08;
	color += sun_color * (sun_disc * 12.0 + sun_glow) * sun_amount;

	// Moon: a pale disc with a few darker patches, and a faint halo.
	vec3 moon_dir = normalize(moon_direction);
	float to_moon = dot(dir, moon_dir);
	float moon_disc = smoothstep(0.99955, 0.9997, to_moon);
	if (moon_disc > 0.0) {
		// Flat coordinates across the moon's face, for its patches.
		vec3 side = normalize(cross(moon_dir, vec3(0.0, 1.0, 0.0)));
		vec3 top = cross(side, moon_dir);
		vec2 face = vec2(dot(dir, side), dot(dir, top)) * 40.0;
		float patches = smoothstep(0.35, 0.2, length(face - vec2(0.25, 0.3)))
			+ smoothstep(0.25, 0.1, length(face - vec2(-0.3, -0.1))) * 0.8
			+ smoothstep(0.2, 0.08, length(face - vec2(0.1, -0.45))) * 0.6;
		vec3 moon_surface = vec3(0.80, 0.82, 0.88) * (1.0 - clamp(patches, 0.0, 1.0) * 0.4);
		color = mix(color, moon_surface, moon_disc * moon_amount);
	}
	color += vec3(0.6, 0.7, 0.9) * pow(max(to_moon, 0.0), 400.0) * 0.25 * moon_amount;

	COLOR = color;
}
