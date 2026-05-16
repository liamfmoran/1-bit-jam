extends Node

const ASTEROID_SCENE := preload("res://scenes/world/asteroid.tscn")
const SIZES: Array[float] = [8.0, 16.0, 28.0]
const SPAWN_INTERVAL := 1.0
const MIN_SPAWN_DIST_FROM_PLAYER := 600.0

var _zone_def: ZoneData
var _config: AsteroidClusterSpawnerConfig
var _ship: Node2D
var _timer: Timer
var _group_id: String
var _dir: Vector2
var _perp: Vector2
var _half_length: float
var _asteroids: Array[Node] = []

func setup(zone_def: ZoneData, config: AsteroidClusterSpawnerConfig, _streamer: Node) -> void:
	_zone_def = zone_def
	_config = config
	_group_id = "zone_belt_%s" % zone_def.id
	_ship = get_tree().get_first_node_in_group("player") as Node2D
	_dir = config.direction
	_perp = Vector2(-_dir.y, _dir.x)
	_half_length = zone_def.radius

	_timer = Timer.new()
	_timer.wait_time = SPAWN_INTERVAL
	_timer.autostart = true
	_timer.timeout.connect(_on_timer)
	add_child(_timer)

	_populate_initial()

func _populate_initial() -> void:
	var zone_center: Vector2 = get_parent().global_position
	for i in _config.max_count:
		var along := randf_range(-_half_length, _half_length)
		var across := randf_range(-_config.width * 0.5, _config.width * 0.5)
		var spawn_pos := zone_center + _dir * along + _perp * across
		if spawn_pos.distance_to(_ship.global_position) < MIN_SPAWN_DIST_FROM_PLAYER:
			continue
		_place_asteroid(spawn_pos)

func _on_timer() -> void:
	if not is_instance_valid(_ship):
		return
	var zone_center: Vector2 = get_parent().global_position
	var dist := _ship.global_position.distance_to(zone_center)
	var density := _density_at(dist)
	if density <= 0.0:
		return
	var target := int(_config.max_count * density)
	var current := get_tree().get_nodes_in_group(_group_id).size()
	if current >= target:
		return
	var player_along := (_ship.global_position - zone_center).dot(_dir)
	var along := clampf(player_along + randf_range(-500.0, 500.0), -_half_length, _half_length)
	var across := randf_range(-_config.width * 0.5, _config.width * 0.5)
	var spawn_pos := zone_center + _dir * along + _perp * across
	if spawn_pos.distance_to(_ship.global_position) >= MIN_SPAWN_DIST_FROM_PLAYER:
		_place_asteroid(spawn_pos)

func _density_at(dist: float) -> float:
	if dist <= _zone_def.radius:
		return 1.0
	if dist >= _zone_def.radius + _zone_def.falloff:
		return 0.0
	return 1.0 - smoothstep(0.0, 1.0, (dist - _zone_def.radius) / _zone_def.falloff)

func _place_asteroid(spawn_pos: Vector2) -> void:
	var asteroid := ASTEROID_SCENE.instantiate() as RigidBody2D
	asteroid.add_to_group(_group_id)
	asteroid.add_to_group("asteroids")
	get_parent().add_child(asteroid)
	asteroid.global_position = spawn_pos
	var r: float = SIZES[randi() % SIZES.size()]
	asteroid.setup(r, _ship)
	var drift_angle := randf() * TAU
	asteroid.linear_velocity = Vector2(cos(drift_angle), sin(drift_angle)) * randf_range(0.0, _config.speed)
	asteroid.angular_velocity = randf_range(-0.6, 0.6)
	_asteroids.append(asteroid)

func cleanup() -> void:
	if is_instance_valid(_timer):
		_timer.stop()
	for ast: Variant in _asteroids:
		if is_instance_valid(ast):
			ast.queue_free()
	_asteroids.clear()
