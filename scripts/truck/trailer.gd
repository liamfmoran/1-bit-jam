extends RigidBody2D

@export var trailer_mass: float = 5.0
@export var trailer_width: float = 60.0
@export var trailer_height: float = 80.0
@export var hook_arm_length: float = 30.0
@export var hook_arm_width: float = 8.0
@export var linear_damp_value: float = 0.5
@export var angular_damp_value: float = 3.0
@export var lateral_friction: float = 15.0
@export var stabilization_thrust: float = 500.0
@export var stabilization_damping: float = 250.0

var preceding_body: RigidBody2D
var preceding_half_height: float = 50.0
var _flames: Dictionary = {}


func _ready() -> void:
	gravity_scale = 0.0
	mass = trailer_mass
	linear_damp = linear_damp_value
	angular_damp = angular_damp_value
	collision_layer = 1
	collision_mask = 7
	_cache_flame_references()
	_update_trailer_visuals()


func _physics_process(_delta: float) -> void:
	_hide_all_flames()

	# Lateral friction: prevent sideways sliding
	var lateral_dir := transform.basis_xform(Vector2(1, 0))
	var lateral_speed := linear_velocity.dot(lateral_dir)
	apply_central_force(-lateral_dir * lateral_speed * lateral_friction * mass)

	if not preceding_body or not is_instance_valid(preceding_body):
		return

	# Steer nose toward the pivot point on the preceding body's back
	var pivot := preceding_body.to_global(Vector2(0, preceding_half_height))
	var nose := to_global(Vector2(0, -trailer_height / 2.0 - hook_arm_length))
	var desired_dir := (pivot - nose).normalized()
	var facing := transform.basis_xform(Vector2(0, -1)).normalized()

	var cross := facing.cross(desired_dir)
	var correction := cross * stabilization_thrust - angular_velocity * stabilization_damping

	if absf(correction) > 1.0:
		apply_torque(correction)
		if correction < 0:
			_show_flame("turn_bl")
			_show_flame("turn_tr")
		else:
			_show_flame("turn_br")
			_show_flame("turn_tl")


func _cache_flame_references() -> void:
	_flames = {
		"turn_bl": $Flames/FlameTurnBL,
		"turn_tr": $Flames/FlameTurnTR,
		"turn_br": $Flames/FlameTurnBR,
		"turn_tl": $Flames/FlameTurnTL,
	}
	_hide_all_flames()


func _update_trailer_visuals() -> void:
	var hw := trailer_width / 2.0
	var hh := trailer_height / 2.0

	var body: ColorRect = $TrailerBody
	body.size = Vector2(trailer_width, trailer_height)
	body.position = Vector2(-hw, -hh)
	body.color = Color.WHITE

	var arm: ColorRect = $HookArm
	arm.size = Vector2(hook_arm_width, hook_arm_length)
	arm.position = Vector2(-hook_arm_width / 2.0, -hh - hook_arm_length)
	arm.color = Color.WHITE

	var col_shape: CollisionShape2D = $CollisionShape2D
	var rect := RectangleShape2D.new()
	rect.size = Vector2(trailer_width, trailer_height)
	col_shape.shape = rect

	_position_flames()


func _position_flames() -> void:
	var hw := trailer_width / 2.0
	var hh := trailer_height / 2.0
	var side_flame_length := 12.0
	var side_flame_width := 6.0

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
