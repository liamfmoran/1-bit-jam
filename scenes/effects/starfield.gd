extends ColorRect

var _ship: Node2D

func _ready() -> void:
	_ship = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_ship):
		_ship = get_tree().get_first_node_in_group("player") as Node2D
	if not _ship:
		return
	material.set_shader_parameter("ship_position", _ship.global_position)
	material.set_shader_parameter("ship_velocity", (_ship as RigidBody2D).linear_velocity if _ship is RigidBody2D else Vector2.ZERO)
	var canvas_pos := get_viewport().get_canvas_transform() * _ship.global_position
	material.set_shader_parameter("player_screen_uv", canvas_pos / get_viewport().get_visible_rect().size)

	var cam := get_viewport().get_camera_2d()
	if cam:
		material.set_shader_parameter("camera_rotation", cam.global_rotation)
