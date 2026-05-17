extends Button

var item_data: ItemData


func _render(data: ItemData) -> void:
	item_data = data
	_update_display()


func _update_display() -> void:
	%Name.text = item_data.display_name
	%Price.text = str(item_data.cost) + ' c'
	if item_data.icon:
		%Icon.texture = item_data.icon
