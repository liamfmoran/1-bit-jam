extends Node

const BLACK_HOLE_SCENE := preload("res://scenes/world/black_hole.tscn")

var _black_hole: Node2D

func setup(_zone_def: ZoneData, config: BlackHoleSpawnerConfig, _streamer: Node) -> void:
	_black_hole = BLACK_HOLE_SCENE.instantiate() as Node2D
	get_parent().add_child(_black_hole)
	_black_hole.call(&"setup", config.pull_strength)

func cleanup() -> void:
	if is_instance_valid(_black_hole):
		_black_hole.queue_free()
