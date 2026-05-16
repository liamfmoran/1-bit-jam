shader_type canvas_item;

uniform float spin_offset : hint_range(0.0, 6.283) = 0.0;
uniform float rotation_speed : hint_range(0.0, 2.0) = 0.4;
uniform float roughness : hint_range(0.0, 1.0) = 0.35;
uniform float edge_roughness : hint_range(0.0, 0.3) = 0.12;
uniform float asteroid_rotation = 0.0;
global uniform vec3 sun_direction;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float v = 0.0, amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += noise(p) * amp;
		p = p * 2.1 + vec2(1.7, 9.2);
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float dist = length(p);
	float t = TIME * rotation_speed + spin_offset;

	// Jagged silhouette: noise along the boundary direction
	vec2 dir = p / max(dist, 0.001);
	float edge_n = fbm(dir * 3.5 + t * 0.05);
	if (dist > 0.88 + edge_n * edge_roughness) {
		discard;
	}

	// Sphere normal from UV
	float z = sqrt(max(0.0, 1.0 - dot(p, p)));
	vec3 normal = normalize(vec3(p, z));

	// Tumble: rotate normal around Y axis over time
	float ca = cos(t * 0.7), sa = sin(t * 0.7);
	vec3 rot_n = vec3(
		normal.x * ca + normal.z * sa,
		normal.y,
		-normal.x * sa + normal.z * ca
	);

	// Perturb normal with FBM for rocky surface
	float nx = fbm(rot_n.xy * 3.0) * 2.0 - 1.0;
	float ny = fbm(rot_n.xy * 3.0 + vec2(5.2, 1.3)) * 2.0 - 1.0;
	vec3 perturbed = normalize(normal + vec3(nx, ny, 0.0) * roughness);

	// Rotate world-space light direction into local sprite space so lighting
	// stays fixed in the world as the asteroid physically spins.
	float cr = cos(-asteroid_rotation), sr = sin(-asteroid_rotation);
	vec2 ld_local = vec2(sun_direction.x * cr - sun_direction.y * sr, sun_direction.x * sr + sun_direction.y * cr);
	vec3 ld = normalize(vec3(ld_local, sun_direction.z));

	float diffuse = max(0.0, dot(perturbed, ld));
	float brightness = diffuse;

	COLOR = vec4(brightness, brightness, brightness, 1.0);
}
