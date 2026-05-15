extends Node2D

@export var zoom_min: float = 0.8
@export var zoom_max: float = 1.5
@export var zoom_speed_factor: float = 0.002
@export var zoom_smoothing: float = 3.0
@export var camera_rotation_smoothing: float = 5.0


@onready var truck_cab: RigidBody2D = $TruckCab
@onready var camera: Camera2D = $Camera2D

var _current_zoom: float = 1.5
var _current_rotation: float = 0.0

func _physics_process(delta: float) -> void:
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	camera.global_position = truck_cab.global_position

	# this didn't actually work 
	
	# _current_rotation = lerp_angle(_current_rotation, truck_cab.global_rotation, camera_rotation_smoothing * delta)
	# camera.global_rotation = _current_rotation

	var speed := truck_cab.linear_velocity.length()
	var target_zoom := clampf(zoom_max - speed * zoom_speed_factor, zoom_min, zoom_max)
	_current_zoom = lerpf(_current_zoom, target_zoom, zoom_smoothing * delta)
	camera.zoom = Vector2(_current_zoom, _current_zoom)
