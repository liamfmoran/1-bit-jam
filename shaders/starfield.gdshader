shader_type canvas_item;

uniform vec2 truck_position;
uniform float cam_rotation;
uniform float cam_zoom;
uniform vec2 screen_target;
uniform vec2 truck_velocity;
uniform float cam_angular_velocity;
uniform float trail_scale : hint_range(0.0, 0.5) = 0.15;
uniform float rotation_trail_scale : hint_range(0.0, 0.01) = 0.007;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 1.5;
uniform float twinkle_amount : hint_range(0.0, 1.0) = 0.4;

float hash21(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 screen_px = UV * vec2(1920.0, 1080.0);
	vec2 offset = (screen_px - screen_target) / cam_zoom;

	float c = cos(cam_rotation);
	float s = sin(cam_rotation);
	vec2 rotated = vec2(c * offset.x - s * offset.y,
	                    s * offset.x + c * offset.y);

	float total_b = 0.0;

	for (int layer = 0; layer < 3; layer++) {
		float parallax;
		float cell_size;
		float star_radius;
		float density;

		if (layer == 0) {
			parallax = 0.02;
			cell_size = 100.0;
			star_radius = 0.6;
			density = 0.35;
		} else if (layer == 1) {
			parallax = 0.06;
			cell_size = 70.0;
			star_radius = 0.9;
			density = 0.30;
		} else {
			parallax = 0.12;
			cell_size = 50.0;
			star_radius = 1.2;
			density = 0.25;
		}

		vec2 lookup = rotated + truck_position * parallax;
		vec2 translational = truck_velocity * parallax * trail_scale;
		vec2 rotational = cam_angular_velocity * vec2(-rotated.y, rotated.x) * rotation_trail_scale;
		vec2 trail_vec = translational + rotational;
		float trail_len = length(trail_vec);

		for (int dy = -1; dy <= 1; dy++) {
			for (int dx = -1; dx <= 1; dx++) {
				vec2 cell = floor(lookup / cell_size) + vec2(float(dx), float(dy));
				vec2 cell_hash_input = cell + float(layer) * 100.0;

				float existence = hash21(cell_hash_input);
				if (existence > density) {
					continue;
				}

				float sx = 0.2 + 0.6 * hash21(cell_hash_input + vec2(31.7, 47.3));
				float sy = 0.2 + 0.6 * hash21(cell_hash_input + vec2(73.1, 11.9));
				vec2 star_pos = (cell + vec2(sx, sy)) * cell_size;

				vec2 diff = lookup - star_pos;
				float dist = length(diff);
				float twinkle_phase = hash21(cell_hash_input + vec2(91.3, 57.7));
				float twinkle = 1.0 - twinkle_amount * (0.5 + 0.5 * sin(TIME * twinkle_speed + twinkle_phase * 6.2831));
				float b = smoothstep(star_radius, star_radius * 0.3, dist) * twinkle;

				if (trail_len > 1.5) {
					vec2 td = trail_vec / trail_len;
					float along = dot(diff, td);
					float perp = abs(dot(diff, vec2(-td.y, td.x)));

					if (along > 0.0 && along < trail_len && perp < star_radius * 0.5) {
						float trail_b = 1.0 - along / trail_len;
						b = max(b, trail_b);
					}
				}

				total_b = max(total_b, b);
			}
		}
	}

	COLOR = vec4(1.0, 1.0, 1.0, total_b);
}
