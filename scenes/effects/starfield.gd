extends ColorRect

func _physics_process(_delta: float) -> void:
	var ship: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if not ship:
		return
	material.set_shader_parameter("ship_position", ship.global_position)
	material.set_shader_parameter("ship_velocity", (ship as RigidBody2D).linear_velocity)

	var cam := get_viewport().get_camera_2d()
	if cam:
		material.set_shader_parameter("camera_rotation", cam.global_rotation)
