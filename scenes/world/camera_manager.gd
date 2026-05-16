extends Camera2D

@export var zoom_min: float = 0.8
@export var zoom_max: float = 1.5
@export var zoom_speed_factor: float = 0.002
@export var zoom_smoothing: float = 3.0
@export var zoom_out_smoothing: float = 5.5
@export var dock_zoom: float = 1.5
@export var dock_zoom_duration: float = 1.4
@export var undock_zoom_duration: float = 1.0
@export var rotation_smoothing: float = 6.0

var _ship: Node2D
var _zoom_tween: Tween
var _current_rotation: float = 0.0
var _dock_zoom_weight: float = 0.0


func _ready() -> void:
	ignore_rotation = false
	zoom = Vector2(zoom_max, zoom_max)
	_ship = get_tree().get_first_node_in_group("player") as Node2D
	GameState.docked.connect(_on_docked)
	GameState.undocked.connect(_on_undocked)


func _physics_process(delta: float) -> void:
	var ship := _ship
	if not ship:
		return

	global_position = ship.global_position

	_current_rotation = lerp_angle(_current_rotation, ship.global_rotation, rotation_smoothing * delta)
	global_rotation = _current_rotation

	var speed := (ship as RigidBody2D).linear_velocity.length() if ship is RigidBody2D else 0.0
	var base_zoom_target := clampf(zoom_max - speed * zoom_speed_factor, zoom_min, zoom_max)
	var dock_zoom_factor := lerpf(1.0, _get_dock_zoom_multiplier(), _dock_zoom_weight)
	var target_zoom := clampf(base_zoom_target * dock_zoom_factor, zoom_min, dock_zoom)

	var smoothing := zoom_out_smoothing if target_zoom < zoom.x else zoom_smoothing
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), smoothing * delta)


func _on_docked() -> void:
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_zoom_tween.tween_property(self, "_dock_zoom_weight", 1.0, dock_zoom_duration)
	_zoom_tween.finished.connect(func() -> void:
		_zoom_tween = null
	)


func _on_undocked() -> void:
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_zoom_tween.tween_property(self, "_dock_zoom_weight", 0.0, undock_zoom_duration)
	_zoom_tween.finished.connect(func() -> void:
		_zoom_tween = null
	)


func _get_dock_zoom_multiplier() -> float:
	if is_zero_approx(zoom_max):
		return 1.0
	return dock_zoom / zoom_max
