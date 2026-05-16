extends Button

func _render(item_data:ItemData):
	%Name.text = item_data.display_name
	%Price.text = str(item_data.cost)+' c'
