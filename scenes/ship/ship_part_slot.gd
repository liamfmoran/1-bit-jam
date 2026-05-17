class_name ShipPartSlot
extends Node2D

@export var slot_id: StringName
@export var equipped_part: ShipPartData


func _ready() -> void:
	if equipped_part != null:
		equip(equipped_part)


func equip(part: ShipPartData) -> void:
	equipped_part = part
	for child in get_children():
		child.queue_free()

	var ship := get_parent()
	var is_player := ship != null and ship.is_in_group("player")

	if part is WeaponPartData:
		var wc := WeaponComponent.new()
		add_child(wc)
		wc.configure_from_part(part)
		if is_player:
			wc.team = &"player"
	elif part is HullPartData:
		var hc := HullComponent.new()
		add_child(hc)
		hc.configure_from_part(part)
	elif part is ShieldPartData:
		var sc := ShieldComponent.new()
		add_child(sc)
		sc.configure_from_part(part)
	elif part is EnginePartData:
		var ec := EngineComponent.new()
		add_child(ec)
		ec.configure_from_part(part)
