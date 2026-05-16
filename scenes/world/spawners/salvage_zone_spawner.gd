extends Node

const SALVAGE_SCENE := preload("res://scenes/world/salvage.tscn")

var _zone_def: ZoneData
var _config: SalvageSpawnerConfig
var _salvage_list: Array[Node] = []

func setup(zone_def: ZoneData, config: SalvageSpawnerConfig, _streamer: Node) -> void:
	_zone_def = zone_def
	_config = config
	_scatter_salvage()

func _scatter_salvage() -> void:
	var zone_radius := _zone_def.radius
	var zone_center: Vector2 = get_parent().global_position

	for i in _config.count:
		var angle := randf() * TAU
		var dist := randf_range(0.0, zone_radius * 0.8)
		var salvage := SALVAGE_SCENE.instantiate() as Node2D
		get_parent().add_child(salvage)
		salvage.global_position = zone_center + Vector2(cos(angle), sin(angle)) * dist
		_salvage_list.append(salvage)

func cleanup() -> void:
	for s: Variant in _salvage_list:
		var node := s as Node
		if is_instance_valid(node):
			node.queue_free()
	_salvage_list.clear()
