extends Node

var active_events: Array[StringName] = []

func _ready() -> void:
	add_event(&"asteroids")

func add_event(id: StringName) -> void:
	if id not in active_events:
		active_events.append(id)

func remove_event(id: StringName) -> void:
	active_events.erase(id)

func has_event(id: StringName) -> bool:
	return id in active_events
