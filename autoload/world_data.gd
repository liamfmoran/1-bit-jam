extends Node

class ShipEntry:
	var node: Node2D
	var kind: StringName

var zones: Array[ZoneData] = []
var items: Dictionary[String, ItemData] = {}
var ship_parts: Dictionary[String, ShipPartData] = {}
var jobs: Dictionary[String, JobData] = {}
var stations: Dictionary[String, StationData] = {}

var _ships: Array[ShipEntry] = []

func _ready() -> void:
	items = DataLoader.load_items()
	ship_parts = DataLoader.load_ship_parts()
	var job_station_refs: Dictionary = {}
	jobs = DataLoader.load_jobs(items, job_station_refs)
	zones = DataLoader.load_zones()
	stations = DataLoader.load_stations(jobs, items, ship_parts)
	for station: StationData in stations.values():
		station.position = _find_station_position(station.id)
	DataLoader.resolve_job_stations(jobs, stations, job_station_refs)

func get_station(id: String) -> StationData:
	return stations.get(id)

func get_item(id: String) -> ItemData:
	return items.get(id)

func get_ship_part(id: String) -> ShipPartData:
	return ship_parts.get(id)

func get_job(id: String) -> JobData:
	return jobs.get(id)

func track_ship(node: Node2D, kind: StringName) -> void:
	var entry := ShipEntry.new()
	entry.node = node
	entry.kind = kind
	_ships.append(entry)
	node.tree_exiting.connect(_on_ship_exiting.bind(node))

func _on_ship_exiting(node: Node2D) -> void:
	for i in range(_ships.size() - 1, -1, -1):
		if _ships[i].node == node:
			_ships.remove_at(i)
			return

func get_ships() -> Array[ShipEntry]:
	return _ships

func _find_station_position(station_id: String) -> Vector2:
	for zone: ZoneData in zones:
		for config: SpawnerConfig in zone.spawners:
			if config is DockSpawnerConfig and config.dock_id == station_id:
				return zone.position
	return Vector2.ZERO
