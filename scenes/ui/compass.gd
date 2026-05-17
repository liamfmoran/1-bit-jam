extends Control

var degree: float = 0.0
var player_position: Vector2 = Vector2.ZERO

func _draw():
	var visible_w = size.x
	var visible_h = size.y
	var ppd = visible_w / 180.0

	for station_id: String in WorldData.stations:
		var station: StationData = WorldData.stations[station_id]
		if station.position == Vector2.ZERO:
			continue

		var diff: Vector2 = station.position - player_position
		var cx: float = _bearing_to_cx(diff, visible_w, ppd)
		var dist: float = diff.length()
		var thickness: float = max(1.0, visible_h * 4.0 * exp(-dist / 2500.0))
		draw_line(Vector2(cx, 0.0), Vector2(cx, visible_h), Color.WHITE, thickness)
		var font := ThemeDB.fallback_font
		var label_w := font.get_string_size(station.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		draw_string(font, Vector2(cx - label_w * 0.5, visible_h + 10.0), station.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		if _has_job_for(station.id):
			draw_circle(Vector2(cx, -6.0), 1.5, Color.WHITE)

	for job: JobData in GameState.active_jobs:
		var fetch := job as FetchJobData
		if fetch == null or fetch.is_fetched:
			continue
		var diff: Vector2 = fetch.fetch_coordinate - player_position
		var cx: float = _bearing_to_cx(diff, visible_w, ppd)
		var dist: float = diff.length()
		var thickness: float = max(1.0, visible_h * 4.0 * exp(-dist / 2500.0))
		draw_line(Vector2(cx, 0.0), Vector2(cx, visible_h), Color.WHITE, thickness)
		draw_circle(Vector2(cx, -6.0), 1.5, Color.WHITE)


func _bearing_to_cx(diff: Vector2, visible_w: float, ppd: float) -> float:
	var raw: float = rad_to_deg(atan2(diff.y, diff.x))
	raw = floor(raw)
	if raw < 0.0:
		raw = 180.0 + (raw + 180.0)
	var adjusted: float = wrapf(degree - 90.0, 0.0, 360.0)
	var rel: float = wrapf(raw - adjusted, -180.0, 180.0)
	return clamp(visible_w * 0.5 + rel * ppd, 0.0, visible_w)


func _has_job_for(station_id: String) -> bool:
	for job: JobData in GameState.active_jobs:
		var delivery := job as DeliveryJobData
		if delivery and delivery.destination != null and delivery.destination.id == station_id:
			return true
		var fetch := job as FetchJobData
		if fetch and fetch.origin != null and fetch.origin.id == station_id:
			return true
	return false
