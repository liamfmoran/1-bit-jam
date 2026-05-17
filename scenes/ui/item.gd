extends Button

var item_data: ItemData


func _render(data: ItemData) -> void:
	item_data = data
	_update_display()


func _update_display() -> void:
	var equipped := item_data is ShipPartData and GameState.is_part_equipped(item_data)
	%Name.text = ("[E] " if equipped else "") + item_data.display_name
	%Price.text = str(item_data.cost) + ' c'
	if item_data.icon:
		%Icon.texture = item_data.icon
