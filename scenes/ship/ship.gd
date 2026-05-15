extends RigidBody2D

@export var rear_thrust_force: float = 120000.0
@export var front_thrust_force: float = 100000.0
@export var brake_force: float = 160000.0
@export var brake_gain: float = 500.0
@export var stabilizer_force: float = 24000.0
@export var angular_stab_gain: float = 10.0
@export var gimbal_max_angle: float = 20.0
@export var gimbal_speed: float = 8.0
@export var lateral_rcs_gain: float = 5.0
@export var lateral_rcs_max: float = 100000.0
@export var steering_ratio: float = 0.35

const FLAME_MAIN_W := 8.0
const FLAME_MAIN_L := 36.0
const FLAME_AUX_W  := 5.0
const FLAME_AUX_L  := 12.0

const FLAME_GROW_RATE   := 5.0   # tip growth speed when thrusting (t-units/sec)
const FLAME_DRIFT_RATE  := 2.5   # detached window center drift speed
const FLAME_SHRINK_RATE := 2.0   # detached window half-length shrink speed
const FLAME_FADE_RATE   := 7.0   # opacity lerp-to-zero rate when detached
const FLAME_SCALE       := 1.8   # rect extends this many times the flame length so the
                                 # drifting window fades out before hitting the UV boundary

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

const SHIP_SHADER  := preload("res://shaders/ship.gdshader")
const FLAME_SHADER := preload("res://shaders/flame.gdshader")

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


var gimbal_angle: float = 0.0
var _hull_mat: ShaderMaterial
var _flame_mats:       Dictionary  # ColorRect -> ShaderMaterial
var _flame_base:       Dictionary  # ColorRect -> float
var _flame_tip:        Dictionary  # ColorRect -> float
var _flame_opacity:    Dictionary  # ColorRect -> float
var _flame_tgt:        Dictionary  # ColorRect -> float (0 = off, 0-1 = thrust level)
var _flame_was_firing: Dictionary  # ColorRect -> bool (edge-detect cutoff for puff)
var _flame_puffs:      Dictionary  # ColorRect -> CPUParticles2D
var _all_flames: Array[ColorRect]

func _ready() -> void:
	add_to_group("player")
	var mat := ShaderMaterial.new()
	mat.shader = SHIP_SHADER
	$Hull.material = mat
	$Logo.material = mat
	_hull_mat = mat
	_setup_thruster_visuals()

func _process(delta: float) -> void:
	_hull_mat.set_shader_parameter("ship_rotation", rotation)
	_tick_flame_intensities(delta)

func _tick_flame_intensities(delta: float) -> void:
	for flame: ColorRect in _all_flames:
		var tgt:        float = _flame_tgt[flame]
		var base:       float = _flame_base[flame]
		var tip:        float = _flame_tip[flame]
		var op:         float = _flame_opacity[flame]
		var was_firing: bool  = _flame_was_firing[flame]

		if tgt > 0.0:
			# Firing: base locked to nozzle, tip grows toward target
			base = 0.0
			tip  = move_toward(tip, tgt, FLAME_GROW_RATE * delta)
			op   = 1.0
			_flame_was_firing[flame] = true
		else:
			if was_firing:
				# Edge: thrust just cut — fire the cutoff puff
				_flame_puffs[flame].emitting = true
				_flame_was_firing[flame] = false
			if tip > 0.005 and op > 0.01:
				# Detached blob: center drifts away while window shrinks and fades
				var half_len := (tip - base) * 0.5
				var center   := (tip + base) * 0.5
				center   += FLAME_DRIFT_RATE  * delta
				half_len  = max(0.0, half_len - FLAME_SHRINK_RATE * delta)
				base = center - half_len
				tip  = center + half_len
				op   = lerp(op, 0.0, FLAME_FADE_RATE * delta)
				if half_len < 0.01 or op < 0.01:
					base = 0.0
					tip  = 0.0
					op   = 0.0
			else:
				base = 0.0
				tip  = 0.0
				op   = 0.0

		_flame_base[flame]    = base
		_flame_tip[flame]     = tip
		_flame_opacity[flame] = op

		flame.visible = tip > 0.005 and op > 0.01
		if flame.visible:
			var mat: ShaderMaterial = _flame_mats[flame]
			mat.set_shader_parameter("flame_base", base)
			mat.set_shader_parameter("flame_tip",  tip)
			mat.set_shader_parameter("opacity",    op)

func _setup_thruster_visuals() -> void:
	# Main engines (regular size)
	_place_flame(flame_rl, ENGINE_RL, Vector2(0, 1),  FLAME_MAIN_W, FLAME_MAIN_L, true)
	_place_flame(flame_rr, ENGINE_RR, Vector2(0, 1),  FLAME_MAIN_W, FLAME_MAIN_L, true)
	_place_flame(flame_fl, ENGINE_FL, Vector2(0, -1), FLAME_MAIN_W, FLAME_MAIN_L, true)
	_place_flame(flame_fr, ENGINE_FR, Vector2(0, -1), FLAME_MAIN_W, FLAME_MAIN_L, true)
	# Aux thrusters (smaller)
	_place_flame(flame_sfr,   ENGINE_SFR,   Vector2(1, 0),  FLAME_AUX_W, FLAME_AUX_L, false)
	_place_flame(flame_sfl,   ENGINE_SFL,   Vector2(-1, 0), FLAME_AUX_W, FLAME_AUX_L, false)
	_place_flame(flame_srr,   ENGINE_SRR,   Vector2(1, 0),  FLAME_AUX_W, FLAME_AUX_L, false)
	_place_flame(flame_srl,   ENGINE_SRL,   Vector2(-1, 0), FLAME_AUX_W, FLAME_AUX_L, false)
	_place_flame(flame_lat_r, ENGINE_RCS_R, Vector2(1, 0),  FLAME_AUX_W, FLAME_AUX_L, false)
	_place_flame(flame_lat_l, ENGINE_RCS_L, Vector2(-1, 0), FLAME_AUX_W, FLAME_AUX_L, false)
	# Pivot offsets for gimbaling flames (nozzle mouth stays fixed during rotation)
	flame_rl.pivot_offset = Vector2(FLAME_MAIN_W * 0.5, 0.0)
	flame_rr.pivot_offset = Vector2(FLAME_MAIN_W * 0.5, 0.0)
	flame_fl.pivot_offset = Vector2(FLAME_MAIN_W * 0.5, FLAME_MAIN_L * FLAME_SCALE)
	flame_fr.pivot_offset = Vector2(FLAME_MAIN_W * 0.5, FLAME_MAIN_L * FLAME_SCALE)

func _place_flame(flame: ColorRect, engine_pos: Vector2, exhaust_dir: Vector2, w: float, l: float, is_main: bool) -> void:
	var rl := l * FLAME_SCALE  # extended rect length gives room for drift past t=1
	if exhaust_dir.y > 0.0:       # exhausts down
		flame.size = Vector2(w, rl)
		flame.position = engine_pos + Vector2(-w * 0.5, 0.0)
	elif exhaust_dir.y < 0.0:     # exhausts up
		flame.size = Vector2(w, rl)
		flame.position = engine_pos + Vector2(-w * 0.5, -rl)
	elif exhaust_dir.x > 0.0:     # exhausts right
		flame.size = Vector2(rl, w)
		flame.position = engine_pos + Vector2(0.0, -w * 0.5)
	else:                          # exhausts left
		flame.size = Vector2(rl, w)
		flame.position = engine_pos + Vector2(-rl, -w * 0.5)
	var mat := ShaderMaterial.new()
	mat.shader = FLAME_SHADER
	mat.set_shader_parameter("is_horizontal", exhaust_dir.x != 0.0)
	mat.set_shader_parameter("is_flipped", exhaust_dir.x < 0.0 or exhaust_dir.y < 0.0)
	mat.set_shader_parameter("speed",       1.5 if is_main else 2.5)
	mat.set_shader_parameter("turbulence",  0.7 if is_main else 1.1)
	mat.set_shader_parameter("rect_scale",  FLAME_SCALE)
	mat.set_shader_parameter("flame_base",  0.0)
	mat.set_shader_parameter("flame_tip",   0.0)
	mat.set_shader_parameter("opacity",     0.0)
	flame.visible = false
	flame.material = mat
	_flame_mats[flame]       = mat
	_flame_base[flame]       = 0.0
	_flame_tip[flame]        = 0.0
	_flame_opacity[flame]    = 0.0
	_flame_tgt[flame]        = 0.0
	_flame_was_firing[flame] = false
	var puff := CPUParticles2D.new()
	puff.emitting      = false
	puff.one_shot      = true
	puff.amount        = 6 if is_main else 4
	puff.lifetime      = 0.45 if is_main else 0.3
	puff.explosiveness = 0.85
	puff.direction     = exhaust_dir
	puff.spread        = 30.0
	puff.gravity       = Vector2.ZERO
	puff.initial_velocity_min = 50.0 if is_main else 30.0
	puff.initial_velocity_max = 110.0 if is_main else 65.0
	puff.scale_amount_min = 1.0
	puff.scale_amount_max = 3.0 if is_main else 2.0
	puff.position      = engine_pos
	var grad := Gradient.new()
	grad.set_color(0, Color.WHITE)
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	puff.color_ramp = grad
	add_child(puff)
	_flame_puffs[flame] = puff
	_all_flames.append(flame)

func _physics_process(delta: float) -> void:
	var forward_dir := -transform.y
	var turn_input := Input.get_axis("turn_left", "turn_right")
	var thrusting_forward := Input.is_action_pressed("thrust_forward")
	var thrusting_reverse := Input.is_action_pressed("thrust_reverse")
	var braking := Input.is_action_pressed("brake")

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

	_update_flames(thrusting_forward, thrusting_reverse, fire_left, fire_right, stab_f / stabilizer_force)


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


func _update_flames(forward: bool, reverse: bool, fire_left: bool, fire_right: bool, stab_ratio: float) -> void:
	_flame_tgt[flame_rl]    = 1.0 if forward    else 0.0
	_flame_tgt[flame_rr]    = 1.0 if forward    else 0.0
	_flame_tgt[flame_fl]    = 1.0 if reverse    else 0.0
	_flame_tgt[flame_fr]    = 1.0 if reverse    else 0.0
	_flame_tgt[flame_sfr]   = stab_ratio if fire_left  else 0.0
	_flame_tgt[flame_srl]   = stab_ratio if fire_left  else 0.0
	_flame_tgt[flame_sfl]   = stab_ratio if fire_right else 0.0
	_flame_tgt[flame_srr]   = stab_ratio if fire_right else 0.0
	var lat_spd := transform.x.dot(linear_velocity)
	if forward or reverse:
		var lat_ratio := minf(absf(lat_spd) * lateral_rcs_gain, lateral_rcs_max) / lateral_rcs_max
		_flame_tgt[flame_lat_r] = lat_ratio if lat_spd > 0.1  else 0.0
		_flame_tgt[flame_lat_l] = lat_ratio if lat_spd < -0.1 else 0.0
	else:
		_flame_tgt[flame_lat_r] = 0.0
		_flame_tgt[flame_lat_l] = 0.0
	var gimbal_rad := deg_to_rad(gimbal_angle)
	flame_rl.rotation = gimbal_rad
	flame_rr.rotation = gimbal_rad
	flame_fl.rotation = gimbal_rad
	flame_fr.rotation = gimbal_rad


func _update_flames_braking(forward_dir: Vector2, turn_input: float) -> void:
	var fwd_spd := forward_dir.dot(linear_velocity)
	var lat_spd := transform.x.dot(linear_velocity)

	_flame_tgt[flame_fl] = clamp(absf(fwd_spd) / 10.0, 0.0, 1.0) if fwd_spd > 0.5  else 0.0
	_flame_tgt[flame_fr] = clamp(absf(fwd_spd) / 10.0, 0.0, 1.0) if fwd_spd > 0.5  else 0.0
	_flame_tgt[flame_rl] = 1.0 if fwd_spd < -0.5 else 0.0
	_flame_tgt[flame_rr] = 1.0 if fwd_spd < -0.5 else 0.0

	if absf(turn_input) > 0.1:
		var fire_left := turn_input < 0.0
		_flame_tgt[flame_sfr] = 1.0 if fire_left      else 0.0
		_flame_tgt[flame_srl] = 1.0 if fire_left      else 0.0
		_flame_tgt[flame_sfl] = 1.0 if not fire_left  else 0.0
		_flame_tgt[flame_srr] = 1.0 if not fire_left  else 0.0
	else:
		var stab_l := angular_velocity > 0.05
		var stab_r := angular_velocity < -0.05
		_flame_tgt[flame_sfr] = 1.0 if stab_l else 0.0
		_flame_tgt[flame_srr] = 1.0 if stab_r else 0.0
		_flame_tgt[flame_sfl] = 1.0 if stab_r else 0.0
		_flame_tgt[flame_srl] = 1.0 if stab_l else 0.0

	_flame_tgt[flame_lat_r] = 1.0 if lat_spd > 0.3  else 0.0
	_flame_tgt[flame_lat_l] = 1.0 if lat_spd < -0.3 else 0.0

	var gimbal_rad := deg_to_rad(gimbal_angle)
	flame_rl.rotation = gimbal_rad
	flame_rr.rotation = gimbal_rad
	flame_fl.rotation = gimbal_rad
	flame_fr.rotation = gimbal_rad
