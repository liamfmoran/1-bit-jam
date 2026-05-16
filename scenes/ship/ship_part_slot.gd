class_name ShipPartSlot
extends Node2D

@export var slot_id: StringName
@export var equipped_part: ShipPartData


func _ready() -> void:
	if equipped_part == null:
		return
	if equipped_part is WeaponPartData:
		var wc := WeaponComponent.new()
		add_child(wc)
		wc.configure_from_part(equipped_part)
		var ship := get_parent()
		if ship and ship.is_in_group("player"):
			wc.team = &"player"
