shader_type canvas_item;

uniform vec4 color_primary : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_secondary : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	// TODO: sample screen_texture, compute luminance, apply Bayer 4x4 dither,
	// output color_primary or color_secondary
	COLOR = texture(screen_texture, SCREEN_UV);
}
