shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/dithering.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	float threshold = dither_threshold(ivec2(FRAGCOORD.xy), DITHER_BAYER4);
	float c = lum > threshold ? 1.0 : 0.0;
	COLOR = vec4(c, c, c, 1.0);
}
