class_name HullComponent
extends Node

var damage_negation: float = 0.0


func configure_from_part(part: HullPartData) -> void:
	damage_negation = part.damage_negation


func reduce(amount: float) -> float:
	return maxf(0.0, amount - damage_negation)
