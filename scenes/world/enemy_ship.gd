class_name EnemyShip
extends BaseShip

enum State { PATROL, PURSUE, ATTACK }

const MAX_SPEED := 1200.0
const MAX_PATROL_SPEED := 600.0
const SEPARATION_RADIUS := 150.0
const SEPARATION_STRENGTH := 6000.0
# Force per RCS thruster. Paired thrusters (e.g. SFL+SRR) each have ~15px moment arm,
# so max torque ≈ 30 × RCS_FORCE — tuned to match the original rotation_kp response.
const RCS_FORCE := 2000.0

const ENGINE_RL  := Vector2(-6.0,  24.0)
const ENGINE_RR  := Vector2( 6.0,  24.0)
const ENGINE_SFR := Vector2( 12.0, -15.0)
const ENGINE_SFL := Vector2(-12.0, -15.0)
const ENGINE_SRR := Vector2( 12.0,  15.0)
const ENGINE_SRL := Vector2(-12.0,  15.0)
const ENGINE_LAT_R := Vector2( 12.0,  0.0)
const ENGINE_LAT_L := Vector2(-12.0,  0.0)

const FLAME_MAIN_W := 5.0
const FLAME_MAIN_L := 22.0
const FLAME_AUX_W  := 3.0
const FLAME_AUX_L  := 7.0

const SHIP_SHADER := preload("res://shaders/ship.gdshader")

@export var thrust_force: float = 56000.0
@export var brake_force: float = 40000.0
@export var detection_range: float = 700.0
@export var attack_range: float = 280.0
@export var leash_range: float = 1800.0
@export var min_safe_dist: float = 20.0
@export var rotation_kp: float = 18000.0
@export var rotation_kd: float = 3000.0
@export var lateral_rcs_gain: float = 5.0
@export var lateral_rcs_max: float = 60000.0
@export var debug_log: bool = false

# Per-instance variance set in setup() — breaks the symmetric-ring pattern
var _attack_range_actual: float

# Logging state
var _log_timer: float = 0.0
var _prev_state: State = State.PATROL
var _log_id: String = ""
const LOG_INTERVAL := 0.2

# Per-frame debug values written by sub-functions, read by the log block.
var _dbg_engage: String = "COAST"
var _dbg_desired: float = 0.0
var _dbg_asp: float = 0.0
var _dbg_angle_err: float = 0.0
var _dbg_rcs_level: float = 0.0
var _dbg_lat_spd: float = 0.0

@onready var flame_rl:  ColorRect = $Flames/FlameRL
@onready var flame_rr:  ColorRect = $Flames/FlameRR
@onready var flame_sfl: ColorRect = $Flames/FlameSFL
@onready var flame_sfr: ColorRect = $Flames/FlameSFR
@onready var flame_srl: ColorRect = $Flames/FlameSRL
@onready var flame_srr: ColorRect = $Flames/FlameSRR
@onready var flame_lat_r: ColorRect = $Flames/FlameLAT_R
@onready var flame_lat_l: ColorRect = $Flames/FlameLAT_L

var _state: State = State.PATROL
var _patrol_center: Vector2
var _patrol_radius: float = 500.0
var _patrol_target: Vector2
var _player: RigidBody2D
var _weapon: WeaponComponent
var _hull_mat: ShaderMaterial
var _thrusters: ThrusterVisuals
var _delta: float = 1.0 / 60.0


func _ready() -> void:
	super._ready()
	add_to_group("enemy")
	WorldData.track_ship(self, &"enemy")
	var mat := ShaderMaterial.new()
	mat.shader = SHIP_SHADER
	$Hull.material = mat
	_hull_mat = mat
	_setup_thruster_visuals()


func _process(delta: float) -> void:
	if _hull_mat:
		_hull_mat.set_shader_parameter("ship_rotation", rotation)
	if _thrusters:
		_thrusters.tick(delta)


func _setup_thruster_visuals() -> void:
	_thrusters = ThrusterVisuals.new()
	add_child(_thrusters)
	_thrusters.init(self)
	_thrusters.register(flame_rl,  ENGINE_RL,  Vector2(0, 1),  FLAME_MAIN_W, FLAME_MAIN_L, true)
	_thrusters.register(flame_rr,  ENGINE_RR,  Vector2(0, 1),  FLAME_MAIN_W, FLAME_MAIN_L, true)
	_thrusters.register(flame_sfl, ENGINE_SFL, Vector2(-1, 0), FLAME_AUX_W,  FLAME_AUX_L,  false)
	_thrusters.register(flame_sfr, ENGINE_SFR, Vector2(1, 0),  FLAME_AUX_W,  FLAME_AUX_L,  false)
	_thrusters.register(flame_srl, ENGINE_SRL, Vector2(-1, 0), FLAME_AUX_W,  FLAME_AUX_L,  false)
	_thrusters.register(flame_srr, ENGINE_SRR, Vector2(1, 0),  FLAME_AUX_W,  FLAME_AUX_L,  false)
	_thrusters.register(flame_lat_r, ENGINE_LAT_R, Vector2(1, 0),  FLAME_AUX_W, FLAME_AUX_L, false)
	_thrusters.register(flame_lat_l, ENGINE_LAT_L, Vector2(-1, 0), FLAME_AUX_W, FLAME_AUX_L, false)


func setup(patrol_center: Vector2, patrol_radius: float, player_ship: Node2D, _streamer: Node = null) -> void:
	_patrol_center = patrol_center
	_patrol_radius = patrol_radius
	_player = player_ship as RigidBody2D
	_state = State.PATROL
	_prev_state = State.PATROL
	health = max_health
	var parts := DataLoader.load_ship_parts()
	var weapon_slot := find_child("WeaponSlot") as ShipPartSlot
	if weapon_slot:
		weapon_slot.equip(parts.get("turret_basic"))
	_weapon = find_in_slots(WeaponComponent) as WeaponComponent
	_pick_patrol_target()
	# Each enemy gets a different trigger distance and overshoot depth so they
	# don't all converge on the same radius around the player.
	_attack_range_actual = attack_range + randf_range(-60.0, 80.0)
	_log_id = "E%d" % (get_instance_id() % 1000)


func _pick_patrol_target() -> void:
	var angle := randf() * TAU
	_patrol_target = _patrol_center + Vector2(cos(angle), sin(angle)) * randf_range(0.0, _patrol_radius)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_delta = delta

	var spd := linear_velocity.length()
	var speed_cap := MAX_PATROL_SPEED if _state == State.PATROL else MAX_SPEED
	if spd > speed_cap:
		linear_velocity = linear_velocity * (speed_cap / spd)
	apply_torque(-angular_velocity * 800.0)

	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	# Per-frame force accumulators for logging
	var sep_force := 0.0
	var sep_count := 0
	var main_thrust_active := false

	match _state:
		State.PATROL:
			_patrol_behavior()
			if dist < detection_range:
				_state = State.PURSUE

		State.PURSUE:
			_steer_toward(_player.global_position)
			main_thrust_active = _thrust_toward(_player.global_position)
			if dist < _attack_range_actual:
				_state = State.ATTACK
			elif dist > leash_range:
				_state = State.PATROL

		State.ATTACK:
			var predicted := _predict_player_pos()
			_steer_toward(_player.global_position)
			main_thrust_active = _thrust_to_engagement()
			_try_fire(predicted)
			if dist > leash_range:
				_state = State.PATROL
			elif dist > _attack_range_actual * 1.6 and linear_velocity.dot(to_player.normalized()) < 0.0:
				_state = State.PURSUE

	if _state != State.PATROL:
		_apply_lateral_rcs()

	for node: Variant in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node) or node == self:
			continue
		var d := global_position.distance_to(node.global_position)
		if d < SEPARATION_RADIUS and d > 1.0:
			var falloff := 1.0 - d / SEPARATION_RADIUS
			var f := SEPARATION_STRENGTH * falloff
			apply_central_force((global_position - node.global_position).normalized() * f)
			sep_force += f
			sep_count += 1

	if debug_log:
		if _state != _prev_state:
			print("[enemy %s] STATE %s -> %s  dist=%.0f spd=%.0f atk_r=%.0f" % [
				_log_id, State.keys()[_prev_state], State.keys()[_state],
				dist, spd, _attack_range_actual])
		_log_timer += delta
		if _log_timer >= LOG_INTERVAL:
			_log_timer = 0.0
			var sep_tag := " SEP×%d(%.0f)" % [sep_count, sep_force] if sep_count > 0 else ""
			print("[enemy %s] %s  d=%.0f  asp=%.1f  des=%.1f  lat=%.1f  ang_err=%.3f  rcs=%.2f  avel=%.2f  spd=%.0f  → %s%s" % [
				_log_id, State.keys()[_state],
				dist, _dbg_asp, _dbg_desired, _dbg_lat_spd,
				_dbg_angle_err, _dbg_rcs_level, angular_velocity, spd,
				_dbg_engage, sep_tag])

	_prev_state = _state


func _patrol_behavior() -> void:
	if (_patrol_target - global_position).length() < 60.0:
		_pick_patrol_target()
		return
	_steer_toward(_patrol_target)
	_thrust_toward(_patrol_target)


func _apply_lateral_rcs() -> void:
	var lat_spd := transform.x.dot(linear_velocity)
	if debug_log:
		_dbg_lat_spd = lat_spd
	var f := minf(absf(lat_spd) * lateral_rcs_gain, lateral_rcs_max)
	if f < 1.0:
		_thrusters.set_target(flame_lat_r, 0.0)
		_thrusters.set_target(flame_lat_l, 0.0)
		return
	var ratio := f / lateral_rcs_max
	if lat_spd > 0.0:
		apply_force(-transform.x * f, ENGINE_LAT_R.rotated(rotation))
		_thrusters.set_target(flame_lat_r, ratio)
		_thrusters.set_target(flame_lat_l, 0.0)
	else:
		apply_force(transform.x * f, ENGINE_LAT_L.rotated(rotation))
		_thrusters.set_target(flame_lat_r, 0.0)
		_thrusters.set_target(flame_lat_l, ratio)


# Applies RCS forces from actual thruster positions and sets flame visuals.
# Paired thrusters cancel translation so only torque is produced.
func _steer_toward(target_pos: Vector2) -> void:
	var desired_angle := (target_pos - global_position).angle() + PI / 2.0
	var angle_err := angle_difference(rotation, desired_angle)
	var torque_cmd := angle_err * rotation_kp - angular_velocity * rotation_kd
	var rcs_level := clampf(absf(torque_cmd) / (PI * rotation_kp), 0.0, 1.0)
	if debug_log:
		_dbg_angle_err = angle_err
		_dbg_rcs_level = rcs_level
	if torque_cmd > 0.0:
		# Clockwise: SFL (+X) and SRR (-X)
		apply_force(transform.x * RCS_FORCE * rcs_level, transform.basis_xform(ENGINE_SFL))
		apply_force(-transform.x * RCS_FORCE * rcs_level, transform.basis_xform(ENGINE_SRR))
		_thrusters.set_target(flame_sfl, rcs_level)
		_thrusters.set_target(flame_srr, rcs_level)
		_thrusters.set_target(flame_sfr, 0.0)
		_thrusters.set_target(flame_srl, 0.0)
	else:
		# Counter-clockwise: SFR (-X) and SRL (+X)
		apply_force(-transform.x * RCS_FORCE * rcs_level, transform.basis_xform(ENGINE_SFR))
		apply_force(transform.x * RCS_FORCE * rcs_level, transform.basis_xform(ENGINE_SRL))
		_thrusters.set_target(flame_sfr, rcs_level)
		_thrusters.set_target(flame_srl, rcs_level)
		_thrusters.set_target(flame_sfl, 0.0)
		_thrusters.set_target(flame_srr, 0.0)


# Applies main engine forces from thruster positions and sets flame visuals.
# Returns true when main engines fired.
func _thrust_toward(target_pos: Vector2) -> bool:
	var to_target := target_pos - global_position
	var dist := to_target.length()
	if dist <= min_safe_dist + 20.0:
		_thrusters.set_target(flame_rl, 0.0)
		_thrusters.set_target(flame_rr, 0.0)
		return false
	var desired_speed := clampf(dist * 0.5, 60.0, MAX_SPEED * 0.5)
	var spd_now := linear_velocity.length()
	var approach_speed := linear_velocity.dot(to_target.normalized())
	# Brake on total speed — prevents orbiting from high perpendicular velocity.
	if spd_now > desired_speed + 50.0:
		apply_central_force(-linear_velocity.normalized() * thrust_force * 0.25)
		_thrusters.set_target(flame_rl, 0.0)
		_thrusters.set_target(flame_rr, 0.0)
		return false
	var deficit := desired_speed - approach_speed
	if deficit > 0.0:
		# Proportional throttle: scale thrust with how far below desired we are.
		# Divisor ≈ one-frame velocity change at full thrust, prevents overshoot oscillation.
		var tscale := clampf(deficit / 1000.0, 0.0, 1.0)
		apply_force(-transform.y * thrust_force * tscale * 0.5, transform.basis_xform(ENGINE_RL))
		apply_force(-transform.y * thrust_force * tscale * 0.5, transform.basis_xform(ENGINE_RR))
		_thrusters.set_target(flame_rl, tscale)
		_thrusters.set_target(flame_rr, tscale)
		return tscale > 0.05
	if approach_speed > desired_speed + 50.0:
		apply_central_force(-linear_velocity.normalized() * thrust_force * 0.25)
	_thrusters.set_target(flame_rl, 0.0)
	_thrusters.set_target(flame_rr, 0.0)
	return false


# Hold a comfortable engagement distance: close enough to fire, clear of avoidance.
# Returns true when main engines fired.
func _thrust_to_engagement() -> bool:
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	var target_dist := maxf(_attack_range_actual * 0.7, min_safe_dist * 2.5)
	var approach_speed := linear_velocity.dot(to_player.normalized())
	if debug_log:
		_dbg_asp = approach_speed
		_dbg_engage = "COAST"

	# Desired approach speed: ramps to 0 as dist reaches target_dist.
	var desired := 0.0
	if dist > target_dist:
		desired = clampf((dist - target_dist) * 0.25, 0.0, 180.0)
	if debug_log:
		_dbg_desired = desired

	var err := approach_speed - desired
	if err > 1.0:
		# Exact impulse to reach desired in one frame — no overshoot, no oscillation.
		var f := clampf(err / _delta, 0.0, thrust_force * 0.5)
		apply_central_force(-to_player.normalized() * f)
		if debug_log:
			_dbg_engage = "BRAKE(%.0fN)" % f
		_thrusters.set_target(flame_rl, 0.0)
		_thrusters.set_target(flame_rr, 0.0)
		return false
	elif desired > 10.0 and approach_speed < desired - 10.0:
		# Exact impulse to close the deficit in one frame.
		var f := clampf((desired - approach_speed) / _delta, 0.0, thrust_force * 0.4)
		var tscale := f / (thrust_force * 0.4)
		apply_force(-transform.y * f * 0.5, transform.basis_xform(ENGINE_RL))
		apply_force(-transform.y * f * 0.5, transform.basis_xform(ENGINE_RR))
		if debug_log:
			_dbg_engage = "THRUST(%.0fN)" % f
		_thrusters.set_target(flame_rl, tscale)
		_thrusters.set_target(flame_rr, tscale)
		return tscale > 0.05

	_thrusters.set_target(flame_rl, 0.0)
	_thrusters.set_target(flame_rr, 0.0)
	return false


func _predict_player_pos() -> Vector2:
	var dist := global_position.distance_to(_player.global_position)
	var bullet_spd := _weapon.bullet_speed if _weapon != null else 600.0
	var travel_time := dist / bullet_spd
	return _player.global_position + _player.linear_velocity * travel_time


func _try_fire(aim_pos: Vector2) -> void:
	if _weapon == null or not _weapon.can_fire():
		return
	if global_position.distance_to(_player.global_position) > _weapon.weapon_range:
		return
	var aim_dir := (aim_pos - global_position).normalized()
	if (-transform.y).dot(aim_dir) > 0.5:
		_weapon.fire(aim_dir)
