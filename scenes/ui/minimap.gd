extends Control

const MAP_SIZE := Vector2(150, 150)
const WORLD_RANGE := 4000.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color.WHITE, false, 2.0)

	var player_world_pos: Variant = _find_player_pos()
	if player_world_pos == null:
		return
	var center: Vector2 = player_world_pos

	_draw_docks(center)
	_draw_ships(center)


func _find_player_pos() -> Variant:
	for entry: WorldData.ShipEntry in WorldData.get_ships():
		if is_instance_valid(entry.node) and entry.kind == &"player":
			return entry.node.global_position
	return null


func _draw_docks(center: Vector2) -> void:
	for station: StationData in WorldData.stations.values():
		var pos := _world_to_map(station.position, center)
		if _in_bounds(pos):
			draw_rect(Rect2(pos - Vector2(4, 4), Vector2(8, 8)), Color.WHITE)


func _draw_ships(center: Vector2) -> void:
	for entry: WorldData.ShipEntry in WorldData.get_ships():
		if not is_instance_valid(entry.node):
			continue
		var map_pos := _world_to_map(entry.node.global_position, center)
		if not _in_bounds(map_pos):
			continue
		match entry.kind:
			&"player":
				var tri := 6.0
				var rot := entry.node.global_rotation
				draw_colored_polygon(PackedVector2Array([
					map_pos + Vector2(0, -tri).rotated(rot),
					map_pos + Vector2(-tri * 0.6, tri * 0.5).rotated(rot),
					map_pos + Vector2(tri * 0.6, tri * 0.5).rotated(rot),
				]), Color.WHITE)
			&"enemy":
				draw_rect(Rect2(map_pos - Vector2(3, 3), Vector2(6, 6)), Color.WHITE, false, 1.5)


func _world_to_map(world_pos: Vector2, center: Vector2) -> Vector2:
	var offset := world_pos - center
	var normalized := offset / WORLD_RANGE
	return MAP_SIZE / 2.0 + normalized * MAP_SIZE


func _in_bounds(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= MAP_SIZE.x and pos.y >= 0 and pos.y <= MAP_SIZE.y
