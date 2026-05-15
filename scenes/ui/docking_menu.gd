extends Control

signal closed

@onready var _inventory_section = %Inventory
@onready var _vendor_section = %Vendors
@onready var _close_button: Button = %Close

var Vendors

var _current_vendor = "home"


func _ready():
	Vendors = {"home":%Home,"engineer":%Engineer,"weapons":%Weapons,"bizzaro":%Bizarro}

	var vendor_group = ButtonGroup.new()
	for i in Vendors.keys():
		Vendors[i].button_group = vendor_group
		Vendors[i].toggled.connect(update_display.bind(i))
	Vendors[_current_vendor].button_pressed = true
	update_display(true, _current_vendor)

	
	_close_button.pressed.connect(closed.emit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


func update_display(toggled_on, display_name):
	if not toggled_on:
		return
	_current_vendor = display_name
	%display_test.text = display_name
