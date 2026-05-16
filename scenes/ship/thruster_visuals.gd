class_name ThrusterVisuals
extends Node2D

const FLAME_GROW_RATE   := 5.0
const FLAME_DRIFT_RATE  := 2.5
const FLAME_SHRINK_RATE := 2.0
const FLAME_FADE_RATE   := 7.0
const FLAME_SCALE       := 1.8

const FLAME_SHADER := preload("res://shaders/flame.gdshader")

var _flame_mats:         Dictionary  # ColorRect -> ShaderMaterial
var _flame_base:         Dictionary  # ColorRect -> float
var _flame_tip:          Dictionary  # ColorRect -> float
var _flame_opacity:      Dictionary  # ColorRect -> float
var _flame_tgt:          Dictionary  # ColorRect -> float (0 = off, 0–1 = thrust level)
var _flame_was_firing:   Dictionary  # ColorRect -> bool (edge-detect for puff cutoff)
var _flame_puffs:        Dictionary  # ColorRect -> CPUParticles2D
var _flame_is_main:      Dictionary  # ColorRect -> bool
var _flame_exhaust_dirs: Dictionary  # ColorRect -> Vector2 (local space)
var _all_flames:         Array[ColorRect]

var _ship: RigidBody2D


func init(ship: RigidBody2D) -> void:
	_ship = ship


func register(flame: ColorRect, engine_pos: Vector2, exhaust_dir: Vector2, w: float, l: float, is_main: bool) -> void:
	_place_flame(flame, engine_pos, exhaust_dir, w, l, is_main)


func set_target(flame: ColorRect, level: float) -> void:
	_flame_tgt[flame] = level


func set_gimbal(rad: float) -> void:
	for flame: ColorRect in _all_flames:
		if _flame_is_main[flame]:
			flame.rotation = rad


func tick(delta: float) -> void:
	for flame: ColorRect in _all_flames:
		var tgt:        float = _flame_tgt[flame]
		var base:       float = _flame_base[flame]
		var tip:        float = _flame_tip[flame]
		var op:         float = _flame_opacity[flame]
		var was_firing: bool  = _flame_was_firing[flame]

		if tgt > 0.0:
			base = 0.0
			tip  = move_toward(tip, tgt, FLAME_GROW_RATE * delta)
			op   = 1.0
			_flame_was_firing[flame] = true
		else:
			if was_firing:
				_fire_puff(flame)
				_flame_was_firing[flame] = false
			if tip > 0.005 and op > 0.01:
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


func _place_flame(flame: ColorRect, engine_pos: Vector2, exhaust_dir: Vector2, w: float, l: float, is_main: bool) -> void:
	var rl := l * FLAME_SCALE
	if exhaust_dir.y > 0.0:
		flame.size = Vector2(w, rl)
		flame.position = engine_pos + Vector2(-w * 0.5, 0.0)
		if is_main:
			flame.pivot_offset = Vector2(w * 0.5, 0.0)
	elif exhaust_dir.y < 0.0:
		flame.size = Vector2(w, rl)
		flame.position = engine_pos + Vector2(-w * 0.5, -rl)
		if is_main:
			flame.pivot_offset = Vector2(w * 0.5, rl)
	elif exhaust_dir.x > 0.0:
		flame.size = Vector2(rl, w)
		flame.position = engine_pos + Vector2(0.0, -w * 0.5)
	else:
		flame.size = Vector2(rl, w)
		flame.position = engine_pos + Vector2(-rl, -w * 0.5)

	var mat := ShaderMaterial.new()
	mat.shader = FLAME_SHADER
	mat.set_shader_parameter("is_horizontal", exhaust_dir.x != 0.0)
	mat.set_shader_parameter("is_flipped",    exhaust_dir.x < 0.0 or exhaust_dir.y < 0.0)
	mat.set_shader_parameter("speed",         1.5 if is_main else 2.5)
	mat.set_shader_parameter("turbulence",    0.7 if is_main else 1.1)
	mat.set_shader_parameter("rect_scale",    FLAME_SCALE)
	mat.set_shader_parameter("flame_base",    0.0)
	mat.set_shader_parameter("flame_tip",     0.0)
	mat.set_shader_parameter("opacity",       0.0)
	flame.visible = false
	flame.material = mat

	_flame_mats[flame]         = mat
	_flame_base[flame]         = 0.0
	_flame_tip[flame]          = 0.0
	_flame_opacity[flame]      = 0.0
	_flame_tgt[flame]          = 0.0
	_flame_was_firing[flame]   = false
	_flame_is_main[flame]      = is_main
	_flame_exhaust_dirs[flame] = exhaust_dir

	var puff := CPUParticles2D.new()
	puff.emitting             = false
	puff.one_shot             = true
	puff.amount               = 6 if is_main else 4
	puff.lifetime             = 0.45 if is_main else 0.3
	puff.explosiveness        = 0.85
	puff.direction            = exhaust_dir
	puff.spread               = 30.0
	puff.gravity              = Vector2.ZERO
	puff.initial_velocity_min = 50.0 if is_main else 30.0
	puff.initial_velocity_max = 110.0 if is_main else 65.0
	puff.scale_amount_min     = 0.25
	puff.scale_amount_max     = 0.75 if is_main else 0.5
	puff.position             = engine_pos
	var grad := Gradient.new()
	grad.set_color(0, Color.WHITE)
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	puff.color_ramp = grad
	add_child(puff)
	_flame_puffs[flame] = puff

	_all_flames.append(flame)


func _fire_puff(flame: ColorRect) -> void:
	var puff: CPUParticles2D = _flame_puffs[flame]
	var is_main: bool = _flame_is_main[flame]
	var exhaust_world: Vector2 = _flame_exhaust_dirs[flame].rotated(_ship.rotation)
	var exhaust_speed: float = 80.0 if is_main else 47.5
	var combined: Vector2 = _ship.linear_velocity + exhaust_world * exhaust_speed
	var speed: float = combined.length()
	var world_dir: Vector2 = combined.normalized() if speed > 1.0 else exhaust_world
	puff.direction = world_dir.rotated(-_ship.rotation)
	puff.initial_velocity_min = speed * 0.7
	puff.initial_velocity_max = speed * 1.3
	puff.emitting = true
