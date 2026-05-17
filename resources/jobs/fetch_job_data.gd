class_name FetchJobData
extends JobData

var fetch_coordinate: Vector2
var fetch_item: ItemData = null
var is_fetched: bool = false

func get_target_label() -> String:
	return "(%.0f, %.0f)" % [fetch_coordinate.x, fetch_coordinate.y]
