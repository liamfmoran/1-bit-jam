class_name BaseShip
extends RigidBody2D

signal died

@export var max_health: float = 100.0
var health: float


func _ready() -> void:
	health = max_health


func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if health == 0.0:
		died.emit()
		_on_die()


func _on_die() -> void:
	pass


func find_in_slots(component_class: Variant) -> Node:
	for child in get_children():
		if child is ShipPartSlot:
			for sub: Node in child.get_children():
				if is_instance_of(sub, component_class):
					return sub
	return null
