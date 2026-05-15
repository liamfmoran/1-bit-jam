extends Control


@onready var Inventory_Section = %Inventory
@onready var Vendor_Section = %Vendors

var Vendors

var _current_vendor = "home"

func _ready():
	Vendors = {"home":%Home,"engineer":%Engineer,"weapons":%Weapons,"bizzaro":%Bizarro} #need a vendors available if we want to have them specific? eh


	var vendor_group = ButtonGroup.new()
	for i in Vendors.keys():
		Vendors[i].button_group = vendor_group
		Vendors[i].toggled.connect(update_display.bind(i))
	Vendors[_current_vendor].button_pressed = true
	update_display(true, _current_vendor)


func update_display(toggled_on, display_name):
	if not toggled_on:
		return
	_current_vendor = display_name
	%display_test.text = display_name
