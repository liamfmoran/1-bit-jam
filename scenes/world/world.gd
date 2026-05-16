extends Node2D

@export var sun_direction: Vector3 = Vector3(0.0, -1.0, 0.4)

static var _param_added := false

func _ready() -> void:
	if not _param_added:
		RenderingServer.global_shader_parameter_add("sun_direction", RenderingServer.GLOBAL_VAR_TYPE_VEC3, sun_direction)
		_param_added = true
	RenderingServer.global_shader_parameter_set("sun_direction", sun_direction)


func _exit_tree() -> void:
	_param_added = false
