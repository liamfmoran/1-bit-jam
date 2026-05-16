shader_type canvas_item;

#include "res://shaders/dithering.gdshaderinc"

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	float threshold = dither_threshold(ivec2(FRAGCOORD.xy), DITHER_BAYER4);
	float c = lum > threshold ? 1.0 : 0.0;
	COLOR = col.a > 0.01 ? vec4(c, c, c, 1.0) : vec4(0.0);
}
