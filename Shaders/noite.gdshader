shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.02, 0.02, 0.08);
uniform vec3 horizon_color : source_color = vec3(0.05, 0.05, 0.15);
uniform float horizon_blur : hint_range(0.0, 1.0) = 0.15;

uniform vec3 moon_color : source_color = vec3(0.9, 0.95, 1.0);
uniform float moon_size : hint_range(0.01, 1.0) = 0.04;
uniform float moon_glow : hint_range(0.0, 0.5) = 0.08;

uniform vec3 star_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float star_density : hint_range(10.0, 100.0) = 50.0;
uniform float star_twinkle_speed : hint_range(0.0, 5.0) = 1.5;

uniform vec3 cloud_color : source_color = vec3(0.3, 0.3, 0.4);
uniform float cloud_edge_sharpness : hint_range(0.0, 1.0) = 0.15;
uniform float cloud_scale : hint_range(0.1, 10.0) = 3.0;
uniform float cloud_speed : hint_range(0.0, 0.5) = 0.01;

float hash(vec2 p) {
	uvec2 q = uvec2(ivec2(p));
	q = q * uvec2(1597334677u, 3812015801u);
	uint n = (q.x ^ q.y) * 1597334677u;
	return float(n) * (1.0 / 4294967295.0);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 3; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void sky() {
	// 1. Base Sky Gradient (Noite profunda)
	float sky_gradient = EYEDIR.y;
	float horizon_mask = smoothstep(-horizon_blur, horizon_blur, sky_gradient);
	vec3 final_sky = mix(horizon_color, sky_color, horizon_mask);

	// 2. Estrelas Procedurais
	if (EYEDIR.y > 0.0) {
		// UV esférico para estrelas
		vec2 star_uv = EYEDIR.xz / (EYEDIR.y + 0.1);
		vec2 star_id = floor(star_uv * star_density);

		// Hash por célula = posição fixa da estrela
		float star_rand = hash(star_id);

		// Só nasce estrela se o hash for alto (controle de densidade)
		if (star_rand > 0.92) {
			// Cintilação baseada no tempo
			float twinkle = sin(TIME * star_twinkle_speed + star_rand * 10.0) * 0.5 + 0.5;
			// Brilho concentrado no centro da célula
			vec2 star_center = fract(star_uv * star_density) - 0.5;
			float star_dist = length(star_center);
			float star_brightness = smoothstep(0.15, 0.0, star_dist) * twinkle;

			final_sky = mix(final_sky, star_color, star_brightness);
		}
	}

	// 3. Lua com Halo/Glow
	float moon_distance = distance(EYEDIR, LIGHT0_DIRECTION);
	// Disco da lua
	float moon_disc = smoothstep(moon_size, moon_size - 0.005, moon_distance);
	// Halo ao redor
	float moon_halo = smoothstep(moon_size + moon_glow, moon_size, moon_distance) * 0.3;
	float moon_total = max(moon_disc, moon_halo);
	final_sky = mix(final_sky, moon_color, moon_total);

	// 4. Nuvens Noturnas (mais escuras e misteriosas)
	if (EYEDIR.y > 0.0) {
		vec2 cloud_uv = EYEDIR.xz / (EYEDIR.y + 0.3);
		cloud_uv += TIME * cloud_speed;
		cloud_uv *= cloud_scale;

		float cloud_noise = fbm(cloud_uv);
		float cloud_mask = smoothstep(0.4, 0.4 + cloud_edge_sharpness, cloud_noise);
		cloud_mask *= smoothstep(0.0, 0.3, EYEDIR.y);

		// Nuvens noturnas com leve iluminação por baixo
		vec3 lit_cloud = mix(cloud_color, vec3(0.1, 0.1, 0.15), 0.5);
		final_sky = mix(final_sky, lit_cloud, cloud_mask * 0.7);
	}

	COLOR = final_sky;
}
