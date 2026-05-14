extends Node

enum GameMode { FLIGHT, CARGO, CUSTOMIZE }

signal mode_changed(old_mode: GameMode, new_mode: GameMode)
signal money_changed(new_amount: int)
signal cargo_changed()

var current_mode: GameMode = GameMode.FLIGHT
var money: int = 0
var placed_items: Array[Dictionary] = []
var equipped_parts: Dictionary = {}
var cab_grid_size: Vector2i = Vector2i(6, 10)
var trailer_grid_sizes: Array[Vector2i] = []
var total_cargo_mass: float = 0.0

var _previous_mode: GameMode = GameMode.FLIGHT


func set_mode(new_mode: GameMode) -> void:
	pass


func get_occupied_cells(item: Resource, origin: Vector2i, rot: int) -> Array[Vector2i]:
	return []


func get_part_stat(slot_id: StringName, stat_key: StringName, default: float) -> float:
	return default
