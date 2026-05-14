extends RigidBody2D

@export var forward_thrust_force: float = 600.0
@export var reverse_thrust_force: float = 400.0
@export var turn_thrust_force: float = 300.0
@export var truck_mass: float = 2.0
@export var truck_width: float = 60.0
@export var truck_height: float = 100.0
@export var linear_damp_value: float = 0.075
@export var angular_damp_value: float = 0.2
@export var trailer_count: int = 3

var _flames: Dictionary = {}
var _thruster_positions: Dictionary = {}
var _trailers: Array[RigidBody2D] = []

const TRAILER_SCENE := preload("res://scenes/truck/trailer.tscn")


func _ready() -> void:
	gravity_scale = 0.0
	mass = truck_mass
	linear_damp = linear_damp_value
	angular_damp = angular_damp_value
	collision_layer = 1
	collision_mask = 7
	_calculate_thruster_positions()
	_cache_flame_references()
	_update_truck_visuals()
	_spawn_trailers.call_deferred()


func _physics_process(_delta: float) -> void:
	_hide_all_flames()

	if Input.is_action_pressed("thrust_forward"):
		var force := _local_to_global_dir(Vector2(0, -forward_thrust_force))
		apply_force(force, _global_offset("forward_left"))
		apply_force(force, _global_offset("forward_right"))
		_show_flame("forward_left")
		_show_flame("forward_right")

	if Input.is_action_pressed("thrust_reverse"):
		var force := _local_to_global_dir(Vector2(0, reverse_thrust_force))
		apply_force(force, _global_offset("reverse_left"))
		apply_force(force, _global_offset("reverse_right"))
		_show_flame("reverse_left")
		_show_flame("reverse_right")

	if Input.is_action_pressed("turn_left"):
		apply_force(
			_local_to_global_dir(Vector2(turn_thrust_force, 0)),
			_global_offset("turn_bl")
		)
		apply_force(
			_local_to_global_dir(Vector2(-turn_thrust_force, 0)),
			_global_offset("turn_tr")
		)
		_show_flame("turn_bl")
		_show_flame("turn_tr")

	if Input.is_action_pressed("turn_right"):
		apply_force(
			_local_to_global_dir(Vector2(-turn_thrust_force, 0)),
			_global_offset("turn_br")
		)
		apply_force(
			_local_to_global_dir(Vector2(turn_thrust_force, 0)),
			_global_offset("turn_tl")
		)
		_show_flame("turn_br")
		_show_flame("turn_tl")


func _calculate_thruster_positions() -> void:
	var hw := truck_width / 2.0
	var hh := truck_height / 2.0
	_thruster_positions = {
		"forward_left": Vector2(-hw, hh),
		"forward_right": Vector2(hw, hh),
		"reverse_left": Vector2(-hw, -hh),
		"reverse_right": Vector2(hw, -hh),
		"turn_bl": Vector2(-hw, hh),
		"turn_tr": Vector2(hw, -hh),
		"turn_br": Vector2(hw, hh),
		"turn_tl": Vector2(-hw, -hh),
	}


func _cache_flame_references() -> void:
	_flames = {
		"forward_left": $Flames/FlameForwardLeft,
		"forward_right": $Flames/FlameForwardRight,
		"reverse_left": $Flames/FlameReverseLeft,
		"reverse_right": $Flames/FlameReverseRight,
		"turn_bl": $Flames/FlameTurnBL,
		"turn_tr": $Flames/FlameTurnTR,
		"turn_br": $Flames/FlameTurnBR,
		"turn_tl": $Flames/FlameTurnTL,
	}
	_hide_all_flames()


func _update_truck_visuals() -> void:
	var body: ColorRect = $TruckBody
	body.size = Vector2(truck_width, truck_height)
	body.position = Vector2(-truck_width / 2.0, -truck_height / 2.0)
	body.color = Color.WHITE

	var col_shape: CollisionShape2D = $CollisionShape2D
	var rect := RectangleShape2D.new()
	rect.size = Vector2(truck_width, truck_height)
	col_shape.shape = rect

	_position_flames()


func _position_flames() -> void:
	var hw := truck_width / 2.0
	var hh := truck_height / 2.0
	var flame_length := 16.0
	var flame_width := 8.0
	var side_flame_length := 12.0
	var side_flame_width := 6.0

	_set_flame_rect("forward_left",
		Vector2(-hw - flame_width / 2.0, hh),
		Vector2(flame_width, flame_length))
	_set_flame_rect("forward_right",
		Vector2(hw - flame_width / 2.0, hh),
		Vector2(flame_width, flame_length))

	_set_flame_rect("reverse_left",
		Vector2(-hw - flame_width / 2.0, -hh - flame_length),
		Vector2(flame_width, flame_length))
	_set_flame_rect("reverse_right",
		Vector2(hw - flame_width / 2.0, -hh - flame_length),
		Vector2(flame_width, flame_length))

	_set_flame_rect("turn_bl",
		Vector2(-hw - side_flame_length, hh - side_flame_width),
		Vector2(side_flame_length, side_flame_width))
	_set_flame_rect("turn_tr",
		Vector2(hw, -hh),
		Vector2(side_flame_length, side_flame_width))
	_set_flame_rect("turn_br",
		Vector2(hw, hh - side_flame_width),
		Vector2(side_flame_length, side_flame_width))
	_set_flame_rect("turn_tl",
		Vector2(-hw - side_flame_length, -hh),
		Vector2(side_flame_length, side_flame_width))


func _set_flame_rect(flame_name: String, pos: Vector2, rect_size: Vector2) -> void:
	var flame: ColorRect = _flames[flame_name]
	flame.position = pos
	flame.size = rect_size
	flame.color = Color.WHITE


func _hide_all_flames() -> void:
	for flame in _flames.values():
		flame.visible = false


func _show_flame(flame_name: String) -> void:
	var flame: ColorRect = _flames[flame_name]
	flame.visible = true
	flame.scale = Vector2(randf_range(0.8, 1.0), randf_range(0.7, 1.0))


func _local_to_global_dir(local_dir: Vector2) -> Vector2:
	return transform.basis_xform(local_dir)


func _global_offset(thruster_name: String) -> Vector2:
	return transform.basis_xform(_thruster_positions[thruster_name])


func _spawn_trailers() -> void:
	if trailer_count <= 0:
		return

	var preceding_body: RigidBody2D = self
	var preceding_hh := truck_height / 2.0

	for i in trailer_count:
		var trailer: RigidBody2D = TRAILER_SCENE.instantiate()
		trailer.name = "Trailer_%d" % (i + 1)

		var trailer_hh: float = trailer.trailer_height / 2.0
		var hook_length: float = trailer.hook_arm_length
		var offset_distance := preceding_hh + hook_length + trailer_hh
		var offset := preceding_body.transform.basis_xform(Vector2(0, offset_distance))
		trailer.global_position = preceding_body.global_position + offset
		trailer.global_rotation = preceding_body.global_rotation

		get_parent().add_child(trailer)

		var joint := PinJoint2D.new()
		joint.name = "TrailerJoint_%d" % (i + 1)
		var joint_offset := preceding_body.transform.basis_xform(Vector2(0, preceding_hh))
		joint.global_position = preceding_body.global_position + joint_offset
		joint.node_a = preceding_body.get_path()
		joint.node_b = trailer.get_path()
		joint.softness = 0.0
		get_parent().add_child(joint)

		_trailers.append(trailer)
		preceding_body = trailer
		preceding_hh = trailer_hh
