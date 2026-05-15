shader_type canvas_item;

uniform float speed : hint_range(0.5, 5.0) = 1.5;
uniform float turbulence : hint_range(0.0, 2.0) = 0.7;
uniform float flame_base : hint_range(-1.0, 3.0) = 0.0;
uniform float flame_tip  : hint_range(0.0,  3.0) = 1.0;
uniform float opacity    : hint_range(0.0,  1.0) = 1.0;
uniform float rect_scale : hint_range(1.0,  3.0) = 1.8;
uniform bool is_horizontal = false;
uniform bool is_flipped = false;

float _hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 74.27);
	return fract(p.x * p.y);
}

float _vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(_hash(i), _hash(i + vec2(1.0, 0.0)), f.x),
		mix(_hash(i + vec2(0.0, 1.0)), _hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float _fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * _vnoise(p);
		p = p * 2.1 + vec2(5.3, 9.1);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float t, s;
	if (is_horizontal) {
		t = (is_flipped ? (1.0 - UV.x) : UV.x) * rect_scale;
		s = UV.y - 0.5;
	} else {
		t = (is_flipped ? (1.0 - UV.y) : UV.y) * rect_scale;
		s = UV.x - 0.5;
	}

	// Active window with soft nozzle-end fade — eliminates the hard base edge.
	// The leading tip stays sharp; the trailing base feathers in over ~15% of length.
	float base_fade = smoothstep(flame_base - 0.15, flame_base + 0.05, t);
	float tip_fade  = 1.0 - smoothstep(flame_tip - 0.05, flame_tip + 0.02, t);
	float in_window = base_fade * tip_fade;
	float t_local   = clamp((t - flame_base) / max(flame_tip - flame_base, 0.001), 0.0, 1.0);

	// Irregular flicker from incommensurate sines — no repeating period
	float flicker = 0.76 + 0.13 * sin(TIME * 19.3) + 0.11 * sin(TIME * 37.7 + 2.1);

	// Slow base shape noise
	float n1 = _fbm(vec2(s * 4.0, t_local * 3.0 - TIME * speed));

	// Fast flutter layer for lively edge movement
	float n2 = _vnoise(vec2(s * 8.0 + 0.5, t_local * 5.0 - TIME * speed * 2.8));

	// Wisp layer: sparse blobs that drift toward the tip
	float n3 = _fbm(vec2(s * 3.0 + 1.3, t_local * 2.0 - TIME * speed * 1.8 + 5.0));
	float wisps = smoothstep(0.62, 0.82, n3) * max(0.0, 1.0 - t_local * 1.5) * 0.55;

	// Edge mask driven by combined noise so silhouette flutters rapidly
	float half_w = (1.0 - t_local) * 0.5;
	float edge_noise = n1 * 0.6 + n2 * 0.4;
	float edge_dist = abs(s) - edge_noise * turbulence * half_w;
	float edge_mask = 1.0 - smoothstep(0.0, half_w + 0.01, edge_dist);
	float envelope = pow(max(0.0, 1.0 - t_local), 1.2) * edge_mask;

	// Bright hot core along centerline
	float core = (1.0 - smoothstep(0.0, half_w * 0.6 + 0.01, abs(s))) * (1.0 - t_local * t_local) * 0.9;

	float final_intensity = clamp((max(envelope, core) + wisps) * flicker * in_window * opacity, 0.0, 1.0);

	COLOR = vec4(final_intensity, final_intensity, final_intensity, final_intensity);
}
