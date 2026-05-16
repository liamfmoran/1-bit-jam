extends Node
class_name WorldStreamer

const SHIP_SPEED_BUFFER := 1200.0
const DEACTIVATION_EXTRA := 600.0
const POLL_INTERVAL := 0.5
const MOVE_THRESHOLD := 300.0

const ENEMY_SCENE := preload("res://scenes/world/enemy_ship.tscn")

var enemy_pool: ObjectPool

var _active_zones: Dictionary = {}
var _dynamic_zone_defs: Array[ZoneData] = []
var _ship: Node2D
var _timer := 0.0
var _last_check_pos := Vector2(INF, INF)

func _ready() -> void:
	enemy_pool = ObjectPool.new()
	enemy_pool.init(ENEMY_SCENE)
	add_child(enemy_pool)

func _process(delta: float) -> void:
	if not _ship:
		_ship = get_tree().get_first_node_in_group("player") as Node2D
		if not _ship:
			return

	_timer += delta
	var moved := _ship.global_position.distance_to(_last_check_pos) > MOVE_THRESHOLD
	if _timer >= POLL_INTERVAL or moved:
		_timer = 0.0
		_last_check_pos = _ship.global_position
		_update_zones()

func _update_zones() -> void:
	_process_zone_list(WorldData.zones)
	_process_zone_list(_dynamic_zone_defs)

func _process_zone_list(zone_list: Array) -> void:
	for zone_data: ZoneData in zone_list:
		var activation_dist := zone_data.radius + zone_data.falloff + SHIP_SPEED_BUFFER
		var deactivation_dist := activation_dist + DEACTIVATION_EXTRA
		var dist := _ship.global_position.distance_to(zone_data.position)

		if dist <= activation_dist and not _active_zones.has(zone_data.id):
			_load_zone(zone_data)
		elif dist > deactivation_dist and _active_zones.has(zone_data.id):
			_unload_zone(zone_data.id)

func _load_zone(zone_data: ZoneData) -> void:
	var zone := ZoneNode.new()
	get_parent().add_child(zone)
	zone.setup(zone_data, self)
	_active_zones[zone_data.id] = zone

func _unload_zone(id: String) -> void:
	var zone := _active_zones[id] as ZoneNode
	_active_zones.erase(id)
	if is_instance_valid(zone):
		zone.cleanup()

func add_zone(zone_data: ZoneData) -> void:
	_dynamic_zone_defs.append(zone_data)
