shader_type sky;

// Céu mais quente e levemente desaturado (azul do fim de tarde)
uniform vec3 sky_color : source_color = vec3(0.35, 0.52, 0.82);

// Horizonte com tom alaranjado/dourado típico do fim de tarde
uniform vec3 horizon_color : source_color = vec3(1.0, 0.65, 0.35);
uniform float horizon_blur : hint_range(0.0, 1.0) = 0.25;

// Sol mais alaranjado, maior e mais difuso (golden hour)
uniform vec3 sun_color : source_color = vec3(1.0, 0.7, 0.35);
uniform float sun_size : hint_range(0.01, 1.0) = 0.12;
uniform float sun_blur : hint_range(0.0, 0.5) = 0.04;

// Nuvens com tom quente/pêssego (luz do sol batendo por baixo)
uniform vec3 cloud_color : source_color = vec3(1.0, 0.85, 0.72);
uniform float cloud_edge_sharpness : hint_range(0.0, 1.0) = 0.15;
uniform float cloud_scale : hint_range(0.1, 10.0) = 2.5;
uniform float cloud_speed : hint_range(0.0, 0.5) = 0.015;

// Direção do sol (mais baixa no horizonte = fim de tarde)
uniform vec3 sun_direction = vec3(0.3, 0.25, 0.92);

// Hash inteiro por permutação de bits (resistente a perda de precisão)
float hash(vec2 p) {
	uvec2 q = uvec2(ivec2(p));
	q = q * 1664525u + 1013904223u;
	q.x += q.y * 1664525u;
	q.y += q.x * 1664525u;
	q.x ^= q.x >> 16u;
	q.y ^= q.y >> 16u;
	return float(q.x) / float(0xFFFFFFFFu);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = EYEDIR;
	float y = clamp(dir.y, 0.0, 1.0);

	// Gradiente base do céu
	vec3 base = mix(horizon_color, sky_color, pow(y, 1.0 - horizon_blur));

	// Sol
	float sun_dot = max(dot(dir, normalize(sun_direction)), 0.0);
	float sun_disk = smoothstep(1.0 - sun_size, 1.0 - sun_size + sun_blur, sun_dot);
	float sun_glow = pow(sun_dot, 32.0) * 0.5;
	vec3 col = base + sun_color * (sun_disk + sun_glow);

	// Nuvens projetadas no plano do céu
	vec2 uv = dir.xz / max(dir.y, 0.1);
	uv *= cloud_scale;
	uv += TIME * cloud_speed;

	float n = fbm(uv);
	float cloud_mask = smoothstep(0.5, 0.5 + cloud_edge_sharpness, n);
	cloud_mask *= smoothstep(0.0, 0.15, dir.y); // não desenha abaixo do horizonte

	// Nuvens ficam mais quentes perto do sol
	float sun_influence = pow(sun_dot, 4.0);
	vec3 lit_cloud = mix(cloud_color, sun_color * 1.2, sun_influence * 0.6);

	col = mix(col, lit_cloud, cloud_mask * 0.85);

	COLOR = col;
}