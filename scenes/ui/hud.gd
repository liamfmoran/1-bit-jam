extends Control

@onready var _compass = %Compass

func render(degree):
	_compass.degree = degree
	_compass.queue_redraw()

func _physics_process(delta):
	var camera = get_viewport().get_camera_2d()
	var degree = camera.global_rotation_degrees
	degree = int(floor(degree))
	if degree <0:
		degree = 180 + (degree+180)
	_compass.player_position = camera.global_position
	render(degree)

	if GameState._is_ship_docked:
		self.visible=0
	else:
		self.visible=1
