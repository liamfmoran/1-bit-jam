extends Button

var item_data: ItemData

func _render(item_data_to_render:ItemData):
	item_data = item_data_to_render
	%Name.text = item_data.display_name
	%Price.text = str(item_data.cost)+' c'
	if item_data.icon:
		%Icon.texture = item_data.icon
