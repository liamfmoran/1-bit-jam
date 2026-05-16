class_name DataLoader

static func load_items() -> Dictionary[String, ItemData]:
	var result: Dictionary[String, ItemData] = {}
	for d: Variant in _load_array("res://data/items.json", "items"):
		result[d.get("id", "") as String] = _item_from_dict(d)
	return result

static func load_ship_parts() -> Dictionary[String, ShipPartData]:
	var result: Dictionary[String, ShipPartData] = {}
	for d: Variant in _load_array("res://data/ship_parts.json", "ship_parts"):
		result[d.get("id", "") as String] = _ship_part_from_dict(d)
	return result

static func load_jobs(item_registry: Dictionary[String, ItemData], out_station_refs: Dictionary) -> Dictionary[String, JobData]:
	var result: Dictionary[String, JobData] = {}
	for d: Variant in _load_array("res://data/jobs.json", "jobs"):
		var id: String = d.get("id", "")
		result[id] = _job_from_dict(d, item_registry)
		out_station_refs[id] = { "origin": d.get("origin", ""), "destination": d.get("destination", "") }
	return result

static func load_zones() -> Array[ZoneData]:
	var result: Array[ZoneData] = []
	for d: Variant in _load_array("res://data/world_map.json", "zones"):
		result.append(_zone_from_dict(d))
	return result

static func load_stations(job_registry: Dictionary[String, JobData], item_registry: Dictionary[String, ItemData]) -> Dictionary[String, StationData]:
	var result: Dictionary[String, StationData] = {}
	for d: Variant in _load_array("res://data/stations.json", "stations"):
		var station := _station_from_dict(d, job_registry, item_registry)
		result[station.id] = station
	return result


static func resolve_job_stations(job_registry: Dictionary[String, JobData], station_registry: Dictionary[String, StationData], station_refs: Dictionary) -> void:
	for id: String in job_registry:
		var job := job_registry[id]
		var refs := station_refs.get(id, {}) as Dictionary
		job.origin = station_registry.get(refs.get("origin", ""))
		if job is DeliveryJobData:
			(job as DeliveryJobData).destination = station_registry.get(refs.get("destination", ""))


static func _item_from_dict(d: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.display_name = d.get("display_name", "")
	item.description = d.get("description", "")
	item.mass = float(d.get("mass", 0.0))
	item.cost = int(d.get("cost", 0))
	return item

static func _ship_part_from_dict(d: Dictionary) -> ShipPartData:
	var slot_str: String = d.get("slot_type", "")
	var part: ShipPartData
	match slot_str:
		"turret":
			var wp := WeaponPartData.new()
			var stats: Dictionary = d.get("stats", {})
			wp.fire_rate    = float(stats.get("fire_rate",    wp.fire_rate))
			wp.damage       = float(stats.get("damage",       wp.damage))
			wp.bullet_speed = float(stats.get("bullet_speed", wp.bullet_speed))
			wp.weapon_range = float(stats.get("range",        wp.weapon_range))
			part = wp
		"thruster":
			part = ThrusterPartData.new()
		"shield":
			part = ShieldPartData.new()
		_:
			push_error("DataLoader: unknown slot type '%s'" % slot_str)
			part = ShipPartData.new()
	part.display_name = d.get("display_name", "")
	part.mass = float(d.get("mass", 0.0))
	part.cost = int(d.get("cost", 0))
	return part

static func _zone_from_dict(d: Dictionary) -> ZoneData:
	var zone := ZoneData.new()
	zone.id = d.get("id", "")
	zone.display_name = d.get("display_name", "")
	var pos: Array = d.get("position", [0, 0])
	zone.position = Vector2(float(pos[0]), float(pos[1]))
	zone.radius = float(d.get("radius", 500.0))
	zone.falloff = float(d.get("falloff", 300.0))
	if d.has("line_direction"):
		var raw_ld: Array = d.get("line_direction", [0, 0])
		zone.line_direction = Vector2(float(raw_ld[0]), float(raw_ld[1])).normalized()
	for sd: Variant in d.get("spawners", []):
		var cfg := _spawner_config_from_dict(sd as Dictionary)
		if cfg:
			zone.spawners.append(cfg)
	return zone

static func _spawner_config_from_dict(d: Dictionary) -> SpawnerConfig:
	match d.get("type", ""):
		"asteroids":
			var c := AsteroidsSpawnerConfig.new()
			c.max_count = int(d.get("max_count", c.max_count))
			return c
		"asteroid_cluster":
			var c := AsteroidClusterSpawnerConfig.new()
			c.speed     = float(d.get("speed", c.speed))
			c.width       = float(d.get("width", c.width))
			c.max_count   = int(d.get("max_count", c.max_count))
			var raw_dir: Array = d.get("direction", [1, 0])
			c.direction   = Vector2(float(raw_dir[0]), float(raw_dir[1])).normalized()
			return c
		"asteroid_belt":
			var c := AsteroidBeltSpawnerConfig.new()
			c.speed       = float(d.get("speed", c.speed))
			c.width       = float(d.get("width", c.width))
			c.max_count   = int(d.get("max_count", c.max_count))
			var raw_dir: Array = d.get("direction", [1, 0])
			c.direction   = Vector2(float(raw_dir[0]), float(raw_dir[1])).normalized()
			return c
		"enemies":
			var c := EnemiesSpawnerConfig.new()
			c.count        = int(d.get("count", c.count))
			c.patrol_radius = float(d.get("patrol_radius", c.patrol_radius))
			return c
		"dock":
			var c := DockSpawnerConfig.new()
			c.dock_id = d.get("dock_id", "")
			return c
		"black_hole":
			var c := BlackHoleSpawnerConfig.new()
			c.pull_strength = float(d.get("pull_strength", c.pull_strength))
			return c
		"salvage":
			var c := SalvageSpawnerConfig.new()
			c.count = int(d.get("count", c.count))
			return c
		_:
			push_error("DataLoader: unknown spawner type '%s'" % d.get("type", ""))
			return null

static func _job_from_dict(d: Dictionary, item_registry: Dictionary[String, ItemData]) -> JobData:
	var type_str: String = d.get("type", "")
	var job: JobData
	match type_str:
		"DELIVERY":
			job = DeliveryJobData.new()
		"FETCH":
			var fetch := FetchJobData.new()
			var fc: Array = d.get("fetch_coordinate", [0, 0])
			fetch.fetch_coordinate = Vector2(float(fc[0]), float(fc[1]))
			job = fetch
		_:
			push_error("DataLoader: unknown job type '%s'" % type_str)
			job = DeliveryJobData.new()
	job.display_name = d.get("display_name", "")
	job.description = d.get("description", "")
	job.money_reward = int(d.get("money_reward", 100))
	for item_id: Variant in d.get("cargo", []):
		var item: ItemData = item_registry.get(item_id as String)
		if item:
			job.cargo.append(item)
	return job

static func _station_from_dict(d: Dictionary, job_registry: Dictionary[String, JobData], item_registry: Dictionary[String, ItemData]) -> StationData:
	var station := StationData.new()
	station.id = d.get("id", "")
	station.display_name = d.get("display_name", "")
	for job_id: Variant in d.get("jobs", []):
		var job: JobData = job_registry.get(job_id as String)
		if job:
			station.jobs.append(job)
	for item_id: Variant in d.get("items_for_sale", []):
		var item: ItemData = item_registry.get(item_id as String)
		if item:
			station.items_for_sale.append(item)
	return station

static func _load_array(path: String, key: String) -> Array:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("DataLoader: could not open %s" % path)
		return []
	var data := JSON.parse_string(text) as Dictionary
	if not data:
		push_error("DataLoader: JSON parse failed in %s" % path)
		return []
	return data.get(key, [])
