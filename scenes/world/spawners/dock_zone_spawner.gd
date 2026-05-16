extends Node

const DOCK_SCENE := preload("res://scenes/world/dock.tscn")

var _dock: Node2D

func setup(_zone_def: ZoneData, config: DockSpawnerConfig, _streamer: Node) -> void:
	_dock = DOCK_SCENE.instantiate() as Node2D
	get_parent().add_child(_dock)
	var station := WorldData.get_station(config.dock_id)
	if not station:
		push_error("DockZoneSpawner: no station data for id '%s'" % config.dock_id)
	else:
		_dock.setup(station)

func cleanup() -> void:
	if is_instance_valid(_dock):
		_dock.queue_free()
