shader_type canvas_item;

uniform float ship_rotation = 0.0;
global uniform vec3 sun_direction;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;

	// Fake convex normals: pixels near the edges tilt outward.
	vec3 local_normal = normalize(vec3(p.x * 0.4, p.y * 0.4, 1.0));

	// Rotate world-space sun into local sprite space (same approach as asteroid).
	float cr = cos(-ship_rotation), sr = sin(-ship_rotation);
	vec2 sd_local = vec2(sun_direction.x * cr - sun_direction.y * sr, sun_direction.x * sr + sun_direction.y * cr);
	vec3 ld = normalize(vec3(sd_local, sun_direction.z));

	float diffuse = max(0.0, dot(local_normal, ld));
	float lum = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	float brightness = lum * (0.1 + 0.9 * diffuse);

	COLOR = vec4(brightness, brightness, brightness, COLOR.a);
}
