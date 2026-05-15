extends Control

const MAP_SIZE := Vector2(150, 150)
const WORLD_RANGE := 4000.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color.WHITE, false, 2.0)

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var center: Vector2 = player.global_position

	for dock in get_tree().get_nodes_in_group("dock"):
		var pos := _world_to_map(dock.global_position, center)
		if _in_bounds(pos):
			draw_rect(Rect2(pos - Vector2(4, 4), Vector2(8, 8)), Color.WHITE)

	var player_pos := MAP_SIZE / 2.0
	var rot: float = player.global_rotation
	var tri_size := 6.0
	var points := PackedVector2Array([
		player_pos + Vector2(0, -tri_size).rotated(rot),
		player_pos + Vector2(-tri_size * 0.6, tri_size * 0.5).rotated(rot),
		player_pos + Vector2(tri_size * 0.6, tri_size * 0.5).rotated(rot),
	])
	draw_colored_polygon(points, Color.WHITE)


func _world_to_map(world_pos: Vector2, center: Vector2) -> Vector2:
	var offset := world_pos - center
	var normalized := offset / WORLD_RANGE
	return MAP_SIZE / 2.0 + normalized * MAP_SIZE


func _in_bounds(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= MAP_SIZE.x and pos.y >= 0 and pos.y <= MAP_SIZE.y
