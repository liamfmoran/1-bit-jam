extends Control

const ITEM_SCENE = preload("res://scenes/ui/item.tscn")

@onready var inventory_list: VBoxContainer = %InventoryList
@onready var shop_list: VBoxContainer = %ShopList
@onready var action_button: Button = %ActionButton

var _inventory_group: ButtonGroup
var _shop_group: ButtonGroup
var _selected_item: Button
var _is_selling: bool = false
var _shop_parts: Array[ItemData] = []


func _ready() -> void:
	_inventory_group = ButtonGroup.new()
	_shop_group = ButtonGroup.new()
	action_button.pressed.connect(_on_action_pressed)
	GameState.inventory_changed.connect(_refresh)
	_refresh()


func set_parts(parts: Array[ItemData]) -> void:
	_shop_parts = parts
	_populate_shop()


func _refresh() -> void:
	_selected_item = null
	_is_selling = false
	_populate_inventory()
	%Credits.text = str(GameState.money) + ' c'
	_populate_shop()


func _populate_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()

	for part in GameState.inventory:
		var item := ITEM_SCENE.instantiate()
		item._render(part)
		item.button_group = _inventory_group
		item.toggled.connect(_on_inventory_toggled.bind(item))
		inventory_list.add_child(item)


func _populate_shop() -> void:
	for child in shop_list.get_children():
		child.queue_free()

	for part in _shop_parts:
		var item := ITEM_SCENE.instantiate()
		item._render(part)
		item.button_group = _shop_group
		item.toggled.connect(_on_shop_toggled.bind(item))
		shop_list.add_child(item)


func _on_inventory_toggled(toggled_on: bool, item: Button) -> void:
	if toggled_on:
		_deselect_group(_shop_group)
		_selected_item = item
		_is_selling = true
		action_button.text = 'Sell'
	else:
		_selected_item = null


func _on_shop_toggled(toggled_on: bool, item: Button) -> void:
	if toggled_on:
		_deselect_group(_inventory_group)
		_selected_item = item
		_is_selling = false
		action_button.text = 'Buy'
	else:
		_selected_item = null


func _deselect_group(group: ButtonGroup) -> void:
	var pressed := group.get_pressed_button()
	if pressed:
		pressed.button_pressed = false


func _on_action_pressed() -> void:
	if not _selected_item:
		return

	if _is_selling:
		GameState.sell_part(_selected_item.item_data)
	else:
		_shop_parts.erase(_selected_item.item_data)
		print(_shop_parts)
		GameState.buy_part(_selected_item.item_data)
		
