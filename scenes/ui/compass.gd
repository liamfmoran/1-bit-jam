extends Control

var degree: float = 0.0

func _draw():
	var tex = preload("res://assets/ui/compass_test.png")
	var tex_size = tex.get_size()
	var visible_w = size.x
	var visible_h = size.y
	var ppd = tex_size.x / 360.0
	var offset = degree * ppd - visible_w * 0.5

	var start = wrapf(offset, 0.0, tex_size.x)
	var dst_x = 0.0

	var first_w = min(visible_w, tex_size.x - start)
	draw_texture_rect_region(tex, Rect2(dst_x, 0, first_w, visible_h), Rect2(start, 0, first_w, visible_h))
	dst_x += first_w

	if dst_x < visible_w:
		var second_w = visible_w - dst_x
		draw_texture_rect_region(tex, Rect2(dst_x, 0, second_w, visible_h), Rect2(0, 0, second_w, visible_h))
