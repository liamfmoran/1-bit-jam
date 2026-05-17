class_name EngineComponent
extends Node

var power_multiplier: float = 1.0
var boost_capacity: float = 0.0
var boost_charge: float = 1.0


func configure_from_part(part: EnginePartData) -> void:
	power_multiplier = part.power_multiplier
	boost_capacity = part.boost_capacity
	boost_charge = 1.0


func has_boost() -> bool:
	return boost_capacity > 0.0


func tick(delta: float, boost_requested: bool) -> void:
	if not has_boost():
		return
	if boost_requested and boost_charge > 0.0:
		boost_charge = maxf(0.0, boost_charge - delta / 10.0)
	elif not boost_requested:
		boost_charge = minf(1.0, boost_charge + delta / 10.0)
