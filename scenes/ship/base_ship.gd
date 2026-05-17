class_name BaseShip
extends RigidBody2D

signal died

@export var max_health: float = 100.0
var health: float


func _ready() -> void:
	health = max_health


func take_damage(amount: float) -> void:
	var shield := find_in_slots(ShieldComponent) as ShieldComponent
	if shield:
		amount = shield.absorb(amount)
	var hull := find_in_slots(HullComponent) as HullComponent
	if hull:
		amount = hull.reduce(amount)
	if amount <= 0.0:
		return
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
				if not sub.is_queued_for_deletion() and is_instance_of(sub, component_class):
					return sub
	return null
