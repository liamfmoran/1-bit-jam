extends Node2D
class_name ZoneNode

var zone_def: ZoneData
var _spawners: Array[Node] = []

func setup(def: ZoneData, streamer: Node) -> void:
	zone_def = def
	global_position = def.position

	for config: SpawnerConfig in def.spawners:
		var script := _get_spawner_script(config)
		if not script:
			continue
		var spawner := Node.new()
		spawner.set_script(script)
		add_child(spawner)
		spawner.setup(zone_def, config, streamer)
		_spawners.append(spawner)

func cleanup() -> void:
	for spawner: Variant in _spawners:
		var s := spawner as Node
		if is_instance_valid(s):
			s.call(&"cleanup")
	queue_free()

func _get_spawner_script(config: SpawnerConfig) -> Script:
	if config is AsteroidsSpawnerConfig:
		return preload("res://scenes/world/spawners/asteroid_zone_spawner.gd")
	if config is AsteroidClusterSpawnerConfig:
		return preload("res://scenes/world/spawners/asteroid_cluster_zone_spawner.gd")
	if config is AsteroidBeltSpawnerConfig:
		return preload("res://scenes/world/spawners/asteroid_belt_zone_spawner.gd")
	if config is EnemiesSpawnerConfig:
		return preload("res://scenes/world/spawners/enemy_zone_spawner.gd")
	if config is DockSpawnerConfig:
		return preload("res://scenes/world/spawners/dock_zone_spawner.gd")
	if config is BlackHoleSpawnerConfig:
		return preload("res://scenes/world/spawners/black_hole_zone_spawner.gd")
	if config is SalvageSpawnerConfig:
		return preload("res://scenes/world/spawners/salvage_zone_spawner.gd")
	push_warning("ZoneNode: no spawner script for config type '%s'" % config.get_class())
	return null
