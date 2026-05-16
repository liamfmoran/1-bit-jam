extends Control

const ITEM_SCENE = preload("res://scenes/ui/item.tscn")

@onready var inventory_list: VBoxContainer = %InventoryList
@onready var shop_list: VBoxContainer = %ShopList
@onready var buy_button: Button = $BuyMenu/ActionButton
@onready var sell_button: Button = $SellMenu/ActionButton

var _inventory_group: ButtonGroup
var _shop_group: ButtonGroup
var _selected_item: Button
var _is_selling: bool = false
var _shop_parts: Array[ItemData] = []


func _ready() -> void:
	_inventory_group = ButtonGroup.new()
	_shop_group = ButtonGroup.new()
	buy_button.pressed.connect(_on_action_pressed)
	sell_button.pressed.connect(_on_action_pressed)
	buy_button.disabled = true
	sell_button.disabled = true
	GameState.inventory_changed.connect(_refresh)
	_refresh()
	show_home()


func set_parts(parts: Array[ItemData]) -> void:
	_shop_parts = parts
	_populate_shop()


func _refresh() -> void:
	_selected_item = null
	_is_selling = false
	buy_button.disabled = true
	sell_button.disabled = true
	_populate_inventory()
	if not _shop_parts.is_empty():
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
		sell_button.text = "Sell %s" % item.item_data.display_name
		sell_button.disabled = false
	else:
		_selected_item = null
		sell_button.disabled = true


func _on_shop_toggled(toggled_on: bool, item: Button) -> void:
	if toggled_on:
		_deselect_group(_inventory_group)
		_selected_item = item
		_is_selling = false
		buy_button.text = "Buy"
		buy_button.disabled = false
	else:
		_selected_item = null
		buy_button.disabled = true


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
		GameState.buy_part(_selected_item.item_data)


func show_buy():
	$Home.visible = false
	$BuyMenu.visible = true
	$SellMenu.visible = false


func show_sell():
	$Home.visible = false
	$BuyMenu.visible = false
	$SellMenu.visible = true
	_populate_inventory()


func show_home():
	$Home.visible = true
	$BuyMenu.visible = false
	$SellMenu.visible = false


func _on_buy_button_button_down():
	show_buy()


func _on_back_button_button_down():
	show_home()


func _on_sell_button_button_down():
	show_sell()
