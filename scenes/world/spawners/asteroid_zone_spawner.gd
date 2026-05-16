extends Node

const ASTEROID_SCENE := preload("res://scenes/world/asteroid.tscn")
const SIZES: Array[float] = [8.0, 16.0, 28.0]
const MIN_SPEED := 80.0
const MAX_SPEED := 220.0
const MAX_ANGULAR_VEL := 2.0
const MIN_SPAWN_DIST := 400.0
const MAX_SPAWN_DIST := 700.0
const SPAWN_INTERVAL := 1.5

var _zone_def: ZoneData
var _config: AsteroidsSpawnerConfig
var _ship: Node2D
var _timer: Timer
var _group_id: String
var _asteroids: Array[Node] = []

func setup(zone_def: ZoneData, config: AsteroidsSpawnerConfig, _streamer: Node) -> void:
	_zone_def = zone_def
	_config = config
	_group_id = "zone_ast_%s" % zone_def.id
	_ship = get_tree().get_first_node_in_group("player") as Node2D

	_timer = Timer.new()
	_timer.wait_time = SPAWN_INTERVAL
	_timer.autostart = true
	_timer.timeout.connect(_on_timer)
	add_child(_timer)

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
	if current < target:
		_spawn_asteroid()
	if current + 1 < target:
		_spawn_asteroid()

func _density_at(dist: float) -> float:
	var zone_radius := _zone_def.radius
	var zone_falloff := _zone_def.falloff
	if dist <= zone_radius:
		return 1.0
	if dist >= zone_radius + zone_falloff:
		return 0.0
	return 1.0 - smoothstep(0.0, 1.0, (dist - zone_radius) / zone_falloff)

func _spawn_asteroid() -> void:
	var angle := randf() * TAU
	var dist := randf_range(MIN_SPAWN_DIST, MAX_SPAWN_DIST)
	var spawn_pos := _ship.global_position + Vector2(cos(angle), sin(angle)) * dist

	var asteroid := ASTEROID_SCENE.instantiate() as RigidBody2D
	asteroid.add_to_group(_group_id)
	asteroid.add_to_group("asteroids")
	get_parent().add_child(asteroid)
	asteroid.global_position = spawn_pos

	var r: float = SIZES[randi() % SIZES.size()]
	asteroid.setup(r, _ship)

	var vel_angle := randf() * TAU
	var speed := randf_range(MIN_SPEED, MAX_SPEED)
	asteroid.linear_velocity = Vector2(cos(vel_angle), sin(vel_angle)) * speed
	asteroid.angular_velocity = randf_range(-MAX_ANGULAR_VEL, MAX_ANGULAR_VEL)
	_asteroids.append(asteroid)

func cleanup() -> void:
	if is_instance_valid(_timer):
		_timer.stop()
	for ast: Variant in _asteroids:
		if is_instance_valid(ast):
			ast.queue_free()
	_asteroids.clear()
