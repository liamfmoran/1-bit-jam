extends ColorRect

@onready var _truck: RigidBody2D = get_node("/root/Main/Truck")
@onready var _mat: ShaderMaterial = material as ShaderMaterial
var _smoothed_angular_vel: float = 0.0


func _ready() -> void:
	var vp_size := get_viewport_rect().size
	var screen_target := vp_size / 2.0 + Vector2(0, _truck.camera_forward_offset)
	_mat.set_shader_parameter("screen_target", screen_target)


func _process(delta: float) -> void:
	var raw_angular_vel: float = angle_difference(_truck._cam_rotation, _truck.global_rotation) * _truck.camera_rotation_smoothing
	_smoothed_angular_vel = lerpf(_smoothed_angular_vel, raw_angular_vel, delta * 6.0)
	var cam_angular_vel: float = _smoothed_angular_vel if absf(_smoothed_angular_vel) > 0.3 else 0.0
	_mat.set_shader_parameter("truck_position", _truck.global_position)
	_mat.set_shader_parameter("cam_rotation", _truck._cam_rotation)
	_mat.set_shader_parameter("cam_zoom", _truck._cam_zoom)
	_mat.set_shader_parameter("truck_velocity", _truck.linear_velocity)
	_mat.set_shader_parameter("cam_angular_velocity", cam_angular_vel)
