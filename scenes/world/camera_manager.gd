class_name CameraManager
extends Camera2D

enum State { FLIGHT, DOCKING, UNDOCKING }

@export var zoom_min: float = 0.6
@export var zoom_max: float = 1.125
@export var zoom_speed_factor: float = 0.0015
@export var zoom_smoothing: float = 3.0
@export var zoom_out_smoothing: float = 5.5
@export var dock_zoom: float = 1.125
@export var dock_zoom_duration: float = 0.0
@export var undock_zoom_duration: float = 1.0
@export var rotation_smoothing: float = 6.0
@export var flight_screen_offset: Vector2 = Vector2(0, 150)

var _player: Node2D
var _dock_target: Node2D
var _state: State = State.FLIGHT
var _dock_tween: Tween
var _current_rotation: float = 0.0
var _dock_weight: float = 0.0
var _zoom_start: float = 1.125


func _ready() -> void:
	ignore_rotation = false
	position_smoothing_enabled = false
	rotation_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	zoom = Vector2(zoom_max, zoom_max)
	_player = get_tree().get_first_node_in_group("player") as Node2D
	GameState.undocked.connect(start_undocking)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	var ship_cam := _player.global_position - (flight_screen_offset / zoom.x).rotated(_current_rotation)
	var new_cam_pos: Vector2
	if _state != State.FLIGHT and _dock_target and is_instance_valid(_dock_target):
		new_cam_pos = ship_cam.lerp(_dock_target.global_position, _dock_weight)
	else:
		new_cam_pos = ship_cam

	global_position = new_cam_pos

	_current_rotation = lerp_angle(_current_rotation, _player.global_rotation, rotation_smoothing * delta)
	global_rotation = _current_rotation

	match _state:
		State.DOCKING:
			var z := lerpf(_zoom_start, dock_zoom, _dock_weight)
			zoom = Vector2(z, z)
		State.FLIGHT, State.UNDOCKING:
			var speed := (_player as RigidBody2D).linear_velocity.length() if _player is RigidBody2D else 0.0
			var flight_zoom := clampf(zoom_max - speed * zoom_speed_factor, zoom_min, zoom_max)
			var smoothing := zoom_out_smoothing if flight_zoom < zoom.x else zoom_smoothing
			zoom = zoom.lerp(Vector2(flight_zoom, flight_zoom), smoothing * delta)


func start_docking(approach_duration: float, dock_target: Node2D) -> void:
	_dock_target = dock_target
	if _dock_tween:
		_dock_tween.kill()
	_state = State.DOCKING
	_zoom_start = zoom.x
	_dock_weight = 0.0
	_dock_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_dock_tween.tween_property(self, "_dock_weight", 1.0, approach_duration + dock_zoom_duration)
	_dock_tween.finished.connect(func() -> void: _dock_tween = null)


func start_undocking() -> void:
	if _state == State.FLIGHT or _state == State.UNDOCKING:
		return
	if _dock_tween:
		_dock_tween.kill()
	_state = State.UNDOCKING
	_dock_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_dock_tween.tween_property(self, "_dock_weight", 0.0, undock_zoom_duration)
	_dock_tween.finished.connect(func() -> void:
		_dock_tween = null
		_state = State.FLIGHT
		_dock_target = null
	)
