extends BaseShip

@export var rear_thrust_force: float = 120000.0
@export var front_thrust_force: float = 100000.0
@export var brake_force: float = 160000.0
@export var brake_gain: float = 500.0
@export var stabilizer_force: float = 24000.0
@export var angular_stab_gain: float = 10.0
@export var gimbal_max_angle: float = 20.0
@export var gimbal_speed: float = 8.0
@export var lateral_rcs_gain: float = 200.0
@export var lateral_rcs_max: float = 100000.0
@export var steering_ratio: float = 0.35

const FLAME_MAIN_W := 8.0
const FLAME_MAIN_L := 36.0
const FLAME_AUX_W  := 5.0
const FLAME_AUX_L  := 12.0

const ENGINE_RL    := Vector2(-10.0, 40.0)   # Rear Left
const ENGINE_RR    := Vector2(10.0, 40.0)    # Rear Right
const ENGINE_FL    := Vector2(-10.0, -40.0)  # Front Left
const ENGINE_FR    := Vector2(10.0, -40.0)   # Front Right
const ENGINE_SFR   := Vector2(20.0, -25.0)   # Side Forward Right
const ENGINE_SFL   := Vector2(-20.0, -25.0)  # Side Forward Left
const ENGINE_SRR   := Vector2(20.0, 25.0)    # Side Rear Right
const ENGINE_SRL   := Vector2(-20.0, 25.0)   # Side Rear Left
const ENGINE_RCS_R := Vector2(20.0, 0.0)     # Lateral RCS, fires -X
const ENGINE_RCS_L := Vector2(-20.0, 0.0)    # Lateral RCS, fires +X

const SHIP_SHADER := preload("res://shaders/ship.gdshader")

@onready var flame_rl:    ColorRect = $Flames/FlameRL
@onready var flame_rr:    ColorRect = $Flames/FlameRR
@onready var flame_fl:    ColorRect = $Flames/FlameFL
@onready var flame_fr:    ColorRect = $Flames/FlameFR
@onready var flame_sfr:   ColorRect = $Flames/FlameSFR
@onready var flame_sfl:   ColorRect = $Flames/FlameSFL
@onready var flame_srr:   ColorRect = $Flames/FlameSRR
@onready var flame_srl:   ColorRect = $Flames/FlameSRL
@onready var flame_lat_r: ColorRect = $Flames/FlameLAT_R
@onready var flame_lat_l: ColorRect = $Flames/FlameLAT_L

var gimbal_angle: float = 0.0
var _hull_mat: ShaderMaterial
var _thrusters: ThrusterVisuals
var _docked: bool

var _weapon_component: WeaponComponent
var _engine_component: EngineComponent
var _weapon_dir := Vector2.UP
var _fire_held := false


func _ready() -> void:
	super._ready()
	add_to_group("player")
	WorldData.track_ship(self, &"player")
	var mat := ShaderMaterial.new()
	mat.shader = SHIP_SHADER
	$Hull.material = mat
	$Logo.material = mat
	_hull_mat = mat
	%Health.value = GameState.hp
	_setup_thruster_visuals()
	_equip_default_parts()
	GameState.equipped_parts_changed.connect(_on_equipped_parts_changed)
	_on_equipped_parts_changed()


func _process(delta: float) -> void:
	_hull_mat.set_shader_parameter("ship_rotation", rotation)
	_thrusters.tick(delta)

	var mouse_world := get_global_mouse_position()
	if mouse_world.distance_squared_to(global_position) > 1.0:
		_weapon_dir = (mouse_world - global_position).normalized()
	if _fire_held and _weapon_component != null:
		_weapon_component.fire(_weapon_dir)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var hovered := get_viewport().gui_get_hovered_control()
			_fire_held = not (hovered is BaseButton)
		else:
			_fire_held = false


func _equip_default_parts() -> void:
	var parts := DataLoader.load_ship_parts()
	_create_slot(&"engine", parts.get("engine_basic"))
	_create_slot(&"hull",   parts.get("hull_basic"))
	_create_slot(&"shield", parts.get("shield_basic"))


func _apply_equipped_weapon() -> void:
	for child in get_children():
		if child is ShipPartSlot and child.slot_id == &"weapon":
			child.queue_free()
	_weapon_component = null
	var part := GameState.equipped_parts.get(&"weapon") as ShipPartData
	if part is WeaponPartData:
		var slot := ShipPartSlot.new()
		slot.slot_id = &"weapon"
		add_child(slot)
		slot.equip(part)
		for c in slot.get_children():
			if c is WeaponComponent:
				_weapon_component = c as WeaponComponent
				break


func _on_equipped_parts_changed() -> void:
	_apply_equipped_weapon()
	_apply_equipped_slot(&"engine")
	_apply_equipped_slot(&"hull")
	_apply_equipped_slot(&"shield")
	_engine_component = find_in_slots(EngineComponent) as EngineComponent


func _apply_equipped_slot(sid: StringName) -> void:
	var part := GameState.equipped_parts.get(sid) as ShipPartData
	if part == null:
		return
	for child in get_children():
		if child is ShipPartSlot and child.slot_id == sid:
			child.equip(part)
			return
	_create_slot(sid, part)


func _create_slot(sid: StringName, part: ShipPartData) -> void:
	if part == null:
		return
	var slot := ShipPartSlot.new()
	slot.slot_id = sid
	add_child(slot)
	slot.equip(part)


func _setup_thruster_visuals() -> void:
	_thrusters = ThrusterVisuals.new()
	add_child(_thrusters)
	_thrusters.init(self)
	_thrusters.register(flame_rl,    ENGINE_RL,    Vector2(0, 1),   FLAME_MAIN_W, FLAME_MAIN_L, true)
	_thrusters.register(flame_rr,    ENGINE_RR,    Vector2(0, 1),   FLAME_MAIN_W, FLAME_MAIN_L, true)
	_thrusters.register(flame_fl,    ENGINE_FL,    Vector2(0, -1),  FLAME_MAIN_W, FLAME_MAIN_L, true)
	_thrusters.register(flame_fr,    ENGINE_FR,    Vector2(0, -1),  FLAME_MAIN_W, FLAME_MAIN_L, true)
	_thrusters.register(flame_sfr,   ENGINE_SFR,   Vector2(1, 0),   FLAME_AUX_W,  FLAME_AUX_L,  false)
	_thrusters.register(flame_sfl,   ENGINE_SFL,   Vector2(-1, 0),  FLAME_AUX_W,  FLAME_AUX_L,  false)
	_thrusters.register(flame_srr,   ENGINE_SRR,   Vector2(1, 0),   FLAME_AUX_W,  FLAME_AUX_L,  false)
	_thrusters.register(flame_srl,   ENGINE_SRL,   Vector2(-1, 0),  FLAME_AUX_W,  FLAME_AUX_L,  false)
	_thrusters.register(flame_lat_r, ENGINE_RCS_R, Vector2(1, 0),   FLAME_AUX_W,  FLAME_AUX_L,  false)
	_thrusters.register(flame_lat_l, ENGINE_RCS_L, Vector2(-1, 0),  FLAME_AUX_W,  FLAME_AUX_L,  false)


func _physics_process(delta: float) -> void:
	var forward_dir := -transform.y
	var turn_input := Input.get_axis("turn_left", "turn_right")
	var thrusting_forward := Input.is_action_pressed("thrust_forward")
	var thrusting_reverse := Input.is_action_pressed("thrust_reverse")
	var braking := Input.is_action_pressed("brake")

	var gimbal_target := 0.0 if braking else -turn_input * gimbal_max_angle
	gimbal_angle = lerp(gimbal_angle, gimbal_target, gimbal_speed * delta)

	if GameState._is_ship_docked and not braking and linear_velocity.length_squared()>0.1:
		braking = true
	elif GameState._is_ship_docked and Input.is_action_pressed('thrust_forward'):
		GameState.undock()

	if braking:
		_brake(forward_dir, turn_input)
		_update_flames_braking(forward_dir, turn_input)
		return

	var boost_req := Input.is_action_pressed("boost")
	var thrust_mult := 1.0
	if _engine_component != null:
		_engine_component.tick(delta, boost_req)
		thrust_mult = _engine_component.power_multiplier
		if boost_req and _engine_component.has_boost() and _engine_component.boost_charge > 0.0:
			thrust_mult *= 2.0

	var steer := transform.x * sin(deg_to_rad(gimbal_angle)) * steering_ratio

	if thrusting_forward:
		apply_central_force(forward_dir * rear_thrust_force * thrust_mult)
		apply_force(steer * rear_thrust_force * thrust_mult, Vector2(0.0, 40.0).rotated(rotation))

	if thrusting_reverse:
		apply_central_force(-forward_dir * front_thrust_force * thrust_mult)
		apply_force(-steer * front_thrust_force * thrust_mult, Vector2(0.0, -40.0).rotated(rotation))

	if thrusting_forward:
		_apply_lateral_rcs()

	var straightening: bool = thrusting_forward and abs(turn_input) < 0.1

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

	_update_flames(thrusting_forward, thrusting_reverse, fire_left, fire_right, stab_f / stabilizer_force, straightening)


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


func _update_flames(forward: bool, reverse: bool, fire_left: bool, fire_right: bool, stab_ratio: float, straightening: bool) -> void:
	_thrusters.set_target(flame_rl,    1.0 if forward               else 0.0)
	_thrusters.set_target(flame_rr,    1.0 if forward               else 0.0)
	_thrusters.set_target(flame_fl,    1.0 if reverse               else 0.0)
	_thrusters.set_target(flame_fr,    1.0 if reverse               else 0.0)
	_thrusters.set_target(flame_sfr,   stab_ratio if fire_left      else 0.0)
	_thrusters.set_target(flame_srl,   stab_ratio if fire_left      else 0.0)
	_thrusters.set_target(flame_sfl,   stab_ratio if fire_right     else 0.0)
	_thrusters.set_target(flame_srr,   stab_ratio if fire_right     else 0.0)
	var lat_spd := transform.x.dot(linear_velocity)
	if straightening:
		var lat_ratio := minf(absf(lat_spd) * lateral_rcs_gain, lateral_rcs_max) / lateral_rcs_max
		_thrusters.set_target(flame_lat_r, lat_ratio if lat_spd > 0.1  else 0.0)
		_thrusters.set_target(flame_lat_l, lat_ratio if lat_spd < -0.1 else 0.0)
	else:
		_thrusters.set_target(flame_lat_r, 0.0)
		_thrusters.set_target(flame_lat_l, 0.0)
	_thrusters.set_gimbal(deg_to_rad(gimbal_angle))


func _update_flames_braking(forward_dir: Vector2, turn_input: float) -> void:
	var fwd_spd := forward_dir.dot(linear_velocity)
	var lat_spd := transform.x.dot(linear_velocity)

	_thrusters.set_target(flame_fl, clamp(absf(fwd_spd) / 10.0, 0.0, 1.0) if fwd_spd > 0.5  else 0.0)
	_thrusters.set_target(flame_fr, clamp(absf(fwd_spd) / 10.0, 0.0, 1.0) if fwd_spd > 0.5  else 0.0)
	_thrusters.set_target(flame_rl, 1.0 if fwd_spd < -0.5 else 0.0)
	_thrusters.set_target(flame_rr, 1.0 if fwd_spd < -0.5 else 0.0)

	if absf(turn_input) > 0.1:
		var fire_left := turn_input < 0.0
		_thrusters.set_target(flame_sfr, 1.0 if fire_left     else 0.0)
		_thrusters.set_target(flame_srl, 1.0 if fire_left     else 0.0)
		_thrusters.set_target(flame_sfl, 1.0 if not fire_left else 0.0)
		_thrusters.set_target(flame_srr, 1.0 if not fire_left else 0.0)
	else:
		var stab_l := angular_velocity > 0.05
		var stab_r := angular_velocity < -0.05
		_thrusters.set_target(flame_sfr, 1.0 if stab_l else 0.0)
		_thrusters.set_target(flame_srr, 1.0 if stab_r else 0.0)
		_thrusters.set_target(flame_sfl, 1.0 if stab_r else 0.0)
		_thrusters.set_target(flame_srl, 1.0 if stab_l else 0.0)

	_thrusters.set_target(flame_lat_r, 1.0 if lat_spd > 0.3  else 0.0)
	_thrusters.set_target(flame_lat_l, 1.0 if lat_spd < -0.3 else 0.0)

	_thrusters.set_gimbal(deg_to_rad(gimbal_angle))
