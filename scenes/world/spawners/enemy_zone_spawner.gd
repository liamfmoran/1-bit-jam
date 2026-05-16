extends Node

var _zone_def: ZoneData
var _config: EnemiesSpawnerConfig
var _streamer: Node
var _ship: Node2D
var _enemies: Array[Node] = []

func setup(zone_def: ZoneData, config: EnemiesSpawnerConfig, streamer: Node) -> void:
	_zone_def = zone_def
	_config = config
	_streamer = streamer
	_ship = get_tree().get_first_node_in_group("player") as Node2D
	_spawn_enemies()

func _spawn_enemies() -> void:
	var zone_center: Vector2 = get_parent().global_position
	var zone_radius := _zone_def.radius

	for i in _config.count:
		var enemy := _streamer.enemy_pool.acquire() as Node2D
		get_parent().add_child(enemy)
		var angle := randf() * TAU
		var dist := randf_range(0.0, zone_radius * 0.8)
		enemy.global_position = zone_center + Vector2(cos(angle), sin(angle)) * dist
		enemy.visible = true
		if enemy is RigidBody2D:
			(enemy as RigidBody2D).linear_velocity = Vector2.ZERO
			(enemy as RigidBody2D).angular_velocity = 0.0
		enemy.call(&"setup", zone_center, _config.patrol_radius, _ship, _streamer)
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died.bind(enemy), CONNECT_ONE_SHOT)
		_enemies.append(enemy)

func _on_enemy_died(enemy: Node) -> void:
	_enemies.erase(enemy)
	_streamer.enemy_pool.release(enemy)

func cleanup() -> void:
	for enemy: Variant in _enemies:
		var e := enemy as Node
		if is_instance_valid(e):
			_streamer.enemy_pool.release(e)
	_enemies.clear()
