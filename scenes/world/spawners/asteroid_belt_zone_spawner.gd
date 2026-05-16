extends Node

const ASTEROID_SCENE := preload("res://scenes/world/asteroid.tscn")
const SIZES: Array[float] = [8.0, 16.0, 28.0]
const MIN_SPAWN_DIST_FROM_PLAYER := 600.0
const OFFSCREEN_BUFFER := 1400.0

var _config: AsteroidBeltSpawnerConfig
var _ship: Node2D
var _group_id: String
var _speed: float
var _width: float
var _dir: Vector2
var _perp: Vector2
var _asteroids: Array = []

func setup(zone_def: ZoneData, config: AsteroidBeltSpawnerConfig, _streamer: Node) -> void:
	_config = config
	_group_id = "zone_belt_%s" % zone_def.id
	_ship = get_tree().get_first_node_in_group("player") as Node2D
	_speed = config.speed
	_width = config.width
	_dir = config.direction
	_perp = Vector2(-_dir.y, _dir.x)
	_populate_initial()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_ship):
		return
	var zone_center: Vector2 = get_parent().global_position
	var player_along: float = (_ship.global_position - zone_center).dot(_dir)

	for i in range(_asteroids.size() - 1, -1, -1):
		var ast = _asteroids[i]
		if not is_instance_valid(ast):
			_asteroids.remove_at(i)
			continue
		var rb := ast as RigidBody2D
		rb.linear_velocity = _dir * _speed
		var ast_along: float = (ast.global_position - zone_center).dot(_dir)
		if ast_along > player_along + OFFSCREEN_BUFFER:
			_recycle(ast, zone_center, player_along, true)
		elif ast_along < player_along - OFFSCREEN_BUFFER:
			_recycle(ast, zone_center, player_along, false)

	var deficit := mini(_config.max_count - _asteroids.size(), 5)
	for i in deficit:
		_spawn_new(zone_center, player_along)

func _populate_initial() -> void:
	var zone_center: Vector2 = get_parent().global_position
	var player_along: float = (_ship.global_position - zone_center).dot(_dir)
	for i in _config.max_count:
		var t := float(i) / float(_config.max_count)
		var along: float = player_along + lerp(-OFFSCREEN_BUFFER, OFFSCREEN_BUFFER, t)
		var spawn_pos := zone_center + _dir * along + _perp * _sample_width()
		if spawn_pos.distance_to(_ship.global_position) < MIN_SPAWN_DIST_FROM_PLAYER:
			continue
		_asteroids.append(_place_asteroid(spawn_pos))

func _recycle(ast: Node, zone_center: Vector2, player_along: float, exited_front: bool) -> void:
	var target_along: float
	if exited_front:
		target_along = player_along - OFFSCREEN_BUFFER + randf_range(0.0, 50.0)
	else:
		target_along = player_along + OFFSCREEN_BUFFER - randf_range(0.0, 50.0)
	ast.global_position = zone_center + _dir * target_along + _perp * _sample_width()
	(ast as RigidBody2D).linear_velocity = _dir * _speed

func _spawn_new(zone_center: Vector2, player_along: float) -> void:
	var upstream := player_along - OFFSCREEN_BUFFER + randf_range(0.0, 100.0)
	var spawn_pos := zone_center + _dir * upstream + _perp * _sample_width()
	if spawn_pos.distance_to(_ship.global_position) < MIN_SPAWN_DIST_FROM_PLAYER:
		return
	_asteroids.append(_place_asteroid(spawn_pos))

func _place_asteroid(spawn_pos: Vector2) -> RigidBody2D:
	var asteroid := ASTEROID_SCENE.instantiate() as RigidBody2D
	asteroid.add_to_group(_group_id)
	asteroid.add_to_group("asteroids")
	get_parent().add_child(asteroid)
	asteroid.global_position = spawn_pos
	var r: float = SIZES[randi() % SIZES.size()]
	asteroid.setup(r, _ship)
	asteroid.linear_velocity = _dir * _speed
	asteroid.angular_velocity = randf_range(-0.6, 0.6)
	return asteroid

func _sample_width() -> float:
	var spread := _width * 0.2 if randf() < 0.7 else _width * 0.55
	return clampf(randfn(0.0, spread), -_width, _width)

func cleanup() -> void:
	for ast in _asteroids:
		if is_instance_valid(ast):
			ast.queue_free()
	_asteroids.clear()
