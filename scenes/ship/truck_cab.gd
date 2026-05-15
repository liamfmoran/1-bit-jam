extends RigidBody2D

@export var thrust_force: float = 400.0
@export var rotation_thrust_force: float = 300.0

const ENGINE_RL := Vector2(-10.0, 40.0)
const ENGINE_RR := Vector2(10.0, 40.0)
const ENGINE_FL := Vector2(-10.0, -40.0)
const ENGINE_FR := Vector2(10.0, -40.0)
const ENGINE_SFR := Vector2(20.0, -25.0)
const ENGINE_SFL := Vector2(-20.0, -25.0)

@onready var flame_rl: ColorRect = $Flames/FlameRL
@onready var flame_rr: ColorRect = $Flames/FlameRR
@onready var flame_fl: ColorRect = $Flames/FlameFL
@onready var flame_fr: ColorRect = $Flames/FlameFR
@onready var flame_sfr: ColorRect = $Flames/FlameSFR
@onready var flame_sfl: ColorRect = $Flames/FlameSFL


func _physics_process(_delta: float) -> void:
	var forward_dir := -transform.y
	var thrusting_forward := Input.is_action_pressed("thrust_forward")
	var thrusting_reverse := Input.is_action_pressed("thrust_reverse")
	var turning_left := Input.is_action_pressed("turn_left")
	var turning_right := Input.is_action_pressed("turn_right")

	if thrusting_forward:
		apply_force(forward_dir * thrust_force, ENGINE_RL.rotated(rotation))
		apply_force(forward_dir * thrust_force, ENGINE_RR.rotated(rotation))

	if thrusting_reverse:
		apply_force(-forward_dir * thrust_force, ENGINE_FL.rotated(rotation))
		apply_force(-forward_dir * thrust_force, ENGINE_FR.rotated(rotation))

	if turning_left:
		apply_force(forward_dir * rotation_thrust_force, ENGINE_SFR.rotated(rotation))

	if turning_right:
		apply_force(forward_dir * rotation_thrust_force, ENGINE_SFL.rotated(rotation))

	_update_flames(thrusting_forward, thrusting_reverse, turning_left, turning_right)


func _update_flames(forward: bool, reverse: bool, left: bool, right: bool) -> void:
	flame_rl.visible = forward
	flame_rr.visible = forward
	flame_fl.visible = reverse
	flame_fr.visible = reverse
	flame_sfr.visible = left
	flame_sfl.visible = right
