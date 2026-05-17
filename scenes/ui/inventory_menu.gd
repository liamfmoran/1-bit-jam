extends Control

const ITEM_SCENE = preload("res://scenes/ui/item.tscn")

@onready var inventory_list: VBoxContainer = %InventoryList
@onready var shop_list: VBoxContainer = %ShopList
@onready var action_button: Button = %ActionButton

var _inventory_group: ButtonGroup
var _shop_group: ButtonGroup
var _selected_item: Button
var _action_callback: Callable
var _shop_items: Array[ItemData] = []


func _ready() -> void:
	_inventory_group = ButtonGroup.new()
	_shop_group = ButtonGroup.new()
	action_button.pressed.connect(_on_action_pressed)
	GameState.inventory_changed.connect(_refresh)
	_refresh()


func setup_station(station: StationData) -> void:
	_shop_items = station.items_for_sale
	_populate_shop()


func _refresh() -> void:
	_selected_item = null
	_action_callback = Callable()
	action_button.text = " "
	_populate_inventory()
	%Credits.text = str(GameState.money) + ' c'
	_populate_shop()


func _populate_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()

	for data in GameState.inventory:
		_add_inventory_row(data)

	for data in GameState.part_inventory:
		_add_inventory_row(data)


func _add_inventory_row(data: Resource) -> void:
	var item := ITEM_SCENE.instantiate()
	item._render(data)
	item.button_group = _inventory_group
	item.toggled.connect(_on_inventory_toggled.bind(item))
	inventory_list.add_child(item)


func _populate_shop() -> void:
	for child in shop_list.get_children():
		child.queue_free()

	for data in _shop_items:
		_add_shop_row(data)


func _add_shop_row(data: Resource) -> void:
	var item := ITEM_SCENE.instantiate()
	item._render(data)
	item.button_group = _shop_group
	item.toggled.connect(_on_shop_toggled.bind(item))
	shop_list.add_child(item)


func _on_inventory_toggled(toggled_on: bool, item: Button) -> void:
	if not toggled_on:
		_selected_item = null
		_action_callback = Callable()
		action_button.text = " "
		return
	_deselect_group(_shop_group)
	_selected_item = item
	if item.item_data is ShipPartData:
		if GameState.is_part_equipped(item.item_data):
			action_button.text = "UNEQUIP"
			_action_callback = func():
				GameState.unequip_part(GameState.slot_id_for(item.item_data))
		else:
			action_button.text = "EQUIP"
			_action_callback = func():
				GameState.equip_part(GameState.slot_id_for(item.item_data), item.item_data)
	else:
		action_button.text = "SELL"
		_action_callback = func(): GameState.sell_part(item.item_data)


func _on_shop_toggled(toggled_on: bool, item: Button) -> void:
	if not toggled_on:
		_selected_item = null
		_action_callback = Callable()
		action_button.text = " "
		return
	_deselect_group(_inventory_group)
	_selected_item = item
	action_button.text = "BUY"
	if item.item_data is ShipPartData:
		_action_callback = func(): GameState.buy_ship_part(item.item_data)
	else:
		_action_callback = func(): GameState.buy_part(item.item_data)


func _deselect_group(group: ButtonGroup) -> void:
	var pressed := group.get_pressed_button()
	if pressed:
		pressed.button_pressed = false


func _on_action_pressed() -> void:
	if _action_callback.is_valid():
		_action_callback.call()
