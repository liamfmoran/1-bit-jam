extends RigidBody2D

@export var trailer_mass: float = 5.0
@export var trailer_width: float = 60.0
@export var trailer_height: float = 80.0
@export var hook_arm_length: float = 30.0
@export var hook_arm_width: float = 8.0
@export var linear_damp_value: float = 0.125
@export var angular_damp_value: float = 0.25


func _ready() -> void:
	gravity_scale = 0.0
	mass = trailer_mass
	linear_damp = linear_damp_value
	angular_damp = angular_damp_value
	collision_layer = 1
	collision_mask = 7
	_update_trailer_visuals()


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
