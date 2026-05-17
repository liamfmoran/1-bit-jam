shader_type canvas_item;

uniform vec2 ship_position = vec2(0.0);
uniform vec2 ship_velocity = vec2(0.0);
uniform float camera_rotation = 0.0;
uniform vec2 player_screen_uv = vec2(0.5, 0.5);

const float TRAIL_FACTOR = 0.08;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 74.27);
	return fract(p.x * p.y);
}

vec2 rotate_vec(vec2 v, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

// Returns star brightness at frag_pos for one parallax layer.
// cell_size: pixel grid size (controls density spacing)
// star_radius: star dot radius in pixels
// density: fraction of cells that contain a star (0..1)
// parallax: how much this layer shifts with ship position
// seed: unique per-layer hash seed
float star_layer(vec2 frag_pos, vec2 viewport_center, float cell_size, float star_radius, float density, float parallax, float seed) {
	// Rotate the screen offset so the star field turns with the camera,
	// then translate by ship_position for parallax scrolling.
	// Rotating frag_pos - center (bounded by ~640px) avoids the artifact where
	// rotating ship_position (which grows with distance) made rotation more
	// intense the further from the world origin.
	vec2 screen_offset = rotate_vec(frag_pos - viewport_center, camera_rotation);
	vec2 shifted = ship_position * parallax + screen_offset;

	vec2 cell = floor(shifted / cell_size);
	vec2 cell_uv = fract(shifted / cell_size);

	if (hash21(cell + vec2(seed * 11.3, seed * 7.9)) > density) {
		return 0.0;
	}

	vec2 star_pos = vec2(
		hash21(cell + vec2(seed, 0.0)),
		hash21(cell + vec2(0.0, seed))
	);

	float radius = star_radius / cell_size;
	vec2 to_frag = cell_uv - star_pos;

	float twinkle_phase = hash21(cell + vec2(seed * 3.7, seed * 5.1)) * 6.28318;
	float twinkle_speed = 0.4 + hash21(cell + vec2(seed * 1.3, seed * 2.9)) * 1.2;
	float twinkle = sin(TIME * twinkle_speed + twinkle_phase) * 0.25 + 0.75;
	float star_brightness = 0.25 + hash21(cell + vec2(seed * 5.3, seed * 9.7)) * 0.75;

	// Star head
	if (length(to_frag) < radius) {
		return twinkle * star_brightness;
	}

	// Comet tail: world-space velocity, no extra rotation needed since
	// shifted is already in world-space-aligned coordinates
	vec2 trail = -ship_velocity * parallax * TRAIL_FACTOR / cell_size;
	float trail_len = length(trail);
	if (trail_len > 0.0001) {
		vec2 trail_dir = trail / trail_len;
		float along = dot(to_frag, trail_dir);
		if (along > 0.0 && along < trail_len) {
			float taper = (1.0 - along / trail_len) * 0.4;
			float perp = length(to_frag - along * trail_dir);
			if (perp < radius * taper) {
				return twinkle * star_brightness * (1.0 - along / trail_len);
			}
		}
	}

	return 0.0;
}

void fragment() {
	vec2 player_screen_pos = player_screen_uv / SCREEN_PIXEL_SIZE;
	float brightness = 0.0;
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 80.0, 0.70, 0.06, 0.020,  1.7));
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 77.0, 0.82, 0.06, 0.027,  2.3));
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 73.0, 0.94, 0.06, 0.037,  4.1));
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 70.0, 1.07, 0.06, 0.050,  5.8));
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 67.0, 1.19, 0.06, 0.068,  6.5));
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 63.0, 1.32, 0.06, 0.092,  7.2));
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 60.0, 1.44, 0.06, 0.125,  8.6));
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 57.0, 1.56, 0.06, 0.170,  9.3));
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 53.0, 1.69, 0.06, 0.230, 11.1));
	brightness = max(brightness, star_layer(FRAGCOORD.xy, player_screen_pos, 50.0, 1.30, 0.06, 0.300, 12.4));
	COLOR = vec4(1.0, 1.0, 1.0, brightness);
}
