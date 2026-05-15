extends RigidBody2D

@export var thrust_force: float = 400.0
@export var rotation_thrust_force: float = 300.0
@export var brake_force: float = 800.0

const ENGINE_RL := Vector2(-10.0, 40.0) #Rear Left
const ENGINE_RR := Vector2(10.0, 40.0) #Rear Right
const ENGINE_FL := Vector2(-10.0, -40.0)
const ENGINE_FR := Vector2(10.0, -40.0)
const ENGINE_SFR := Vector2(20.0, -25.0) 
const ENGINE_SFL := Vector2(-20.0, -25.0) #Side Forward Left

const ENGINE_SRR := Vector2(20.0, 25.0) 
const ENGINE_SRL := Vector2(-20.0, 25.0) #Side Rear Left

@onready var flame_rl: ColorRect = $Flames/FlameRL
@onready var flame_rr: ColorRect = $Flames/FlameRR
@onready var flame_fl: ColorRect = $Flames/FlameFL
@onready var flame_fr: ColorRect = $Flames/FlameFR
@onready var flame_sfr: ColorRect = $Flames/FlameSFR
@onready var flame_sfl: ColorRect = $Flames/FlameSFL
@onready var flame_srr: ColorRect = $Flames/FlameSRR
@onready var flame_srl: ColorRect = $Flames/FlameSRL

@onready var ship_size = $Hull.size #we can use this to call the dimensions to where to put the boosters?

func _physics_process(_delta: float) -> void:
	var forward_dir := -transform.y
	var thrusting_forward := Input.is_action_pressed("thrust_forward")
	var thrusting_reverse := Input.is_action_pressed("thrust_reverse")
	var turning_left := Input.is_action_pressed("turn_left")
	var turning_right := Input.is_action_pressed("turn_right")
	var braking := Input.is_action_pressed('break')

	if braking and linear_velocity.length_squared() > 1.0:
		var brake_dir := -linear_velocity.normalized()
		apply_central_force(brake_dir * brake_force)

	if braking and linear_velocity.length_squared() < 0.5: #snaps the momentum to 0
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0



	if thrusting_forward:
		apply_force(forward_dir * thrust_force, ENGINE_RL.rotated(rotation))
		apply_force(forward_dir * thrust_force, ENGINE_RR.rotated(rotation))

	if thrusting_reverse:
		apply_force(-forward_dir * thrust_force, ENGINE_FL.rotated(rotation))
		apply_force(-forward_dir * thrust_force, ENGINE_FR.rotated(rotation))

	if turning_left:
		apply_force(forward_dir * rotation_thrust_force, ENGINE_SFR.rotated(rotation))
		apply_force(-forward_dir * rotation_thrust_force, ENGINE_SRL.rotated(rotation))

	if turning_right:
		apply_force(forward_dir * rotation_thrust_force, ENGINE_SFL.rotated(rotation))
		apply_force(-forward_dir * rotation_thrust_force, ENGINE_SRR.rotated(rotation))


	_update_flames(thrusting_forward, thrusting_reverse, turning_left, turning_right, braking)


func _update_flames(forward: bool, reverse: bool, left: bool, right: bool, brake: bool) -> void:
	flame_rl.visible = forward or brake
	flame_rr.visible = forward or brake
	flame_fl.visible = reverse or brake
	flame_fr.visible = reverse or brake
	flame_sfr.visible = left or brake
	flame_sfl.visible = right or brake
	flame_srl.visible = left or brake
	flame_srr.visible = right or brake
