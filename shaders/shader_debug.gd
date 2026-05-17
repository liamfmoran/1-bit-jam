extends Control

@onready var _bg := $Bg
var _dark := true

func _ready():
	_bg.color = Color.BLACK

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_dark = not _dark
		if _dark:
			_bg.color = Color.BLACK
			_set_text_color(Color.WHITE)
		else:
			_bg.color = Color.WHITE
			_set_text_color(Color.BLACK)

func _set_text_color(color: Color):
	for label in %Labels.get_children():
		label.add_theme_color_override("font_color", color)
