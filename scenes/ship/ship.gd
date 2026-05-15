extends RigidBody2D

@export var rear_thrust_force: float = 600.0
@export var front_thrust_force: float = 500.0
@export var brake_force: float = 800.0
@export var brake_gain: float = 2.5
@export var stabilizer_force: float = 120.0
@export var angular_stab_gain: float = 10.0
@export var gimbal_max_angle: float = 20.0
@export var gimbal_speed: float = 8.0
@export var lateral_rcs_gain: float = 5.0
@export var lateral_rcs_max: float = 500.0
@export var steering_ratio: float = 0.35

const FLAME_MAIN_W := 4.0
const FLAME_MAIN_L := 12.0
const FLAME_AUX_W  := 3.0
const FLAME_AUX_L  := 8.0

const ENGINE_RL := Vector2(-10.0, 40.0) #Rear Left
const ENGINE_RR := Vector2(10.0, 40.0) #Rear Right
const ENGINE_FL := Vector2(-10.0, -40.0)
const ENGINE_FR := Vector2(10.0, -40.0)
const ENGINE_SFR := Vector2(20.0, -25.0)
const ENGINE_SFL := Vector2(-20.0, -25.0) #Side Forward Left
const ENGINE_SRR := Vector2(20.0, 25.0)
const ENGINE_SRL := Vector2(-20.0, 25.0) #Side Rear Left
const ENGINE_RCS_R := Vector2(20.0, 0.0)  # lateral RCS, fires -X (pushes ship left)
const ENGINE_RCS_L := Vector2(-20.0, 0.0) # lateral RCS, fires +X (pushes ship right)

@onready var flame_rl: ColorRect = $Flames/FlameRL
@onready var flame_rr: ColorRect = $Flames/FlameRR
@onready var flame_fl: ColorRect = $Flames/FlameFL
@onready var flame_fr: ColorRect = $Flames/FlameFR
@onready var flame_sfr: ColorRect = $Flames/FlameSFR
@onready var flame_sfl: ColorRect = $Flames/FlameSFL
@onready var flame_srr: ColorRect = $Flames/FlameSRR
@onready var flame_srl: ColorRect = $Flames/FlameSRL
@onready var flame_lat_r: ColorRect = $Flames/FlameLAT_R
@onready var flame_lat_l: ColorRect = $Flames/FlameLAT_L

@onready var ship_size = $Hull.size

var gimbal_angle: float = 0.0

func _ready() -> void:
	_setup_thruster_visuals()

func _setup_thruster_visuals() -> void:
	# Main engines (regular size)
	_place_flame(flame_rl, ENGINE_RL, Vector2(0, 1),  FLAME_MAIN_W, FLAME_MAIN_L)
	_place_flame(flame_rr, ENGINE_RR, Vector2(0, 1),  FLAME_MAIN_W, FLAME_MAIN_L)
	_place_flame(flame_fl, ENGINE_FL, Vector2(0, -1), FLAME_MAIN_W, FLAME_MAIN_L)
	_place_flame(flame_fr, ENGINE_FR, Vector2(0, -1), FLAME_MAIN_W, FLAME_MAIN_L)
	# Aux thrusters (smaller)
	_place_flame(flame_sfr,   ENGINE_SFR,   Vector2(1, 0),  FLAME_AUX_W, FLAME_AUX_L)
	_place_flame(flame_sfl,   ENGINE_SFL,   Vector2(-1, 0), FLAME_AUX_W, FLAME_AUX_L)
	_place_flame(flame_srr,   ENGINE_SRR,   Vector2(1, 0),  FLAME_AUX_W, FLAME_AUX_L)
	_place_flame(flame_srl,   ENGINE_SRL,   Vector2(-1, 0), FLAME_AUX_W, FLAME_AUX_L)
	_place_flame(flame_lat_r, ENGINE_RCS_R, Vector2(1, 0),  FLAME_AUX_W, FLAME_AUX_L)
	_place_flame(flame_lat_l, ENGINE_RCS_L, Vector2(-1, 0), FLAME_AUX_W, FLAME_AUX_L)
	# Pivot offsets for gimbaling flames (nozzle mouth stays fixed during rotation)
	flame_rl.pivot_offset = Vector2(FLAME_MAIN_W * 0.5, 0.0)
	flame_rr.pivot_offset = Vector2(FLAME_MAIN_W * 0.5, 0.0)
	flame_fl.pivot_offset = Vector2(FLAME_MAIN_W * 0.5, FLAME_MAIN_L)
	flame_fr.pivot_offset = Vector2(FLAME_MAIN_W * 0.5, FLAME_MAIN_L)

func _place_flame(flame: ColorRect, engine_pos: Vector2, exhaust_dir: Vector2, w: float, l: float) -> void:
	if exhaust_dir.y > 0.0:       # exhausts down
		flame.size = Vector2(w, l)
		flame.position = engine_pos + Vector2(-w * 0.5, 0.0)
	elif exhaust_dir.y < 0.0:     # exhausts up
		flame.size = Vector2(w, l)
		flame.position = engine_pos + Vector2(-w * 0.5, -l)
	elif exhaust_dir.x > 0.0:     # exhausts right
		flame.size = Vector2(l, w)
		flame.position = engine_pos + Vector2(0.0, -w * 0.5)
	else:                          # exhausts left
		flame.size = Vector2(l, w)
		flame.position = engine_pos + Vector2(-l, -w * 0.5)

func _physics_process(delta: float) -> void:
	var forward_dir := -transform.y
	var turn_input := Input.get_axis("turn_left", "turn_right")
	var thrusting_forward := Input.is_action_pressed("thrust_forward")
	var thrusting_reverse := Input.is_action_pressed("thrust_reverse")
	var braking := Input.is_action_pressed("break")

	# Gimbal lerps to 0 during braking so flames return to center
	var gimbal_target := 0.0 if braking else -turn_input * gimbal_max_angle
	gimbal_angle = lerp(gimbal_angle, gimbal_target, gimbal_speed * delta)

	if braking:
		_brake(forward_dir, turn_input)
		_update_flames_braking(forward_dir, turn_input)
		return

	var steer := transform.x * sin(deg_to_rad(gimbal_angle)) * steering_ratio

	if thrusting_forward:
		apply_central_force(forward_dir * rear_thrust_force)
		apply_force(steer * rear_thrust_force, Vector2(0.0, 40.0).rotated(rotation))

	if thrusting_reverse:
		apply_central_force(-forward_dir * front_thrust_force)
		apply_force(-steer * front_thrust_force, Vector2(0.0, -40.0).rotated(rotation))

	if thrusting_forward or thrusting_reverse:
		_apply_lateral_rcs()

	var fire_left := false
	var fire_right := false
	var stab_f := stabilizer_force

	if abs(turn_input) > 0.1 and not thrusting_forward and not thrusting_reverse:
		if turn_input < 0.0:
			fire_left = true
		else:
			fire_right = true
	elif abs(turn_input) < 0.1 and abs(angular_velocity) > 0.5:
		stab_f = minf(absf(angular_velocity) * angular_stab_gain, stabilizer_force)
		if angular_velocity > 0.0:
			fire_left = true
		else:
			fire_right = true

	if fire_left:
		apply_force(forward_dir * stab_f, ENGINE_SFR.rotated(rotation))
		apply_force(-forward_dir * stab_f, ENGINE_SRL.rotated(rotation))
	if fire_right:
		apply_force(forward_dir * stab_f, ENGINE_SFL.rotated(rotation))
		apply_force(-forward_dir * stab_f, ENGINE_SRR.rotated(rotation))

	_update_flames(thrusting_forward, thrusting_reverse, fire_left, fire_right)


func _apply_lateral_rcs() -> void:
	var lat_spd := transform.x.dot(linear_velocity)
	if absf(lat_spd) < 0.1:
		return
	var f := minf(absf(lat_spd) * lateral_rcs_gain, lateral_rcs_max)
	if lat_spd > 0.0:
		apply_force(-transform.x * f, ENGINE_RCS_R.rotated(rotation))
	else:
		apply_force(transform.x * f, ENGINE_RCS_L.rotated(rotation))


func _brake(forward_dir: Vector2, turn_input: float) -> void:
	var speed := linear_velocity.length()

	if speed > 0.5:
		var f := minf(speed * brake_gain, brake_force)
		apply_central_force(-linear_velocity.normalized() * f)

	if absf(turn_input) > 0.1:
		if turn_input < 0.0:
			apply_force(forward_dir * stabilizer_force, ENGINE_SFR.rotated(rotation))
			apply_force(-forward_dir * stabilizer_force, ENGINE_SRL.rotated(rotation))
		else:
			apply_force(forward_dir * stabilizer_force, ENGINE_SFL.rotated(rotation))
			apply_force(-forward_dir * stabilizer_force, ENGINE_SRR.rotated(rotation))
	else:
		if angular_velocity > 0.05:
			var f := minf(angular_velocity * angular_stab_gain, stabilizer_force)
			apply_force(forward_dir * f, ENGINE_SFR.rotated(rotation))
			apply_force(-forward_dir * f, ENGINE_SRL.rotated(rotation))
		elif angular_velocity < -0.05:
			var f := minf(-angular_velocity * angular_stab_gain, stabilizer_force)
			apply_force(forward_dir * f, ENGINE_SFL.rotated(rotation))
			apply_force(-forward_dir * f, ENGINE_SRR.rotated(rotation))

	if linear_velocity.length_squared() < 1.0 and absf(angular_velocity) < 0.1:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0


func _update_flames(forward: bool, reverse: bool, fire_left: bool, fire_right: bool) -> void:
	flame_rl.visible = forward
	flame_rr.visible = forward
	flame_fl.visible = reverse
	flame_fr.visible = reverse
	flame_sfr.visible = fire_left
	flame_srl.visible = fire_left
	flame_sfl.visible = fire_right
	flame_srr.visible = fire_right
	var lat_spd := transform.x.dot(linear_velocity)
	flame_lat_r.visible = (forward or reverse) and lat_spd > 0.1
	flame_lat_l.visible = (forward or reverse) and lat_spd < -0.1
	var gimbal_rad := deg_to_rad(gimbal_angle)
	flame_rl.rotation = gimbal_rad
	flame_rr.rotation = gimbal_rad
	flame_fl.rotation = gimbal_rad
	flame_fr.rotation = gimbal_rad


func _update_flames_braking(forward_dir: Vector2, turn_input: float) -> void:
	var fwd_spd := forward_dir.dot(linear_velocity)
	var lat_spd := transform.x.dot(linear_velocity)

	flame_fl.visible = fwd_spd > 0.5
	flame_fr.visible = fwd_spd > 0.5
	flame_rl.visible = fwd_spd < -0.5
	flame_rr.visible = fwd_spd < -0.5

	if absf(turn_input) > 0.1:
		var fire_left := turn_input < 0.0
		flame_sfr.visible = fire_left
		flame_srl.visible = fire_left
		flame_sfl.visible = not fire_left
		flame_srr.visible = not fire_left
	else:
		var stab_l := angular_velocity > 0.05
		var stab_r := angular_velocity < -0.05
		flame_sfr.visible = stab_l
		flame_srr.visible = stab_r
		flame_sfl.visible = stab_r
		flame_srl.visible = stab_l

	flame_lat_r.visible = lat_spd > 0.3
	flame_lat_l.visible = lat_spd < -0.3

	var gimbal_rad := deg_to_rad(gimbal_angle)
	flame_rl.rotation = gimbal_rad
	flame_rr.rotation = gimbal_rad
	flame_fl.rotation = gimbal_rad
	flame_fr.rotation = gimbal_rad
